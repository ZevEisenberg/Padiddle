//
//  ToolbarViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/12/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Anchorage

class ToolbarViewController: UIViewController {

    fileprivate let toolbarAnimationDuration = 0.3

    var viewModel: ToolbarViewModel?

    fileprivate var tutorialCoordinator: TutorialCoordinator!

    fileprivate var toolbarVisible: Bool = true

    fileprivate let recordButtonBack = UIImageView(axId: "recordButtonBack")
    fileprivate let toolbarStackView = UIStackView(axId: "toolbarStackView")
    fileprivate let clearButton = UIButton(type: .custom, axId: "clearButton")
    fileprivate let colorButton = UIButton(type: .custom, axId: "colorButton")
    fileprivate let recordButtonPlaceholder = UIView(axId: "recordButtonPlaceholder")
    fileprivate let recordButton = UIButton(type: .custom, axId: "recordButton")
    fileprivate let shareButton = UIButton(type: .custom, axId: "shareButton")
    fileprivate let helpButton = UIButton(type: .custom, axId: "helpButton")

    fileprivate var toolbarBottomConstraint: NSLayoutConstraint!
    fileprivate var toolbarTopConstraint: NSLayoutConstraint!

    fileprivate var passthroughViews: [UIView] {
        return [toolbarStackView, recordButton]
    }

    fileprivate let recordPromptLabel = { (label: UILabel) -> UILabel in
        label.text = "Start by tapping the Record button"
        return label
    }(UILabel())

    fileprivate let spinPromptLabel = { (label: UILabel) -> UILabel in
        label.text = "Spin me right round!"
        return label
    }(UILabel())

    init(spinManager: SpinManager) {
        super.init(nibName: nil, bundle: nil)

        tutorialCoordinator = TutorialCoordinator(delegate: self, spinManager: spinManager)
    }

    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable) required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("\(#function) has not been implemented")
    }

}

// MARK: - Layout

extension ToolbarViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "toolbar view controller view"

        configureViews()

        updateColorButton((viewModel?.colorPickerViewModel?.selectedColorManager)!)

        tutorialCoordinator.start()
    }

    private func configureViews() {

        let toolbarView = UIView(axId: "toolbarView")
        let toolbarHairline = UIView(axId: "toolbarHairline")
        let spacerViews: [UIView] = {
            var spacers = [UIView]()
            for i in 0..<6 {
                spacers.append(UIView(axId: "spacer\(i)"))
            }
            return spacers
        }()

        // Record Button Back View
        recordButtonBack.image = #imageLiteral(resourceName: "RecordButtonBack")
        view.addSubview(recordButtonBack)

        // Toolbar
        toolbarView.backgroundColor = .toolbar
        view.addSubview(toolbarView)
        toolbarView.heightAnchor == 44

        toolbarView.horizontalAnchors == view.horizontalAnchors ~ .high

        toolbarTopConstraint = (toolbarView.topAnchor == bottomLayoutGuide.topAnchor)
        toolbarTopConstraint.isActive = false // so it doesn't conflict with toolbarBottomConstraint

        toolbarBottomConstraint = (toolbarView.bottomAnchor == bottomLayoutGuide.topAnchor)

        toolbarHairline.backgroundColor = .toolbarHairline
        toolbarView.addSubview(toolbarHairline)

        toolbarHairline.heightAnchor == 1
        toolbarHairline.topAnchor == toolbarView.topAnchor
        toolbarHairline.horizontalAnchors == toolbarView.horizontalAnchors

        // Stack View
        view.addSubview(toolbarStackView)
        toolbarStackView.axis = .horizontal
        toolbarStackView.alignment = .fill
        toolbarStackView.distribution = .fill
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

        let stackSubViews = spacerViews.interleave(with: buttons)

        stackSubViews.forEach {
            toolbarStackView.addArrangedSubview($0)
        }

        recordButtonBack.widthAnchor == recordButtonPlaceholder.widthAnchor
        recordButtonBack.centerXAnchor == recordButtonPlaceholder.centerXAnchor
        if let recordButtonPlaceholderSuperview = recordButtonPlaceholder.superview {
            recordButtonPlaceholder.heightAnchor == recordButtonPlaceholderSuperview.heightAnchor
        }

        clearButton.setImage(#imageLiteral(resourceName: "TrashButton"), for: .normal)
        clearButton.addTarget(self, action: #selector(ToolbarViewController.trashTapped), for: .touchUpInside)

        // image is dynamic
        colorButton.addTarget(self, action: #selector(ToolbarViewController.colorTapped), for: .touchUpInside)

        recordButtonBack.image = #imageLiteral(resourceName: "RecordButtonBack")

        recordButton.setImage(#imageLiteral(resourceName: "RecordButtonFront"), for: .normal)
        recordButton.setImage(#imageLiteral(resourceName: "PauseButton"), for: .selected)
        recordButton.addTarget(self, action: #selector(ToolbarViewController.recordTapped), for: .touchUpInside)

        shareButton.setImage(#imageLiteral(resourceName: "ShareButton"), for: .normal)
        shareButton.addTarget(self, action: #selector(ToolbarViewController.shareTapped), for: .touchUpInside)

        helpButton.setImage(#imageLiteral(resourceName: "HelpButton"), for: .normal)
        helpButton.addTarget(self, action: #selector(ToolbarViewController.helpTapped), for: .touchUpInside)

        let nonRecordButtons: [UIButton] = [
            clearButton,
            colorButton,
            shareButton,
            helpButton,
        ]

        // make buttons equal width to each other
        for (left, right) in zip(nonRecordButtons, nonRecordButtons.dropFirst()) {
            left.widthAnchor == right.widthAnchor
        }

        // Make first and last spacer views’ widths equal to each other
        guard let first = spacerViews.first, let last = spacerViews.last else { fatalError() }
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

        // Placeholder
        view.addSubview(recordPromptLabel)
        view.addSubview(spinPromptLabel)

        recordPromptLabel.centerAnchors == view.centerAnchors
        spinPromptLabel.centerAnchors == view.centerAnchors

        recordPromptLabel.isHidden = true
        spinPromptLabel.isHidden = true
    }

}

// MARK: - Button Handlers

extension ToolbarViewController {

    func trashTapped() {
        Log.info()
        let clearAction = UIAlertAction(title: L10n.clearDrawing.string, style: .destructive) { _ in
            Log.info("Clear Drawing tapped")
            self.viewModel?.clearTapped()
        }
        let cancelAction = UIAlertAction(title: L10n.cancel.string, style: .cancel) { _ in Log.info("Clear Drawing canceled") }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(clearAction)
        alert.addAction(cancelAction)
        alert.modalPresentationStyle = .popover

        present(alert, animated: true, completion: nil)
        configurePopover(viewController: alert, sourceView: clearButton)
    }

    func colorTapped() {
        Log.info()
        let viewControllerToShow: UIViewController

        let colorPickerViewController = ColorPickerViewController(viewModel: (viewModel?.colorPickerViewModel)!, delegate: self)

        if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            viewControllerToShow = colorPickerViewController
            viewControllerToShow.modalPresentationStyle = .popover
        }
        else {
            let navigationController = UINavigationController(rootViewController: colorPickerViewController)
            setUpNavigationItem(colorPickerViewController.navigationItem, cancelSelector: #selector(ToolbarViewController.dismissModal), doneSelector: nil)
            viewControllerToShow = navigationController
            viewControllerToShow.modalPresentationStyle = .formSheet
        }

        present(viewControllerToShow, animated: true, completion: nil)
        configurePopover(viewController: viewControllerToShow, sourceView: colorButton)
    }

    func recordTapped() {
        Log.info("new recording status: \(!recordButton.isSelected)")
        recordButton.isSelected = !recordButton.isSelected

        viewModel?.recordButtonTapped()
        tutorialCoordinator.recordButtonTapped()
    }

    func shareTapped() {
        Log.info()

        guard let viewModel = viewModel else { fatalError() }

        // Prevent the user from doing stuff while we are generating the snapshot

        toolbarStackView.isUserInteractionEnabled = false
        recordButton.isUserInteractionEnabled = false

        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.color = .appTint
        activityIndicator.startAnimating()

        shareButton.alpha = 0
        toolbarStackView.addSubview(activityIndicator) // not insertArrangedSubview!
        activityIndicator.centerXAnchor == shareButton.centerXAnchor
        activityIndicator.centerYAnchor == shareButton.centerYAnchor

        // Dismiss any other modals that may be visible
        dismiss(animated: true, completion: nil)

        // We are going to run this whether or not we get an image back
        let restoreShareButton: (UIViewController) -> Void = { presentedViewController in
            self.shareButton.alpha = 1
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()

            self.toolbarStackView.isUserInteractionEnabled = true
            self.recordButton.isUserInteractionEnabled = true

            guard let popoverController = presentedViewController.popoverPresentationController else { return }
            popoverController.sourceView = self.shareButton
            popoverController.sourceRect = self.shareButton.bounds
        }

        // Get the snapshot image async
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        viewModel.getSnapshotImage(interfaceOrientation) { image in

            assert(Thread.isMainThread)

            let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            activityViewController.excludedActivityTypes = [.assignToContact]
            activityViewController.modalPresentationStyle = .popover
            activityViewController.completionWithItemsHandler = { (activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, activityError: Error?) in
                if completed {
                    if let activityType = activityType {
                        Log.info("shared via \(activityType)")
                    }
                    else {
                        Log.info("shared via unknown sharing type")
                    }
                }
                else {
                    Log.info("Canceled sharing")
                }
            }

            self.present(activityViewController, animated: true, completion: {
                restoreShareButton(activityViewController)
            })
            self.configurePopover(viewController: activityViewController, sourceView: activityIndicator)
        }
    }

    func helpTapped() {
        Log.info()
        let helpViewController = HelpViewController()
        helpViewController.modalPresentationStyle = .popover

        let viewControllerToShow: UIViewController

        if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            viewControllerToShow = helpViewController
            viewControllerToShow.modalPresentationStyle = .popover
        }
        else {
            let navigationController = UINavigationController(rootViewController: helpViewController)
            setUpNavigationItem(helpViewController.navigationItem, cancelSelector: nil, doneSelector: #selector(ToolbarViewController.dismissModal))
            viewControllerToShow = navigationController
            viewControllerToShow.modalPresentationStyle = .formSheet
        }

        self.present(viewControllerToShow, animated: true, completion: nil)
        configurePopover(viewController: viewControllerToShow, sourceView: helpButton)
    }

}

// MARK: - ColorPickerDelegate

extension ToolbarViewController: ColorPickerDelegate {

    func colorPicked(_ color: ColorManager) {
        updateColorButton(color)

        if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            self.popColor()
            dismiss(animated: true, completion: nil)
        }
        else {
            dismiss(animated: true, completion: {
                self.popColor()
            })
        }
        Log.info("picked color: \(color)")
    }

}

// MARK: - ToolbarViewModelToolbarDelegate

extension ToolbarViewController: ToolbarViewModelToolbarDelegate {

    func setToolbarVisible(_ visible: Bool, animated: Bool) {
        if toolbarVisible != visible {
            toolbarVisible = visible
            updateToolbarConstraints(visible)

            let duration = animated ? toolbarAnimationDuration : 0.0
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        }
    }

}

extension ToolbarViewController: TutorialCoordinatorDelegate {

    func showRecordPrompt() {
        recordPromptLabel.isHidden = false
    }

    func hideRecordPrompt() {
        recordPromptLabel.isHidden = true
    }

    func showSpinPrompt() {
        spinPromptLabel.isHidden = false
    }

    func hideSpinPrompt() {
        spinPromptLabel.isHidden = true
    }

}

private extension ToolbarViewController {

    @objc func dismissModal() {
        Log.info()
        dismiss(animated: true, completion: nil)
    }

    func popColor() {
        let pushDuration: TimeInterval = 0.15
        let popDuration: TimeInterval = 0.7
        let damping: CGFloat = 0.3
        let scale: CGFloat = 1.2
        let initialSpringVelocity: CGFloat = 10.0

        UIView.animate(
            withDuration: pushDuration,
            delay: 0.0,
            options: [.allowUserInteraction, .curveEaseOut],
            animations: {
                self.colorButton.transform = self.colorButton.transform.scaledBy(x: scale, y: scale)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: popDuration,
                    delay: 0.0,
                    usingSpringWithDamping: damping,
                    initialSpringVelocity: initialSpringVelocity,
                    options: .allowUserInteraction,
                    animations: {
                        self.colorButton.transform = .identity
                    },
                    completion: nil
                )
            }
        )
    }

    func setUpNavigationItem(_ navigationItem: UINavigationItem, cancelSelector: Selector?, doneSelector: Selector?) {

        if let cancelSelector = cancelSelector {
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: cancelSelector)
            cancelButton.accessibilityIdentifier = "cancelButton"
            navigationItem.leftBarButtonItem = cancelButton
        }

        if let doneSelector = doneSelector {
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: doneSelector)
            doneButton.accessibilityIdentifier = "doneButton"
            navigationItem.rightBarButtonItem = doneButton
        }
    }

    func updateColorButton(_ colorManager: ColorManager) {
        let imageSize = 36
        let model = SpiralModel(
            colorManager: colorManager,
            size: CGSize(width: imageSize, height: imageSize),
            startRadius: 0,
            spacePerLoop: 0.7,
            thetaRange: 0...(2.0 * .pi * 4.0),
            thetaStep: .pi / 16.0,
            lineWidth: 2.3)

        let image = SpiralImageMaker.image(spiralModel: model)

        colorButton.setImage(image, for: .normal)
        HelpImageProtocol.colorButtonImage = image
    }

    func updateToolbarConstraints(_ toolbarVisible: Bool) {
        if toolbarVisible {
            toolbarTopConstraint.isActive = false
            toolbarBottomConstraint.isActive = true
        }
        else {
            toolbarBottomConstraint.isActive = false
            toolbarTopConstraint.isActive = true
        }
    }

    func configurePopover(viewController: UIViewController, sourceView: UIView) {
        guard let popoverController = viewController.popoverPresentationController else { return }
        popoverController.sourceView = sourceView
        popoverController.sourceRect = sourceView.bounds
        popoverController.permittedArrowDirections = .down
        popoverController.passthroughViews = self.passthroughViews
    }

}
