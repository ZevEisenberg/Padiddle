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

    @IBOutlet private var clearButton: UIButton!
    @IBOutlet private var colorButton: UIButton!
    @IBOutlet private var recordButton: UIButton!
    @IBOutlet private var shareButton: UIButton!
    @IBOutlet private var helpButton: UIButton!

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
        let viewControllerToShow: UIViewController

        let viewModel = ColorPickerViewModel()
        let colorPickerViewController = ColorPickerViewController(viewModel: viewModel)

        if traitCollection.horizontalSizeClass == .Regular && traitCollection.verticalSizeClass == .Regular {
            viewControllerToShow = colorPickerViewController
            viewControllerToShow.modalPresentationStyle = .Popover
        }
        else {
            let navigationController = UINavigationController(rootViewController: colorPickerViewController)
            setUpNavigationItem(colorPickerViewController.navigationItem, cancelSelector: "dismissModal", doneSelector: nil)
            viewControllerToShow = navigationController
            viewControllerToShow.modalPresentationStyle = .FormSheet
        }

        self.presentViewController(viewControllerToShow, animated: true, completion: nil)
        if let popoverController = viewControllerToShow.popoverPresentationController {
            popoverController.sourceView = colorButton
            popoverController.sourceRect = colorButton.bounds
            popoverController.permittedArrowDirections = .Down
        }
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

    func dismissModal() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    //Mark: Private

    private func updateToolbarConstraints(toolbarVisible toolbarVisible: Bool) {
        if toolbarVisible {
            toolbarTopConstraint.active = false
            toolbarBottomConstraint.active = true
        }
        else {
            toolbarBottomConstraint.active = false
            toolbarTopConstraint.active = true
        }
    }

    private func setUpNavigationItem(navigationItem: UINavigationItem, cancelSelector: Selector?, doneSelector: Selector?) {

        if cancelSelector != nil {
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: cancelSelector!)
            navigationItem.leftBarButtonItem = cancelButton
        }

        if doneSelector != nil {
            let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: doneSelector!)
            navigationItem.rightBarButtonItem = doneButton
        }
    }
}
