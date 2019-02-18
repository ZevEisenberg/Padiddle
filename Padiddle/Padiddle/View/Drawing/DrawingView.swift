//
//  DrawingView.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/7/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

class DrawingView: UIView, DrawingViewBoundsVendor {

    private var displayLink: CADisplayLink?

    private let viewModel: DrawingViewModel

    private let drawingLayer = CALayer()

    init(viewModel: DrawingViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        layer.addSublayer(drawingLayer)
        viewModel.view = self
        viewModel.imageUpdatedCallback = { [weak self] newImage in
            CATransaction.performWithoutAnimation {
                self?.drawingLayer.contents = newImage
            }
        }

        displayLink = CADisplayLink(target: self, selector: #selector(DrawingView.displayLinkUpdated))
        displayLink?.add(to: .main, forMode: .default)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    override func layoutSubviews() {
        drawingLayer.bounds = bounds
        drawingLayer.anchorPoint = .zero
        drawingLayer.position = .zero
        super.layoutSubviews()
    }

    func startDrawing() {
        displayLink?.isPaused = false
    }

    func stopDrawing() {
        displayLink?.isPaused = true
    }

    func clear() {
        viewModel.clear()
        setNeedsDisplay()
    }

    func addPoint(_ point: CGPoint) {
        viewModel.addPoint(point)
    }

    func restartAtPoint(_ point: CGPoint) {
        viewModel.restartAtPoint(point)
    }

}

private extension DrawingView {

    @objc func displayLinkUpdated() {
        viewModel.requestUpdatedImage()
    }

}
