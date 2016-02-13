//
//  PickerCell.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/18/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

let backgroundColorNormal = UIColor.clearColor()
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
        imageView = UIImageView()
        titleLabel = UILabel()

        super.init(frame: frame)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .Center
        imageView.clipsToBounds = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = textColor
        titleLabel.textAlignment = .Center
        titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        titleLabel.numberOfLines = 0 // in case we are even in a situation where we need to wrap lines

        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)

        contentView.layer.cornerRadius = 5
        contentView.layer.borderColor = borderColor.CGColor

        // Layout

        imageView.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor).active = true
        imageView.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor).active = true
        imageView.topAnchor.constraintEqualToAnchor(contentView.topAnchor).active = true

        titleLabel.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor).active = true
        titleLabel.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor).active = true
        contentView.bottomAnchor.constraintEqualToAnchor(titleLabel.bottomAnchor, constant: 6).active = true

        imageView.bottomAnchor.constraintEqualToAnchor(titleLabel.topAnchor).active = true
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

    override var selected: Bool {
        didSet {
            if selected {
                //--------------------------------------------------
                // Use the appTintColor here, instead of our own
                // view’s tintColor, because we aren’t necessarily
                // in the view hierarchy yet, in which case we don’t
                // have the right tintColor.
                //--------------------------------------------------
                contentView.layer.borderWidth = borderWidth
                titleLabel.textColor = UIColor(named: .AppTint)
            } else {
                contentView.layer.borderWidth = 0
                titleLabel.textColor = textColor
            }
        }
    }

    override var highlighted: Bool {
        didSet {
            if highlighted {
                contentView.backgroundColor = backgroundColorHighlighted
                contentView.layer.borderColor = highlightedTrimColor.CGColor
                contentView.layer.borderWidth = borderWidth
                titleLabel.textColor = highlightedTextColor
            } else {
                contentView.backgroundColor = backgroundColorNormal
                contentView.layer.borderColor = borderColor.CGColor
                contentView.layer.borderWidth = 0.0
                titleLabel.textColor = textColor
            }
        }
    }
}
