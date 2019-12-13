//
//  PulsingButton.swift
//  Camera
//
//  Created by WON on 08/10/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import UIKit

class PulsingButton: UIButton {

    var action: ((_ button: UIButton) -> Void)?
    var pulses = false
    private var isPulsing = false

    convenience init(title: String, pulses: Bool = false, action: ((_ button: UIButton) -> Void)? = nil) {
        self.init(frame: CGRect.zero)
        self.setTitle(title, for: [])
        self.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        self.sizeToFit()
        self.pulses = pulses
        self.action = action
        self.addTarget(self, action: #selector(handleTap), for: .primaryActionTriggered)
        startPulsing()
    }

    @objc
    func handleTap() {
        action?(self)
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                stopPulsing()
                animate(toScale: 1.4)
            } else {
                startPulsing()
                animateToDefaultScale()
            }
        }
    }

    private func animateToDefaultScale() {
        guard !isHighlighted && !pulses else { return }
        animate(toScale: 1.0)
    }

    private func animate(toScale: CGFloat) {
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                        self.transform = CGAffineTransform(scaleX: toScale, y: toScale)
        })
    }

    private func stopPulsing() {
        guard pulses else { return }

        isPulsing = false
        layer.removeAllAnimations()
    }

    private func startPulsing() {
        guard pulses && !isPulsing else { return }

        isPulsing = true

        let minScale = CGFloat(0.95)
        let maxScale = CGFloat(1.05)
        let pulseDuration = 0.5

        UIView.animate(withDuration: pulseDuration / 2.0,
                       delay: 0,
                       options: [.allowUserInteraction],
                       animations: {
                        self.transform = CGAffineTransform(scaleX: minScale, y: minScale)
        }, completion: { _ in
            UIView.animate(withDuration: pulseDuration,
                           delay: 0,
                           options: [.allowUserInteraction, .repeat, .autoreverse],
                           animations: {
                            self.transform = CGAffineTransform(scaleX: maxScale, y: maxScale)
            })
        })
    }
}
