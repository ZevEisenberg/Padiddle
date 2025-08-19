import Dependencies
import DependenciesMacros
import SwiftUI
import Synchronization
import UIKit

@DependencyClient
struct BitmapContextClient: DependencyKey, Sendable {
  var configureContext: @Sendable (
    _ contextSize: CGSize,
    _ screenScale: CGFloat
  ) -> Bool = { _, _ in false }

  var addPath: @Sendable (CGPath, Color) -> Void

  var context: @Sendable () -> CGContext?

  var contextSize: @Sendable () -> CGSize = { .zero }
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

    return Self(
      configureContext: { theContextSize, theScreenScale in
        screenScale = theScreenScale
        contextSize = theContextSize
        let bytesPerPixel: size_t = 4
        let bitsPerComponent: size_t = 8

        /// Number of bytes per row. Each pixel in the bitmap in this example is represented by 4 bytes: 8 bits each of red, green, blue, and alpha.
        let bitmapBytesPerRow = Int(theContextSize.width) * bytesPerPixel * Int(screenScale)

        let widthPx = Int(contextSize.width * screenScale)
        let heightPx = Int(contextSize.height * screenScale)

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
