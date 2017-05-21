//
//  DrawingViewModel.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/7/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

private let debugging = false

let kNibUpdateInterval: TimeInterval = 1.0 / 60.0

protocol DrawingViewModelDelegate: class {

    func start()
    func pause()
    func drawingViewModelUpdatedLocation(_ newLocation: CGPoint)

}

protocol DrawingViewBoundsVendor: class {

    var bounds: CGRect { get }

}

class DrawingViewModel: NSObject { // must inherit from NSObject for NSTimer to work

    var isUpdating = false
    var needToMoveNibToNewStartLocation = true

    fileprivate let brushDiameter: CGFloat = 12

    weak var delegate: DrawingViewModelDelegate?
    weak var view: DrawingViewBoundsVendor?

    fileprivate var colorManager: ColorManager?

    fileprivate let spinManager: SpinManager

    fileprivate let maxRadius: CGFloat

    fileprivate var updateTimer: Timer?

    fileprivate var offscreenContext: CGContext!

    fileprivate let contextSize = CGSize(width: 1024.0, height: 1024.0)

    lazy private var contextScale: CGFloat = {
        // don't go more extreme than necessary on an @3x device
        return min(UIScreen.main.scale, 2.0)
    }()

    private(set) var currentDirtyRect = CGRect.null

    func nullifyDirtyRect() {
        currentDirtyRect = .null
    }

    private var points = Array(repeating: CGPoint.zero, count: 4)

    fileprivate let screenScale = UIScreen.main.scale

    lazy fileprivate var contextScaleFactor: CGFloat = {
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
            return UIColor.magenta
        }

        return colorManager.currentColor
    }

    required init(maxRadius: CGFloat, spinManager: SpinManager) {
        assert(maxRadius > 0)
        self.maxRadius = maxRadius
        self.spinManager = spinManager
        super.init()
        let success = configureOffscreenContext()
        assert(success, "Problem creating bitmap context")

    }

    func addPoint(_ point: CGPoint) {
        let scaledPoint = convertViewPointToContextCoordinates(point)
        let distance = CGPoint.distanceBetween(points[3], scaledPoint)
        if distance > 2.25 {
            points.removeFirst()
            points.append(scaledPoint)

            addLineSegmentBasedOnUpdatedPoints()
        }
    }

    // MARK: Drawing

    func clear() {
        offscreenContext.setFillColor(UIColor.white.cgColor)
        offscreenContext.fill(CGRect(origin: .zero, size: contextSize))
    }

    func restartAtPoint(_ point: CGPoint) {
        let convertedPoint = convertViewPointToContextCoordinates(point)
        points = Array(repeating: convertedPoint, count: points.count)
        addLineSegmentBasedOnUpdatedPoints()
    }

    func drawInto(_ context: CGContext, dirtyRect: CGRect) {
        guard let view = view else { fatalError() }
        let offscreenImage = offscreenContext.makeImage()
        let offset = CGSize(
            width: contextSize.width * contextScaleFactor - view.bounds.width,
            height: contextSize.height * contextScaleFactor - view.bounds.height
        )
        let drawingRect = CGRect(
            x: -offset.width / 2.0,
            y: -offset.height / 2.0,
            width: contextSize.width * contextScaleFactor,
            height: contextSize.height * contextScaleFactor
        )
        context.draw(offscreenImage!, in: drawingRect)

        if debugging {
            context.setStrokeColor(UIColor.green.cgColor)
            context.setLineWidth(1)
            context.stroke(dirtyRect)
        }
    }

    func setInitialImage(_ image: UIImage) {
        let rect = CGRect(origin: .zero, size: contextSize)
        offscreenContext.draw(image.cgImage!, in: rect)
    }

    func addPathSegment(_ pathSegment: CGPath, color: UIColor) {
        offscreenContext.addPath(pathSegment)
        offscreenContext.setStrokeColor(color.cgColor)
        offscreenContext.strokePath()
    }

    private func addLineSegmentBasedOnUpdatedPoints() {
        let pathSegment = CGPath.smoothedPathSegment(points: points)

        // draw the segment into the context

        addPathSegment(pathSegment, color: currentColor)

        let pathBoundingRect = pathSegment.boundingBoxOfPath

        let insetPathBoundingRect = pathBoundingRect.insetBy(dx: -brushDiameter, dy: -brushDiameter)
        currentDirtyRect = currentDirtyRect.union(insetPathBoundingRect)
    }

    // Saving & Loading

    func snapshot(_ orientation: UIInterfaceOrientation) -> UIImage {
        let (imageOrientation, rotation) = orientation.imageRotation

        let cacheCGImage = offscreenContext.makeImage()!
        let unrotatedImage = UIImage(cgImage: cacheCGImage, scale: UIScreen.main.scale, orientation: imageOrientation)
        let rotatedImage = unrotatedImage.imageRotatedByRadians(rotation)
        return rotatedImage
    }

    func getSnapshotImage(interfaceOrientation: UIInterfaceOrientation, completion: @escaping (UIImage) -> Void) {
        DispatchQueue.global(qos: .default).async {
            let image = self.snapshot(interfaceOrientation)

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    func persistImageInBackground() {
        let image = self.snapshot(.portrait)
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

    @objc func recordingStatusChanged(_ recording: Bool) {
        if recording {
            delegate?.start()
        }
        else {
            delegate?.pause()
        }
    }

    @objc func motionUpdatesStatusChanged(_ updates: Bool) {
        if updates {
            startMotionUpdates()
        }
        else {
            stopMotionUpdates()
        }
    }

}

extension DrawingViewModel: RootColorManagerDelegate {

    func colorManagerPicked(_ colorManager: ColorManager) {
        var newManager = colorManager
        newManager.maxRadius = maxRadius
        self.colorManager = newManager
    }

}

extension DrawingViewModel { // Coordinate conversions

    fileprivate func convertViewPointToContextCoordinates(_ point: CGPoint) -> CGPoint {

        guard let view = view else { fatalError() }

        var newPoint = point

        // 1. Multiply the point by the reciprocal of the context scale factor
        newPoint.x *= (1 / contextScaleFactor)
        newPoint.y *= (1 / contextScaleFactor)

        // 2. Get the size of self in context coordinates
        let viewSize = view.bounds.size
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

    func convertContextRectToViewCoordinates(_ rect: CGRect) -> CGRect {

        guard !rect.equalTo(CGRect.null) else { return CGRect.null }
        guard let view = view else { fatalError() }

        // 1. Get the size of the context in self coordinates
        let scaledContextSize = CGSize(
            width: contextSize.width * contextScaleFactor,
            height: contextSize.height * contextScaleFactor
        )

        // 2. Get the difference in size between self and the context
        let boundsSize = view.bounds.size

        let difference = CGSize(
            width: scaledContextSize.width - boundsSize.width,
            height: scaledContextSize.height - boundsSize.height
        )

        // 3. Scale the rect by the context scale factor
        let scaledRect = rect.applying(CGAffineTransform(scaleX: contextScaleFactor, y: contextScaleFactor))

        // 4. Shift the rect by negative the half the difference in width and height
        let offsetRect = scaledRect.offsetBy(dx: -difference.width / 2.0, dy: -difference.height / 2.0)

        return offsetRect
    }

}

// MARK: Context configuration

private extension DrawingViewModel {

    func configureOffscreenContext() -> Bool {
        let bitmapBytesPerRow: Int

        // Declare the number of bytes per row. Each pixel in the bitmap in this
        // example is represented by 4 bytes: 8 bits each of red, green, blue, and
        // alpha.

        bitmapBytesPerRow = Int(contextSize.width) * bytesPerPixel * Int(screenScale)

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let context = CGContext(data: nil,
            width: Int(contextSize.width * screenScale),
            height: Int(contextSize.height * screenScale),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bitmapBytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        guard context != nil else {
            assertionFailure("Problem creating context")
            return false
        }

        offscreenContext = context

        // http://stackoverflow.com/questions/10867767/how-to-create-a-cgbitmapcontext-which-works-for-retina-display-and-not-wasting-s
        offscreenContext?.scaleBy(x: screenScale, y: screenScale)

        offscreenContext?.setLineCap(.round)
        offscreenContext?.setLineWidth(brushDiameter)

        clear()

        return true
    }
}

// MARK: Core Motion

extension DrawingViewModel {

    func startMotionUpdates() {
        spinManager.startMotionUpdates()
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(timeInterval: kNibUpdateInterval, target: self, selector: #selector(DrawingViewModel.timerFired), userInfo: nil, repeats: true)
        }
    }

    func stopMotionUpdates() {
        updateTimer?.invalidate()
        spinManager.stopMotionUpdates()
    }

    func timerFired() {
        if let deviceMotion = spinManager.deviceMotion {

            let zRotation = deviceMotion.rotationRate.z
            let radius = maxRadius / UIDevice.gyroMaxValue * CGFloat(fabs(zRotation))

            // Yaw is on the range [-π...π]. Remap to [0...π]
            let theta = deviceMotion.attitude.yaw + .pi

            let x = radius * CGFloat(cos(theta)) + maxRadius / 2.0
            let y = radius * CGFloat(sin(theta)) + maxRadius / 2.0

            colorManager?.radius = radius
            colorManager?.theta = CGFloat(theta)

            delegate?.drawingViewModelUpdatedLocation(CGPoint(x: x, y: y))
        }
    }

}
