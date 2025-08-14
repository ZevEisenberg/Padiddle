import ComposableArchitecture
import Testing

@testable import PadiddleCore

@Suite
@MainActor
struct HintFeatureTests {
  @Test
  func allHints() async {
    let store = TestStore(
      initialState: .init()
    ) {
      HintFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.start) {
      $0.hintState = .waitToShowRecordPrompt
    }

    await store.receive(\.showRecordPrompt) {
      $0.hintState = .promptForRecord
    }

    @Shared(.isRecording) var isRecording

    $isRecording.withLock { $0 = true }

    await store.receive(\.isRecordingChanged, true) {
      $0.hintState = .waitToShowSpinPrompt
    }

    await store.receive(\.showSpinPrompt) {
      $0.hintState = .promptForSpin
    }

    await store.send(\.spunEnoughToHideSpinPrompt) {
      $0.hintState = .disabled
    }
  }

  @Test
  func tappedRecordBeforeRecordHint() async {
    let clock = TestClock()
    let store = TestStore(
      initialState: .init()
    ) {
      HintFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }

    await store.send(.start) {
      $0.hintState = .waitToShowRecordPrompt
    }

    // not enough to trigger the hint
    await clock.advance(by: .seconds(1))

    @Shared(.isRecording) var isRecording
    $isRecording.withLock { $0 = true }

    await store.receive(\.isRecordingChanged, true) {
      $0.hintState = .waitToShowSpinPrompt
    }

    // more than enough to trigger the hint
    await clock.advance(by: .seconds(10))

    await store.receive(\.showSpinPrompt) {
      $0.hintState = .promptForSpin
    }

    await store.send(\.spunEnoughToHideSpinPrompt) {
      $0.hintState = .disabled
    }
  }

  @Test
  func spunBeforeSpinHint() async {
    let clock = TestClock()
    let store = TestStore(
      initialState: .init()
    ) {
      HintFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }

    await store.send(.start) {
      $0.hintState = .waitToShowRecordPrompt
    }

    // not enough to trigger hint
    await clock.advance(by: .seconds(1))

    @Shared(.isRecording) var isRecording
    $isRecording.withLock { $0 = true }

    await store.receive(\.isRecordingChanged, true) {
      $0.hintState = .waitToShowSpinPrompt
    }

    // not enough to trigger the hint
    await clock.advance(by: .seconds(1))

    await store.send(\.spunEnoughToHideSpinPrompt) {
      $0.hintState = .disabled
    }
  }
}
