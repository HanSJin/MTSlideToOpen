//
//  AnimatedMaskLabel.swift
//  driver
//
//  Created by SJin Han on 2021/09/09.
//

import UIKit
import QuartzCore

class AnimatedMaskLabel: UIView {

    var textColor: UIColor = .black {
        didSet {
            setNeedsDisplay()
            update()
        }
    }
    var font: UIFont = .systemFont(ofSize: 32) {
        didSet {
            setNeedsDisplay()
            update()
        }
    }
    var textAlignment: NSTextAlignment = .center {
        didSet {
            setNeedsDisplay()
            update()
        }
    }
    var text: String! {
        didSet {
            setNeedsDisplay()
            update()
        }
    }
    
    private let gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()

        // Configure the gradient here
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)

        let colors = [
            UIColor.white.cgColor,
            UIColor.white.withAlphaComponent(0.3).cgColor,
            UIColor.white.cgColor
        ]
        gradientLayer.colors = colors

        let locations = [
            0.25,
            0.5,
            0.75
        ]
        gradientLayer.locations = locations as [NSNumber]

        return gradientLayer
    }()

    private var textAttributes: [NSAttributedString.Key: AnyObject] {
        let style = NSMutableParagraphStyle()
        style.alignment = textAlignment

        return [
            .font: font,
            .paragraphStyle: style,
        ]
    }

    override func layoutSubviews() {
        gradientLayer.frame = CGRect(
            x: -bounds.size.width,
            y: bounds.origin.y,
            width: 3 * bounds.size.width,
            height: bounds.size.height)
        update()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        layer.addSublayer(gradientLayer)

        let gradientAnimation = CABasicAnimation(keyPath: "locations")
        gradientAnimation.fromValue = [0.0, 0.12, 0.25]
        gradientAnimation.toValue = [0.75, 0.85, 1.0]
        gradientAnimation.duration = 1.5
        gradientAnimation.repeatCount = Float.infinity

        gradientLayer.add(gradientAnimation, forKey: nil)
    }

    var sizeLabel: UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.sizeToFit()
        return label
    }
    
    private func update() {
        let sizeLabel = self.sizeLabel
        
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        text.draw(in: CGRect(
                    x: bounds.origin.x,
                    y: (bounds.size.height - sizeLabel.frame.height) / 2,
                    width: bounds.size.width,
                    height: sizeLabel.frame.height),
                  withAttributes: textAttributes)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let maskLayer = CALayer()
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.frame = bounds.offsetBy(dx: bounds.width, dy: 0)
        maskLayer.contents = image?.cgImage
        gradientLayer.mask = maskLayer
    }
}
