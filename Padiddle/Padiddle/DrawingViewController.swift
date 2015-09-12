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

        label.text = "Drawing view will go here eventually"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        label.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        label.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        label.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        label.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
    }
}
