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

extension SharedKey where Self == AppStorageKey<ColorGenerator>.Default {
  static var colorGenerator: Self {
    Self[.appStorage("colorGenerator"), default: ColorGenerator.toPick[0]]
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
    @Shared(.colorGenerator)
    var colorGenerator: ColorGenerator

    @Presents
    var destination: Destination.State?

    var hint: HintFeature.State = .init()
  }

  @Reducer(state: .equatable)
  enum Destination {
    case colorPicker(ColorPickerFeature)
    @ReducerCaseIgnored
    case about
  }

  enum Action: BindableAction {
    case onTask

    // User Actions
    case clearButtonTapped
    case colorButtonTapped
    case recordButtonTapped
    case aboutButtonTapped

    // Nested Features
    case destination(PresentationAction<Destination.Action>)
    case hint(HintFeature.Action)

    case binding(BindingAction<ToolbarFeature.State>)
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

      case .aboutButtonTapped:
        state.destination = .about
        return .none

      case .destination(.presented(.colorPicker(let action))):
        switch action {
        case .colorPicked(let color):
          state.$colorGenerator.withLock { $0 = color }
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

      case .binding:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)

    BindingReducer()
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
            @SharedReader(.isRecording) var isRecording

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
                      SpringKeyframe(1.2, duration: 0.2, spring: .smooth)
                      SpringKeyframe(1, spring: .smooth, startVelocity: 10)
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

              aboutButton
                .glassEffect(.regular.interactive())
                .glassEffectID("about", in: namespace)
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
        SpinPromptView()
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
      Image(
        uiImage: ColorButtonImageCache.shared.image(
          forColorGenerator: store.colorGenerator,
          displayScale: displayScale
        )
      )
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
  var aboutButton: some View {
    Button {
      store.send(.aboutButtonTapped)
    } label: {
      Image(systemName: "questionmark.circle")
        .accessibilityLabel(Text("About"))
        .frame(size: Design.buttonSize)
    }
    .popover(isPresented: $store.destination.about) {
      AboutView(horizontalSizeClass: horizontalSizeClass!)
        .frame(minWidth: 320, minHeight: 500)
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
      Self.recordButtonLabel(isRecording: isRecording)
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

extension ToolbarView {
  @ViewBuilder
  static func recordButtonLabel(isRecording: Bool) -> some View {
    Image(systemName: isRecording ? "pause" : "arrow.trianglehead.2.clockwise.rotate.90")
      .fontWeight(.black)
      .foregroundStyle(.white)
      .frame(size: Design.recordButtonSize)
      .font(.system(size: 28))
  }
}

#Preview("Initial") {
  @Previewable @SharedReader(.isRecording) var isRecording = false

  ToolbarView(
    store: .init(
      initialState: .init()
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
        hint: .init(hintState: .promptForRecord)
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
        hint: .init(hintState: .promptForSpin)
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

private let aboutPreviewState = ToolbarFeature.State(
  destination: .about,
  hint: .init(hintState: .disabled)
)

#Preview("About") {
  ToolbarView(
    store: .init(
      initialState: aboutPreviewState
    ) {
      ToolbarFeature()._printChanges()
    }
  )
  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  .background(.gray)
}
