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
    private var backgroundSaveTask: UIBackgroundTaskIdentifier?

    private var contextScale: CGFloat {
        // don't go more extreme than necessary on an @3x device
        return min(UIScreen.mainScreen().scale, 2.0)
    }

    #if SCREENSHOTS
    private let persistedImageName = "ScreenshotPersistedImage"
    #else
    private let persistedImageName = "PadiddlePersistedImage"
    #endif

    private let persistedImageExtension = "png"

    override func viewDidLoad() {
        super.viewDidLoad()

        drawingView.drawingViewDelegate = viewModel

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

        loadPersistedImage()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        viewModel?.startMotionUpdates()
    }

    func getSnapshotImage(interfaceOrientation: UIInterfaceOrientation, completion: ImageCallback) {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let image = self.drawingView.snapshotForInterfaceOrientation(interfaceOrientation)

            dispatch_async(dispatch_get_main_queue()) {
                completion(image)
            }
        }
    }

    func clearTapped() {
        drawingView.clear()
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
        persistImageInBackground()
    }

    func drawingViewModelUpdatedLocation(newLocation: CGPoint) {
        nib.center = newLocation.screenPixelsIntegral

        if let extantViewModel = viewModel {
            if extantViewModel.isUpdating {
                if extantViewModel.needToMoveNibToNewStartLocation {
                    extantViewModel.needToMoveNibToNewStartLocation = false
                    drawingView.restartAtPoint(newLocation)
                } else {
                    drawingView.addPoint(newLocation)
                }
            }
        }
    }

    // MARK: Private

    // TODO: move to view model
    private func persistImageInBackground() {
        #if !SCREENSHOTS // no-op in screenshot mode
            let snapshot = drawingView.snapshotForInterfaceOrientation(.Portrait)

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

    // TODO: Move to view model
    private func urlForPersistedImage() -> NSURL {
        var scaledContextSize = self.drawingView.contextSize
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

    private func loadPersistedImageData(imageData: NSData) {
        guard let image = UIImage(data: imageData, scale: contextScale)?.imageFlippedVertically else {
            print("Error: couldn't create image from data on disk")
            return
        }

        drawingView.setInitialImage(image)
    }

    func loadPersistedImage() {
        let imageURL = urlForPersistedImage()

        if let imageData = NSData(contentsOfURL: imageURL) {
            loadPersistedImageData(imageData)
        }
    }
}
