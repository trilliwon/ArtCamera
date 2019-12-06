//
//  GridView.swift
//  Camera
//
//  Created by WON on 08/10/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import UIKit

protocol GridDrawable {
    var gridView: GridView? { get }

    func hideGridView()
    func showGridView()
}

extension GridDrawable where Self: UIView {

    func hideGridView() {
        gridView?.isHidden = true
    }

    func showGridView() {
        gridView?.isHidden = false
    }
}

class GridView: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        configureSubviews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
    }

    func configureSubviews() {
        subviews.forEach { $0.removeFromSuperview() }

        isUserInteractionEnabled = false
        let stroke: CGFloat = 0.5

        let line1 = UIView()
        let line2 = UIView()
        let line3 = UIView()
        let line4 = UIView()

        addSubview(line1)
        addSubview(line2)
        addSubview(line3)
        addSubview(line4)

        translatesAutoresizingMaskIntoConstraints = false

        line1.translatesAutoresizingMaskIntoConstraints = false
        line2.translatesAutoresizingMaskIntoConstraints = false
        line3.translatesAutoresizingMaskIntoConstraints = false
        line4.translatesAutoresizingMaskIntoConstraints = false

        line1.leftAnchor.constraint(equalTo: leftAnchor, constant: frame.width / 3.0).isActive = true
        line1.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        line1.widthAnchor.constraint(equalToConstant: stroke).isActive = true

        line2.leftAnchor.constraint(equalTo: leftAnchor, constant: (frame.width / 3.0) * 2).isActive = true
        line2.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        line2.widthAnchor.constraint(equalToConstant: stroke).isActive = true

        line3.topAnchor.constraint(equalTo: topAnchor, constant: frame.height / 3.0).isActive = true
        line3.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        line3.heightAnchor.constraint(equalToConstant: stroke).isActive = true

        line4.topAnchor.constraint(equalTo: topAnchor, constant: (frame.height / 3.0) * 2).isActive = true
        line4.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        line4.heightAnchor.constraint(equalToConstant: stroke).isActive = true

        let color = UIColor.white.withAlphaComponent(0.6)
        line1.backgroundColor = color
        line2.backgroundColor = color
        line3.backgroundColor = color
        line4.backgroundColor = color

        applyShadow(to: line1)
        applyShadow(to: line2)
        applyShadow(to: line3)
        applyShadow(to: line4)
    }

    func applyShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 2
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
}
