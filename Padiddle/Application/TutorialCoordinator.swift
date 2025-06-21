import ComposableArchitecture
import UIKit

extension TutorialCoordinator {
  enum State {
    case initial
    case waitToShowRecordPrompt
    case promptForRecord
    case waitToShowSpinPrompt
    case promptForSpin
    case disabled
  }
}

@MainActor
protocol TutorialCoordinatorDelegate: AnyObject {
  func showRecordPrompt()
  func hideRecordPrompt()

  func showSpinPrompt()
  func hideSpinPrompt()
}

@MainActor
final class TutorialCoordinator {
  // Private Properties

  private var state: State = .initial {
    didSet {
      guard oldValue != state else {
        return
      }

      if state == .disabled {
        invalidateTimer()
      }

      switch (oldValue, state) {
      case (.initial, .waitToShowRecordPrompt):
        startTimer(timeout: Constants.waitForRecordTimeout)

      case (.waitToShowRecordPrompt, .disabled):
        // nothing more to do
        break

      case (.waitToShowRecordPrompt, .promptForRecord):
        delegate?.showRecordPrompt()

      case (.waitToShowRecordPrompt, .waitToShowSpinPrompt):
        startTimer(timeout: Constants.waitForSpinTimeout)
        spinManager.startMonitoringForSufficientSpin()

      case (.promptForRecord, .disabled):
        delegate?.hideRecordPrompt()

      case (.promptForRecord, .waitToShowSpinPrompt):
        delegate?.hideRecordPrompt()
        startTimer(timeout: Constants.waitForSpinTimeout)
        spinManager.startMonitoringForSufficientSpin()

      case (.waitToShowSpinPrompt, .disabled):
        // nothing more to do
        break

      case (.waitToShowSpinPrompt, .promptForSpin):
        delegate?.showSpinPrompt()

      case (.promptForSpin, .disabled):
        delegate?.hideSpinPrompt()
        spinManager.stopMonitoringForSufficientSpin()

      case (.disabled, .waitToShowSpinPrompt):
        startTimer(timeout: Constants.waitForSpinTimeout)

      default:
        fatalError("Invalid state transition: \(oldValue) -> \(state)")
      }
    }
  }

  private weak var delegate: TutorialCoordinatorDelegate!
  var spinManager: SpinManager

  private var timer: Timer?

  init(delegate: TutorialCoordinatorDelegate, spinManager: SpinManager) {
    self.delegate = delegate
    self.spinManager = spinManager
    self.spinManager.sufficientSpinDelegate = self
  }
}

// MARK: Public Functions

extension TutorialCoordinator {
  func start() {
    state = .waitToShowRecordPrompt
  }

  func recordButtonTapped() {
    switch state {
    case .waitToShowRecordPrompt,
         .promptForRecord:
      state = .waitToShowSpinPrompt
    default:
      state = .disabled
    }
  }
}

// MARK: Handlers

private extension TutorialCoordinator {
  @objc func timerFired() {
    timer?.invalidate()
    switch state {
    case .waitToShowRecordPrompt:
      state = .promptForRecord
    case .waitToShowSpinPrompt:
      state = .promptForSpin
    case .disabled:
      // nothing to do
      break
    default:
      fatalError("Timer finished in invalid state: \(state)")
    }
  }
}

// MARK: SufficientSpinDelegate

extension TutorialCoordinator: SufficientSpinDelegate {
  func spunEnough() {
    switch state {
    case .waitToShowSpinPrompt,
         .promptForSpin:
      state = .disabled
    case .disabled:
      // nothing to do
      break
    default:
      fatalError("Sufficient spin came back in unhandled state: \(state)")
    }
  }
}

// MARK: Private

private extension TutorialCoordinator {
  enum Constants {
    static let waitForRecordTimeout: TimeInterval = 5
    static let waitForSpinTimeout: TimeInterval = 3
  }

  func startTimer(timeout: TimeInterval) {
    self.timer?.invalidate()
    let timer = Timer(timeInterval: timeout, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  func invalidateTimer() {
    timer?.invalidate()
    timer = nil
  }
}
