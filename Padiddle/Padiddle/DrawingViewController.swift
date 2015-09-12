//
//  DrawingViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/12/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

class DrawingViewController: UIViewController {

    private let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.3)

        let width = CGRectGetWidth(UIScreen.mainScreen().bounds)
        let height = CGRectGetHeight(UIScreen.mainScreen().bounds)

        let longSide = max(width, height)

        view.widthAnchor.constraintEqualToConstant(longSide).active = true
        view.heightAnchor.constraintEqualToConstant(longSide).active = true

        label.text = "Drawing view will go here eventually"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        label.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        label.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true
    }
}
