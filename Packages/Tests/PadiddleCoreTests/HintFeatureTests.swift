import ComposableArchitecture1
import Testing

@testable import PadiddleCore

@Suite
@MainActor
struct HintFeatureTests {
  @Test
  func allHints() async throws {
    let store = TestStore(
      initialState: HintFeature.State()
    ) {
      withDependencies {
        $0.continuousClock = ImmediateClock()
      } operation: {
        HintFeature()
      }
    }

    try store.start()

    store.expect { state in
      state.hintState = .waitToShowRecordPrompt
    }

    await store.receive(\.showRecordPrompt) {
      $0.hintState = .promptForRecord
    }

    @Shared(.isRecording) var isRecording
    $isRecording.withLock { $0 = true }

    await store.receive(\.isRecordingChanged) {
      $0.hintState = .waitToShowSpinPrompt
    }

    await store.receive(\.showSpinPrompt) {
      $0.hintState = .promptForSpin
    }

    try store.spunEnoughToHidePrompt()
    store.expect {
      $0.hintState = .disabled
    }
  }
//
//  @Test
//  func tappedRecordBeforeRecordHint() async {
//    let clock = TestClock()
//    let store = withDependencies {
//      $0.continuousClock = clock
//    } operation: {
//      TestStore(initialState: .init()) {
//        HintFeature()
//      }
//    }
//
//    store.send(.start) {
//      $0.hintState = .waitToShowRecordPrompt
//    }
//
//    // not enough to trigger the hint
//    await clock.advance(by: .seconds(1))
//
//    @Shared(.isRecording) var isRecording
//    $isRecording.withLock { $0 = true }
//
//    await store.receive(\.isRecordingChanged) {
//      $0.hintState = .waitToShowSpinPrompt
//    }
//
//    // more than enough to trigger the hint
//    await clock.advance(by: .seconds(10))
//
//    await store.receive(\.showSpinPrompt) {
//      $0.hintState = .promptForSpin
//    }
//
//    store.modify {
//      $0.spunEnoughToHidePrompt()
//    } changes: {
//      $0.hintState = .disabled
//    }
//  }
//
//  @Test
//  func spunBeforeSpinHint() async {
//    let clock = TestClock()
//
//    let store = withDependencies {
//      $0.continuousClock = clock
//    } operation: {
//      TestStore(initialState: .init()) {
//        HintFeature()
//      }
//    }
//
//    store.send(.start) {
//      $0.hintState = .waitToShowRecordPrompt
//    }
//
//    // not enough to trigger hint
//    await clock.advance(by: .seconds(1))
//
//    @Shared(.isRecording) var isRecording
//    $isRecording.withLock { $0 = true }
//
//    await store.receive(\.isRecordingChanged) {
//      $0.hintState = .waitToShowSpinPrompt
//    }
//
//    // not enough to trigger the hint
//    await clock.advance(by: .seconds(1))
//
//    store.modify {
//      $0.spunEnoughToHidePrompt()
//    } changes: {
//      $0.hintState = .disabled
//    }
//  }
//
//  @Test(.dependency(\.exhaustivity, .off)) // skip effects at the end
//  func stoppedRecordingWhileSpinHintIsVisible() async {
//    let store = withDependencies {
//      $0.continuousClock = ImmediateClock()
//    } operation: {
//      TestStore(initialState: .init()) {
//        HintFeature()
//      }
//    }
//
//    store.send(.start) {
//      $0.hintState = .waitToShowRecordPrompt
//    }
//
//    await store.receive(\.showRecordPrompt) {
//      $0.hintState = .promptForRecord
//    }
//
//    @Shared(.isRecording) var isRecording
//    $isRecording.withLock { $0 = true }
//
//    await store.receive(\.isRecordingChanged) {
//      $0.hintState = .waitToShowSpinPrompt
//    }
//
//    await store.receive(\.showSpinPrompt) {
//      $0.hintState = .promptForSpin
//    }
//
//    $isRecording.withLock { $0 = false }
//
//    await store.receive(\.isRecordingChanged) {
//      $0.hintState = .waitToShowSpinPrompt
//    }
//  }
}
