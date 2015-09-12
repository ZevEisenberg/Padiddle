//
//  ToolbarViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/12/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

class ToolbarViewController: UIViewController {

    private let toolbar = UIToolbar()

    override func viewDidLoad() {
        super.viewDidLoad()

        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)
        toolbar.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        toolbar.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        toolbar.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
    }
}
