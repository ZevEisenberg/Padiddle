//
//  CounterRotatingViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/7/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Anchorage

extension UIInterfaceOrientation: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .portrait:
            return "Portrait"
        case .portraitUpsideDown:
            return "PortraitUpsideDown"
        case .landscapeLeft:
            return "LandscapeLeft"
        case .landscapeRight:
            return "LandscapeRight"
        }
    }
}

func transformForStatusBarOrientation(_ statusBarOrientation: UIInterfaceOrientation) -> CGAffineTransform {
    let newTransform: CGAffineTransform
    switch statusBarOrientation {
    case .portrait, .unknown:
        newTransform = CGAffineTransform.identity
    case .portraitUpsideDown:
        newTransform = CGAffineTransform(rotationAngle: .pi)
    case .landscapeLeft:
        newTransform = CGAffineTransform(rotationAngle: .pi / 2)
    case .landscapeRight:
        newTransform = CGAffineTransform(rotationAngle: -.pi / 2)
    }
    return newTransform
}

class CounterRotatingViewController: UIViewController {

    let counterRotatingView = UIView(axId: "counterRotatingView")
    var rotationLocked = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(counterRotatingView)

        counterRotatingView.centerXAnchor == view.centerXAnchor
        counterRotatingView.centerYAnchor == view.centerYAnchor

        counterRotatingView.transform = transformForStatusBarOrientation(UIApplication.shared.statusBarOrientation)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {

        // amount of rotation relative to previous status bar orientation
        let targetTransform = coordinator.targetTransform

        // status bar orientation right before this rotation occurred
        let statusBarTransform = transformForStatusBarOrientation(UIApplication.shared.statusBarOrientation)

        let newTransform = targetTransform.inverted().concatenating(statusBarTransform)

        let oldAngle = counterRotatingView.transform.angle.reasonableValue
        let newAngle = newTransform.angle.reasonableValue
        let delta = newAngle - oldAngle

        let duration = coordinator.transitionDuration

        if rotationLocked {
            UIView.setAnimationsEnabled(false)
        }

        UIView.animateKeyframes(
            withDuration: duration,
            delay: 0,
            options: UIViewKeyframeAnimationOptions(),
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {

                    // The midpoint of the two-step rotation animation
                    var average = (oldAngle + newAngle) / 2

                    // Handle two edge cases that cause undesirable reverse counter-rotation,
                    // where the counter-rotating view makes a full 360° or 270° rotation
                    // instead of taking the 180° or 90° shortest path.
                    // The edge cases are as follows:
                    //     1. if the delta is +180° (+π rad)
                    //     2. if the delta is ±270° (±3π/2 rad)
                    // In both cases, we subtract 180° (π rad) so it will take the shortest path.
                    if delta.closeEnough(to: .pi) || abs(delta).closeEnough(to: 3 * .pi / 2) {
                        average -= .pi
                    }

                    self.counterRotatingView.transform = CGAffineTransform(rotationAngle: average.reasonableValue)
                }

                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.counterRotatingView.transform = newTransform
                }

            },
            completion: nil
        )

        coordinator.animate(alongsideTransition: nil, completion: { _ in
            if self.rotationLocked {
                UIView.setAnimationsEnabled(true)
            }
        })
    }

}
