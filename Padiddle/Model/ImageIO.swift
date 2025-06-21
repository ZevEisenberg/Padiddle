import Synchronization
import UIKit.UIImage

enum ImageIO {
  #warning("TODO: probably don't need a background task for this")
  @MainActor
  static func persistImageInBackground(_ image: UIImage, contextScale: CGFloat, contextSize: CGSize) {
    guard !Defaults.snapshotMode else {
      // no-op in screenshot mode
      return
    }
    let app = UIApplication.shared

    backgroundSaveTask.withLock { outerTask in
      outerTask = app.beginBackgroundTask {
        backgroundSaveTask.withLock { innerTask in
          if let innerTaskNonOptional = innerTask {
            app.endBackgroundTask(innerTaskNonOptional)
            innerTask = .invalid
          }
        }
      }
    }

    defer {
      backgroundSaveTask.withLock { task in
        if let task {
          app.endBackgroundTask(task)
        }
        task = .invalid
      }
    }

    guard let imageData = image.pngData() else {
      Log.error("Could not generate PNG to save image: \(image)")
      return
    }

    let imageURL = urlForPersistedImage(contextScale, contextSize: contextSize)

    do {
      try imageData.write(to: imageURL, options: [.atomic])
    } catch {
      Log.error("Error writing to file: \(error)")
    }

    do {
      try addSkipBackupAttributeToItem(atUrl: imageURL)
    } catch {
      Log.error("Error adding do-not-back-up attribute to item at \(imageURL)")
    }
  }

  static func loadPersistedImage(contextScale: CGFloat, contextSize: CGSize) -> UIImage? {
    let imageURL = urlForPersistedImage(contextScale, contextSize: contextSize)

    do {
      let imageData = try Data(contentsOf: imageURL)
      let image = loadPersistedImageData(imageData, contextScale: contextScale)
      return image
    } catch {
      Log.error("Error creating data from image URL \(imageURL): \(error)")
      return nil
    }
  }
}

private extension ImageIO {
  static let persistedImageExtension = "png"

  static let persistedImageName: String = Defaults.snapshotMode
    ? "ScreenshotPersistedImage"
    : "PadiddlePersistedImage"

  static let backgroundSaveTask: Mutex<UIBackgroundTaskIdentifier?> = .init(nil)

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
      } catch {
        Log.error("Error creating directory at path \(path): \(error)")
      }
    }

    let fullURL = documentsURL.appendingPathComponent(imageName).appendingPathExtension(persistedImageExtension)

    return fullURL
  }

  static func loadPersistedImageData(_ imageData: Data, contextScale: CGFloat) -> UIImage? {
    guard let image = UIImage(data: imageData, scale: contextScale) else {
      Log.error("Couldn't create image from data on disk")
      if Defaults.snapshotMode {
        fatalError("We must always have a screenshot in snapshot mode.")
      }
      return nil
    }

    // As of this writing, I don't remember why I have to flip the image.
    let flipped = image.flippedTopToBottom

    return flipped
  }

  static func addSkipBackupAttributeToItem(atUrl url: URL) throws {
    var url = url
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try url.setResourceValues(values)
  }
}
