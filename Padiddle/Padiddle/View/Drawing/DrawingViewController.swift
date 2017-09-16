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

    fileprivate let viewModel: DrawingViewModel
    fileprivate let drawingView: DrawingView
    fileprivate let nib = UIImageView()

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

        view.backgroundColor = .white
        view.accessibilityIdentifier = "drawing view controller view"

        counterRotatingView.addSubview(drawingView)

        view.sizeAnchors == CGSize(width: UIScreen.main.longestSide, height: UIScreen.main.longestSide)

        drawingView.widthAnchor == UIScreen.main.longestSide
        drawingView.heightAnchor == UIScreen.main.longestSide
        drawingView.centerAnchors == counterRotatingView.centerAnchors

        let nibDiameter = 12.0
        let borderWidth: CGFloat = (UIScreen.main.scale == 1.0) ? 1.5 : 1.0 // 1.5 looks best on non-Retina

        nib.image = UIImage.ellipseImage(
            color: .black,
            size: CGSize(width: nibDiameter, height: nibDiameter),
            borderWidth: borderWidth,
            borderColor: .white)
        nib.sizeToFit()

        drawingView.addSubview(nib)

        if showDebugLabel {
            let label = UILabel()
            label.text = "Drawing view debug label"
            counterRotatingView.addSubview(label)

            label.centerAnchors == view.centerAnchors
        }

        viewModel.loadPersistedImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.startMotionUpdates()
    }

    func getSnapshotImage(interfaceOrientation: UIInterfaceOrientation, completion: @escaping (UIImage) -> Void) {
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

    func drawingViewModelUpdatedLocation(_ newLocation: CGPoint) {
        let convertedLocation = viewModel.convertContextPointToViewCoordinates(newLocation)

        nib.center = convertedLocation.screenPixelsIntegral

        if viewModel.isUpdating {
            if viewModel.needToMoveNibToNewStartLocation {
                viewModel.needToMoveNibToNewStartLocation = false
                drawingView.restartAtPoint(convertedLocation)
            }
            else {
                drawingView.addPoint(convertedLocation)
            }
        }
    }

}
