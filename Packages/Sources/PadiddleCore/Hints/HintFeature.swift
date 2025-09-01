import ComposableArchitecture
import SwiftUI
import Utilities

@Reducer
struct HintFeature {
  @ObservableState
  struct State: Equatable {
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
    case start
    case isRecordingChanged(Bool)

    case showRecordPrompt
    case showSpinPrompt

    case spunEnoughToHideSpinPrompt
  }

  enum Design {
    static let waitForRecordTimeout: Duration = .seconds(5)
    static let waitForSpinTimeout: Duration = .seconds(3)
  }

  @Dependency(\.continuousClock) private var clock

  enum CancelID {
    case waitToShowRecordPrompt
    case waitToShowSpinPrompt
    case spunEnoughToHideSpinPrompt
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .start:
        if state.hintState == .initial {
          state.hintState = .waitToShowRecordPrompt
        }
        return .merge {
          if state.hintState == .waitToShowRecordPrompt {
            Effect.run { send in
              try await clock.sleep(for: Design.waitForRecordTimeout)
              await send(.showRecordPrompt, animation: .spring)
            }
            .cancellable(id: CancelID.waitToShowRecordPrompt, cancelInFlight: true)
          }

          @SharedReader(.isRecording) var isRecording
          Effect.publisher {
            $isRecording.publisher.dropFirst().map {
              Action.isRecordingChanged($0)
            }
          }
          .cancellable(id: CancelID.spunEnoughToHideSpinPrompt)
        }

      case .isRecordingChanged(let isRecording):
        /// When isRecording changes, we always revert to `waitToShowSpinPrompt`.
        /// Reasoning:
        /// - If `isRecording` changes to `true`, we wait to see if the user spins, and if they don’t, we show the prompt.
        /// - If `isRecording` changes to `false`, we want to:
        ///  - Hide the spin prompt if it happened to be visible.
        ///  - Cancel any pending spin prompt so it doesn’t show when we are not recording.
        ///  - _Not_ set the state to `disabled`, because the next time they start recording, we still want to be able to show the spin prompt if they don’t understand how spinning works.
        state.hintState = .waitToShowSpinPrompt
        return .merge {
          Effect.cancel(id: CancelID.waitToShowRecordPrompt)
          if isRecording {
            Effect.run { send in
              try await clock.sleep(for: Design.waitForSpinTimeout)
              await send(.showSpinPrompt, animation: .default)
            }
            .cancellable(id: CancelID.waitToShowSpinPrompt, cancelInFlight: true)
          } else {
            Effect.cancel(id: CancelID.waitToShowSpinPrompt)
          }
        }

      case .showRecordPrompt:
        state.hintState = .promptForRecord
        return .none

      case .showSpinPrompt:
        #if DEBUG
        @SharedReader(.isRecording) var isRecording
        precondition(isRecording, "we should never show the spin prompt when we are not recording")
        #endif
        state.hintState = .promptForSpin
        return .none

      case .spunEnoughToHideSpinPrompt:
        state.hintState = .disabled
        return .merge(
          .cancel(id: CancelID.waitToShowRecordPrompt),
          .cancel(id: CancelID.waitToShowSpinPrompt),
          .cancel(id: CancelID.spunEnoughToHideSpinPrompt)
        )
      }
    }
  }
}
