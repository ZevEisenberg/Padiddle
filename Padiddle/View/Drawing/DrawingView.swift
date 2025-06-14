import UIKit

class DrawingView: UIView, DrawingViewBoundsVendor {
  private let viewModel: DrawingViewModel

  private let drawingLayer = CALayer()

  init(viewModel: DrawingViewModel) {
    self.viewModel = viewModel
    super.init(frame: .zero)
    layer.addSublayer(drawingLayer)
    viewModel.view = self
    viewModel.imageUpdatedCallback = { [weak self] newImage in
      CATransaction.performWithoutAnimation {
        self?.drawingLayer.contents = newImage
      }
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  override func layoutSubviews() {
    drawingLayer.bounds = bounds
    drawingLayer.anchorPoint = .zero
    drawingLayer.position = .zero
    super.layoutSubviews()
  }

  func clear() {
    viewModel.clear()
    setNeedsDisplay()
  }

  func addPoint(_ point: CGPoint) {
    viewModel.addPoint(point)
  }

  func restartAtPoint(_ point: CGPoint) {
    viewModel.restartAtPoint(point)
  }
}
