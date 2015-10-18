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

class ToolbarViewController: UIViewController, ColorPickerDelegate, ToolbarViewModelToolbarDelegate {

    var viewModel: ToolbarViewModel?

    var toolbarVisible: Bool = true

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

        view.backgroundColor = nil

        for spacer in spacerViews {
            spacer.backgroundColor = nil
        }

        let pauseImage = UIImage(named: kPauseButtonName)!
        recordButton.setImage(pauseImage, forState: .Selected)
        updateColorButton(colorManager: (viewModel?.colorPickerViewModel?.selectedColorManager)!)
    }

    // MARK: Button Handlers

    @IBAction func trashTapped() {
        print(__FUNCTION__)
    }

    @IBAction func colorTapped() {
        let viewControllerToShow: UIViewController

        let colorPickerViewController = ColorPickerViewController(viewModel: (viewModel?.colorPickerViewModel)!, delegate: self)

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

        presentViewController(viewControllerToShow, animated: true, completion: nil)
        if let popoverController = viewControllerToShow.popoverPresentationController {
            popoverController.sourceView = colorButton
            popoverController.sourceRect = colorButton.bounds
            popoverController.permittedArrowDirections = .Down
        }
    }

    @IBAction func recordTapped() {
        print(__FUNCTION__)
        recordButton.selected = !recordButton.selected

        // TODO: tapping record button when already recording does not correctly restore toolbar
        viewModel?.recordButtonTapped()
    }

    @IBAction func shareTapped() {
        print(__FUNCTION__)
    }

    @IBAction func helpTapped() {
        print(__FUNCTION__)
    }

    func dismissModal() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: ColorPickerDelegate

    func colorPicked(color: ColorManager) {
        updateColorButton(colorManager: color)
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: ToolbarViewModelDelegate

    func setToolbarVisible(visible: Bool, animated: Bool) {
        if visible != toolbarVisible {
            updateToolbarConstraints(toolbarVisible: visible)

            let duration = animated ? kToolbarAnimationDuration : 0.0
            UIView.animateWithDuration(duration) {
                self.view.layoutIfNeeded()
            }
        }
    }

    // MARK: Private

    private func updateColorButton(colorManager color: ColorManager) {
        let imageSize = 36
        let image = ImageMaker.image(color,
            size: CGSize(width: imageSize, height: imageSize),
            startRadius: 0,
            spacePerLoop: 0.7,
            startTheta: 0,
            endTheta: 2.0 * CGFloat(M_PI) * 4.0,
            thetaStep: CGFloat(M_PI) / 16.0,
            lineWidth: 2.3)
        colorButton.setImage(image, forState: .Normal)
    }

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
