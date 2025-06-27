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
              await send(.showRecordPrompt)
            }
            .cancellable(id: CancelID.waitToShowRecordPrompt, cancelInFlight: true)
          }

          @Shared(.isRecording) var isRecording
          Effect.publisher {
            $isRecording.publisher.dropFirst().map {
              Action.isRecordingChanged($0)
            }
          }
          .cancellable(id: CancelID.spunEnoughToHideSpinPrompt)
        }

      case .isRecordingChanged(let isRecording):
        // Careful: state.isRecording is not updated yet apparently???
        if isRecording {
          state.hintState = .waitToShowSpinPrompt
        }
        return .merge {
          Effect.cancel(id: CancelID.waitToShowRecordPrompt)
          if isRecording {
            Effect.run { send in
              try await clock.sleep(for: Design.waitForSpinTimeout)
              await send(.showSpinPrompt)
            }
            .cancellable(id: CancelID.waitToShowSpinPrompt)
          }
        }

      case .showRecordPrompt:
        state.hintState = .promptForRecord
        return .none

      case .showSpinPrompt:
        state.hintState = .promptForSpin
        return .none

      case .spunEnoughToHideSpinPrompt:
        state.hintState = .disabled
        return .merge(
          .cancel(id: CancelID.waitToShowRecordPrompt),
          .cancel(id: CancelID.waitToShowSpinPrompt),
          .cancel(id: CancelID.spunEnoughToHideSpinPrompt),
        )
      }
    }
  }
}
