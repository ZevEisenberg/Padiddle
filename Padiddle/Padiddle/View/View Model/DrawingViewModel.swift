//
//  DrawingViewModel.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/7/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit
import CoreMotion

private let debugging = false

let kMotionManagerUpdateInterval: NSTimeInterval = 1.0 / 120.0
let kNibUpdateInterval: NSTimeInterval = 1.0 / 60.0

protocol DrawingViewModelDelegate: class {
    func start()
    func pause()
    func drawingViewModelUpdatedLocation(newLocation: CGPoint)
}

protocol DrawingViewBoundsVendor: class {
    var bounds: CGRect { get }
}

class DrawingViewModel: NSObject { // must inherit from NSObject for NSTimer to work
    var isUpdating = false
    var needToMoveNibToNewStartLocation = true
    private var smoothing = true

    private let brushDiameter: CGFloat = 12

    weak var delegate: DrawingViewModelDelegate?
    weak var view: DrawingViewBoundsVendor?

    private var colorManager: ColorManager?

    private let motionManager = CMMotionManager()

    private let maxRadius: CGFloat

    private var updateTimer: NSTimer?

    private var offscreenContext: CGContextRef?

    private let contextSize: CGSize

    lazy private var contextScale: CGFloat = {
        // don't go more extreme than necessary on an @3x device
        return min(UIScreen.mainScreen().scale, 2.0)
    }()

    private(set) var currentDirtyRect = CGRect.null

    func nullifyDirtyRect() {
        currentDirtyRect = .null
    }

    private var points = Array(count: 4, repeatedValue: CGPoint.zero)

    private let screenScale = UIScreen.mainScreen().scale

    lazy private var contextScaleFactor: CGFloat = {
        // The context image is scaled as Aspect Fill, so the larger dimension
        // of the bounds is the limiting factor
        let maxDimension = max(self.contextSize.width, self.contextSize.height)
        assert(maxDimension > 0)

        // Given context side length L and bounds max dimension l,
        // We are looking for a factor, ƒ, such that L * ƒ = l
        // So we divide both sides by L to get ƒ = l / L
        let ƒ = maxDimension / self.contextSize.width
        return ƒ
    }()

    private var currentColor: UIColor {
        guard let colorManager = colorManager else {
            return UIColor.magentaColor()
        }

        return colorManager.currentColor
    }

    required init(maxRadius: CGFloat) {
        assert(maxRadius > 0)
        self.maxRadius = maxRadius
        let minContextSize: CGFloat = 1024.0
        let sideLength = max(minContextSize, maxRadius)
        contextSize = CGSize(
            width: sideLength,
            height: sideLength
        )
        motionManager.deviceMotionUpdateInterval = kMotionManagerUpdateInterval
    }

    func configure() {
        let success = configureOffscreenContext()
        assert(success, "Problem creating bitmap context")
    }

    func addPoint(point: CGPoint) {
        let scaledPoint = convertViewPointToContextCoordinates(point)
        let distance = CGPoint.distanceBetween(scaledPoint, points[3])
        if distance > 2.25 || !smoothing {
            points.removeFirst()
            points.append(scaledPoint)

            addLineSegmentBasedOnUpdatedPoints()
        }
    }

    // MARK: Drawing

    func clear() {
        CGContextSetFillColorWithColor(offscreenContext, UIColor.whiteColor().CGColor)
        CGContextFillRect(offscreenContext, CGRect(origin: CGPoint.zero, size: contextSize))
    }

    func restartAtPoint(point: CGPoint) {
        let convertedPoint = convertViewPointToContextCoordinates(point)
        points = Array(count: points.count, repeatedValue: convertedPoint)
        addLineSegmentBasedOnUpdatedPoints()
    }

    func drawInto(context: CGContextRef, dirtyRect: CGRect) {
        guard let view = view else { fatalError() }
        let offscreenImage = CGBitmapContextCreateImage(offscreenContext)
        let offset = CGSize(
            width: contextSize.width * contextScaleFactor - CGRectGetWidth(view.bounds),
            height: contextSize.height * contextScaleFactor - CGRectGetHeight(view.bounds)
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
            CGContextStrokeRect(context, dirtyRect)
        }
    }

    func setInitialImage(image: UIImage) {
        let rect = CGRect(origin: CGPoint.zero, size: contextSize)
        CGContextDrawImage(offscreenContext, rect, image.CGImage!)
    }

    func addPathSegment(pathSegment: CGPathRef, color: UIColor) {
        CGContextAddPath(offscreenContext, pathSegment)
        CGContextSetStrokeColorWithColor(offscreenContext, color.CGColor)
        CGContextStrokePath(offscreenContext)
    }

    private func addLineSegmentBasedOnUpdatedPoints() {
        let pathSegment = CGPathRef.smoothedPathSegment(points: points)

        // draw the segment into the context

        addPathSegment(pathSegment, color: currentColor)

        let pathBoundingRect = CGPathGetPathBoundingBox(pathSegment)

        let insetPathBoundingRect = CGRectInset(pathBoundingRect, -brushDiameter, -brushDiameter)
        currentDirtyRect = CGRectUnion(currentDirtyRect, insetPathBoundingRect)
    }

    // Saving & Loading

    func snapshot(orientation orientation: UIInterfaceOrientation) -> UIImage {
        let (imageOrientation, rotation) = orientation.imageRotation

        let cacheCGImage = CGBitmapContextCreateImage(offscreenContext)!
        let unrotatedImage = UIImage(CGImage: cacheCGImage, scale: UIScreen.mainScreen().scale, orientation: imageOrientation)
        let rotatedImage = unrotatedImage.imageRotatedByRadians(rotation)
        return rotatedImage
    }

    func getSnapshotImage(interfaceOrientation interfaceOrientation: UIInterfaceOrientation, completion: UIImage -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

            let image = self.snapshot(orientation: interfaceOrientation)

            dispatch_async(dispatch_get_main_queue()) {
                completion(image)
            }
        }
    }

    func persistImageInBackground() {
        let image = self.snapshot(orientation: .Portrait)
        ImageIO.persistImageInBackground(image, contextScale: contextScale, contextSize: contextSize)
    }

    func loadPersistedImage() {
        ImageIO.loadPersistedImage(contextScale: contextScale, contextSize: contextSize) { image in
            if let image = image {
                self.setInitialImage(image)
            }
        }
    }
}

extension DrawingViewModel: RecordingDelegate {
    @objc func recordingStatusChanged(recording: Bool) {
        if recording {
            delegate?.start()
        } else {
            delegate?.pause()
        }
    }

    @objc func motionUpdatesStatusChanged(updates: Bool) {
        if updates {
            startMotionUpdates()
        } else {
            stopMotionUpdates()
        }
    }
}

extension DrawingViewModel: RootColorManagerDelegate {
    func colorManagerPicked(colorManager: ColorManager) {
        var newManager = colorManager
        newManager.maxRadius = maxRadius
        self.colorManager = newManager
    }
}

extension DrawingViewModel { // Coordinate conversions

    private func convertViewPointToContextCoordinates(point: CGPoint) -> CGPoint {

        guard let view = view else { fatalError() }

        var newPoint = point

        // 1. Multiply the point by the reciprocal of the context scale factor
        newPoint.x *= (1 / contextScaleFactor)
        newPoint.y *= (1 / contextScaleFactor)

        // 2. Get the size of self in context coordinates
        let viewSize = CGSize(width: CGRectGetWidth(view.bounds), height: CGRectGetHeight(view.bounds))
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

    func convertContextRectToViewCoordinates(rect: CGRect) -> CGRect {

        guard !CGRectEqualToRect(rect, CGRect.null) else { return CGRect.null }
        guard let view = view else { fatalError() }

        // 1. Get the size of the context in self coordinates
        let scaledContextSize = CGSize(
            width: contextSize.width * contextScaleFactor,
            height: contextSize.height * contextScaleFactor
        )

        // 2. Get the difference in size between self and the context
        let boundsSize = CGSize(
            width: CGRectGetWidth(view.bounds),
            height: CGRectGetHeight(view.bounds)
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
}

private extension DrawingViewModel { // Context configuration
    func configureOffscreenContext() -> Bool {
        let bitmapBytesPerRow: Int

        // Declare the number of bytes per row. Each pixel in the bitmap in this
        // example is represented by 4 bytes: 8 bits each of red, green, blue, and
        // alpha.

        bitmapBytesPerRow = Int(contextSize.width) * bytesPerPixel * Int(screenScale)

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let context = CGBitmapContextCreate(nil,
            Int(contextSize.width * screenScale),
            Int(contextSize.height * screenScale),
            bitsPerComponent,
            bitmapBytesPerRow,
            colorSpace,
            CGImageAlphaInfo.NoneSkipFirst.rawValue)

        if context == nil {
            assertionFailure("Problem creating context")
            return false
        }

        offscreenContext = context

        // http://stackoverflow.com/questions/10867767/how-to-create-a-cgbitmapcontext-which-works-for-retina-display-and-not-wasting-s
        CGContextScaleCTM(offscreenContext, screenScale, screenScale)

        CGContextSetLineCap(offscreenContext, .Round)
        CGContextSetLineWidth(offscreenContext, brushDiameter)

        clear()

        return true
    }
}

extension DrawingViewModel { // Core Motion
    func startMotionUpdates() {
        if motionManager.gyroAvailable {
            if motionManager.magnetometerAvailable {
                motionManager.startDeviceMotionUpdatesUsingReferenceFrame(.XArbitraryCorrectedZVertical)
            } else {
                motionManager.startDeviceMotionUpdatesUsingReferenceFrame(.XArbitraryZVertical)
            }

            if updateTimer == nil {
                updateTimer = NSTimer.scheduledTimerWithTimeInterval(kNibUpdateInterval, target: self, selector: #selector(DrawingViewModel.timerFired), userInfo: nil, repeats: true)
            }
        }
    }

    func stopMotionUpdates() {
        updateTimer?.invalidate()
        motionManager.stopDeviceMotionUpdates()
    }

    func timerFired() {
        if let deviceMotion = motionManager.deviceMotion {

            let zRotation = deviceMotion.rotationRate.z
            let radius = maxRadius / UIDevice.gyroMaxValue * CGFloat(fabs(zRotation))
            let theta = deviceMotion.attitude.yaw

            let x = radius * CGFloat(cos(theta)) + maxRadius / 2.0
            let y = radius * CGFloat(sin(theta)) + maxRadius / 2.0

            colorManager?.radius = radius
            colorManager?.theta = CGFloat(theta)

            delegate?.drawingViewModelUpdatedLocation(CGPoint(x: x, y: y))
        }
    }
}
