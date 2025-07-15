import SwiftUI
import UIKit
import Utilities

@MainActor
public final class ColorButtonImageCache {
  var cache: [CacheKey: UIImage] = [:]

  public static let shared = ColorButtonImageCache()

  private init() {}

  public func image(forColorGenerator colorGenerator: ColorGenerator, displayScale: CGFloat) -> UIImage {
    let key = CacheKey(colorGenerator: colorGenerator, displayScale: displayScale)
    if let image = cache[key] {
      return image
    }

    let spiralModel = SpiralModel(
      colorGenerator: colorGenerator,
      size: .square(sideLength: 36),
      startRadius: 0,
      spacePerLoop: 0.7,
      thetaRange: 0...(2 * .pi * 4),
      thetaStep: .pi / 16,
      lineWidth: 2.3
    )

    let image = SpiralImageMaker.image(
      spiralModel: spiralModel,
      scale: displayScale
    )

    cache[key] = image
    return image
  }
}

extension ColorButtonImageCache {
  struct CacheKey: Hashable {
    var colorGenerator: ColorGenerator
    var displayScale: CGFloat
  }
}
