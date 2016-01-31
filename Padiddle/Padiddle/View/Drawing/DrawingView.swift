//
//  DrawingView.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/7/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

class DrawingView: UIView, DrawingViewBoundsVendor {
    private var needsErase = true
    private let screenScale = UIScreen.mainScreen().scale

    private var displayLink: CADisplayLink?

    private var viewModel: DrawingViewModel

    var isUpdating: Bool {
        get {
            return viewModel.isUpdating
        }
        set {
            viewModel.isUpdating = newValue
        }
    }

    var needToMoveNibToNewStartLocation: Bool {
        get {
            return viewModel.needToMoveNibToNewStartLocation
        }
        set {
            viewModel.needToMoveNibToNewStartLocation = newValue
        }
    }

    init(viewModel: DrawingViewModel) {

        self.viewModel = viewModel

        super.init(frame: CGRect.zero)

        viewModel.view = self

        displayLink = CADisplayLink(target: self, selector: "displayLinkUpdated")
        displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("\(__FUNCTION__) has not been implemented")
    }

    func startDrawing() {
        displayLink?.paused = false
    }

    func stopDrawing() {
        displayLink?.paused = true
    }

    func clear() {
        viewModel.clear()
        setNeedsDisplay()
    }

    func addPoint(point: CGPoint) {
        viewModel.addPoint(point)
    }

    func restartAtPoint(point: CGPoint) {
        viewModel.restartAtPoint(point)
    }

    override func drawRect(rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            viewModel.drawInto(context, dirtyRect: rect)
        }
    }

    func setInitialImage(image: UIImage) {
        viewModel.setInitialImage(image)
    }
}

private extension DrawingView {
    @objc func displayLinkUpdated() { // marked @objc so it can be looked up by selector
        setNeedsDisplayInRect(viewModel.convertContextRectToViewCoordinates(viewModel.currentDirtyRect))
    }
}
