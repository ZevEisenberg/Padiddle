import Anchorage
import UIKit

class PickerCell: UICollectionViewCell {
  var image: UIImage? {
    didSet {
      imageView.image = image
    }
  }

  var title: String = "" {
    didSet {
      titleLabel.text = title
    }
  }

  let imageView: UIImageView
  let titleLabel: UILabel

  override init(frame: CGRect) {
    self.imageView = UIImageView(axId: "imageView")
    self.titleLabel = UILabel(axId: "titleLabel")

    super.init(frame: frame)

    imageView.contentMode = .center
    imageView.clipsToBounds = true

    titleLabel.textColor = UIColor(resource: .ColorPicker.Text.normal)
    titleLabel.textAlignment = .center
    titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 0 // in case we are even in a situation where we need to wrap lines

    contentView.addSubview(imageView)
    contentView.addSubview(titleLabel)

    contentView.layer.cornerRadius = 10

    // Layout

    imageView.horizontalAnchors == contentView.horizontalAnchors
    imageView.topAnchor == contentView.topAnchor

    titleLabel.horizontalAnchors == contentView.horizontalAnchors
    titleLabel.bottomAnchor == contentView.bottomAnchor - 6

    titleLabel.topAnchor == imageView.bottomAnchor

    registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
      self.updateColors()
    }

    updateColors()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    updateColors()
    super.prepareForReuse()
  }

  override var isSelected: Bool {
    didSet {
      updateColors()
    }
  }

  override var isHighlighted: Bool {
    didSet {
      updateColors()
    }
  }

  func updateColors() {
    // Layer
    contentView.layer.borderColor = UIColor(
      resource: isHighlighted
        ? .ColorPicker.Border.highlighted
        : .ColorPicker.Border.normal
    ).cgColor

    contentView.layer.borderWidth = (isHighlighted || isSelected) ? 2 : 0

    // UIColors

    let textResource: ColorResource
    let backgroundResource: ColorResource

    if isHighlighted {
      textResource = .ColorPicker.Text.highlighted
      backgroundResource = .ColorPicker.Background.highlighted
    } else if isSelected {
      // Use the appTintColor here, instead of our own view’s tintColor, because we aren’t necessarily in the view hierarchy yet, in which case we don’t have the right tintColor.
      textResource = .accent
      backgroundResource = .ColorPicker.Background.selected
    } else {
      textResource = .ColorPicker.Text.normal
      backgroundResource = .ColorPicker.Background.normal
    }
    titleLabel.textColor = UIColor(resource: textResource)
    contentView.backgroundColor = UIColor(resource: backgroundResource)
  }
}
