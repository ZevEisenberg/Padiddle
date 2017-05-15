//
//  TutorialCoordinator.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 5/13/17.
//  Copyright © 2017 Zev Eisenberg. All rights reserved.
//

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

protocol TutorialCoordinatorDelegate: class {

    func showRecordPrompt()
    func hideRecordPrompt()

    func showSpinPrompt()
    func hideSpinPrompt()

}

final class TutorialCoordinator {

    // Private Properties

    fileprivate var state: State = .initial {
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

            case (.promptForRecord, .disabled):
                delegate?.hideRecordPrompt()

            case (.promptForRecord, .waitToShowSpinPrompt):
                delegate?.hideRecordPrompt()
                startTimer(timeout: Constants.waitForSpinTimeout)

            case (.waitToShowSpinPrompt, .disabled):
                // nothing more to do
                break

            case (.waitToShowSpinPrompt, .promptForSpin):
                delegate?.showSpinPrompt()

            case (.promptForSpin, .disabled):
                delegate?.hideSpinPrompt()

            case (.disabled, .waitToShowSpinPrompt):
                startTimer(timeout: Constants.waitForSpinTimeout)
            default:
                fatalError("Invalid state transition: \(oldValue) -> \(state)")

            }
        }
    }

    private weak var delegate: TutorialCoordinatorDelegate!

    fileprivate var timer: Timer?

    init(delegate: TutorialCoordinatorDelegate) {
        self.delegate = delegate
    }

}

// MARK: Public Functions

extension TutorialCoordinator {

    func start() {
        state = .waitToShowRecordPrompt
    }

    func recordButtonTapped() {
        switch state {
        case .waitToShowRecordPrompt, .promptForRecord:
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
            break // no harm done
        default:
            fatalError("Timer finished in invalid state: \(state)")
        }
    }

}

// MARK: Private

private extension TutorialCoordinator {

    enum Constants {

        static let waitForRecordTimeout: TimeInterval = 5
        static let waitForSpinTimeout: TimeInterval = 5

    }

    func startTimer(timeout: TimeInterval) {
        self.timer?.invalidate()
        let timer = Timer(timeInterval: timeout, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
        self.timer = timer
    }

    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

}
