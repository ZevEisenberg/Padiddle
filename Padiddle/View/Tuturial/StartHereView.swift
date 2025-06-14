import Anchorage
import BonMot
import UIKit

final class StarthereView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)

    let backgroundImage = UIImage(resource: .startHereBackground)

    let backgroundImageView = UIImageView(image: backgroundImage)

    let imageInsets = backgroundImage.capInsets

    let labelInsets = UIEdgeInsets(
      top: imageInsets.top + 0,
      left: imageInsets.left + 30,
      bottom: imageInsets.bottom + 0,
      right: imageInsets.right + 30
    )

    let label = UILabel(axId: "startHereLabel")
    label.numberOfLines = 0
    label.attributedText = String(localized: .tutorialStartHere).styled(with: StringStyle([
      .adapt(.control),
      .font(UIFont.systemFont(ofSize: 30, weight: .medium)),
      .color(UIColor(resource: .tutorialText)),
      .alignment(.center),
    ]))

    addSubview(backgroundImageView)
    addSubview(label)

    backgroundImageView.edgeAnchors == edgeAnchors

    label.edgeAnchors == edgeAnchors + labelInsets

    widthAnchor == backgroundImage.size.width
  }

  @available(*, unavailable) required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
