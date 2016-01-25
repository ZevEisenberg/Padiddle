//
//  RootViewModel.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/17/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Foundation
import UIKit.UIApplication

@objc protocol RecordingDelegate:
class {
    func recordingStatusChanged(recording: Bool)
    optional func motionUpdatesStatusChanged(updates: Bool)
    optional func persistImageInBackground()
}

protocol RootColorManagerDelegate:
class {
    func colorManagerPicked(colorManager: ColorManager)
}

class RootViewModel {
    private var recordingDelegates = [Weak<RecordingDelegate>]()
    weak var rootColorManagerDelegate: RootColorManagerDelegate?
    weak var drawingViewController: DrawingViewController?

    init(rootColorManagerDelegate: RootColorManagerDelegate) {
        self.rootColorManagerDelegate = rootColorManagerDelegate
    }

    var recording = false {
        didSet {
            for delegate in recordingDelegates {
                delegate.value?.recordingStatusChanged(recording)
            }
        }
    }

    var motionUpdates = false {
        didSet {
            for delegate in recordingDelegates {
                delegate.value?.motionUpdatesStatusChanged?(motionUpdates)
            }
        }
    }

    func persistImageInBackground() {
        for delegate in recordingDelegates {
            delegate.value?.persistImageInBackground?()
        }
    }

    func addRecordingDelegate(delegate: RecordingDelegate) {
        recordingDelegates.append(Weak(value: delegate))
    }

    func getSnapshotImage(interfaceOrientation: UIInterfaceOrientation, completion: UIImage -> Void) {
        guard let drawingViewController = drawingViewController else { fatalError() }
        drawingViewController.getSnapshotImage(interfaceOrientation, completion: completion)
    }

    func clearTapped() {
        drawingViewController?.clearTapped()
    }
}

extension RootViewModel: ToolbarViewModelColorDelegate {
    func colorManagerPicked(colorManager: ColorManager) {
        rootColorManagerDelegate?.colorManagerPicked(colorManager)
    }
}
