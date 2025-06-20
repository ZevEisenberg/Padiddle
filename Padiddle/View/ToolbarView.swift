import ComposableArchitecture
import SwiftUI

struct ToolbarView: View {
  let model: ToolbarViewModel
  private let spiralModel: SpiralModel

  private var isRecording: Bool {
    model.rootViewModel.isRecording
  }

  @Namespace private var namespace

  init(
    model: ToolbarViewModel,
    spiralModel: SpiralModel
  ) {
    self.model = model
    self.spiralModel = spiralModel
  }

  var body: some View {
    GlassEffectContainer {
      #warning("TODO: idea from Cam: try putting non-record buttons at the top in a toolbar")
      HStack(spacing: 20) {
        if !isRecording {
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
    }
    .font(.system(size: 28))
    .overlay(alignment: .top) {
      StartHereViewSwiftUI()
        .alignmentGuide(.top) { $0[.bottom] + 15 }
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
      model.clearTapped()
    } label: {
      Image(systemName: "trash")
        .accessibilityLabel(Text("Clear"))
        .frame(size: Design.buttonSize)
    }
  }

  @ViewBuilder
  var colorButton: some View {
    Button {
      #warning("TODO")
    } label: {
      let image = SpiralImageMaker.image(
        spiralModel: spiralModel
      )
      Image(uiImage: image)
        .frame(size: Design.buttonSize)
    }
  }

  @ViewBuilder
  var recordButtonPlaceholder: some View {
    Color.clear
      .frame(size: Design.recordButtonSize)
      .border(.purple)
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
      #warning("TODO")
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
      model.recordButtonTapped()
    } label: {
      Image(systemName: model.rootViewModel.isRecording ? "pause" : "arrow.trianglehead.2.clockwise.rotate.90")
        .fontWeight(.black)
        .foregroundStyle(.white)
        .frame(size: Design.recordButtonSize)
        .glassEffect(.regular.interactive().tint(Color(isRecording ? .red : .ToolbarSwiftUI.RecordButton.foreground)))
    }
  }
}

private let previewOnlyDrawingViewModel = DrawingViewModel(maxRadius: 30, contextSize: .square(sideLength: 500), screenScale: 2, spinManager: SpinManager())

#Preview {
  @Previewable let toolbarVC = ToolbarViewController(spinManager: SpinManager(), maximumFramesPerSecond: 120)
  @Previewable let rootViewModel = RootViewModel(rootColorManagerDelegate: previewOnlyDrawingViewModel)

  ToolbarView(
    model: ToolbarViewModel(
      rootViewModel: rootViewModel,
      toolbarDelegate: toolbarVC,
      colorDelegate: rootViewModel
    ),
    spiralModel: SpiralModel(
      colorManager: .init(colorModel: .hsv(
        h: .manual(30.0 / 360.0),
        s: .velocityIn,
        v: .manual(1.0)
      ), title: "Placeholder"),
      size: .square(sideLength: 36),
      startRadius: 0,
      spacePerLoop: 0.7,
      thetaRange: 0...(2 * .pi * 4),
      thetaStep: .pi / 16,
      lineWidth: 2.3
    )
  )
  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  .background(.gray)
}
