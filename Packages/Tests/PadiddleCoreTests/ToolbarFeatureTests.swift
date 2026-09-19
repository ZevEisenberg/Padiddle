import ComposableArchitecture1
import Models
import Testing

@testable import PadiddleCore

@Suite
@MainActor
struct ToolbarFeatureTests {
  @Test
  func basics() throws {
    @Shared(.colorGenerator) var colorGenerator = .tangerine

    let clock = TestClock()
    try TestExhaustivity.$current.withValue(.off) {
      let store = withDependencies {
        $0.continuousClock = clock
      } operation: {
        TestStore(
          initialState: .init(colorGenerator: $colorGenerator)
        ) {
          ToolbarFeature(delegate: { _ in })
        }
      }

      try store.hint.start()

      store.expect {
        $0.hint.hintState = .waitToShowRecordPrompt
      }
    }
  }

  @Test
  func colorPickerCancel() {
    @Shared(.colorGenerator) var colorGenerator = .blackWidow

    let store = withDependencies {
      $0.continuousClock = ImmediateClock()
    } operation: {
      TestStore(
        initialState: .init(
          colorGenerator: $colorGenerator
        )
      ) {
        ToolbarFeature(disableHintsForTesting: true, delegate: { _ in })
      }
    }

    store.send(.colorButtonTapped) {
      $0.destination = .colorPicker(.init(currentSelection: ColorGenerator.blackWidow.id))
    }

    store.send(.destination(.colorPicker(.delegate(.cancelTapped)))) {
      $0.destination = nil
    }
  }

  @Test
  func colorPickerPick() {
    @Shared(.colorGenerator) var colorGenerator = .monsters
    let store = withDependencies {
      $0.continuousClock = ImmediateClock()
    } operation: {
      TestStore(
        initialState: .init(
          colorGenerator: $colorGenerator
        )
      ) {
        ToolbarFeature(disableHintsForTesting: true, delegate: { _ in })
      }
    }

    store.send(.colorButtonTapped) {
      $0.destination = .colorPicker(.init(currentSelection: ColorGenerator.monsters.id))
    }

    store.send(.destination(.colorPicker(.colorPicked(.merlin)))) {
      $0.destination = nil
      $0.colorGenerator = .merlin
    }
  }
}
