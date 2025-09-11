import ComposableArchitecture
import SwiftUI
import Utilities

@Reducer
struct RootFeature {
  @ObservableState
  struct State: Equatable {
    var screenMetrics: ScreenMetrics?

    // Nested Features
    var deviceMotion: DeviceMotionFeature.State = .init()
    var drawing: DrawingFeature.State = .init()
    var toolbar: ToolbarFeature.State = .init()
  }

  enum Action {
    case screenChanged(ScreenMetrics?)
    case scenePhaseChanged(ScenePhase)

    #if DEBUG
    case debugDrawImage
    #endif

    // Nested Features
    case deviceMotion(DeviceMotionFeature.Action)
    case drawing(DrawingFeature.Action)
    case toolbar(ToolbarFeature.Action)
  }

  @Dependency(\.bitmapContextClient) var bitmapContext
  @Dependency(\.deviceMotionClient) var deviceMotion

  var body: some ReducerOf<Self> {
    Scope(state: \.deviceMotion, action: \.deviceMotion) {
      DeviceMotionFeature()
    }

    Scope(state: \.drawing, action: \.drawing) {
      DrawingFeature()
    }

    Scope(state: \.toolbar, action: \.toolbar) {
      ToolbarFeature()
    }

    Reduce { state, action in
      switch action {
      case .screenChanged(let metrics):
        if let metrics {
          let maxDimension = max(metrics.size.width, metrics.size.height)
          state.drawing.contextSideLength = maxDimension
          return .run { send in
            let success = await bitmapContext.configure(
              contextSideLength: maxDimension,
              screenScale: metrics.scale
            )
            assert(success, "Problem creating bitmap context")

            await send(.deviceMotion(.start))
          }
        }

        return .none

      case .scenePhaseChanged(let phase):
        return .run { send in
          switch phase {
          case .active:
            await send(.deviceMotion(.start))
          case .inactive,
               .background:
            await send(.deviceMotion(.stop))
          @unknown default:
            assertionFailure("unknown scene phase \(phase)")
          }
        }

      #if DEBUG
      case .debugDrawImage:
        Shared(.isRecording).withLock { $0 = true }
        return .run { send in
          await send(.drawing(.eraseDrawing))
          await send(.toolbar(.hint(.spunEnoughToHideSpinPrompt)))

          // Uncomment the code in DrawingView to capture new values for this file
          guard let sampleURL = Bundle.module.url(forResource: "sample_drawing", withExtension: "json") else {
            assertionFailure("could not find sample URL")
            return
          }

          let data = try Data(contentsOf: sampleURL)
          let motions = try JSONDecoder().decode([PadiddleDeviceMotion].self, from: data)

          for motion in motions {
            await send(.drawing(.processMotion(motion)))
          }
          Shared(.isRecording).withLock { $0 = false }
        }
      #endif

      case .deviceMotion(.delegate(let action)):
        switch action {
        case .spunSufficiently:
          return .send(.toolbar(.hint(.spunEnoughToHideSpinPrompt)))
        }

      case .toolbar(.delegate(.eraseDrawing)):
        return .send(.drawing(.eraseDrawing))

      case .deviceMotion,
           .drawing,
           .toolbar:
        return .none
      }
    }
  }
}

public struct RootView: View {
  let store = StoreOf<RootFeature>(initialState: .init()) {
    RootFeature()
      .signpost()
      ._printChanges(.init(printChange: { receivedAction, oldState, newState in
        switch receivedAction {
        case .drawing(.updateMotion),
             .drawing(.processMotion):
          // noisy things
          break
        default:
          _ReducerPrinter.customDump.printChange(receivedAction: receivedAction, oldState: oldState, newState: newState)
        }
      }))
  }

  @Environment(\.scenePhase)
  private var scenePhase

  public init() {}

  public var body: some View {
    ZStack {
      GeometryReader { proxy in
        DrawingView(
          store: store.scope(
            state: \.drawing,
            action: \.drawing
          )
        )
        .counterRotating(longestSideLength: max(proxy.size.width, proxy.size.height))
      }
      .ignoresSafeArea()
      #if DEBUG
        .overlay {
          Color.clear
            .contentShape(.rect) // make clear color tappable
            .onTapGesture(count: 2) {
              store.send(.debugDrawImage)
            }
        }
      #endif

      ToolbarView(
        store: store.scope(
          state: \.toolbar,
          action: \.toolbar
        )
      )
      .frame(maxHeight: .infinity, alignment: .bottom)
    }
    .onScreenChange { metrics in
      store.send(.screenChanged(metrics))
    }
    .onChange(of: scenePhase) {
      store.send(.scenePhaseChanged(scenePhase))
    }
    .statusBarHidden()
  }
}

#Preview {
  RootView()
}
