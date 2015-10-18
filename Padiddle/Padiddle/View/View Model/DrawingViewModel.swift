//
//  DrawingViewModel.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/7/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit
import CoreMotion

let kMotionManagerUpdateInterval: NSTimeInterval = 1.0 / 120.0
let kNibUpdateInterval: NSTimeInterval = 1.0 / 60.0

protocol DrawingViewModelDelegate: class {
    func start()
    func pause()
    func drawingViewModelUpdatedLocation(newLocation: CGPoint)
}

class DrawingViewModel: NSObject, RecordingDelegate { // must inherit from NSObject for NSTimer to work
    var isUpdating = false
    var needToMoveNibToNewStartLocation = true
    weak var delegate: DrawingViewModelDelegate?

    private let motionManager = CMMotionManager()

    private let maxRadius: CGFloat

    private var updateTimer: NSTimer?

    required init(maxRadius: CGFloat) {
        assert(maxRadius > 0)
        self.maxRadius = maxRadius
        motionManager.deviceMotionUpdateInterval = kMotionManagerUpdateInterval
    }

    func startMotionUpdates() {
        if motionManager.gyroAvailable {
            if motionManager.magnetometerAvailable {
                motionManager.startDeviceMotionUpdatesUsingReferenceFrame(.XArbitraryCorrectedZVertical)
            }
            else {
                motionManager.startDeviceMotionUpdatesUsingReferenceFrame(.XArbitraryZVertical)
            }

            if updateTimer == nil {
                updateTimer = NSTimer.scheduledTimerWithTimeInterval(kNibUpdateInterval, target: self, selector: "timerFired", userInfo: nil, repeats: true)
            }
        }
    }

    func stopMotionUpdates() {
        updateTimer?.invalidate()
        motionManager.stopDeviceMotionUpdates()
    }

    func timerFired() {
        if let deviceMotion = motionManager.deviceMotion {

            let zRotation = deviceMotion.rotationRate.z
            let radius = maxRadius / UIDevice.gyroMaxValue * CGFloat(fabs(zRotation))
            let theta = deviceMotion.attitude.yaw

            let x = radius * CGFloat(cos(theta)) + maxRadius / 2.0
            let y = radius * CGFloat(sin(theta)) + maxRadius / 2.0

            delegate?.drawingViewModelUpdatedLocation(CGPoint(x: x, y: y))
        }
    }

    // MARK: RecordingDelegate

    @objc func recordingStatusChanged(recording: Bool) {
        if recording {
            delegate?.start()
        }
        else {
            delegate?.pause()
        }
    }

    @objc func motionUpdatesStatusChanged(updates: Bool) {
        if updates {
            startMotionUpdates()
        }
        else {
            stopMotionUpdates()
        }
    }

    @objc func persistImageInBackground() {
        // TODO
    }
}
