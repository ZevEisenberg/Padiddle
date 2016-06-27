//
//  ToolbarViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/12/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Anchorage

class ToolbarViewController: UIViewController {

    private let toolbarAnimationDuration = 0.3

    var viewModel: ToolbarViewModel?

    private var toolbarVisible: Bool = true

    private let recordButtonBack = UIImageView("recordButtonBack")
    private let toolbarStackView = UIStackView("toolbarStackView")
    private let clearButton = UIButton(type: .Custom, "clearButton")
    private let colorButton = UIButton(type: .Custom, "colorButton")
    private let recordButtonPlaceholder = UIView("recordButtonPlaceholder")
    private let recordButton = UIButton(type: .Custom, "recordButton")
    private let shareButton = UIButton(type: .Custom, "shareButton")
    private let helpButton = UIButton(type: .Custom, "helpButton")

    private var toolbarBottomConstraint: NSLayoutConstraint!
    private var toolbarTopConstraint: NSLayoutConstraint!

    private var passthroughViews: [UIView] {
        return [toolbarStackView, recordButton]
    }
}

private typealias Layout = ToolbarViewController
extension Layout {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "toolbar view controller view"

        configureViews()

        updateColorButton(colorManager: (viewModel?.colorPickerViewModel?.selectedColorManager)!)
    }

    private func configureViews() {

        let toolbarView = UIView("toolbarView")
        let toolbarHairline = UIView("toolbarHairline")
        let spacerViews: [UIView] = {
            var spacers = [UIView]()
            for i in 0..<6 {
                spacers.append(UIView("spacer\(i)"))
            }
            return spacers
        }()

        // Record Button Back View
        recordButtonBack.image = UIImage(asset: .RecordButtonBack)
        view.addSubview(recordButtonBack)

        // Toolbar
        toolbarView.backgroundColor = UIColor(named: .Toolbar)
        view.addSubview(toolbarView)
        toolbarView.heightAnchor == 44

        toolbarView.horizontalAnchors == view.horizontalAnchors ~ UILayoutPriorityDefaultHigh

        toolbarBottomConstraint = (toolbarView.bottomAnchor == bottomLayoutGuide.topAnchor)

        // don't activate yet
        toolbarTopConstraint = toolbarView.topAnchor.constraintEqualToAnchor(self.bottomLayoutGuide.topAnchor)

        toolbarHairline.backgroundColor = UIColor(named: .ToolbarHairline)
        toolbarView.addSubview(toolbarHairline)

        toolbarHairline.heightAnchor == 1
        toolbarHairline.topAnchor == toolbarView.topAnchor
        toolbarHairline.horizontalAnchors == toolbarView.horizontalAnchors

        // Stack View
        view.addSubview(toolbarStackView)
        toolbarStackView.axis = .Horizontal
        toolbarStackView.alignment = .Fill
        toolbarStackView.distribution = .Fill
        toolbarStackView.spacing = 0

        toolbarStackView.edgeAnchors == toolbarView.edgeAnchors

        spacerViews.forEach {
            $0.backgroundColor = nil
        }

        let buttons = [
            clearButton,
            colorButton,
            recordButtonPlaceholder,
            shareButton,
            helpButton,
        ]

        let stackSubViews = spacerViews.zip(almostSameLengthArray: buttons)

        stackSubViews.forEach {
            toolbarStackView.addArrangedSubview($0)
        }

        recordButtonBack.widthAnchor == recordButtonPlaceholder.widthAnchor
        recordButtonBack.centerXAnchor == recordButtonPlaceholder.centerXAnchor
        if let recordButtonPlaceholderSuperview = recordButtonPlaceholder.superview {
            recordButtonPlaceholder.heightAnchor == recordButtonPlaceholderSuperview.heightAnchor
        }

        clearButton.setImage(UIImage(asset: .TrashButton), forState: .Normal)
        clearButton.addTarget(self, action: #selector(ToolbarViewController.trashTapped), forControlEvents: .TouchUpInside)

        // image is dynamic
        colorButton.addTarget(self, action: #selector(ToolbarViewController.colorTapped), forControlEvents: .TouchUpInside)

        recordButtonBack.image = UIImage(asset: .RecordButtonBack)

        recordButton.setImage(UIImage(asset: .RecordButtonFront), forState: .Normal)
        recordButton.setImage(UIImage(asset: .PauseButton), forState: .Selected)
        recordButton.addTarget(self, action: #selector(ToolbarViewController.recordTapped), forControlEvents: .TouchUpInside)

        shareButton.setImage((UIImage(asset: .ShareButton)), forState: .Normal)
        shareButton.addTarget(self, action: #selector(ToolbarViewController.shareTapped), forControlEvents: .TouchUpInside)

        helpButton.setImage(UIImage(asset: .HelpButton), forState: .Normal)
        helpButton.addTarget(self, action: #selector(ToolbarViewController.helpTapped), forControlEvents: .TouchUpInside)

        let nonRecordButtons: [UIButton] = [
            clearButton,
            colorButton,
            shareButton,
            helpButton,
        ]

        // make buttons equal width to each other
        for buttonDoublet in nonRecordButtons.doublets! {
            buttonDoublet.0.widthAnchor == buttonDoublet.1.widthAnchor
        }

        // Make first and last spacer views’ widths equal to each other
        guard let first = spacerViews.first, last = spacerViews.last else { fatalError() }
        first.widthAnchor == last.widthAnchor

        // Make all other spacer views a fixed width
        spacerViews.dropFirst().dropLast().forEach {
            $0.widthAnchor == 20
        }

        view.addSubview(recordButton)
        recordButton.centerXAnchor == recordButtonPlaceholder.centerXAnchor
        recordButton.widthAnchor == recordButtonPlaceholder.widthAnchor
        recordButton.centerXAnchor == recordButtonBack.centerXAnchor
        recordButton.centerYAnchor == recordButtonBack.centerYAnchor
        recordButton.bottomAnchor == bottomLayoutGuide.topAnchor - 5
        recordButton.widthAnchor == recordButtonBack.widthAnchor
        recordButton.heightAnchor == recordButtonBack.heightAnchor
        if let recordButtonSuperview = recordButton.superview {
            recordButton.centerXAnchor == recordButtonSuperview.centerXAnchor
        }
    }
}

typealias ButtonHandlers = ToolbarViewController
extension ButtonHandlers {
    func trashTapped() {
        Log.info()
        let clearAction = UIAlertAction(title: L10n.ClearDrawing.string, style: .Destructive) { _ in
            Log.info("Clear Drawing tapped")
            self.viewModel?.clearTapped()
        }
        let cancelAction = UIAlertAction(title: L10n.Cancel.string, style: .Cancel) { _ in Log.info("Clear Drawing canceled") }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alert.addAction(clearAction)
        alert.addAction(cancelAction)
        alert.modalPresentationStyle = .Popover

        presentViewController(alert, animated: true, completion: nil)
        configurePopover(viewController: alert, sourceView: clearButton)
    }

    func colorTapped() {
        Log.info()
        let viewControllerToShow: UIViewController

        let colorPickerViewController = ColorPickerViewController(viewModel: (viewModel?.colorPickerViewModel)!, delegate: self)

        if traitCollection.horizontalSizeClass == .Regular && traitCollection.verticalSizeClass == .Regular {
            viewControllerToShow = colorPickerViewController
            viewControllerToShow.modalPresentationStyle = .Popover
        } else {
            let navigationController = UINavigationController(rootViewController: colorPickerViewController)
            setUpNavigationItem(colorPickerViewController.navigationItem, cancelSelector: #selector(ToolbarViewController.dismissModal), doneSelector: nil)
            viewControllerToShow = navigationController
            viewControllerToShow.modalPresentationStyle = .FormSheet
        }

        presentViewController(viewControllerToShow, animated: true, completion: nil)
        configurePopover(viewController: viewControllerToShow, sourceView: colorButton)
    }

    func recordTapped() {
        Log.info("new recording status: \(!recordButton.selected)")
        recordButton.selected = !recordButton.selected

        viewModel?.recordButtonTapped()
    }

    func shareTapped() {
        Log.info()

        guard let viewModel = viewModel else { fatalError() }

        // Prevent the user from doing stuff while we are generating the snapshot

        toolbarStackView.userInteractionEnabled = false
        recordButton.userInteractionEnabled = false

        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.color = UIColor(named: .AppTint)
        activityIndicator.startAnimating()

        shareButton.alpha = 0
        toolbarStackView.addSubview(activityIndicator) // not insertArrangedSubview!
        activityIndicator.centerXAnchor == shareButton.centerXAnchor
        activityIndicator.centerYAnchor == shareButton.centerYAnchor

        // Dismiss any other modals that may be visible
        dismissViewControllerAnimated(true, completion: nil)

        // We are going to run this whether or not we get an image back
        let restoreShareButton: UIViewController -> Void = { presentedViewController in
            self.shareButton.alpha = 1
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
            activityViewController.completionWithItemsHandler = { (activityType: String?, completed: Bool, returnedItems: [AnyObject]?, activityError: NSError?) in
                if completed {
                    Log.info("shared via \(activityType ?? "unknown sharing type")")
                } else {
                    Log.info("Canceled sharing")
                }
            }

            self.presentViewController(activityViewController, animated: true, completion: {
                restoreShareButton(activityViewController)
            })
            self.configurePopover(viewController: activityViewController, sourceView: activityIndicator)
        }
    }

    func helpTapped() {
        Log.info()
        let helpViewController = HelpViewController()
        helpViewController.modalPresentationStyle = .Popover

        let viewControllerToShow: UIViewController

        if traitCollection.horizontalSizeClass == .Regular && traitCollection.verticalSizeClass == .Regular {
            viewControllerToShow = helpViewController
            viewControllerToShow.modalPresentationStyle = .Popover
        } else {
            let navigationController = UINavigationController(rootViewController: helpViewController)
            setUpNavigationItem(helpViewController.navigationItem, cancelSelector: nil, doneSelector: #selector(ToolbarViewController.dismissModal))
            viewControllerToShow = navigationController
            viewControllerToShow.modalPresentationStyle = .FormSheet
        }

        self.presentViewController(viewControllerToShow, animated: true, completion: nil)
        configurePopover(viewController: viewControllerToShow, sourceView: helpButton)
    }
}

extension ToolbarViewController: ColorPickerDelegate {
    func colorPicked(color: ColorManager) {
        updateColorButton(colorManager: color)
        dismissViewControllerAnimated(true, completion: nil)
        Log.info(color)
    }
}

extension ToolbarViewController: ToolbarViewModelToolbarDelegate {
    func setToolbarVisible(visible: Bool, animated: Bool) {
        if toolbarVisible != visible {
            toolbarVisible = visible
            updateToolbarConstraints(toolbarVisible: visible)

            let duration = animated ? toolbarAnimationDuration : 0.0
            UIView.animateWithDuration(duration) {
                self.view.layoutIfNeeded()
            }
        }
    }
}

private extension ToolbarViewController {

    @objc func dismissModal() {
        Log.info()
        dismissViewControllerAnimated(true, completion: nil)
    }

    func setUpNavigationItem(navigationItem: UINavigationItem, cancelSelector: Selector?, doneSelector: Selector?) {

        if let cancelSelector = cancelSelector {
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: cancelSelector)
            cancelButton.accessibilityIdentifier = "cancelButton"
            navigationItem.leftBarButtonItem = cancelButton
        }

        if let doneSelector = doneSelector {
            let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: doneSelector)
            doneButton.accessibilityIdentifier = "doneButton"
            navigationItem.rightBarButtonItem = doneButton
        }
    }

    func updateColorButton(colorManager colorManager: ColorManager) {
        let imageSize = 36
        let model = SpiralModel(
            colorManager: colorManager,
            size: CGSize(width: imageSize, height: imageSize),
            startRadius: 0,
            spacePerLoop: 0.7,
            thetaRange: 0...(2.0 * π * 4.0),
            thetaStep: π / 16.0,
            lineWidth: 2.3)

        let image = SpiralImageMaker.image(spiralModel: model)

        colorButton.setImage(image, forState: .Normal)
        HelpImageProtocol.colorButtonImage = image
    }

    func updateToolbarConstraints(toolbarVisible toolbarVisible: Bool) {
        if toolbarVisible {
            toolbarTopConstraint.active = false
            toolbarBottomConstraint.active = true
        } else {
            toolbarBottomConstraint.active = false
            toolbarTopConstraint.active = true
        }
    }

    func configurePopover(viewController viewController: UIViewController, sourceView: UIView) {
        guard let popoverController = viewController.popoverPresentationController else { return }
        popoverController.sourceView = sourceView
        popoverController.sourceRect = sourceView.bounds
        popoverController.permittedArrowDirections = .Down
        popoverController.passthroughViews = self.passthroughViews
    }
}
