import Anchorage
import UIKit

let showDebugLabel = false

class DrawingViewController: CounterRotatingViewController {
  private let viewModel: DrawingViewModel
  private let drawingView: DrawingView
  private let nib = UIImageView()

  init(viewModel: DrawingViewModel, screenLongestSideLength: CGFloat) {
    self.viewModel = viewModel
    self.drawingView = DrawingView(viewModel: self.viewModel)
    super.init(screenLongestSideLength: screenLongestSideLength)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    viewModel.delegate = self

    view.backgroundColor = .systemBackground
    view.accessibilityIdentifier = "drawing view controller view"

    counterRotatingView.addSubview(drawingView)

    view.sizeAnchors == viewModel.contextSize

    drawingView.widthAnchor == viewModel.contextSize.width
    drawingView.heightAnchor == viewModel.contextSize.width
    drawingView.centerAnchors == counterRotatingView.centerAnchors

    let nibDiameter = 12.0

    nib.image = UIImage.ellipseImage(
      color: UIColor.label,
      size: CGSize(width: nibDiameter, height: nibDiameter),
      borderWidth: 1,
      borderColor: .systemBackground
    )
    nib.sizeToFit()

    drawingView.addSubview(nib)

    if showDebugLabel {
      let label = UILabel()
      label.text = "Drawing view debug label"
      counterRotatingView.addSubview(label)

      label.centerAnchors == view.centerAnchors
    }

    viewModel.loadPersistedImage()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    viewModel.startMotionUpdates()
  }

  func getSnapshotImage(interfaceOrientation: UIInterfaceOrientation, destination: ImageDestination) -> ExportableImage {
    viewModel.getSnapshotImage(interfaceOrientation: interfaceOrientation, destination: destination)
  }

  func clearTapped() {
    drawingView.clear()
  }
}

extension DrawingViewController: DrawingViewModelDelegate {
  func startDrawing() {
    viewModel.startDrawing()
    viewModel.startMotionUpdates()
  }

  func pauseDrawing() {
    viewModel.needToMoveNibToNewStartLocation = true
    viewModel.stopDrawing()
    viewModel.persistImageInBackground()
  }

  func drawingViewModelUpdatedLocation(_ newLocation: CGPoint) {
    let convertedLocation = viewModel.convertContextPointToViewCoordinates(newLocation)

    nib.center = convertedLocation.screenPixelsIntegral(forScreenScale: traitCollection.displayScale)

    if viewModel.isDrawing {
      if viewModel.needToMoveNibToNewStartLocation {
        viewModel.needToMoveNibToNewStartLocation = false
        drawingView.restartAtPoint(convertedLocation)
      } else {
        drawingView.addPoint(convertedLocation)
      }
    }
  }
}
