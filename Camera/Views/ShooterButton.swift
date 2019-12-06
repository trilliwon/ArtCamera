//
//  ShutterButton.swift
//  Camera
//
//  Created by wonjo on 28/05/2018.
//  Copyright © 2018 trilliwon. All rights reserved.
//

import UIKit

@IBDesignable
open class ShooterButton: UIButton {

    // MARK: - IBInspectable Properties
    @IBInspectable public var buttonColor: UIColor = .white {
        didSet {
            circleLayer.fillColor = buttonColor.cgColor
        }
    }

    @IBInspectable public var arcColor: UIColor = .white {
        didSet {
            arcLayer.strokeColor = arcColor.cgColor
        }
    }

    // MARK: - Private Properties
    private var arcWidth: CGFloat {
        return bounds.width * 0.09
    }

    private var arcMargin: CGFloat {
        return bounds.width * 0.03
    }

    lazy private var circleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = circlePath.cgPath
        layer.fillColor = buttonColor.cgColor
        return layer
    }()

    private func animateCircleLayer(animatinglayer: CAShapeLayer, toPath: CGPath) {
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.toValue = toPath
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        animatinglayer.add(animation, forKey: "pathAnimation")
    }

    lazy private var arcLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = arcPath.cgPath
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = arcColor.cgColor
        layer.lineWidth = arcWidth
        return layer
    }()

    private var circlePath: UIBezierPath {
        let side = bounds.width - arcWidth * 2 - arcMargin * 2
        let posX = bounds.width / 2 - side / 2
        let posY = bounds.width / 2 - side / 2
        let roundedRect = CGRect(x: posX, y: posY, width: side, height: side)
        return UIBezierPath(roundedRect: roundedRect, cornerRadius: side / 2)
    }

    private var pressedCirclePath: UIBezierPath {
        let side = bounds.width - arcWidth * 2 - arcMargin * 2 - 7.0
        let posX = bounds.width / 2 - side / 2
        let posY = bounds.width / 2 - side / 2
        let roundedRect = CGRect(x: posX, y: posY, width: side, height: side)
        return UIBezierPath(roundedRect: roundedRect, cornerRadius: side / 2)
    }

    private var arcPath: UIBezierPath {
        return UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                            radius: bounds.width / 2 - arcWidth / 2,
                            startAngle: -.pi / 2,
                            endAngle: .pi * 2 - .pi / 2,
                            clockwise: true)
    }

    // MARK: - init
    public convenience init(frame: CGRect, buttonColor: UIColor) {
        self.init(frame: frame)
        self.buttonColor = buttonColor
    }

    // MARK: - Override
    override open var isHighlighted: Bool {
        didSet {

            if isHighlighted && !isSelected {
                isSelected = true
                animateCircleLayer(animatinglayer: circleLayer, toPath: pressedCirclePath.cgPath)
            }

            if !isHighlighted {
                isSelected = false
                animateCircleLayer(animatinglayer: circleLayer, toPath: circlePath.cgPath)
            }
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        if arcLayer.superlayer != layer {
            layer.addSublayer(arcLayer)
        } else {
            arcLayer.path = arcPath.cgPath
            arcLayer.lineWidth = arcWidth
        }

        if circleLayer.superlayer != layer {
            layer.addSublayer(circleLayer)
        }
    }

    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setTitle("", for: UIControl.State.normal)
    }
}
