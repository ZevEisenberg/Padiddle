import SwiftUI
import UIKit

protocol DrawingViewModelDelegate: AnyObject {
  func startDrawing()
  func pauseDrawing()
  func drawingViewModelUpdatedLocation(_ newLocation: CGPoint)
}

protocol DrawingViewBoundsVendor: AnyObject {
  var bounds: CGRect { get }
}

enum ImageDestination {
  /// Clear background, for state restoration on app relaunch
  case saveToDisk

  /// Opaque background with the specified color, for export
  case export(ColorScheme)
}

extension UIUserInterfaceStyle {
  var asColorScheme: ColorScheme? {
    switch self {
    case .unspecified:
      nil
    case .light:
      .light
    case .dark:
      .dark
    @unknown default:
      nil
    }
  }
}

class DrawingViewModel: NSObject { // must inherit from NSObject for @objc callbacks to work
  private(set) var isDrawing = false
  var needToMoveNibToNewStartLocation = true

  let contextSize: CGSize
  let screenScale: CGFloat

  private let brushDiameter: CGFloat = 12

  weak var delegate: DrawingViewModelDelegate?
  weak var view: DrawingViewBoundsVendor?

  private var colorManager: ColorManager?

  private let spinManager: SpinManager

  private let maxRadius: CGFloat

  private var offscreenContext: CGContext!

  private var points = Array(repeating: CGPoint.zero, count: 4)

  private var displayLink: CADisplayLink?

  var imageUpdatedCallback: ((CGImage) -> Void)?

  private lazy var contextScaleFactor: CGFloat = {
    // The context image is scaled as Aspect Fill, so the larger dimension
    // of the bounds is the limiting factor
    let maxDimension = max(self.contextSize.width, self.contextSize.height)
    assert(maxDimension > 0)

    // Given context side length L and bounds max dimension l,
    // We are looking for a factor, ƒ, such that L * ƒ = l
    // So we divide both sides by L to get ƒ = l / L
    let ƒ = maxDimension / self.contextSize.width
    return ƒ
  }()

  private var currentColor: UIColor {
    guard let colorManager = colorManager else {
      return UIColor.magenta
    }

    return colorManager.currentColor
  }

  required init(
    maxRadius: CGFloat,
    contextSize: CGSize,
    screenScale: CGFloat,
    spinManager: SpinManager
  ) {
    assert(maxRadius > 0)
    self.maxRadius = maxRadius
    self.contextSize = contextSize
    self.screenScale = screenScale
    self.spinManager = spinManager
    super.init()
    let success = configureOffscreenContext()
    assert(success, "Problem creating bitmap context")

    self.displayLink = CADisplayLink(target: self, selector: #selector(DrawingViewModel.displayLinkUpdated))
    displayLink?.preferredFrameRateRange = .init(minimum: 60, maximum: 120, preferred: 120)
    displayLink?.add(to: .main, forMode: .default)
  }

  func addPoint(_ point: CGPoint) {
    let scaledPoint = convertViewPointToContextCoordinates(point)
    let distance = CGPoint.distanceBetween(points[3], scaledPoint)
    if distance > 2.25 {
      points.removeFirst()
      points.append(scaledPoint)

      addLineSegmentBasedOnUpdatedPoints()
    }
  }

  // MARK: Drawing

  func startDrawing() {
    isDrawing = true
  }

  func stopDrawing() {
    isDrawing = false
  }

  func clear(andPersist persist: Bool) {
    offscreenContext.clear(CGRect(origin: .zero, size: contextSize))
    offscreenContext.makeImage().map { imageUpdatedCallback?($0) }
    if persist {
      persistImageInBackground()
    }
  }

  func restartAtPoint(_ point: CGPoint) {
    let convertedPoint = convertViewPointToContextCoordinates(point)
    points = Array(repeating: convertedPoint, count: points.count)
    addLineSegmentBasedOnUpdatedPoints()
  }

  func setInitialImage(_ image: UIImage) {
    let rect = CGRect(origin: .zero, size: contextSize)
    offscreenContext.draw(image.cgImage!, in: rect)
    offscreenContext.makeImage().map { imageUpdatedCallback?($0) }
  }

  private func addLineSegmentBasedOnUpdatedPoints() {
    let pathSegment = CGPath.smoothedPathSegment(points: points)
    offscreenContext.addPath(pathSegment)
    offscreenContext.setStrokeColor(currentColor.cgColor)
    offscreenContext.strokePath()
    offscreenContext.makeImage().map { imageUpdatedCallback?($0) }
  }

  // Saving & Loading

  func snapshot(_ orientation: UIInterfaceOrientation, destination: ImageDestination) -> UIImage {
    let (imageOrientation, rotation) = orientation.imageRotation

    let cacheCGImage = offscreenContext.makeImage()!
    let unrotatedImage = UIImage(cgImage: cacheCGImage, scale: screenScale, orientation: imageOrientation)
    let backgroundColor: UIColor? = switch destination {
    case .saveToDisk:
      nil
    case .export(let colorScheme):
      switch colorScheme {
      case .light:
        .white
      case .dark:
        .black
      @unknown default:
        .black
      }
    }
    let rotatedImage = unrotatedImage.rotatedByRadians(rotation, onBackgroundColor: backgroundColor)
    return rotatedImage
  }

  func getSnapshotImage(interfaceOrientation: UIInterfaceOrientation, destination: ImageDestination) -> ExportableImage {
    let image = snapshot(interfaceOrientation, destination: destination)

    return ExportableImage(pngData: image.pngData(), image: image)
  }

  func persistImageInBackground() {
    let image = snapshot(.portrait, destination: .saveToDisk)
    ImageIO.persistImageInBackground(image, contextScale: screenScale, contextSize: contextSize)
  }

  func loadPersistedImage() {
    if let image = ImageIO.loadPersistedImage(
      contextScale: screenScale,
      contextSize: contextSize
    ) {
      setInitialImage(image)
    }
  }
}

extension DrawingViewModel {
  @objc func displayLinkUpdated() {
    updateMotion()
  }
}

extension DrawingViewModel: RecordingDelegate {
  @objc func recordingStatusChanged(_ recording: Bool) {
    if recording {
      delegate?.startDrawing()
    } else {
      delegate?.pauseDrawing()
    }
  }

  @objc func motionUpdatesStatusChanged(_ updates: Bool) {
    if updates {
      startMotionUpdates()
    } else {
      stopMotionUpdates()
    }
  }
}

extension DrawingViewModel: RootColorManagerDelegate {
  func colorManagerPicked(_ colorManager: ColorManager) {
    var newManager = colorManager
    newManager.maxRadius = maxRadius
    self.colorManager = newManager
  }
}

extension DrawingViewModel { // Coordinate conversions
  private func convertViewPointToContextCoordinates(_ point: CGPoint) -> CGPoint {
    guard let view = view else {
      fatalError("Not having a view represents a programmer error")
    }

    var newPoint = point

    // 1. Multiply the point by the reciprocal of the context scale factor
    newPoint.x *= (1 / contextScaleFactor)
    newPoint.y *= (1 / contextScaleFactor)

    // 2. Get the size of self in context coordinates
    let viewSize = view.bounds.size
    let scaledViewSize = CGSize(
      width: viewSize.width * (1 / contextScaleFactor),
      height: viewSize.height * (1 / contextScaleFactor)
    )

    // 3. Get the difference in size between self and the context
    let difference = CGSize(
      width: contextSize.width - scaledViewSize.width,
      height: contextSize.height - scaledViewSize.height
    )

    // 4. Shift the point by half the difference in width and height
    newPoint.x += difference.width / 2
    newPoint.y += difference.height / 2

    return newPoint
  }

  func convertContextRectToViewCoordinates(_ rect: CGRect) -> CGRect {
    guard !rect.equalTo(CGRect.null) else {
      return .null
    }
    guard let view = view else { fatalError("Not having a view represents a programmer error") }

    // 1. Get the size of the context in self coordinates
    let scaledContextSize = CGSize(
      width: contextSize.width * contextScaleFactor,
      height: contextSize.height * contextScaleFactor
    )

    // 2. Get the difference in size between self and the context
    let boundsSize = view.bounds.size

    let difference = CGSize(
      width: scaledContextSize.width - boundsSize.width,
      height: scaledContextSize.height - boundsSize.height
    )

    // 3. Scale the rect by the context scale factor
    let scaledRect = rect.applying(CGAffineTransform(scaleX: contextScaleFactor, y: contextScaleFactor))

    // 4. Shift the rect by negative the half the difference in width and height
    let offsetRect = scaledRect.offsetBy(dx: -difference.width / 2.0, dy: -difference.height / 2.0)

    return offsetRect
  }

  func convertContextPointToViewCoordinates(_ point: CGPoint) -> CGPoint {
    guard let view = view else {
      fatalError("Not having a view represents a programmer error")
    }

    // 1. Get the size of the context in self coordinates
    let scaledContextSize = CGSize(
      width: contextSize.width * contextScaleFactor,
      height: contextSize.height * contextScaleFactor
    )

    // 2. Get the difference in size between self and the context
    let boundsSize = view.bounds.size

    let difference = CGSize(
      width: scaledContextSize.width - boundsSize.width,
      height: scaledContextSize.height - boundsSize.height
    )

    // 3. Scale the rect by the context scale factor
    let scaledPoint = point.applying(CGAffineTransform(scaleX: contextScaleFactor, y: contextScaleFactor))

    // 4. Shift the rect by negative the half the difference in width and height
    let offsetPoint = scaledPoint.offsetBy(dx: -difference.width / 2.0, dy: -difference.height / 2.0)

    return offsetPoint
  }
}

// MARK: Context configuration

private extension DrawingViewModel {
  func configureOffscreenContext() -> Bool {
    let bitmapBytesPerRow: Int

    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes: 8 bits each of red, green, blue, and
    // alpha.

    bitmapBytesPerRow = Int(contextSize.width) * bytesPerPixel * Int(screenScale)

    let widthPx = Int(contextSize.width * screenScale)
    let heightPx = Int(contextSize.height * screenScale)

    let context = CGContext(
      data: nil,
      width: widthPx,
      height: heightPx,
      bitsPerComponent: bitsPerComponent,
      bytesPerRow: bitmapBytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGBitmapInfo(alpha: .premultipliedFirst)
    )

    guard context != nil else {
      assertionFailure("Problem creating context")
      return false
    }

    offscreenContext = context

    // Scale by screen scale because the context is in pixels, not points.
    // If we don't invert the y axis, the world will be turned upside down
    offscreenContext?.translateBy(x: 0, y: CGFloat(heightPx))
    offscreenContext?.scaleBy(x: screenScale, y: -screenScale)

    offscreenContext?.setLineCap(.round)
    offscreenContext?.setLineWidth(brushDiameter)

    clear(andPersist: false)

    return true
  }
}

// MARK: Core Motion

extension DrawingViewModel {
  func startMotionUpdates() {
//        startDrawing()
    spinManager.startMotionUpdates()
  }

  func stopMotionUpdates() {
    stopDrawing()
    spinManager.stopMotionUpdates()
  }

  @objc func updateMotion() {
    if let deviceMotion = spinManager.deviceMotion {
      let zRotation = deviceMotion.rotationRate.z
      let radius = maxRadius / UIDevice.gyroMaxValue * CGFloat(fabs(zRotation))

      // Yaw is on the range [-π...π]. Remap to [0...π]
      let theta = deviceMotion.attitude.yaw + .pi

      let x = radius * CGFloat(cos(theta)) + contextSize.width / 2.0
      let y = radius * CGFloat(sin(theta)) + contextSize.height / 2.0

      colorManager?.radius = radius
      colorManager?.theta = CGFloat(theta)

      delegate?.drawingViewModelUpdatedLocation(CGPoint(x: x, y: y))
    }
  }
}

struct ExportableImage {
  /// If we can get the PNG data from the image, we should, because it is higher quality than the default JPEG image sharing for the type of image we are generating.
  let pngData: Data?

  /// The original image. Used for the share sheet preview and as a fallback in case the PNG data was not available for some reason.
  let image: UIImage
}
