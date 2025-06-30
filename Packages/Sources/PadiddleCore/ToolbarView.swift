import Clocks
import ComposableArchitecture
import Models
import SwiftUI
import Utilities

extension SharedKey where Self == InMemoryKey<Bool>.Default {
  static var isRecording: Self {
    Self[.inMemory("isRecording"), default: false]
  }
}

@Reducer
struct ToolbarFeature {
  let disableHintsForTesting: Bool

  init(disableHintsForTesting: Bool = false) {
    self.disableHintsForTesting = disableHintsForTesting
  }

  @ObservableState
  struct State: Equatable {
    var colorGenerator: ColorGenerator

    @Presents
    var destination: Destination.State?

    var hint: HintFeature.State = .init()

    /// The maximum refresh rate of the display. Usually 120 for ProMotion displays and 60 otherwise.
    var maximumFramesPerSecond: Int
  }

  @Reducer(state: .equatable)
  enum Destination {
    case colorPicker(ColorPickerFeature)
    @ReducerCaseIgnored
    case help
  }

  enum Action {
    case onTask

    // User Actions
    case clearButtonTapped
    case colorButtonTapped
    case recordButtonTapped
    case helpButtonTapped

    // Nested Features
    case destination(PresentationAction<Destination.Action>)
    case hint(HintFeature.Action)
  }

  var body: some ReducerOf<Self> {
    if !disableHintsForTesting {
      Scope(state: \.hint, action: \.hint) {
        HintFeature()
      }
    }

    Reduce { state, action in
      switch action {
      case .onTask:
        return .run { send in
          if !disableHintsForTesting {
            await send(.hint(.start))
          }
        }

      case .clearButtonTapped:
        return .none

      case .colorButtonTapped:
        state.destination = .colorPicker(ColorPickerFeature.State(currentSelection: state.colorGenerator.id))
        return .none

      case .recordButtonTapped:
        @Shared(.isRecording) var isRecording
        $isRecording.withLock { $0.toggle() }
        return .none

      case .helpButtonTapped:
        return .none

      case .destination(.presented(.colorPicker(let action))):
        switch action {
        case .colorPicked(let color):
          state.colorGenerator = color
          state.destination = nil
          return .none

        case .delegate(.cancelTapped):
          state.destination = nil
          return .none
        }

      case .destination:
        return .none

      case .hint:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension ToolbarFeature {
  /// Which hint, if any, is currently visible
  enum Hint {
    case pressRecordButton
    case howToSpin
  }
}

struct ToolbarView: View {
  @Bindable
  var store: StoreOf<ToolbarFeature>

  @Namespace private var namespace
  @Environment(\.displayScale) private var displayScale
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  var isPopoverActuallyPopover: Bool {
    horizontalSizeClass == .regular && verticalSizeClass == .regular
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      ZStack(alignment: .top) {
        GlassEffectContainer {
          #warning("TODO: idea from Cam: try putting non-record buttons at the top in a toolbar")
          HStack(spacing: 20) {
            @Shared(.isRecording) var isRecording

            if !isRecording {
              clearButton
                .glassEffect(.regular.interactive())
                .glassEffectID("clear", in: namespace)
                .glassEffectUnion(id: "leading", namespace: namespace)

              colorButton
                .keyframeAnimator(
                  initialValue: 1.0,
                  trigger: store.colorGenerator,
                  content: { content, value in
                    content
                      .scaleEffect(value)
                  },
                  keyframes: { _ in
                    KeyframeTrack {
                      if !isPopoverActuallyPopover {
                        // wait for sheet to dismiss
                        LinearKeyframe(1, duration: 0.4)
                      } else {
                        // required for conditional builder
                      }
                      SpringKeyframe(1.2, duration: 0.2, spring: .snappy)
                      SpringKeyframe(1, spring: .snappy, startVelocity: 10)
                    }
                  }
                )
                .glassEffect(.regular.interactive())
                .glassEffectID("color", in: namespace)
                .glassEffectUnion(id: "leading", namespace: namespace)
                .popover(
                  item: $store.scope(
                    state: \.destination?.colorPicker,
                    action: \.destination.colorPicker
                  ),
                  arrowEdge: .bottom
                ) { store in
                  ColorPickerView(store: store)
                    .frame(minWidth: 320)
                }
            }

            recordButton
              .glassEffectID("record", in: namespace)
              .glassEffectUnion(id: "middle", namespace: namespace)

            if !isRecording {
              shareButton
                .glassEffect(.regular.interactive())
                .glassEffectID("share", in: namespace)
                .glassEffectUnion(id: "trailing", namespace: namespace)

              helpButton
                .glassEffect(.regular.interactive())
                .glassEffectID("help", in: namespace)
                .glassEffectUnion(id: "trailing", namespace: namespace)
            }
          }

          if store.hint.hintState == .promptForRecord {
            StartHereView()
              .padding(.bottom, 10)
              .alignmentGuide(.top) { $0[.bottom] }
              .transition(
                .opacity
                  .combined(
                    with: .offset(y: -10)
                  )
              )
          }
        }
      }
      if store.hint.hintState == .promptForSpin {
        SpinPromptView(
          maximumFramesPerSecond: store.maximumFramesPerSecond
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
      }
    }
    .font(.system(size: 28))
    .frame(maxWidth: .infinity)
    .task {
      await store.send(.onTask).finish()
    }
  }
}

private extension ToolbarView {
  enum Design {
    static let recordButtonSize = CGSize.square(sideLength: 60)
    static let buttonSize = CGSize.square(sideLength: 54)
  }
}

// MARK: - Main Buttons

private extension ToolbarView {
  @ViewBuilder
  var clearButton: some View {
    Button {
      store.send(.clearButtonTapped)
    } label: {
      Image(systemName: "trash")
        .accessibilityLabel(Text("Clear"))
        .frame(size: Design.buttonSize)
    }
  }

  @ViewBuilder
  var colorButton: some View {
    Button {
      store.send(.colorButtonTapped)
    } label: {
      let spiralModel = SpiralModel(
        colorGenerator: store.colorGenerator,
        size: .square(sideLength: 36),
        startRadius: 0,
        spacePerLoop: 0.7,
        thetaRange: 0...(2 * .pi * 4),
        thetaStep: .pi / 16,
        lineWidth: 2.3
      )
      let image = SpiralImageMaker.image(
        spiralModel: spiralModel,
        scale: displayScale
      )
      Image(uiImage: image)
        .frame(size: Design.buttonSize)
    }
  }

  @ViewBuilder
  var shareButton: some View {
    ShareLink(
      item: Image(systemName: "watch.analog"),
      preview: SharePreview(
        "TODO",
        image: Image(systemName: "eyes")
      )
    ) {
      Image(systemName: "square.and.arrow.up")
        .frame(size: Design.buttonSize)
    }
  }

  @ViewBuilder
  var helpButton: some View {
    Button {
      store.send(.helpButtonTapped)
    } label: {
      Image(systemName: "questionmark.circle")
        .accessibilityLabel(Text("Help"))
        .frame(size: Design.buttonSize)
    }
  }
}

// MARK: - Record Button

private extension ToolbarView {
  @ViewBuilder
  var recordButton: some View {
    Button {
      store.send(.recordButtonTapped, animation: .snappy)
    } label: {
      @SharedReader(.isRecording) var isRecording
      Image(systemName: isRecording ? "pause" : "arrow.trianglehead.2.clockwise.rotate.90")
        .fontWeight(.black)
        .foregroundStyle(.white)
        .frame(size: Design.recordButtonSize)
        .glassEffect(
          .regular.interactive().tint(
            Color(
              isRecording
                ? .Toolbar.RecordButton.pause
                : .Toolbar.RecordButton.record
            )
          )
        )
    }
  }
}

#Preview("Initial") {
  @Previewable @Shared(.isRecording) var isRecording = false

  ToolbarView(
    store: .init(
      initialState: .init(
        colorGenerator: .classic,
        maximumFramesPerSecond: 120
      )
    ) {
      ToolbarFeature()._printChanges()
    }
  )
  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  .background(.gray)
}

#Preview("Prompt for Record") {
  @Previewable @Shared(.isRecording) var isRecording = false
  ToolbarView(
    store: .init(
      initialState: .init(
        colorGenerator: .classic,
        hint: .init(hintState: .promptForRecord),
        maximumFramesPerSecond: 120
      )
    ) {
      ToolbarFeature()._printChanges()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }
  )
  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  .background(.gray)
  .onAppear {
    $isRecording.withLock { $0 = false }
  }
}

#Preview("Spin Prompt") {
  @Previewable @Shared(.isRecording) var isRecording
  ToolbarView(
    store: .init(
      initialState: .init(
        colorGenerator: .classic,
        hint: .init(hintState: .promptForSpin),
        maximumFramesPerSecond: 120
      )
    ) {
      ToolbarFeature()._printChanges()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }
  )
  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  .background(.gray)
  .onAppear {
    $isRecording.withLock { $0 = true }
  }
}
