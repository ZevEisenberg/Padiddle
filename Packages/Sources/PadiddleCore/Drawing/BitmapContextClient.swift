import Dependencies
import DependenciesMacros
import SwiftUI
import Synchronization
import UIKit
import Utilities

@DependencyClient
struct BitmapContextClient: DependencyKey, Sendable {
  var configureContext: @Sendable (
    _ contextSize: CGSize,
    _ screenScale: CGFloat
  ) -> Bool = { _, _ in false }

  var eraseDrawing: @Sendable () -> Void

  var addPath: @Sendable (CGPath, Color) -> Void

  var context: @Sendable () -> CGContext?

  var contextSize: @Sendable () -> CGSize = { .zero }
  var screenScale: @Sendable () -> CGFloat = { 1 }
  var contextFittingScaleFactor: @Sendable () -> CGFloat = { 1 }

  static var testValue: Self {
    liveValue
  }
}

extension BitmapContextClient {
  static var liveValue: Self {
    nonisolated(unsafe) var context: CGContext!
    nonisolated(unsafe) var contextSize: CGSize = .zero
    nonisolated(unsafe) var screenScale: CGFloat = 0

    return BitmapContextClient(
      configureContext: { theContextSize, theScreenScale in
        screenScale = theScreenScale
        contextSize = theContextSize
        let bytesPerPixel: size_t = 4
        let bitsPerComponent: size_t = 8

        /// Number of bytes per row. Each pixel in the bitmap in this example is represented by 4 bytes: 8 bits each of red, green, blue, and alpha.
        let bitmapBytesPerRow = Int(theContextSize.width) * bytesPerPixel * Int(screenScale)

        let widthPx = Int(theContextSize.width * screenScale)
        let heightPx = Int(theContextSize.height * screenScale)

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
      },
      eraseDrawing: {
        context.clear(CGRect(origin: .zero, size: contextSize))
      },
      addPath: { path, color in
        context.addPath(path)
        context.setStrokeColor(color.cgColor!)
        context.strokePath()
      },
      context: {
        context
      },
      contextSize: {
        contextSize
      },
      screenScale: {
        screenScale
      },
      contextFittingScaleFactor: {
        // The context image is scaled as Aspect Fill, so the larger dimension
        // of the bounds is the limiting factor
        let maxDimension = max(contextSize.width, contextSize.height)
        assert(maxDimension > 0)

        // Given context side length L and bounds max dimension l,
        // We are looking for a factor, ƒ, such that L * ƒ = l
        // So we divide both sides by L to get ƒ = l / L
        let ƒ = maxDimension / contextSize.width
        return ƒ
      }
    )
  }
}

extension DependencyValues {
  var bitmapContextClient: BitmapContextClient {
    get { self[BitmapContextClient.self] }
    set { self[BitmapContextClient.self] = newValue }
  }
}

extension BitmapContextClient {
  func renderer(colorScheme: ColorScheme, sideLength: Double? = nil) -> some Transferable {
    Renderer(colorScheme: colorScheme, client: self, overrideSideLength: sideLength)
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
        let fileURL = FileManager.default.temporaryDirectory
          .appendingPathComponent(fileName)

        let data = try await renderer.renderedImageData()
        try data.write(to: fileURL)
        return SentTransferredFile(fileURL)
      }
      .suggestedFileName { _ in
        // The actual file name on disk appears to be the one that is actually used, but we set this one just in case.
        fileName
      }

      DataRepresentation(exportedContentType: .png) { renderer in
        try await renderer.renderedImageData()
      }
      .suggestedFileName { _ in
        fileName
      }
    }

    @MainActor
    func renderedImageData() throws -> Data {
      guard let cgImage = client.context()!.makeImage() else {
        struct CannotMakeCGImageFromContext: Error {}
        throw CannotMakeCGImageFromContext()
      }

      let uiImage = UIImage(
        cgImage: cgImage,
        scale: client.screenScale(),
        orientation: .up
      )

      let swiftUIImage = Image(uiImage: uiImage)

      // Rendered image has a clear background. Composite it over the default background color, as appropriate, for light or dark mode.
      let swiftUIView = ZStack {
        Rectangle()
          .fill(.background)
        swiftUIImage
          .resizable()
          .interpolation(.high) // only affects renders with overridden size
          .scaledToFit()
      }
      .environment(\.colorScheme, colorScheme)

      let imageRenderer = ImageRenderer(content: swiftUIView)
      imageRenderer.scale = client.screenScale()
      if let overrideSideLength {
        imageRenderer.proposedSize = .init(CGSize.square(sideLength: overrideSideLength))
      }

      guard let renderedImage = imageRenderer.uiImage else {
        struct CannotMakeImageFromRenderer: Error {}
        throw CannotMakeImageFromRenderer()
      }
      guard let data = renderedImage.pngData() else {
        struct CannotMakePNGDataFromImage: Error {}
        throw CannotMakePNGDataFromImage()
      }

      return data
    }
  }
}
