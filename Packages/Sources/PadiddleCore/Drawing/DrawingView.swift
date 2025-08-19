import ComposableArchitecture
import SwiftUI
import Utilities

let brushDiameter = 12.0

@Reducer
struct DrawingFeature {
  @ObservableState
  struct State: Equatable {
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
    case updateMotion
    case addPoint(CGPoint)
  }

  @Dependency(\.bitmapContextClient)
  private var bitmapContext

  @Dependency(\.drawingLayerClient.layer)
  private var drawingLayer

  @Dependency(\.deviceMotionClient)
  private var motionClient

  @Shared(.isRecording)
  private var isRecording

  @SharedReader(.colorGenerator)
  private var colorGenerator

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .onAppear(let viewSize):
      state.viewSize = viewSize
      return .none

    case .updateMotion:
      guard let viewSize = state.viewSize else {
        return .none
      }

      return .run { send in
        if let deviceMotion = await motionClient.deviceMotion() {
          let zRotation = deviceMotion.rotationRateZ
          let maxRadius = max(viewSize.width, viewSize.height) / 2
          let radius = maxRadius / 30 * abs(zRotation)

          // Yaw is on the range [-π...π]. Remap to [0...π]
          let theta = deviceMotion.attitudeYaw + .pi

          let contextSize = bitmapContext.contextSize()
          let x = radius * cos(theta) + contextSize.width / 2
          let y = radius * sin(theta) + contextSize.height / 2
          await send(.addPoint(CGPoint(x: x, y: y)))
        }
      }

    case .addPoint(let point):
      state.nibLocation = point
      if isRecording {
        let contextSize = bitmapContext.contextSize()
        let contextScaleFactor = bitmapContext.contextFittingScaleFactor()

        if state.needToMoveNibToNewStartLocation {
          state.restart(
            at: point,
            contextSize: contextSize,
            contextScaleFactor: contextScaleFactor
          )
          state.needToMoveNibToNewStartLocation = false
        } else {
          state.addPoint(
            point,
            contextSize: contextSize,
            contextScaleFactor: contextScaleFactor
          )
        }

        let pathSegment = CGPath.smoothedPathSegment(points: state.points)
        let context = bitmapContext.context()!
        context.addPath(pathSegment)
        #warning("TODO: real color")
        context.setStrokeColor(UIColor.green.cgColor)
        context.strokePath()
        drawingLayer().contents = context.makeImage()
      }
      return .none
    }
  }
}

extension DrawingFeature.State {
  mutating func addPoint(
    _ point: CGPoint,
    contextSize: CGSize,
    contextScaleFactor: CGFloat
  ) {
    let scaledPoint = convertViewPointToContextCoordinates(
      point,
      contextSize: contextSize,
      contextFittingScaleFactor: contextScaleFactor
    )
    let distance = CGPoint.distanceBetween(points[3], scaledPoint)
    if distance > 2.25 {
      points.removeFirst()
      points.append(scaledPoint)
    }
  }

  mutating func restart(
    at point: CGPoint,
    contextSize: CGSize,
    contextScaleFactor: CGFloat
  ) {
    let scaledPoint = convertViewPointToContextCoordinates(
      point,
      contextSize: contextSize,
      contextFittingScaleFactor: contextScaleFactor
    )
    points = Array(repeating: scaledPoint, count: points.count)
  }

  private func convertViewPointToContextCoordinates(
    _ point: CGPoint,
    contextSize: CGSize,
    contextFittingScaleFactor: CGFloat
  ) -> CGPoint {
    guard let viewSize else {
      fatalError("Not having a view size represents a programmer error")
    }

    var newPoint = point

    // 1. Scale the point by the context scale factor
    newPoint.x /= contextFittingScaleFactor
    newPoint.y /= contextFittingScaleFactor

    // 2. Get the size of self in context coordinates
    let scaledViewSize = CGSize(
      width: viewSize.width / contextFittingScaleFactor,
      height: viewSize.height / contextFittingScaleFactor
    )

    // 3. Get the difference in size between self and the context
    let difference = CGSize(
      width: contextSize.width - scaledViewSize.width,
      height: contextSize.height - scaledViewSize.height
    )

    // 4. Shift the point by half the difference in width and height
    newPoint.x += difference.width / 2
    newPoint.y += difference.height / 2

    return newPoint
  }
}

struct DrawingView: View {
  let store: StoreOf<DrawingFeature>

  @Dependency(\.bitmapContextClient.context)
  private var bitmapContext

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
