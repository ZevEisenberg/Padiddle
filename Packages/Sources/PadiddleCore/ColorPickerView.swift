import Algorithms
import ComposableArchitecture
import Models
import SwiftUI

@Reducer
struct ColorPickerFeature {
  @ObservableState
  struct State: Equatable {
    var currentSelection: ColorGenerator.ID = ColorGenerator.classic.id
  }

  enum Action: Hashable {
    case colorPicked(ColorGenerator)
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Hashable {
      case cancelTapped
    }
  }

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .colorPicked(let colorGenerator):
      state.currentSelection = colorGenerator.id
      return .none

    case .delegate:
      return .none
    }
  }
}

public struct ColorPickerView: View {
  let store: StoreOf<ColorPickerFeature>

  private let colorGenerators = ColorGenerator.toPick

  public var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(
          columns: [GridItem(.adaptive(minimum: 140, maximum: 200), alignment: .top)],
          spacing: 12
        ) {
          ForEach(colorGenerators) { colorGenerator in
            SpiralCell(
              generator: colorGenerator,
              isSelected: store.currentSelection == colorGenerator.id,
              didSelect: {
                store.send(.colorPicked(colorGenerator))
              }
            )
          }
        }
        .padding(.horizontal)
      }
      .scrollIndicatorsFlash(onAppear: true)
      .navigationTitle(Text(.colors))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .cancel) {
            store.send(.delegate(.cancelTapped))
          }
        }
      }
    }
  }
}

struct SpiralCell: View {
  let generator: ColorGenerator
  let isSelected: Bool
  let didSelect: () -> Void

  @Environment(\.displayScale) var displayScale

  var body: some View {
    Button {
      didSelect()
    } label: {
      VStack {
        GeometryReader { proxy in
          let longestSide = max(proxy.size.width, proxy.size.height)
          let model = SpiralModel(
            colorGenerator: generator,
            size: CGSize.square(sideLength: longestSide),
            startRadius: 0,
            spacePerLoop: longestSide / 90,
            thetaRange: 0...(2.0 * .pi * 10.0),
            thetaStep: .pi / 32.0,
            lineWidth: longestSide / 30
          )

          let image = SpiralImageMaker.image(
            spiralModel: model,
            scale: displayScale
          )
          Image(uiImage: image)
            .clipShape(.rect(cornerRadius: 10))
        }
        .aspectRatio(1, contentMode: .fit)

        Text(generator.title)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.bottom, 5)
      }
    }
    .buttonStyle(ColorPickerButtonStyle(isSelected: isSelected))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

private struct ColorPickerButtonStyle: ButtonStyle {
  let isSelected: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background {
        let color: ColorResource = if configuration.isPressed {
          .ColorPicker.Background.highlighted
        } else if isSelected {
          .ColorPicker.Background.selected
        } else {
          .ColorPicker.Background.normal
        }
        Color(color)
          .padding(-5)
          .clipShape(.rect(cornerRadius: 10))
      }
      .overlay {
        RoundedRectangle(cornerRadius: 10)
          .stroke(
            Color(
              configuration.isPressed
                ? .ColorPicker.Border.highlighted
                : .ColorPicker.Border.normal
            ),
            lineWidth: (configuration.isPressed || isSelected) ? 2 : 0
          )
          .padding(-5)
      }
  }
}

#Preview {
  ColorPickerView(
    store: .init(
      initialState: .init()
    ) {
      ColorPickerFeature()
        ._printChanges()
    }
  )
}
