//
//  SpinPromptView.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 5/18/17.
//  Copyright © 2017 Zev Eisenberg. All rights reserved.
//

import Anchorage
import BonMot
import UIKit

final class SpinPromptView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        let (backgroundImage, imageInsets) = UIDevice.spinPromptImage
        let imageView = UIImageView(image: backgroundImage)

        let label = UILabel(axId: "spinPromptLabel")
        label.numberOfLines = 0
        label.attributedText = L10n.tutorialSpinPrompt.styled(with: StringStyle([
            .adapt(.control),
            .font(UIFont.systemFont(ofSize: 30, weight: .medium)),
            .color(.tutorialText),
            .alignment(.center),
            ]))

        // View Hierarchy

        addSubview(imageView)
        imageView.addSubview(label)

        // Layout

        imageView.centerAnchors == centerAnchors

        imageView.sizeAnchors == backgroundImage.size
        sizeAnchors == backgroundImage.size

        label.edgeAnchors == imageView.edgeAnchors + imageInsets
    }

    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - Public Methods

extension SpinPromptView {

    func startAnimating() {
        let twoPi: CGFloat = 2 * .pi
        let keyframeAnimation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.transform))

        let duration: CFTimeInterval = 2
        let framesPerSecond = Double(UIScreen.main.maximumFramesPerSecond)
        let frameCount = duration * framesPerSecond

        let frameFractions = stride(from: 0, to: 1.0, by: 1.0 / frameCount)

        let fractions = frameFractions.map {
            SpinPromptView.rotationFraction(forFraction: $0)
        }

        let values = fractions.map {
            CATransform3DMakeRotation(twoPi * CGFloat($0), 0, 0, 1)
        }

        keyframeAnimation.values = values
        keyframeAnimation.duration = duration
        keyframeAnimation.repeatCount = .greatestFiniteMagnitude
        keyframeAnimation.timingFunction = CAMediaTimingFunction(name: .linear)

        layer.add(keyframeAnimation, forKey: "spinny")
    }

    func stopAnimating() {
        layer.removeAnimation(forKey: "spinny")
    }

}

// MARK: - Private Methods

private extension SpinPromptView {

    static func rotationFraction(forFraction x: Double) -> Double {
        let a = 6.0
        let numerator = atan(a * (x - 0.5))
        let denominator = 2 * atan(a / 2)
        return numerator / denominator + 0.5
    }

}
