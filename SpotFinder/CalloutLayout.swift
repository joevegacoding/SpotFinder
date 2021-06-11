//
//  CalloutLayout.swift
//  SpotFinder
//
//  Created by Joseph Bouhanef on 2021-06-10.
//

import Foundation
import UIKit

class CalloutCntainer: UIView {
    
    let imageView = UIImageView(image: nil, contentMode: .scaleAspectFill)
    let nameLabel = UILabel(font: UIFont(name: "AvenirNext-DemiBold", size: 18), textColor: .systemBackground, textAlignment: .center)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .systemBackground
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 10
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemPurple.withAlphaComponent(0.5).cgColor
        setupShadow(opacity: 0.5, radius: 8, offset: .zero, color: .darkGray)
        
        //loads the spinner when loading an image inside the annotation
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .darkGray
        spinner.startAnimating()
        addSubview(spinner)
        spinner.fillSuperview()
        
        addSubview(imageView)
        
        imageView.fillSuperview()
        imageView.layer.cornerRadius = 10
        
        let labelContainer = UIView(backgroundColor: .label.withAlphaComponent(0.5))
        labelContainer.stack(nameLabel)
        labelContainer.layer.cornerRadius = 10
        labelContainer.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        stack(UIView(), labelContainer.withHeight(40))
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
