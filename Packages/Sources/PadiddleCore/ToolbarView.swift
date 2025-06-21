import ComposableArchitecture
import Models
import SwiftUI
import Utilities

@Reducer
struct ToolbarFeature {
  @ObservableState
  struct State {
    @Shared var isRecording: Bool
    var colorGenerator: ColorGenerator

    /// Which hint, if any, is currently visible
    var hint: Hint?
  }

  enum Action {
    case onTask

    // User Actions
    case clearButtonTapped
    case colorButtonTapped
    case recordButtonTapped
    case helpButtonTapped

    // Timed Events
    case showHint(Hint)
    case hideHint
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onTask:
        return .none
      case .clearButtonTapped:
        return .none
      case .colorButtonTapped:
        return .none
      case .recordButtonTapped:
        state.$isRecording.withLock { $0.toggle() }
        return .none
      case .helpButtonTapped:
        return .none
      case .showHint(let hint):
        return .none
      case .hideHint:
        return .none
      }
    }
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
  let store: StoreOf<ToolbarFeature>

  @Namespace private var namespace
  @Environment(\.displayScale) private var displayScale

  var body: some View {
    GlassEffectContainer {
      #warning("TODO: idea from Cam: try putting non-record buttons at the top in a toolbar")
      HStack(spacing: 20) {
        if !store.isRecording {
          clearButton
            .glassEffect(.regular.interactive())
            .glassEffectID("clear", in: namespace)
            .glassEffectUnion(id: "leading", namespace: namespace)

          colorButton
            .glassEffect(.regular.interactive())
            .glassEffectID("color", in: namespace)
            .glassEffectUnion(id: "leading", namespace: namespace)
        }

        recordButton
          .glassEffectID("record", in: namespace)
          .glassEffectUnion(id: "middle", namespace: namespace)

        if !store.isRecording {
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
    }
    .border(.red)
    .font(.system(size: 28))
    .overlay(alignment: .top) {
      StartHereView()
        .alignmentGuide(.top) { $0[.bottom] + 15 }
    }
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
      Image(systemName: store.isRecording ? "pause" : "arrow.trianglehead.2.clockwise.rotate.90")
        .fontWeight(.black)
        .foregroundStyle(.white)
        .frame(size: Design.recordButtonSize)
        .glassEffect(
          .regular.interactive().tint(
            Color(
              store.isRecording
                ? .Toolbar.RecordButton.pause
                : .Toolbar.RecordButton.record
            )
          )
        )
    }
  }
}

#Preview {
  ToolbarView(
    store: .init(
      initialState: .init(
        isRecording: Shared(value: false),
        colorGenerator: .classic
      )
    ) {
      ToolbarFeature()
    }
  )
  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  .background(.gray)
}
