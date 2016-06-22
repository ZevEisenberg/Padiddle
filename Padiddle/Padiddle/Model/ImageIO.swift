//
//  ImageIO.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 1/24/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import UIKit.UIImage

struct ImageIO {

    static func persistImageInBackground(image: UIImage, contextScale: CGFloat, contextSize: CGSize) {
        if !Defaults.snapshotMode { // no-op in screenshot mode
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

                guard let imageData = UIImagePNGRepresentation(image) else {
                    Log.error("Could not generate PNG to save image: \(image)")
                    return
                }

                let imageURL = urlForPersistedImage(contextScale, contextSize: contextSize)

                do {
                    try imageData.writeToURL(imageURL, options: [.DataWritingAtomic])
                } catch let error {
                    Log.error("Error writing to file: \(error)")
                }
            }
        }
    }

    static func loadPersistedImage(contextScale contextScale: CGFloat, contextSize: CGSize, completion: UIImage? -> Void) {
        let imageURL = urlForPersistedImage(contextScale, contextSize: contextSize)

        if let imageData = NSData(contentsOfURL: imageURL) {

            let image = loadPersistedImageData(imageData, contextScale: contextScale)
            completion(image)
        }
    }
}

private extension ImageIO {
    static let persistedImageExtension = "png"

    static let persistedImageName: String = {
        if Defaults.snapshotMode {
            return "ScreenshotPersistedImage"
        } else {
            return "PadiddlePersistedImage"
        }
    }()

    static var backgroundSaveTask: UIBackgroundTaskIdentifier?

    static func rotationForInterfaceOrientation(interfaceOrientation: UIInterfaceOrientation) -> (orientation: UIImageOrientation, rotation: CGFloat) {

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


    static func urlForPersistedImage(contextScale: CGFloat, contextSize: CGSize) -> NSURL {
        var scaledContextSize = contextSize
        scaledContextSize.width *= contextScale
        scaledContextSize.height *= contextScale

        let imageName = NSString(format: "%@-%.0f×%.0f", persistedImageName, scaledContextSize.width, scaledContextSize.height) as String

        guard !Defaults.snapshotMode else {
            return NSBundle.mainBundle().URLForResource(imageName, withExtension:persistedImageExtension)!
        }

        let paths = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)

        let documentsURL = paths.first!

        let path = documentsURL.path!
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
            } catch let error {
                Log.error("Error creating direcotry at path \(path): \(error)")
            }
        }

        let fullURL = documentsURL.URLByAppendingPathComponent(imageName).URLByAppendingPathExtension(persistedImageExtension)

        return fullURL
    }

    static func loadPersistedImageData(imageData: NSData, contextScale: CGFloat) -> UIImage? {
        guard let image = UIImage(data: imageData, scale: contextScale)?.imageFlippedVertically else {
            Log.error("Couldn't create image from data on disk")
            return nil
        }

        return image
    }
}
