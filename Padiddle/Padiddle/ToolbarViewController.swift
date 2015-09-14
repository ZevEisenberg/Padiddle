//
//  ToolbarViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/12/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

private let kPauseButtonName = "PauseButton"
private let kTempColorButtonName = "TempColorButton"
private let kHelpButtonName = "HelpButton"

private let kOtherButtonPadding = CGFloat(20.0)
private let kRecordButtonPadding = CGFloat(20.0)

private let kToolbarAnimationDuration = 0.3

class ToolbarViewController: UIViewController {

    @IBOutlet var recordButton: UIButton!

    @IBOutlet var spacerViews: [UIView]!

    @IBOutlet var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet var toolbarTopConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        for spacer in spacerViews {
            spacer.backgroundColor = nil
        }

        let pauseImage = UIImage(named: kPauseButtonName)!
        recordButton.setImage(pauseImage, forState: .Selected)
    }

    //Mark: Button Handlers

    @IBAction func trashTapped() {
        print(__FUNCTION__)
    }

    @IBAction func colorTapped() {
        print(__FUNCTION__)
    }

    @IBAction func recordTapped() {
        print(__FUNCTION__)
        recordButton.selected = !recordButton.selected

        updateToolbarConstraints(toolbarVisible: !recordButton.selected)

        UIView.animateWithDuration(kToolbarAnimationDuration) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func shareTapped() {
        print(__FUNCTION__)
    }

    @IBAction func helpTapped() {
        print(__FUNCTION__)
    }

    //Mark: Private

    func updateToolbarConstraints(toolbarVisible toolbarVisible: Bool) {
        if toolbarVisible {
            toolbarTopConstraint.active = false
            toolbarBottomConstraint.active = true
        }
        else {
            toolbarBottomConstraint.active = false
            toolbarTopConstraint.active = true
        }
    }
}
