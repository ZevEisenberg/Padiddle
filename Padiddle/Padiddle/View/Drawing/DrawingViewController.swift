//
//  DrawingViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/12/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

let showDebugLabel = false

extension CGPoint {
    var screenPixelsIntegral: CGPoint {
        let screenScale = UIScreen.mainScreen().scale
        var newX = x
        var newY = y

        // integralize to screen pixels
        newX *= screenScale
        newY *= screenScale

        newX = round(newX)
        newY = round(newY)

        newX /= screenScale
        newY /= screenScale

        return CGPoint(x: newX, y: newY)
    }
}

class DrawingViewController: CounterRotatingViewController, DrawingViewModelDelegate {

    var viewModel: DrawingViewModel?
    private let drawingView = DrawingView()
    private let nib = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel?.delegate = self

        view.backgroundColor = .whiteColor()

        counterRotatingView.addSubview(drawingView)
        drawingView.translatesAutoresizingMaskIntoConstraints = false

        drawingView.widthAnchor.constraintEqualToConstant(UIScreen.mainScreen().longestSide).active = true
        drawingView.heightAnchor.constraintEqualToConstant(UIScreen.mainScreen().longestSide).active = true
        drawingView.centerXAnchor.constraintEqualToAnchor(counterRotatingView.centerXAnchor).active = true
        drawingView.centerYAnchor.constraintEqualToAnchor(counterRotatingView.centerYAnchor).active = true

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
            label.translatesAutoresizingMaskIntoConstraints = false
            counterRotatingView.addSubview(label)

            label.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
            label.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        viewModel?.startMotionUpdates()
    }

    // MARK: DrawingViewModelDelegate

    func start() {
        viewModel?.isUpdating = true
        drawingView.startDrawing()
        viewModel?.startMotionUpdates()
    }

    func pause() {
        viewModel?.isUpdating = false
        viewModel?.needToMoveNibToNewStartLocation = true
        drawingView.stopDrawing()
        // TODO: persist image in background
    }

    func drawingViewModelUpdatedLocation(newLocation: CGPoint) {
        nib.center = newLocation.screenPixelsIntegral

        if let extantViewModel = viewModel {
            if extantViewModel.isUpdating {
                if extantViewModel.needToMoveNibToNewStartLocation {
                    extantViewModel.needToMoveNibToNewStartLocation = false
                    drawingView.restartAtPoint(newLocation)
                }
                else {
                    drawingView.addPoint(newLocation)
                }
            }
        }
    }
}
