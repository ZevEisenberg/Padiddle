//
//  DrawingViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/12/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

let showDebugLabel = false

class DrawingViewController: CounterRotatingViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .whiteColor()

        let width = CGRectGetWidth(UIScreen.mainScreen().bounds)
        let height = CGRectGetHeight(UIScreen.mainScreen().bounds)

        let longSide = max(width, height)

        view.widthAnchor.constraintEqualToConstant(longSide).active = true
        view.heightAnchor.constraintEqualToConstant(longSide).active = true

        if showDebugLabel {
            let label = UILabel()
            label.text = "Drawing view debug label"
            label.translatesAutoresizingMaskIntoConstraints = false
            counterRotatingView.addSubview(label)

            label.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
            label.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true
        }
    }
}
