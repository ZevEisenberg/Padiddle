import Dependencies
import os
import SwiftUI
import Synchronization
import UIKit
import Utilities

actor BitmapContextClient {
  var context: CGContext!
  var contextSideLength: CGFloat = 0
  var screenScale: CGFloat = 0

  func configure(contextSideLength: CGFloat, screenScale: CGFloat) -> Bool {
    self.contextSideLength = contextSideLength
    self.screenScale = screenScale

    let bytesPerPixel: size_t = 4
    let bitsPerComponent: size_t = 8

    /// Number of bytes per row. Each pixel in the bitmap in this example is represented by 4 bytes: 8 bits each of red, green, blue, and alpha.
    let bitmapBytesPerRow = Int(contextSideLength) * bytesPerPixel * Int(screenScale)

    let widthPx = Int(contextSideLength * screenScale)
    let heightPx = Int(contextSideLength * screenScale)

    guard let theContext = CGContext(
      data: nil,
      width: widthPx,
      height: heightPx,
      bitsPerComponent: bitsPerComponent,
      bytesPerRow: bitmapBytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGBitmapInfo(alpha: .premultipliedFirst)
    ) else {
      return false
    }

    // Scale by screen scale because the context is in pixels, not points.
    // If we don't invert the y axis, the world will be turned upside down
    theContext.translateBy(x: 0, y: CGFloat(heightPx))
    theContext.scaleBy(x: screenScale, y: -screenScale)

    theContext.setLineCap(.round)
    theContext.setLineWidth(brushDiameter)

    context = theContext
    return true
  }

  func setScreenScale(_ newValue: CGFloat) {
    screenScale = newValue
  }

  func contextOperation<Output>(_ operation: @Sendable (CGContext) -> Output) -> Output {
    operation(context)
  }

  func eraseDrawing() {
    context.clear(
      CGRect(
        origin: .zero,
        size: CGSize.square(
          sideLength: contextSideLength
        )
      )
    )
  }
}

extension BitmapContextClient: DependencyKey {
  static var liveValue: BitmapContextClient {
    Self()
  }

  static var testValue: BitmapContextClient {
    liveValue
  }
}

extension DependencyValues {
  var bitmapContextClient: BitmapContextClient {
    get { self[BitmapContextClient.self] }
    set { self[BitmapContextClient.self] = newValue }
  }
}

extension BitmapContextClient {
  nonisolated func renderer(colorScheme: ColorScheme, sideLength: Double? = nil) -> some Transferable {
    Renderer(colorScheme: colorScheme, client: self, overrideSideLength: sideLength)
  }

  enum Rep {
    case file
    case data

    var name: StaticString {
      switch self {
      case .file:
        "file"
      case .data:
        "data"
      }
    }
  }

  func renderedImageData(rep: Rep, colorScheme: ColorScheme, overrideSideLength: Double?) throws -> Data {
    let signposter = OSSignposter()
    let signpostID = signposter.makeSignpostID()

    let signpostState = signposter.beginInterval("makeImage", id: signpostID, "representation: \(rep.name), size: \(overrideSideLength.map(\.description) ?? "default")")

    guard let cgImage = context.makeImage() else {
      struct CannotMakeCGImageFromContext: Error {}
      throw CannotMakeCGImageFromContext()
    }

    let format = UIGraphicsImageRendererFormat()
    format.scale = screenScale
    let size = CGSize.square(sideLength: overrideSideLength ?? contextSideLength)

    // Context image has a clear background. Composite it over the appropriate background color for light or dark mode.
    let renderedImage = UIGraphicsImageRenderer(size: size, format: format).image { rendererContext in
      let backgroundColor: UIColor = switch colorScheme {
      case .light:
        .white
      case .dark:
        .black
      @unknown default:
        .white
      }

      let fullRect = CGRect(origin: .zero, size: size)
      backgroundColor.setFill()
      rendererContext.fill(fullRect)
      rendererContext.cgContext.draw(cgImage, in: fullRect)
    }

    guard let data = renderedImage.pngData() else {
      struct CannotMakePNGDataFromImage: Error {}
      throw CannotMakePNGDataFromImage()
    }

    signposter.endInterval("makeImage", signpostState)

    return data
  }
}

private extension BitmapContextClient {
  struct Renderer: Transferable {
    let colorScheme: ColorScheme
    let client: BitmapContextClient
    let overrideSideLength: Double?

    static var transferRepresentation: some TransferRepresentation {
      let fileName = "Image from Padiddle.png"

      // Between AirDrop, copy/paste, Save to Files, and others, we end up needing both representations.

      FileRepresentation(exportedContentType: .png) { renderer in
        let signposter = OSSignposter()
        let signpostID = signposter.makeSignpostID()

        let signpostState = signposter.beginInterval("exporting", id: signpostID, "size: \(renderer.overrideSideLength.map(\.description) ?? "default")")

        let fileURL = signposter.withIntervalSignpost("make URL") {
          FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
        }

        let renderID = signposter.makeSignpostID()
        let renderState = signposter.beginInterval("rendering", id: renderID, "size: \(renderer.overrideSideLength.map(\.description) ?? "default")")

        let data = try await renderer.client.renderedImageData(
          rep: .file,
          colorScheme: renderer.colorScheme,
          overrideSideLength: renderer.overrideSideLength
        )
        signposter.endInterval("rendering", renderState)

        try signposter.withIntervalSignpost("write to URL") {
          try data.write(to: fileURL)
        }

        let result = signposter.withIntervalSignpost("make transferred file") {
          SentTransferredFile(fileURL)
        }
        signposter.endInterval("exporting", signpostState)
        return result
      }
      .suggestedFileName { _ in
        // The actual file name on disk appears to be the one that is actually used, but we set this one just in case.
        fileName
      }

      DataRepresentation(exportedContentType: .png) { renderer in
        try await renderer.client.renderedImageData(
          rep: .data,
          colorScheme: renderer.colorScheme,
          overrideSideLength: renderer.overrideSideLength
        )
      }
      .suggestedFileName { _ in
        fileName
      }
    }
  }
}
