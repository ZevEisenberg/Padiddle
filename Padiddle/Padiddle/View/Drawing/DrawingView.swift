//
//  DrawingView.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/7/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

private let debugging = false

typealias ImageCallback = UIImage? -> Void

protocol DrawingViewDelegate:
class {
    var currentColor: UIColor { get }
}

class DrawingView: UIView {

    weak var drawingViewDelegate: DrawingViewDelegate?

    private var needsErase = true
    private var smoothing = true
    private let screenScale = UIScreen.mainScreen().scale

    lazy private var contextScaleFactor: CGFloat = {
        // The context image is scaled as Aspect Fill, so the larger dimension
        // of the bounds is the limiting factor
        let maxDimension = max(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))
        assert(maxDimension > 0)

        // Given context side length L and bounds max dimension l,
        // We are looking for a factor, ƒ, such that L * ƒ = l
        // So we divide both sides by L to get ƒ = l / L
        let ƒ = maxDimension / self.contextSize.width
        return ƒ
    }()

    // TODO: make private when image persistence is in view model
    let contextSize = CGSize(width: 1024, height: 1024)

    private let brushDiameter: CGFloat = 12

    private let bytesPerPixel: size_t = 4
    private let bitsPerComponent: size_t = 8

    private var points = Array(count: 4, repeatedValue: CGPoint.zero)

    // TODO: move offscreen context into view model
    private var offscreenContext: CGContextRef?

    private var currentDirtyRect = CGRect.null

    private var displayLink: CADisplayLink?

    private var viewModel: DrawingViewModel

    init(viewModel: DrawingViewModel) {

        self.viewModel = viewModel

        super.init(frame: CGRect.zero)

        displayLink = CADisplayLink(target: self, selector: "displayLinkUpdated")
        displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)

        let success = configureOffscreenContext()
        assert(success, "Problem creating bitmap context")
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
        CGContextSetFillColorWithColor(offscreenContext, UIColor.whiteColor().CGColor)
        CGContextFillRect(offscreenContext, CGRect(origin: CGPoint.zero, size: contextSize))

        setNeedsDisplay()
    }

    func addPoint(point: CGPoint) {
        let scaledPoint = convertViewPointToContextCoordinates(point)
        let distance = Geometry.distanceBetween(scaledPoint, p2: points[3])
        if distance > 2.25 || !smoothing {
            points.removeFirst()
            points.append(scaledPoint)

            addLineSegmentBasedOnUpdatedPoints()
        }
    }

    func restartAtPoint(point: CGPoint) {
        let convertedPoint = convertViewPointToContextCoordinates(point)
        points = Array(count: points.count, repeatedValue: convertedPoint)
        addLineSegmentBasedOnUpdatedPoints()
    }

    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let offscreenImage = CGBitmapContextCreateImage(offscreenContext)
        let offset = CGSize(
            width: contextSize.width * contextScaleFactor - CGRectGetWidth(bounds),
            height: contextSize.height * contextScaleFactor - CGRectGetHeight(bounds)
        )
        let drawingRect = CGRect(
            x: -offset.width / 2.0,
            y: -offset.height / 2.0,
            width: contextSize.width * contextScaleFactor,
            height: contextSize.height * contextScaleFactor
        )
        CGContextDrawImage(context, drawingRect, offscreenImage)

        if debugging {
            CGContextSetStrokeColorWithColor(context, UIColor.greenColor().CGColor)
            CGContextSetLineWidth(context, 1)
            CGContextStrokeRect(context, rect)
        }
    }

    func setInitialImage(image: UIImage) {
        let rect = CGRect(origin: CGPoint.zero, size: contextSize)
        CGContextDrawImage(offscreenContext, rect, image.CGImage!)
    }

    func snapshotForInterfaceOrientation(interfaceOrientation: UIInterfaceOrientation) -> UIImage {
        let (imageOrientation, rotation) = rotationForInterfaceOrientation(interfaceOrientation)

        let cacheImage = CGBitmapContextCreateImage(offscreenContext)!

        let originalImage = UIImage(CGImage: cacheImage, scale: screenScale, orientation: imageOrientation)

        let rotatedImage = originalImage.imageRotatedByRadians(rotation)

        return rotatedImage
    }

    // MARK: Private

    @objc private func displayLinkUpdated() { // marked @objc so it can be looked up by selector
        setNeedsDisplayInRect(convertContextRectToViewCoordinates(currentDirtyRect))

        currentDirtyRect = CGRect.null
    }

    private func addLineSegmentBasedOnUpdatedPoints() {
        // point smoothing from http://www.effectiveui.com/blog/2011/12/02/how-to-build-a-simple-painting-app-for-ios/

        let x0 = (points[0].x > -1) ? points[0].x : points[1].x //after 4 touches we should have a back anchor point. If not, use the current anchor point
        let y0 = (points[0].y > -1) ? points[0].y : points[1].y //after 4 touches we should have a back anchor point. If not, use the current anchor point
        let x1 = points[1].x
        let y1 = points[1].y
        let x2 = points[2].x
        let y2 = points[2].y
        let x3 = points[3].x
        let y3 = points[3].y

        let xc1 = (x0 + x1) / 2.0
        let yc1 = (y0 + y1) / 2.0
        let xc2 = (x1 + x2) / 2.0
        let yc2 = (y1 + y2) / 2.0
        let xc3 = (x2 + x3) / 2.0
        let yc3 = (y2 + y3) / 2.0

        let len1 = sqrt(pow(x1 - x0, 2.0) + pow(y1 - y0, 2.0))
        let len2 = sqrt(pow(x2 - x1, 2.0) + pow(y2 - y1, 2.0))
        let len3 = sqrt(pow(x3 - x2, 2.0) + pow(y3 - y2, 2.0))

        let k1 = len1 / (len1 + len2)
        let k2 = len2 / (len2 + len3)

        let xm1 = xc1 + (xc2 - xc1) * k1
        let ym1 = yc1 + (yc2 - yc1) * k1
        let xm2 = xc2 + (xc3 - xc2) * k2
        let ym2 = yc2 + (yc3 - yc2) * k2

        let smoothValue = CGFloat(0.5)
        let ctrl1x = xm1 + (xc2 - xm1) * smoothValue + x1 - xm1
        let ctrl1y = ym1 + (yc2 - ym1) * smoothValue + y1 - ym1
        let ctrl2x = xm2 + (xc2 - xm2) * smoothValue + x2 - xm2
        let ctrl2y = ym2 + (yc2 - ym2) * smoothValue + y2 - ym2

        // Create path segment. We are making a mutable path segment,
        // rather than just adding the path to the context directly,
        // so we can also mark dirty the segment's bounding rect

        let pathSegment = CGPathCreateMutable()
        CGPathMoveToPoint(pathSegment, nil, points[1].x, points[1].y)
        CGPathAddCurveToPoint(pathSegment, nil, ctrl1x, ctrl1y, ctrl2x, ctrl2y, points[2].x, points[2].y)

        let color = (drawingViewDelegate?.currentColor)!

        // draw the segment into the context

        CGContextAddPath(offscreenContext, pathSegment)
        CGContextSetStrokeColorWithColor(offscreenContext, color.CGColor)
        CGContextStrokePath(offscreenContext)

        let pathBoundingRect = CGPathGetPathBoundingBox(pathSegment)

        let insetPathBoundingRect = CGRectInset(pathBoundingRect, -brushDiameter, -brushDiameter)
        currentDirtyRect = CGRectUnion(currentDirtyRect, insetPathBoundingRect)
    }

    private func convertViewPointToContextCoordinates(point: CGPoint) -> CGPoint {
        var newPoint = point

        // 1. Multiply the point by the reciprocal of the context scale factor
        newPoint.x *= (1 / contextScaleFactor)
        newPoint.y *= (1 / contextScaleFactor)

        // 2. Get the size of self in context coordinates
        let viewSize = CGSize(width: CGRectGetWidth(bounds), height: CGRectGetHeight(bounds))
        let scaledViewSize = CGSize(
            width: viewSize.width * (1 / contextScaleFactor),
            height: viewSize.height * (1 / contextScaleFactor)
        )

        // 3. Get the difference in size between self and the context
        let difference = CGSize(
            width: contextSize.width - scaledViewSize.width,
            height: contextSize.height - scaledViewSize.height
        )

        // 4. Shift the point by half the difference in width and height
        newPoint.x += difference.width / 2
        newPoint.y += difference.height / 2

        return newPoint
    }

    private func convertContextRectToViewCoordinates(rect: CGRect) -> CGRect {

        guard !CGRectEqualToRect(rect, CGRect.null) else { return CGRect.null }

        // 1. Get the size of the context in self coordinates
        let scaledContextSize = CGSize(
            width: contextSize.width * contextScaleFactor,
            height: contextSize.height * contextScaleFactor
        )

        // 2. Get the difference in size between self and the context
        let boundsSize = CGSize(
            width: CGRectGetWidth(bounds),
            height: CGRectGetHeight(bounds)
        )

        let difference = CGSize(
            width: scaledContextSize.width - boundsSize.width,
            height: scaledContextSize.height - boundsSize.height
        )

        // 3. Scale the rect by the context scale factor
        let scaledRect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(contextScaleFactor, contextScaleFactor))

        // 4. Shift the rect by negative the half the difference in width and height
        let offsetRect = CGRectOffset(scaledRect, -difference.width / 2.0, -difference.height / 2.0)

        return offsetRect
    }

    private func configureOffscreenContext() -> Bool {
        let bitmapBytesPerRow: Int

        // Declare the number of bytes per row. Each pixel in the bitmap in this
        // example is represented by 4 bytes: 8 bits each of red, green, blue, and
        // alpha.

        bitmapBytesPerRow = Int(contextSize.width) * bytesPerPixel * Int(screenScale)

        // Passing NULL as first param makes Quartz handle memory allocation.

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let context = CGBitmapContextCreate(nil,
            Int(contextSize.width * screenScale),
            Int(contextSize.height * screenScale),
            bitsPerComponent,
            bitmapBytesPerRow,
            colorSpace,
            CGImageAlphaInfo.NoneSkipFirst.rawValue)

        guard context != nil else { return false }

        assert(context != nil, "Problem creating context.")

        offscreenContext = context

        // http://stackoverflow.com/questions/10867767/how-to-create-a-cgbitmapcontext-which-works-for-retina-display-and-not-wasting-s
        CGContextScaleCTM(offscreenContext, screenScale, screenScale)

        CGContextSetLineCap(offscreenContext, .Round)
        CGContextSetLineWidth(offscreenContext, brushDiameter)

        clear()

        return true
    }

    private func rotationForInterfaceOrientation(interfaceOrientation: UIInterfaceOrientation) -> (orientation: UIImageOrientation, rotation: CGFloat) {

        let rotation: CGFloat
        let imageOrientaion: UIImageOrientation

        switch interfaceOrientation {
        case .LandscapeLeft:
            rotation = -π / 2.0
            imageOrientaion = .Right
        case .LandscapeRight:
            rotation = π / 2.0
            imageOrientaion = .Left
        case .PortraitUpsideDown:
            rotation = π
            imageOrientaion = .Down
        case .Portrait, .Unknown:
            rotation = 0
            imageOrientaion = .Up
        }

        return (imageOrientaion, rotation)
    }
}
