import ComposableArchitecture
import Models
import Testing

@testable import PadiddleCore

@Suite
@MainActor
struct ToolbarFeatureTests {
  @Test
  func basics() async {
    @Shared(.colorGenerator) var colorGenerator = .tangerine
    let store = TestStore(
      initialState: .init(colorGenerator: $colorGenerator)
    ) {
      ToolbarFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    store.exhaustivity = .off

    await store.send(.onTask)

    await store.receive(\.hint, .start)
  }

  @Test
  func colorPickerCancel() async {
    @Shared(.colorGenerator) var colorGenerator = .blackWidow

    let store = TestStore(
      initialState: .init(
        colorGenerator: $colorGenerator
      )
    ) {
      ToolbarFeature(disableHintsForTesting: true)
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.colorButtonTapped) {
      $0.destination = .colorPicker(.init(currentSelection: ColorGenerator.blackWidow.id))
    }

    await store.send(\.destination.colorPicker.delegate.cancelTapped) {
      $0.destination = nil
    }
  }

  @Test
  func colorPickerPick() async {
    @Shared(.colorGenerator) var colorGenerator = .monsters
    let store = TestStore(
      initialState: .init(
        colorGenerator: $colorGenerator
      )
    ) {
      ToolbarFeature(disableHintsForTesting: true)
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.colorButtonTapped) {
      $0.destination = .colorPicker(.init(currentSelection: ColorGenerator.monsters.id))
    }

    await store.send(\.destination.colorPicker.colorPicked, .merlin) {
      $0.destination = nil
      $0.$colorGenerator.withLock { $0 = .merlin }
    }
  }
}
