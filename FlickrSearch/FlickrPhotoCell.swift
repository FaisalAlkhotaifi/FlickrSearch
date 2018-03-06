//
//  FlickrPhotoCell.swift
//  FlickrSearch
//
//  Created by Faisal Alkhotaifi on 3/4/18.
//  Copyright © 2018 Faisal Alkhotaifi. All rights reserved.
//

import UIKit

class FlickrPhotoCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var themeColor: UIColor?
    
    // MARK: - Properties
    override var isSelected: Bool{
        didSet {
            imageView.layer.borderWidth = isSelected ? 10 : 0
        }
    }
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            themeColor = appDelegate.themeColor
        } else {
            themeColor = UIColor(red: 0.01, green: 0.41, blue: 0.22, alpha: 1.0)
        }
        
        imageView.layer.borderColor = themeColor?.cgColor
        isSelected = false
    }
}
