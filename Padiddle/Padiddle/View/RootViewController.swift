//
//  ViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/12/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {

    var pinnedViewController: UIViewController
    var rotatingViewController: UIViewController

    required init(pinnedViewController: UIViewController, rotatingViewController: UIViewController) {
        self.pinnedViewController = pinnedViewController
        self.rotatingViewController = rotatingViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("\(__FUNCTION__) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .whiteColor()
        view.clipsToBounds = true

        addChildViewController(pinnedViewController)
        addChildViewController(rotatingViewController)

        view.addSubview(pinnedViewController.view)
        view.addSubview(rotatingViewController.view)

        pinnedViewController.didMoveToParentViewController(self)
        rotatingViewController.didMoveToParentViewController(self)

        pinnedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        rotatingViewController.view.translatesAutoresizingMaskIntoConstraints = false

        pinnedViewController.view.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        pinnedViewController.view.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true

        rotatingViewController.view.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        rotatingViewController.view.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        rotatingViewController.view.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        rotatingViewController.view.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
