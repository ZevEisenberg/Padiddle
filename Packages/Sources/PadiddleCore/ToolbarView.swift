import Clocks
import ComposableArchitecture1
import Models
import SwiftUI
import SwiftUINavigation
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

@Feature
struct EraseConfirmation: Prompt {
  enum Action {
    case eraseDrawingTapped
  }
}

@Feature
struct ToolbarFeature {
  let disableHintsForTesting: Bool

  init(
    disableHintsForTesting: Bool = false,
    delegate: @escaping (DelegateAction) throws -> Void
  ) {
    self.disableHintsForTesting = disableHintsForTesting
    self.delegate = delegate
  }

  struct State: Equatable {
    @Shared(.colorGenerator)
    var colorGenerator: ColorGenerator

    @Shared(.isRecording)
    var isRecording: Bool

    var destination: Destination.State?

    var hint: HintFeature.State = .init()
  }

  @Feature
  enum Destination {
    case colorPicker(ColorPickerFeature)
    case clearConfirmation(EraseConfirmation)
    case about
  }

  enum Action {
    // User Actions
    case eraseButtonTapped
    case colorButtonTapped
    case recordButtonTapped
    case aboutButtonTapped

    // Nested Features
    case destination(Destination.Action)
    case hint(HintFeature.Action)
  }

  enum DelegateAction {
    case eraseDrawing
  }

  let delegate: (DelegateAction) throws -> Void

  var body: some FeatureProtocol<State, Action> {
    let _ = Self._logChanges() // swiftlint:disable:this redundant_discardable_let
    if !disableHintsForTesting {
      Scope(\.hint, action: \.hint) {
        HintFeature()
      }
    }

    Update { state, action in
      switch action {
      case .eraseButtonTapped:
        state.destination = .clearConfirmation(.init())

      case .colorButtonTapped:
        state.destination = .colorPicker(ColorPickerFeature.State(currentSelection: state.colorGenerator.id))

      case .recordButtonTapped:
        state.$isRecording.withLock { $0.toggle() }

      case .aboutButtonTapped:
        state.destination = .about

      case .destination(.colorPicker(let action)):
        switch action {
        case .colorPicked(let color):
          state.$colorGenerator.withLock { $0 = color }
          state.destination = nil

        case .delegate(.cancelTapped):
          state.destination = nil
        }

      case .destination(.clearConfirmation(.eraseDrawingTapped)):
        store.addTask {
          try delegate(.eraseDrawing)
        }

      case .destination,
           .hint:
        return
      }
    }
    .onMount { _ in
      store.addTask {
        if !disableHintsForTesting {
          try store.hint.start()
        }
      }
    }
    .ifLet(\.destination, action: \.destination) {
      Destination.body
    }
  }
}

extension ToolbarFeature.Destination.State: Equatable {}

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
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.displayScale) private var displayScale
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  var isPopoverActuallyPopover: Bool {
    horizontalSizeClass == .regular && verticalSizeClass == .regular
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .bottom) {
        GlassEffectContainer {
          HStack(spacing: 20) {
            @SharedReader(.isRecording) var isRecording

            if !isRecording {
              eraseButton
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
                  item: $store.scope(\.destination, action: \.destination).colorPicker
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
          .padding(.bottom, proxy.safeAreaInsets.bottom.isZero ? 10 : 0)
        }
        .overlay(alignment: .top) {
          Group {
            if store.hint.hintState == .promptForRecord {
              StartHereView()
                .padding(.bottom, 10)
                .transition(
                  .opacity
                    .combined(
                      with: .offset(y: -10)
                    )
                )
            }
          }
          .alignmentGuide(.top) {
            $0[.bottom]
          }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)

        if store.hint.hintState == .promptForSpin {
          SpinPromptView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
        }
      }
      .font(.system(size: 28))
      .frame(maxWidth: .infinity)
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
  var eraseButton: some View {
    Button {
      store.send(.eraseButtonTapped)
    } label: {
      Image(systemName: "trash")
        .accessibilityLabel(Text(.erase))
        .frame(size: Design.buttonSize)
    }
    .confirmationDialog(
      item: $store.scope(\.destination, action: \.destination)
        .clearConfirmation
    ) { _ in
      Text(.eraseDrawing)
    } actions: { _ in
      Button(.erase, role: .destructive) {
        store.send(.eraseButtonTapped)
      }
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
    .accessibilityLabel(Text(.colorSettings))
    .accessibilityIdentifier("colorButton")
  }

  @ViewBuilder
  var shareButton: some View {
    @Dependency(\.bitmapContextClient) var bitmapClient
    ShareLink(
      item: bitmapClient.renderer(colorScheme: colorScheme),
      preview: SharePreview(
        Text("Image from Padiddle"),
        icon: bitmapClient.renderer(
          colorScheme: colorScheme,
          sideLength: 100
        )
      )
    ) {
      // Override default label in order to hide the default preview text that ShareLink uses.
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
        .accessibilityLabel(Text(.about))
        .frame(size: Design.buttonSize)
    }
    .accessibilityIdentifier("helpButton")
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
    @SharedReader(.isRecording) var isRecording
    Button {
      withAnimation {
        _ = store.send(.recordButtonTapped)
      }
    } label: {
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
    .contentShape(Circle())
    .accessibilityLabel(Text(isRecording ? .pauseDrawing : .startDrawing))
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
      ToolbarFeature(delegate: { _ in })

      // swiftlint:disable:next redundant_discardable_let
      let _ = ToolbarFeature._logChanges()
      // swiftformat:disable:previous redundantLet
    }
  )
  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  .background(.gray)
}

#Preview("Prompt for Record") {
  @Previewable @Shared(.isRecording) var isRecording = false
  ToolbarView(
    store: withDependencies {
      $0.continuousClock = ImmediateClock()
    } operation: {
      Store(
        initialState: .init(
          hint: .init(hintState: .promptForRecord)
        )
      ) {
        ToolbarFeature(delegate: { _ in })

        // swiftlint:disable:next redundant_discardable_let
        let _ = ToolbarFeature._logChanges()
        // swiftformat:disable:previous redundantLet
      }
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
    store: withDependencies {
      $0.continuousClock = ImmediateClock()
    } operation: {
      .init(
        initialState: .init(
          hint: .init(hintState: .promptForSpin)
        )
      ) {
        ToolbarFeature(delegate: { _ in })

        // swiftlint:disable:next redundant_discardable_let
        let _ = ToolbarFeature._logChanges()
        // swiftformat:disable:previous redundantLet
      }
    }
  )
  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  .background(.gray)
  .onAppear {
    $isRecording.withLock { $0 = true }
  }
}

private extension ToolbarFeature.State {
  static var aboutPreview: Self {
    .init(
      destination: .about,
      hint: .init(hintState: .disabled)
    )
  }
}

#Preview("About") {
  ToolbarView(
    store: .init(
      initialState: .aboutPreview
    ) {
      ToolbarFeature(delegate: { _ in })

      // swiftlint:disable:next redundant_discardable_let
      let _ = ToolbarFeature._logChanges()
      // swiftformat:disable:previous redundantLet
    }
  )
  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  .background(.gray)
}
