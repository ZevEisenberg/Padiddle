//
//  DrawingViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/12/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Anchorage

let showDebugLabel = false

class DrawingViewController: CounterRotatingViewController {

    private let viewModel: DrawingViewModel
    private let drawingView: DrawingView
    private let nib = UIImageView()

    init(viewModel: DrawingViewModel) {
        self.viewModel = viewModel
        drawingView = DrawingView(viewModel: self.viewModel)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.delegate = self

        view.backgroundColor = .whiteColor()
        view.accessibilityIdentifier = "drawing view controller view"

        counterRotatingView.addSubview(drawingView)

        drawingView.widthAnchor == UIScreen.mainScreen().longestSide
        drawingView.heightAnchor == UIScreen.mainScreen().longestSide
        drawingView.centerXAnchor == counterRotatingView.centerXAnchor
        drawingView.centerYAnchor == counterRotatingView.centerYAnchor

        let nibDiameter = 12.0
        let borderWidth: CGFloat = (UIScreen.mainScreen().scale == 1.0) ? 1.5 : 1.0 // 1.5 looks best on non-Retina

        nib.image = UIImage.ellipseImageWithColor(
            color: .blackColor(),
            size: CGSize(width: nibDiameter, height: nibDiameter),
            borderWidth: borderWidth,
            borderColor: .whiteColor())
        nib.sizeToFit()

        drawingView.addSubview(nib)

        if showDebugLabel {
            let label = UILabel()
            label.text = "Drawing view debug label"
            counterRotatingView.addSubview(label)

            label.centerXAnchor == view.centerXAnchor
            label.centerYAnchor == view.centerYAnchor
        }

        viewModel.loadPersistedImage()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.startMotionUpdates()
    }

    func getSnapshotImage(interfaceOrientation interfaceOrientation: UIInterfaceOrientation, completion: UIImage -> Void) {
        viewModel.getSnapshotImage(interfaceOrientation: interfaceOrientation, completion: completion)
    }

    func clearTapped() {
        drawingView.clear()
    }
}

extension DrawingViewController: DrawingViewModelDelegate {
    func start() {
        viewModel.isUpdating = true
        drawingView.startDrawing()
        viewModel.startMotionUpdates()
    }

    func pause() {
        viewModel.isUpdating = false
        viewModel.needToMoveNibToNewStartLocation = true
        drawingView.stopDrawing()
        viewModel.persistImageInBackground()
    }

    func drawingViewModelUpdatedLocation(newLocation: CGPoint) {
        nib.center = newLocation.screenPixelsIntegral

        if viewModel.isUpdating {
            if viewModel.needToMoveNibToNewStartLocation {
                viewModel.needToMoveNibToNewStartLocation = false
                drawingView.restartAtPoint(newLocation)
            } else {
                drawingView.addPoint(newLocation)
            }
        }
    }
}
