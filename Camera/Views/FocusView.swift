//
//  FocusView.swift
//  ArtCamera
//
//  Created by Won on 06/01/2019.
//  Copyright © 1019 WON. All rights reserved.
//

import UIKit

class FocusView: UIView {

    private let topLine = UIView()
    private let bottomLine = UIView()
    private let leftLine = UIView()
    private let rightLine = UIView()

    private let topCenterLine = UIView()
    private let bottomCenterLine = UIView()
    private let leftCenterLine = UIView()
    private let rightCenterLine = UIView()

    private var lines: [UIView] {
        return [topCenterLine, bottomCenterLine, leftCenterLine, rightCenterLine, topLine, bottomLine, leftLine, rightLine]
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    convenience init() {
        self.init(frame: .zero)
        frame.size = CGSize(width: 90, height: 90)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
    }

    private func configureSubviews() {
        isUserInteractionEnabled = false
        lines.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.backgroundColor = .clear
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            topCenterLine.widthAnchor.constraint(equalToConstant: 1),
            topCenterLine.heightAnchor.constraint(equalToConstant: 7),
            topCenterLine.topAnchor.constraint(equalTo: topLine.bottomAnchor),
            topCenterLine.centerXAnchor.constraint(equalTo: centerXAnchor),

            bottomCenterLine.widthAnchor.constraint(equalToConstant: 1),
            bottomCenterLine.heightAnchor.constraint(equalToConstant: 7),
            bottomCenterLine.bottomAnchor.constraint(equalTo: bottomLine.topAnchor),
            bottomCenterLine.centerXAnchor.constraint(equalTo: centerXAnchor),

            leftCenterLine.widthAnchor.constraint(equalToConstant: 7),
            leftCenterLine.heightAnchor.constraint(equalToConstant: 1),
            leftCenterLine.leftAnchor.constraint(equalTo: leftLine.rightAnchor),
            leftCenterLine.centerYAnchor.constraint(equalTo: centerYAnchor),

            rightCenterLine.widthAnchor.constraint(equalToConstant: 7),
            rightCenterLine.heightAnchor.constraint(equalToConstant: 1),
            rightCenterLine.rightAnchor.constraint(equalTo: rightLine.leftAnchor),
            rightCenterLine.centerYAnchor.constraint(equalTo: centerYAnchor)])

        NSLayoutConstraint.activate([
            topLine.heightAnchor.constraint(equalToConstant: 1),
            topLine.topAnchor.constraint(equalTo: topAnchor),
            topLine.leftAnchor.constraint(equalTo: leftAnchor),
            topLine.rightAnchor.constraint(equalTo: rightAnchor),

            bottomLine.heightAnchor.constraint(equalToConstant: 1),
            bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomLine.leftAnchor.constraint(equalTo: leftAnchor),
            bottomLine.rightAnchor.constraint(equalTo: rightAnchor),

            leftLine.widthAnchor.constraint(equalToConstant: 1),
            leftLine.leftAnchor.constraint(equalTo: leftAnchor),
            leftLine.topAnchor.constraint(equalTo: topLine.bottomAnchor),
            leftLine.bottomAnchor.constraint(equalTo: bottomLine.topAnchor),

            rightLine.widthAnchor.constraint(equalToConstant: 1),
            rightLine.rightAnchor.constraint(equalTo: rightAnchor),
            rightLine.topAnchor.constraint(equalTo: topLine.bottomAnchor),
            rightLine.bottomAnchor.constraint(equalTo: bottomLine.topAnchor)])

    }

    var dismissTimer: Timer?

    func focus(point: CGPoint, completion: (() -> Void)? = nil) {
        dismissTimer?.invalidate()
        dismissTimer = nil

        center = point

        isHidden = false

        let one = UIColor(red: 0, green: 162 / 255, blue: 1, alpha: 1).withAlphaComponent(0.7)
        lines.forEach { $0.backgroundColor = one }

        let two = UIColor(red: 0, green: 162 / 255, blue: 1, alpha: 1).withAlphaComponent(1)
        UIView.animate(withDuration: 0.2, delay: 0, options: [.autoreverse, .repeat], animations: { [weak self] in
            self?.lines.forEach { $0.backgroundColor = two }
        })

        dismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] timer in
            if timer.isValid {
                self?.lines.map { $0.layer }.forEach { $0.removeAllAnimations() }
                self?.lines.forEach { $0.backgroundColor = .clear }
            }
            completion?()
        }
    }
}
