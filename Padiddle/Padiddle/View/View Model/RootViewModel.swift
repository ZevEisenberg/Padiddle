//
//  RootViewModel.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/17/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Foundation

@objc protocol RecordingDelegate:
class {
    func recordingStatusChanged(recording: Bool)
    optional func motionUpdatesStatusChanged(updates: Bool)
    optional func persistImageInBackground()
}

class RootViewModel {
    private var recordingDelegates = [Weak<RecordingDelegate>]()

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
}
