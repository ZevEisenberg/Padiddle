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

class DrawingViewModel: NSObject, RecordingDelegate, RootColorManagerDelegate { // must inherit from NSObject for NSTimer to work
    var isUpdating = false
    var needToMoveNibToNewStartLocation = true
    private var smoothing = true

    private let persistedImageExtension = "png"

    private var backgroundSaveTask: UIBackgroundTaskIdentifier?

    #if SCREENSHOTS
    private let persistedImageName = "ScreenshotPersistedImage"
    #else
    private let persistedImageName = "PadiddlePersistedImage"
    #endif

    private let brushDiameter: CGFloat = 12

    private let bytesPerPixel: size_t = 4
    private let bitsPerComponent: size_t = 8

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

    func startMotionUpdates() {
        if motionManager.gyroAvailable {
            if motionManager.magnetometerAvailable {
                motionManager.startDeviceMotionUpdatesUsingReferenceFrame(.XArbitraryCorrectedZVertical)
            } else {
                motionManager.startDeviceMotionUpdatesUsingReferenceFrame(.XArbitraryZVertical)
            }

            if updateTimer == nil {
                updateTimer = NSTimer.scheduledTimerWithTimeInterval(kNibUpdateInterval, target: self, selector: "timerFired", userInfo: nil, repeats: true)
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

    func addPoint(point: CGPoint) {
        let scaledPoint = convertViewPointToContextCoordinates(point)
        let distance = Geometry.distanceBetween(scaledPoint, p2: points[3])
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

    func snapshotForInterfaceOrientation(interfaceOrientation: UIInterfaceOrientation) -> UIImage {
        let (imageOrientation, rotation) = DrawingViewModel.rotationForInterfaceOrientation(interfaceOrientation)

        let cacheImage = CGBitmapContextCreateImage(offscreenContext)!

        let originalImage = UIImage(CGImage: cacheImage, scale: screenScale, orientation: imageOrientation)

        let rotatedImage = originalImage.imageRotatedByRadians(rotation)

        return rotatedImage
    }

    func addPathSegment(pathSegment: CGPathRef, color: UIColor) {
        CGContextAddPath(offscreenContext, pathSegment)
        CGContextSetStrokeColorWithColor(offscreenContext, color.CGColor)
        CGContextStrokePath(offscreenContext)
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

        // draw the segment into the context

        addPathSegment(pathSegment, color: currentColor)

        let pathBoundingRect = CGPathGetPathBoundingBox(pathSegment)

        let insetPathBoundingRect = CGRectInset(pathBoundingRect, -brushDiameter, -brushDiameter)
        currentDirtyRect = CGRectUnion(currentDirtyRect, insetPathBoundingRect)
    }

    // Saving & Loading

    private func urlForPersistedImage() -> NSURL {
        var scaledContextSize = contextSize
        scaledContextSize.width *= contextScale
        scaledContextSize.height *= contextScale

        let imageName = NSString(format: "%@-%.0f×%.0f", persistedImageName, scaledContextSize.width, scaledContextSize.height) as String

        #if SCREENSHOTS
            let url = NSBundle.mainBundle().URLForResource(imageName, withExtension:persistedImageExtension)
            return url
        #endif

        let paths = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)

        let documentsURL = paths.first!

        let path = documentsURL.path!
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
            } catch let error {
                print("Error creating direcotry at path \(path): \(error)")
            }
        }

        let fullURL = documentsURL.URLByAppendingPathComponent(imageName).URLByAppendingPathExtension(persistedImageExtension)

        return fullURL
    }

    func persistImageInBackground() {
        #if !SCREENSHOTS // no-op in screenshot mode
            let snapshot = snapshotForInterfaceOrientation(.Portrait)

            let app = UIApplication.sharedApplication()


            backgroundSaveTask = app.beginBackgroundTaskWithExpirationHandler {
                if let task = self.backgroundSaveTask {
                    app.endBackgroundTask(task)
                    self.backgroundSaveTask = UIBackgroundTaskInvalid
                }
            }

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                defer {
                    if let task = self.backgroundSaveTask {
                        app.endBackgroundTask(task)
                    }
                    self.backgroundSaveTask = UIBackgroundTaskInvalid
                }

                guard let imageData = UIImagePNGRepresentation(snapshot) else {
                    print("Error - could not generate PNG to save image")
                    return
                }

                let imageURL = self.urlForPersistedImage()

                let success = imageData.writeToURL(imageURL, atomically: true)

                if !success {
                    print("Error writing file")
                }
            }
        #endif
    }

    private func loadPersistedImageData(imageData: NSData) {
        guard let image = UIImage(data: imageData, scale: contextScale)?.imageFlippedVertically else {
            print("Error: couldn't create image from data on disk")
            return
        }

        setInitialImage(image)
    }

    func loadPersistedImage() {
        let imageURL = urlForPersistedImage()

        if let imageData = NSData(contentsOfURL: imageURL) {
            loadPersistedImageData(imageData)
        }
    }

    // MARK: RecordingDelegate

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

    // MARK: RootColorManagerDelegate

    func colorManagerPicked(colorManager: ColorManager) {
        var newManager = colorManager
        newManager.maxRadius = maxRadius
        self.colorManager = newManager
    }

    // MARK: Private

    private class func rotationForInterfaceOrientation(interfaceOrientation: UIInterfaceOrientation) -> (orientation: UIImageOrientation, rotation: CGFloat) {

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
