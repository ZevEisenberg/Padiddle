import ComposableArchitecture1
import SwiftUI
import Utilities

@Feature
struct HintFeature {
  struct State: Equatable {
    @Trigger var spunEnoughToHidePrompt
    @Trigger var start

    var hintState: HintState = .initial

    enum HintState {
      case initial
      case waitToShowRecordPrompt
      case promptForRecord
      case waitToShowSpinPrompt
      case promptForSpin
      case disabled
    }
  }

  @CasePathable
  enum Action: Hashable {
    case isRecordingChanged(Bool)

    case showRecordPrompt
    case showSpinPrompt
  }

  enum Design {
    static let waitForRecordTimeout: Duration = .seconds(5)
    static let waitForSpinTimeout: Duration = .seconds(3)
  }

  @Dependency(\DependencyValues.continuousClock) private var clock

  @StoreTaskID var spunEnoughToHideSpinPrompt
  @StoreTaskID var waitToShowRecordPrompt
  @StoreTaskID var waitToShowSpinPrompt

  var body: some FeatureProtocol<State, Action> {
    Update { state, action in
      switch action {
      case .isRecordingChanged(let isRecording):
        /// When isRecording changes, we always revert to `waitToShowSpinPrompt`.
        /// Reasoning:
        /// - If `isRecording` changes to `true`, we wait to see if the user spins, and if they don’t, we show the prompt.
        /// - If `isRecording` changes to `false`, we want to:
        ///  - Hide the spin prompt if it happened to be visible.
        ///  - Cancel any pending spin prompt so it doesn’t show when we are not recording.
        ///  - _Not_ set the state to `disabled`, because the next time they start recording, we still want to be able to show the spin prompt if they don’t understand how spinning works.
        state.hintState = .waitToShowSpinPrompt

        waitToShowRecordPrompt.cancel()

        if isRecording {
          store.addTask(id: waitToShowSpinPrompt) {
            try await clock.sleep(for: Design.waitForSpinTimeout)
            try withAnimation {
              _ = try store.send(.showSpinPrompt)
            }
          }
        } else {
          waitToShowSpinPrompt.cancel()
        }

      case .showRecordPrompt:
        state.hintState = .promptForRecord

      case .showSpinPrompt:
        #if DEBUG
        @SharedReader(.isRecording) var isRecording
        precondition(isRecording, "we should never show the spin prompt when we are not recording")
        #endif
        state.hintState = .promptForSpin
      }
    }
    .onTrigger(store.start) { state in
      if state.hintState == .initial {
        state.hintState = .waitToShowRecordPrompt
      }
      if state.hintState == .waitToShowRecordPrompt {
        store.addTask(id: waitToShowRecordPrompt) {
          try await clock.sleep(for: Design.waitForRecordTimeout)
          try withAnimation(.spring) {
            _ = try store.send(.showRecordPrompt)
          }
        }
      }

      @SharedReader(.isRecording) var isRecording
      let obs = Observations { isRecording }

      store.addTask(id: spunEnoughToHideSpinPrompt) {
        for await value in obs.dropFirst() {
          try store.send(.isRecordingChanged(value))
        }
      }
    }
    .onTrigger(store.spunEnoughToHidePrompt) { state in
      state.hintState = .disabled

      waitToShowRecordPrompt.cancel()
      waitToShowSpinPrompt.cancel()
      spunEnoughToHideSpinPrompt.cancel()
    }
  }
}
