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

    Reduce { _, action in
      switch action {
      case .screenChanged(let metrics):
        if let metrics {
          let maxDimension = max(metrics.size.width, metrics.size.height)
          let contextSize = CGSize.square(sideLength: maxDimension)
          let success = bitmapContext.configureContext(
            contextSize: contextSize,
            screenScale: metrics.scale
          )
          assert(success, "Problem creating bitmap context")

          return .run { send in
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

      case .deviceMotion(.delegate(let action)):
        switch action {
        case .spunSufficiently:
          return .send(.toolbar(.hint(.spunEnoughToHideSpinPrompt)))
        }

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
      ._printChanges(.init(printChange: { receivedAction, oldState, newState in
        switch receivedAction {
        case .drawing(.updateMotion):
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
