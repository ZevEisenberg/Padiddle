//
//  SpinManager.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 5/17/17.
//  Copyright © 2017 Zev Eisenberg. All rights reserved.
//

import CoreMotion
import Foundation

class SpinManager: NSObject {

    // Public Properties

    var deviceMotion: CMDeviceMotion? {
        return motionManager.deviceMotion
    }

    // Private Properties

    fileprivate let motionManager: CMMotionManager = {
        let manager = CMMotionManager()
        manager.deviceMotionUpdateInterval = 1.0 / 120.0
        return manager
    }()

}

// MARK: Public Methods

extension SpinManager {

    func startMotionUpdates() {
        if motionManager.isMagnetometerAvailable {
            motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
        }
        else {
            motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)
        }

    }

    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }

}
