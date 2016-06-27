//
//  CounterRotatingViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/7/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

extension UIInterfaceOrientation: CustomStringConvertible {
    public var description: String {
        switch self {
        case Unknown:
            return "Unknown"
        case Portrait:
            return "Portrait"
        case PortraitUpsideDown:
            return "PortraitUpsideDown"
        case LandscapeLeft:
            return "LandscapeLeft"
        case LandscapeRight:
            return "LandscapeRight"
        }
    }
}

func transformForStatusBarOrientation(statusBarOrientation: UIInterfaceOrientation) -> CGAffineTransform {
    let newTransform: CGAffineTransform
    switch statusBarOrientation {
    case .Portrait, .Unknown:
        newTransform = CGAffineTransformIdentity
    case .PortraitUpsideDown:
        newTransform = CGAffineTransformMakeRotation(π)
    case .LandscapeLeft:
        newTransform = CGAffineTransformMakeRotation(π / 2)
    case .LandscapeRight:
        newTransform = CGAffineTransformMakeRotation(-π / 2)
    }
    return newTransform
}

class CounterRotatingViewController: UIViewController {

    let counterRotatingView = UIView("counterRotatingView")
    var rotationLocked = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(counterRotatingView)
        counterRotatingView.translatesAutoresizingMaskIntoConstraints = false

        counterRotatingView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        counterRotatingView.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true

        counterRotatingView.transform = transformForStatusBarOrientation(UIApplication.sharedApplication().statusBarOrientation)
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {

        // amount of rotation relative to previous status bar orientation
        let targetTransform = coordinator.targetTransform()

        // status bar orientation right before this rotation occurred
        let statusBarTransform = transformForStatusBarOrientation(UIApplication.sharedApplication().statusBarOrientation)

        let newTransform = CGAffineTransformConcat(CGAffineTransformInvert(targetTransform), statusBarTransform)

        let oldAngle = counterRotatingView.transform.angle.reasonableValue
        let newAngle = newTransform.angle.reasonableValue
        let delta = newAngle - oldAngle

        let duration = coordinator.transitionDuration()

        if rotationLocked {
            UIView.setAnimationsEnabled(false)
        }

        UIView.animateKeyframesWithDuration(
            duration,
            delay: 0,
            options: UIViewKeyframeAnimationOptions(),
            animations: {
                UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.5) {

                    // The midpoint of the two-step rotation animation
                    var average = (oldAngle + newAngle) / 2

                    // Handle two edge cases that cause undesirable reverse counter-rotation,
                    // where the counter-rotating view makes a full 360° or 270° rotation
                    // instead of taking the 180° or 90° shortest path.
                    // The edge cases are as follows:
                    //     1. if the delta is +180° (+π rad)
                    //     2. if the delta is ±270° (±3π/2 rad)
                    // In both cases, we subtract 180° (π rad) so it will take the shortest path.
                    if delta.closeEnough(π) || abs(delta).closeEnough(3 * π / 2) {
                        average -= π
                    }

                    self.counterRotatingView.transform = CGAffineTransformMakeRotation(average.reasonableValue)
                }

                UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5) {
                    self.counterRotatingView.transform = newTransform
                }

            },
            completion: nil
        )

        coordinator.animateAlongsideTransition(nil, completion: { _ in
            if self.rotationLocked {
                UIView.setAnimationsEnabled(true)
            }
        })
    }
}
