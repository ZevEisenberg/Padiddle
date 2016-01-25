//
//  ImageIO.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 1/24/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import UIKit.UIImage

struct ImageIO {

    static func persistImageInBackground(image: UIImage, contextScale: CGFloat, contextSize: CGSize, completion: () -> Void) {
        #if !SCREENSHOTS // no-op in screenshot mode
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
                    completion()
                }

                guard let imageData = UIImagePNGRepresentation(image) else {
                    print("Error - could not generate PNG to save image")
                    return
                }

                let imageURL = urlForPersistedImage(contextScale, contextSize: contextSize)

                let success = imageData.writeToURL(imageURL, atomically: true)

                if !success {
                    print("Error writing file")
                }
            }
        #endif
    }

    static func loadPersistedImage(contextScale: CGFloat, contextSize: CGSize, completion: UIImage? -> Void) {
        let imageURL = urlForPersistedImage(contextScale, contextSize: contextSize)

        if let imageData = NSData(contentsOfURL: imageURL) {

            let image = loadPersistedImageData(imageData, contextScale: contextScale)
            completion(image)
        }
    }

    // MARK: Private

    private static let persistedImageExtension = "png"

    #if SCREENSHOTS
    private static let persistedImageName = "ScreenshotPersistedImage"
    #else
    private static let persistedImageName = "PadiddlePersistedImage"
    #endif

    private static var backgroundSaveTask: UIBackgroundTaskIdentifier?

    private static func rotationForInterfaceOrientation(interfaceOrientation: UIInterfaceOrientation) -> (orientation: UIImageOrientation, rotation: CGFloat) {

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


    private static func urlForPersistedImage(contextScale: CGFloat, contextSize: CGSize) -> NSURL {
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

    private static func loadPersistedImageData(imageData: NSData, contextScale: CGFloat) -> UIImage? {
        guard let image = UIImage(data: imageData, scale: contextScale)?.imageFlippedVertically else {
            print("Error: couldn't create image from data on disk")
            return nil
        }

        return image
    }
}
