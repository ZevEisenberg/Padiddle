import UIKit

extension UIImage {
  static func ellipseImage(
    color: UIColor,
    size: CGSize,
    borderWidth: CGFloat,
    borderColor: UIColor
  ) -> UIImage {
    // Build a rect of appropriate size at origin (1,1)
    let fullRect = CGRect(origin: .zero, size: size)
    let insetRect = fullRect.insetBy(dx: borderWidth / 2.0, dy: borderWidth / 2.0)

    let image = UIGraphicsImageRenderer(size: size).image { rendererContext in
      let context = rendererContext.cgContext

      // Add ellipse for masking
      context.addEllipse(in: insetRect)

      // Save the graphics state so we can undo the clip to draw the stroke
      context.saveGState()

      // Clip the context by the current path to get rid of
      // the part of the stroke that drew outside the line
      context.clip()

      // Set the fill color
      context.setFillColor(color.cgColor)

      // Fill the color
      context.fill(fullRect)

      // Undo the clip so the stroke draws inside and out
      context.restoreGState()

      // Set up the stroke
      context.setStrokeColor(borderColor.cgColor)
      context.setLineWidth(borderWidth)

      // Stroke the color
      context.strokeEllipse(in: insetRect)
    }

    return image
  }

  func rotatedByRadians(
    _ radians: CGFloat,
    onBackgroundColor backgroundColor: UIColor?
  ) -> UIImage {
    // Don't optimize out the radians == 0 case by just returning self.
    // It results in an image that is flipped vertically.
    // I likely have a double rotation somewhere.

    let rotatedSize: CGSize = if radians == .pi || radians == 0 {
      size
    } else {
      CGSize(width: size.height, height: size.width)
    }

    let format = UIGraphicsImageRendererFormat()
    format.opaque = backgroundColor != nil
    format.scale = scale

    let image = UIGraphicsImageRenderer(size: rotatedSize, format: format).image { rendererContext in
      let context = rendererContext.cgContext

      // Move the origin to the middle of the image so we will rotate and scale around the center.
      context.translateBy(x: size.width / 2, y: size.height / 2)

      // Rotate the image context
      context.rotate(by: radians)

      // Now, draw the rotated/scaled image into the context
      let imageRect = CGRect(
        x: -rotatedSize.width / 2,
        y: -rotatedSize.height / 2,
        width: rotatedSize.width,
        height: rotatedSize.height
      )

      if let backgroundColor {
        context.setFillColor(backgroundColor.cgColor)
        context.fill(imageRect)
      }

      draw(in: imageRect)
    }

    return image
  }

  var flippedTopToBottom: UIImage {
    imageScaledBy(CGVector(dx: 1, dy: -1))
  }

  static func recordButtonImage() -> UIImage {
    let backgroundImage = UIImage(resource: .recordButtonBack)
    let foregroundImage = UIImage(resource: .recordButtonFront)

    let backgroundImageBounds = CGRect(origin: .zero, size: backgroundImage.size)
    let foregroundImageBounds = CGRect(origin: .zero, size: backgroundImage.size)

    let imageSize = CGSize.max(foregroundImage.size, backgroundImage.size)
    let image = UIGraphicsImageRenderer(size: imageSize).image { _ in
      let contextRect = CGRect(origin: .zero, size: imageSize)

      let backgroundImageFrame = contextRect.centerSmallerRect(backgroundImageBounds)
      let foregroundImageFrame = contextRect.centerSmallerRect(foregroundImageBounds)

      backgroundImage.draw(in: backgroundImageFrame)
      foregroundImage.draw(in: foregroundImageFrame)
    }
    return image
  }

  private func imageScaledBy(_ scaleVector: CGVector) -> UIImage {
    let scaledSize = CGSize(
      width: size.width * scaleVector.dx,
      height: size.height * scaleVector.dy
    )

    let scaledSizeNormalized = CGSize(
      width: abs(scaledSize.width),
      height: abs(scaledSize.height)
    )

    let format = UIGraphicsImageRendererFormat()
    format.opaque = ciImage?.isOpaque ?? false
    format.scale = scale
    let image = UIGraphicsImageRenderer(size: scaledSizeNormalized, format: format).image { rendererContext in
      let context = rendererContext.cgContext
      // Move the origin to the middle of the image so we will scale around the center.
      context.scaleBy(x: scaleVector.dx, y: scaleVector.dy)
      context.translateBy(x: scaledSize.width / 2, y: scaledSize.height / 2)

      // Now, draw the rotated/scaled image into the context. Image still thinks it is its own normal size, just drawing in a scaled context.
      let drawRect = CGRect(
        x: -size.width / 2,
        y: -size.height / 2,
        width: size.width,
        height: size.height
      )
      draw(in: drawRect)
    }

    return image
  }
}
