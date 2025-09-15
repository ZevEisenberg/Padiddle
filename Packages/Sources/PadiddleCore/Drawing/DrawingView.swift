import ComposableArchitecture
import Models
import SwiftUI
import Utilities

let brushDiameter = 12.0

@Reducer
struct DrawingFeature {
  @ObservableState
  struct State: Equatable {
    var contextSideLength: CGFloat = 0

    /// Where the nib is right now, relative to the center point.
    var nibLocation: CGPoint = .zero

    var needToMoveNibToNewStartLocation = true

    /// A rolling buffer of the last _n_ points recorded. Used for Bézier path smoothing.
    var points = Array(repeating: CGPoint.zero, count: 4)

    /// The size of the drawing view in points.
    var viewSize: CGSize?
  }

  enum Action {
    case onAppear(viewSize: CGSize)
    case eraseDrawing
    case updateMotion
    case processMotion(PadiddleDeviceMotion)
  }

  @Dependency(\.bitmapContextClient)
  private var bitmapContext

  @Dependency(\.drawingLayerClient.layer)
  private var drawingLayer

  @Dependency(\.deviceMotionClient)
  private var motionClient

  @Dependency(\.imageIO)
  private var imageIO

  @SharedReader(.isRecording)
  private var isRecording

  @SharedReader(.colorGenerator)
  private var colorGenerator

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .onAppear(let viewSize):
      state.viewSize = viewSize

      if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
        return .run { _ in
          let sideLength = await Int(bitmapContext.contextSideLength * bitmapContext.screenScale)
          let image = imageIO.fetchImage(sideLengthPixels: sideLength)
          await CATransaction.withoutAnimation {
            drawingLayer().contents = image
          }
        }
      }

      return .none

    case .eraseDrawing:
      return .run { _ in
        await bitmapContext.eraseDrawing()
        await CATransaction.withoutAnimation {
          drawingLayer().contents = await bitmapContext.contextOperation { $0.makeImage() }
        }
      }

    case .updateMotion:
      return .run { send in
        if let deviceMotion = await motionClient.deviceMotion() {
          await send(.processMotion(deviceMotion))
        }
      }

    case .processMotion(let motion):
      guard let viewSize = state.viewSize else {
        return .none
      }

      // Uncomment to record new drawing data
//      if isRecording {
//        let motionData = try! JSONEncoder().encode(motion)
//        print("motionLog:", String(decoding: motionData, as: UTF8.self))
//      }

      let zRotation = motion.rotationRateZ
      let maxRadius = max(viewSize.width, viewSize.height) / 2
      let radius = maxRadius / 30 * abs(zRotation)

      // Yaw is on the range [-π...π]. Remap to [0...π]
      let theta = motion.attitudeYaw + .pi

      let coordinate = ColorGenerator.Coordinate(
        radius: radius,
        theta: theta,
        maxRadius: maxRadius
      )

      let contextSideLength = state.contextSideLength
      let x = radius * cos(theta) + contextSideLength / 2
      let y = radius * sin(theta) + contextSideLength / 2
      let point = CGPoint(x: x, y: y)

      state.nibLocation = point
      if isRecording {
        if state.needToMoveNibToNewStartLocation {
          state.restart(
            at: point,
            contextSideLength: contextSideLength
          )
          state.needToMoveNibToNewStartLocation = false
        } else {
          state.addPoint(
            point,
            contextSideLength: contextSideLength
          )
        }

        let points = state.points
        return .run { _ in
          await bitmapContext.contextOperation { context in
            let pathSegment = CGPath.smoothedPathSegment(points: points)
            context.addPath(pathSegment)
            if let color = colorGenerator.color(at: coordinate).cgColor {
              context.setStrokeColor(color)
            }
            context.strokePath()
          }
          await CATransaction.withoutAnimation {
            drawingLayer().contents = await bitmapContext.contextOperation { $0.makeImage() }
          }
        }
      }
      return .none
    }
  }
}

extension DrawingFeature.State {
  mutating func addPoint(
    _ point: CGPoint,
    contextSideLength: CGFloat
  ) {
    let scaledPoint = convertViewPointToContextCoordinates(
      point,
      contextSideLength: contextSideLength
    )
    let distance = CGPoint.distanceBetween(points[3], scaledPoint)
    if distance > 2.25 {
      points.removeFirst()
      points.append(scaledPoint)
    }
  }

  mutating func restart(
    at point: CGPoint,
    contextSideLength: CGFloat
  ) {
    let scaledPoint = convertViewPointToContextCoordinates(
      point,
      contextSideLength: contextSideLength
    )
    points = Array(repeating: scaledPoint, count: points.count)
  }

  private func convertViewPointToContextCoordinates(
    _ point: CGPoint,
    contextSideLength: CGFloat
  ) -> CGPoint {
    guard let viewSize else {
      fatalError("Not having a view size represents a programmer error")
    }

    var newPoint = point

    // 1. Get the difference in size between self and the context
    let difference = CGSize(
      width: contextSideLength - viewSize.width,
      height: contextSideLength - viewSize.height
    )

    // 2. Shift the point by half the difference in width and height
    newPoint.x += difference.width / 2
    newPoint.y += difference.height / 2

    return newPoint
  }
}

struct DrawingView: View {
  let store: StoreOf<DrawingFeature>

  @Dependency(\.drawingLayerClient.layer)
  private var drawingLayer

  var body: some View {
    GeometryReader { proxy in
      TimelineView(.animation) { context in
        LayerHostingViewRepresentable(hostedLayer: drawingLayer())
          .onChange(of: context.date) {
            store.send(.updateMotion)
          }
      }
      .overlay(alignment: .topLeading) {
        Circle()
          .stroke(Color(UIColor.systemBackground), lineWidth: 1)
          .fill(Color(UIColor.label))
          .frame(width: brushDiameter)
          .alignmentGuide(.top) { $0[.center] }
          .alignmentGuide(.leading) { $0[.center] }
          .offset(store.nibLocation)
      }
      .onAppear {
        store.send(.onAppear(viewSize: proxy.size))
      }
    }
  }
}

@DependencyClient
struct DrawingLayerClient: DependencyKey, Sendable {
  var layer: @Sendable () -> CALayer = { CALayer() }

  static var testValue: Self {
    liveValue
  }
}

extension DrawingLayerClient {
  static var liveValue: Self {
    MainActor.assertIsolated()
    nonisolated(unsafe) let layer = CALayer()
    return Self(layer: { layer })
  }
}

extension DependencyValues {
  var drawingLayerClient: DrawingLayerClient {
    get { self[DrawingLayerClient.self] }
    set { self[DrawingLayerClient.self] = newValue }
  }
}

extension CATransaction {
  static func withoutAnimation(_ block: @Sendable () async -> Void) async {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    await block()
    CATransaction.commit()
  }
}

#Preview {
  DrawingView(
    store: .init(
      initialState: .init(
        nibLocation: CGPoint(x: 0, y: 0)
      )
    ) {
      DrawingFeature()
    })
}
