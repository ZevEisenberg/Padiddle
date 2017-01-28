//
//  PickerCell.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/18/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Anchorage

let backgroundColorNormal = UIColor.clear
let backgroundColorHighlighted = UIColor(white:0.85, alpha:1)
let borderColor = UIColor(white:0.85, alpha:1)

let textColor = UIColor(white:0.5, alpha:1)
let highlightedTextColor = UIColor(white:0.4, alpha:1)
let highlightedTrimColor = UIColor(white:0.65, alpha:1.0)

let borderWidth = CGFloat(2)

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
        imageView = UIImageView(axId: "imageView")
        titleLabel = UILabel(axId: "titleLabel")

        super.init(frame: frame)

        imageView.contentMode = .center
        imageView.clipsToBounds = true

        titleLabel.textColor = textColor
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0 // in case we are even in a situation where we need to wrap lines

        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)

        contentView.layer.cornerRadius = 5
        contentView.layer.borderColor = borderColor.cgColor

        // Layout

        imageView.horizontalAnchors == contentView.horizontalAnchors
        imageView.topAnchor == contentView.topAnchor

        titleLabel.horizontalAnchors == contentView.horizontalAnchors
        titleLabel.bottomAnchor == contentView.bottomAnchor - 6

        titleLabel.topAnchor == imageView.bottomAnchor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.textColor = textColor
        contentView.backgroundColor = backgroundColorNormal
        contentView.layer.borderWidth = 0
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                //--------------------------------------------------
                // Use the appTintColor here, instead of our own
                // view’s tintColor, because we aren’t necessarily
                // in the view hierarchy yet, in which case we don’t
                // have the right tintColor.
                //--------------------------------------------------
                contentView.layer.borderWidth = borderWidth
                titleLabel.textColor = .appTint
            }
            else {
                contentView.layer.borderWidth = 0
                titleLabel.textColor = textColor
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                contentView.backgroundColor = backgroundColorHighlighted
                contentView.layer.borderColor = highlightedTrimColor.cgColor
                contentView.layer.borderWidth = borderWidth
                titleLabel.textColor = highlightedTextColor
            }
            else {
                contentView.backgroundColor = backgroundColorNormal
                contentView.layer.borderColor = borderColor.cgColor
                contentView.layer.borderWidth = 0.0
                titleLabel.textColor = textColor
            }
        }
    }
}
