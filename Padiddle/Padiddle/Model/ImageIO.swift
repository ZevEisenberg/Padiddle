//
//  ImageIO.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 1/24/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import UIKit.UIImage

enum ImageIO {

    static func persistImageInBackground(_ image: UIImage, contextScale: CGFloat, contextSize: CGSize) {
        if !Defaults.snapshotMode { // no-op in screenshot mode
            let app = UIApplication.shared

            backgroundSaveTask = app.beginBackgroundTask {
                if let task = self.backgroundSaveTask {
                    app.endBackgroundTask(task)
                    self.backgroundSaveTask = .invalid
                }
            }

            DispatchQueue.global(qos: .default).async {
                defer {
                    if let task = self.backgroundSaveTask {
                        app.endBackgroundTask(task)
                    }
                    self.backgroundSaveTask = .invalid
                }

                guard let imageData = image.pngData() else {
                    Log.error("Could not generate PNG to save image: \(image)")
                    return
                }

                let imageURL = urlForPersistedImage(contextScale, contextSize: contextSize)

                do {
                    try imageData.write(to: imageURL, options: [.atomic])
                }
                catch {
                    Log.error("Error writing to file: \(error)")
                }

                do {
                    try addSkipBackupAttributeToItem(atUrl: imageURL)
                }
                catch {
                    Log.error("Error adding do-not-back-up attribute to item at \(imageURL)")
                }
            }
        }
    }

    static func loadPersistedImage(contextScale: CGFloat, contextSize: CGSize, completion: (UIImage?) -> Void) {
        let imageURL = urlForPersistedImage(contextScale, contextSize: contextSize)

        if let imageData = try? Data(contentsOf: imageURL) {

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
        }
        else {
            return "PadiddlePersistedImage"
        }
    }()

    static var backgroundSaveTask: UIBackgroundTaskIdentifier?

    static func urlForPersistedImage(_ contextScale: CGFloat, contextSize: CGSize) -> URL {
        var scaledContextSize = contextSize
        scaledContextSize.width *= contextScale
        scaledContextSize.height *= contextScale

        let imageName = String(format: "%@-%.0f×%.0f", persistedImageName, scaledContextSize.width, scaledContextSize.height)

        guard !Defaults.snapshotMode else {
            return Bundle.main.url(forResource: imageName, withExtension: persistedImageExtension)!
        }

        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        let documentsURL = paths.first!

        let path = documentsURL.path
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            }
            catch {
                Log.error("Error creating direcotry at path \(path): \(error)")
            }
        }

        let fullURL = documentsURL.appendingPathComponent(imageName).appendingPathExtension(persistedImageExtension)

        return fullURL
    }

    static func loadPersistedImageData(_ imageData: Data, contextScale: CGFloat) -> UIImage? {
        guard let image = UIImage(data: imageData, scale: contextScale)?.imageFlippedVertically else {
            Log.error("Couldn't create image from data on disk")
            return nil
        }

        return image
    }

    static func addSkipBackupAttributeToItem(atUrl url: URL) throws {
        var url = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
    }

}
