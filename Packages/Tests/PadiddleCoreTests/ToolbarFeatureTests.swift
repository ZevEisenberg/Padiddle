import ComposableArchitecture
import Models
import Testing

@testable import PadiddleCore

@Suite
@MainActor
struct ToolbarFeatureTests {
  @Test
  func basics() async {
    let store = TestStore(
      initialState: .init(
        colorGenerator: .tangerine,
        maximumFramesPerSecond: 120
      )
    ) {
      ToolbarFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    store.exhaustivity = .off

    await store.send(.onTask)

    await store.receive(.hint(.start))
  }
}
