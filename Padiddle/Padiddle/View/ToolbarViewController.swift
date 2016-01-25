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

    @IBOutlet private var toolbarStackView: UIStackView!
    @IBOutlet private var clearButton: UIButton!
    @IBOutlet private var colorButton: UIButton!
    @IBOutlet private var recordButton: UIButton!
    @IBOutlet private var shareButton: UIButton!
    @IBOutlet private var helpButton: UIButton!

    @IBOutlet var spacerViews: [UIView]!

    @IBOutlet var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet var toolbarTopConstraint: NSLayoutConstraint!

    private var passthroughViews: [UIView] {
        return [toolbarStackView, recordButton]
    }

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
        let clearAction = UIAlertAction(title: NSLocalizedString("Clear Drawing", comment: "Title of a button to erase the current drawing immediately"), style: .Destructive) { _ in
            self.viewModel?.clearTapped()
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Button to cancel the current action"), style: .Cancel, handler: nil)
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alert.addAction(clearAction)
        alert.addAction(cancelAction)
        alert.modalPresentationStyle = .Popover

        presentViewController(alert, animated: true, completion: nil)
        let popoverController = alert.popoverPresentationController
        popoverController?.sourceView = self.clearButton
        popoverController?.sourceRect = self.clearButton.bounds
        popoverController?.permittedArrowDirections = .Down
    }

    @IBAction func colorTapped() {
        let viewControllerToShow: UIViewController

        let colorPickerViewController = ColorPickerViewController(viewModel: (viewModel?.colorPickerViewModel)!, delegate: self)

        if traitCollection.horizontalSizeClass == .Regular && traitCollection.verticalSizeClass == .Regular {
            viewControllerToShow = colorPickerViewController
            viewControllerToShow.modalPresentationStyle = .Popover
        } else {
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
            popoverController.passthroughViews = passthroughViews
        }
    }

    @IBAction func recordTapped() {
        print(__FUNCTION__)
        recordButton.selected = !recordButton.selected

        viewModel?.recordButtonTapped()
    }

    @IBAction func shareTapped() {
        print(__FUNCTION__)

        guard let viewModel = viewModel else { fatalError() }

        // Prevent the user from doing stuff while we are generating the snapshot

        toolbarStackView.userInteractionEnabled = false
        recordButton.userInteractionEnabled = false

        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.color = UIColor.appTintColor
        activityIndicator.startAnimating()

        guard let indexOfShareButton = toolbarStackView.arrangedSubviews.indexOf(shareButton) else {
            fatalError("If shareButton does not exist in the toolbar stack view, something is wrong")
        }

        toolbarStackView.removeArrangedSubview(shareButton)
        shareButton.hidden = true
        toolbarStackView.insertArrangedSubview(activityIndicator, atIndex: indexOfShareButton)

        // Dismiss any other modals that may be visible
        dismissViewControllerAnimated(true, completion: nil)

        // We are going to run this whether or not we get an image back
        let restoreShareButton: UIViewController -> Void = { presentedViewController in
            self.toolbarStackView.removeArrangedSubview(activityIndicator)
            self.toolbarStackView.insertArrangedSubview(self.shareButton, atIndex: indexOfShareButton)
            self.shareButton.hidden = false
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()

            self.toolbarStackView.userInteractionEnabled = true
            self.recordButton.userInteractionEnabled = true

            guard let popoverController = presentedViewController.popoverPresentationController else { return }
            popoverController.sourceView = self.shareButton
            popoverController.sourceRect = self.shareButton.bounds
        }

        // Get the snapshot image async
        let interfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
        viewModel.getSnapshotImage(interfaceOrientation) { image in

            assert(NSThread.isMainThread())

            let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            activityViewController.excludedActivityTypes = [UIActivityTypeAssignToContact]
            activityViewController.modalPresentationStyle = .Popover

            self.presentViewController(activityViewController, animated: true) {
                restoreShareButton(activityViewController)
            }

            guard let popoverController = activityViewController.popoverPresentationController else { return }
            popoverController.sourceView = activityIndicator
            popoverController.sourceRect = activityIndicator.bounds
            popoverController.permittedArrowDirections = .Down
            popoverController.passthroughViews = self.passthroughViews
        }
    }

    @IBAction func helpTapped() {
        let helpViewController = HelpViewController()
        helpViewController.modalPresentationStyle = .Popover

        let viewControllerToShow: UIViewController

        if traitCollection.horizontalSizeClass == .Regular && traitCollection.verticalSizeClass == .Regular {
            viewControllerToShow = helpViewController
            viewControllerToShow.modalPresentationStyle = .Popover
        } else {
            let navigationController = UINavigationController(rootViewController: helpViewController)
            setUpNavigationItem(helpViewController.navigationItem, cancelSelector: nil, doneSelector: "dismissModal")
            viewControllerToShow = navigationController
            viewControllerToShow.modalPresentationStyle = .FormSheet
        }

        self.presentViewController(viewControllerToShow, animated: true) { }

        if let popoverController = viewControllerToShow.popoverPresentationController {
            popoverController.sourceView = helpButton
            popoverController.sourceRect = helpButton.bounds
            popoverController.permittedArrowDirections = .Down
            popoverController.passthroughViews = passthroughViews
        }
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
        if toolbarVisible != visible {
            toolbarVisible = visible
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
        let image = SpiralImageMaker.image(color,
            size: CGSize(width: imageSize, height: imageSize),
            startRadius: 0,
            spacePerLoop: 0.7,
            startTheta: 0,
            endTheta: 2.0 * π * 4.0,
            thetaStep: π / 16.0,
            lineWidth: 2.3)
        colorButton.setImage(image, forState: .Normal)
        HelpImageProtocol.colorButtonImage = image
    }

    private func updateToolbarConstraints(toolbarVisible toolbarVisible: Bool) {
        if toolbarVisible {
            toolbarTopConstraint.active = false
            toolbarBottomConstraint.active = true
        } else {
            toolbarBottomConstraint.active = false
            toolbarTopConstraint.active = true
        }
    }

    private func setUpNavigationItem(navigationItem: UINavigationItem, cancelSelector: Selector?, doneSelector: Selector?) {

        if let cancelSelector = cancelSelector {
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: cancelSelector)
            navigationItem.leftBarButtonItem = cancelButton
        }

        if let doneSelector = doneSelector {
            let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: doneSelector)
            navigationItem.rightBarButtonItem = doneButton
        }
    }
}
