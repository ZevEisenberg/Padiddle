import ComposableArchitecture1
import os
import SwiftUI
import Utilities

let signposter = OSSignposter(subsystem: "padiddle", category: "root")

@Feature
struct RootFeature {
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

  var body: some FeatureProtocol<State, Action> {
    Update { _, action in
      switch action {
      case .screenChanged(let metrics):
        signposter.emitEvent("screenChanged", "metrics: \(String(describing: metrics))")
      case .scenePhaseChanged(let phase):
        signposter.emitEvent("screenPhaseChanged", "metrics: \(String(describing: phase))")
      #if DEBUG
      case .debugDrawImage:
        signposter.emitEvent("debugDrawImage")
      #endif
      case .deviceMotion(let motion):
        signposter.emitEvent("deviceMotion", "motion: \(String(describing: motion))")
      case .drawing(let drawing):
        signposter.emitEvent("drawing", "\(String(describing: drawing))")
      case .toolbar(let toolbar):
        signposter.emitEvent("toolbar", "\(String(describing: toolbar))")
      }
    }
    Scope(\.deviceMotion) {
      DeviceMotionFeature(delegate: { action in
        switch action {
        case .spunSufficiently:
          store.addTask {
            try store.toolbar.hint.spunEnoughToHidePrompt()
          }
        }
      })
    }

    Scope(\.drawing) {
      DrawingFeature()
    }

    Scope(\.toolbar) {
      ToolbarFeature(
        delegate: { action in
          switch action {
          case .eraseDrawing:
            try store.drawing.erase()
          }
        }
      )
    }

    Update { state, action in
      switch action {
      case .screenChanged(let metrics):
        if let metrics {
          let maxDimension = max(metrics.size.width, metrics.size.height)
          state.drawing.contextSideLength = maxDimension
          store.addTask {
            let success = await bitmapContext.configure(
              contextSideLength: maxDimension,
              screenScale: metrics.scale
            )
            assert(success, "Problem creating bitmap context")

            try store.send(.deviceMotion(.start))
          }
        }

      case .scenePhaseChanged(let phase):
        store.addTask {
          switch phase {
          case .active:
            try store.send(.deviceMotion(.start))
            try store.toolbar.hint.start()
          case .inactive,
               .background:
            try store.send(.deviceMotion(.stop))
          @unknown default:
            assertionFailure("unknown scene phase \(phase)")
          }
        }

      #if DEBUG
      case .debugDrawImage:
        Shared(.isRecording).withLock { $0 = true }
        store.addTask {
          try store.drawing.erase()
          try store.toolbar.hint.spunEnoughToHidePrompt()

          // Uncomment the code in DrawingView to capture new values for this file
          guard let sampleURL = #bundle.url(forResource: "sample_drawing", withExtension: "json") else {
            assertionFailure("could not find sample URL")
            return
          }

          let data = try Data(contentsOf: sampleURL)
          let motions = try JSONDecoder().decode([PadiddleDeviceMotion].self, from: data)

          for motion in motions {
            try store.send(.drawing(.processMotion(motion)))
          }
          Shared(.isRecording).withLock { $0 = false }
        }
      #endif

      case .deviceMotion,
           .drawing,
           .toolbar:
        break
      }
    }
  }
}

public struct RootView: View {
  let store = StoreOf<RootFeature>(initialState: .init()) {
    RootFeature()

    // swiftlint:disable:next redundant_discardable_let
    let _ = RootFeature._logChanges()
    // swiftformat:disable:previous redundantLet

    #warning("TODO: use action/trigger/delegation/event/private stuff to reduce noise instead of doing it the old way")

//    let _ = RootFeature._printChanges(.init(printChange: { receivedAction, oldState, newState in
//      switch receivedAction {
//      case .drawing(.updateMotion),
//           .drawing(.processMotion):
//        // noisy things
//        break
//      default:
//        _ReducerPrinter.customDump.printChange(receivedAction: receivedAction, oldState: oldState, newState: newState)
//      }
//    }))
  }

  @Environment(\.scenePhase)
  private var scenePhase

  public init() {}

  public var body: some View {
    ZStack {
      GeometryReader { proxy in
        DrawingView(
          store: store.scope(\.drawing)
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
        store: store.scope(\.toolbar)
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
