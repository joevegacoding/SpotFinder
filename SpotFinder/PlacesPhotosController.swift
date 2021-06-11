//
//  PlacesPhotosController.swift
//  SpotFinder
//
//  Created by Joseph Bouhanef on 2021-06-10.
//

import Foundation
import UIKit
import LBTATools


class PhotoCell: LBTAListCell<UIImage> {
    
    override var item: UIImage! {
        didSet {
            imageView.image = item
        }
    }
    
    let imageView = UIImageView(image: nil, contentMode: .scaleAspectFill)
    let nameLabel = UILabel(text: "Name", font: UIFont(name: "AvenirNext-Bold", size: 20), textColor: .label, textAlignment: .left, numberOfLines: 0)
    
    override func setupViews() {
        
        addSubview(imageView)
        imageView.layer.cornerRadius = 15
        imageView.fillSuperview()
        
    }
}

class PlacePhotosController: LBTAListController<PhotoCell, UIImage>, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width - 50, height: 700)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Photos"
    }
}
