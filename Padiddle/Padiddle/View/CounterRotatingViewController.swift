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

extension CGAffineTransform {
    var angle: CGFloat {
        get {
            return atan2(b, a)
        }
    }
}

enum Direction {
    case None
    case Left
    case Right
}

extension CGAffineTransform {
    var direction: Direction {
        let direction: Direction
        if b > 0 {
            direction = .Left
        }
        else if b < 0 {
            direction = .Right
        }
        else {
            direction = .None
        }

        return direction
    }
}

extension CGFloat {
    var reasonableValue: CGFloat {
        get {
            return (fabs(self) < 0.0001 ? 0 : self)
        }
    }
}

func transformForStatusBarOrientation(statusBarOrientation: UIInterfaceOrientation) -> CGAffineTransform {
    let newTransform: CGAffineTransform
    switch statusBarOrientation {
    case .Portrait, .Unknown:
        newTransform = CGAffineTransformIdentity
    case .PortraitUpsideDown:
        newTransform = CGAffineTransformMakeRotation(CGFloat(M_PI))
    case .LandscapeLeft:
        newTransform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
    case .LandscapeRight:
        newTransform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
    }
    return newTransform
}

class CounterRotatingViewController: UIViewController {

    let counterRotatingView = UIView()
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

        let duration = coordinator.transitionDuration()

        if rotationLocked {
            UIView.setAnimationsEnabled(false)
        }
        UIView.animateKeyframesWithDuration(duration, delay: 0, options: UIViewKeyframeAnimationOptions(rawValue: 0), animations: {
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.5, animations: {
                let average = (oldAngle + newAngle) / 2
                self.counterRotatingView.transform = CGAffineTransformMakeRotation(average)
            })
            UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5, animations: {
                self.counterRotatingView.transform = newTransform
            })
            }) { (finished: Bool) -> Void in
        }

        coordinator.animateAlongsideTransition({ (context) -> Void in
            }) { (context) -> Void in
                if self.rotationLocked {
                    UIView.setAnimationsEnabled(true)
                }
        }
    }
}
