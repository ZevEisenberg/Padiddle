//
//  RootViewModel.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/17/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Foundation
import UIKit.UIApplication

@objc protocol RecordingDelegate: class {

    func recordingStatusChanged(_ recording: Bool)
    @objc optional func motionUpdatesStatusChanged(_ updates: Bool)
    @objc optional func persistImageInBackground()

}

protocol RootColorManagerDelegate: class {

    func colorManagerPicked(_ colorManager: ColorManager)

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

    func addRecordingDelegate(_ delegate: RecordingDelegate) {
        recordingDelegates.append(Weak(value: delegate))
    }

    func getSnapshotImage(_ interfaceOrientation: UIInterfaceOrientation, completion: @escaping (UIImage) -> Void) {
        guard let drawingViewController = drawingViewController else { fatalError() }
        drawingViewController.getSnapshotImage(interfaceOrientation: interfaceOrientation, completion: completion)
    }

    func clearTapped() {
        drawingViewController?.clearTapped()
    }

}

extension RootViewModel: ToolbarViewModelColorDelegate {

    func colorManagerPicked(_ colorManager: ColorManager) {
        rootColorManagerDelegate?.colorManagerPicked(colorManager)
    }

}
