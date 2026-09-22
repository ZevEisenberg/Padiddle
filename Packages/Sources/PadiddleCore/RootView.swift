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
          // n.b. the delegate is called from inside the motion-polling task, so this must fire the
          // trigger directly. Wrapping it in `store.addTask` is outside any update phase, and the
          // store rejects it, silently dropping the trigger.
          try store.toolbar.hint.spunEnoughToHidePrompt()
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
        guard let metrics, metrics != state.screenMetrics else {
          break
        }
        state.screenMetrics = metrics

        // The bitmap only grows (see `ensureSideLength`), and `contextSideLength` must always
        // match it, not the current screen. `viewSize` follows the current screen.
        let sideLength = max(
          state.drawing.contextSideLength,
          metrics.size.width,
          metrics.size.height
        )
        state.drawing.contextSideLength = sideLength
        state.drawing.viewSize = metrics.size
        store.addTask {
          let success = await bitmapContext.ensureSideLength(
            sideLength,
            screenScale: metrics.scale
          )
          assert(success, "Problem creating bitmap context")

          try store.send(.deviceMotion(.start))
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
  @State private var store = StoreOf<RootFeature>(initialState: .init()) {
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
    arrangedContent
      .onScreenChange { metrics in
        store.send(.screenChanged(metrics))
      }
      .onChange(of: scenePhase) {
        store.send(.scenePhaseChanged(scenePhase))
      }
      .statusBarHidden()
  }

  /// The canvas and the toolbar, arranged so a folded device puts the toolbar on its own page.
  ///
  /// This is an `ArrangementView` rather than a `ZStack` so that the system can hand the toolbar a
  /// page of its own when the device is folded into book mode. Flat, the arrangement overlays its
  /// two children full-width and the result is indistinguishable from the old `ZStack`; folded, it
  /// gives each child a page and the toolbar lands on the right-hand one.
  @ViewBuilder
  private var arrangedContent: some View {
    if #available(iOS 27.1, *) {
      ArrangementView {
        // In an overlay arrangement the *primary* is the foreground. Putting the canvas here
        // instead hides the toolbar behind it and swallows its touches.
        toolbar
          .overlayArrangementEdge(.bottom)
      } secondary: {
        // The canvas is deliberately not the secondary. An arrangement sizes and places each child
        // within a single page, and the drawing derives its square from whatever box it is laid out
        // in, so as the secondary it comes out one page wide and centered on that page. It spans the
        // whole display behind the arrangement instead, and this placeholder just occupies the page
        // the toolbar vacated.
        Color.clear
      }
      .arrangementViewStyle(.overlay)
      .background {
        canvas
      }
    } else {
      ZStack {
        canvas
        toolbar
      }
    }
  }

  @ViewBuilder
  private var canvas: some View {
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
  }

  @ViewBuilder
  private var toolbar: some View {
    ToolbarView(
      store: store.scope(\.toolbar)
    )
    .frame(maxHeight: .infinity, alignment: .bottom)
    // A display cutout contributes its full width to `safeAreaInsets` for the whole height of the
    // scene, not just the rows it actually occupies. On the Duo cover display that is an 84pt
    // trailing inset for a camera in the top corner, which shoves this bar 42pt off center even
    // though it sits hundreds of points below the camera. Span the full width instead.
    //
    // This is safe only because the bar is narrow and centered, so it never reaches a cutout at
    // either end. A bar that stretched edge to edge would have to inset itself by the occlusion
    // regions that genuinely overlap its own band — see `reservedRegions(kind: .occlusion)`.
    .ignoresSafeArea(.container, edges: .horizontal)
  }
}

#Preview {
  RootView()
}
