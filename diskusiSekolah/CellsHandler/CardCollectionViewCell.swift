//
//  CardCollectionViewCell.swift
//  Carousel_Practice
//
//  Created by Alnodi Adnan on 11/05/20.
//  Copyright © 2020 Alnodi Adnan. All rights reserved.
//

import UIKit

protocol CardCollectionViewCellDelegate {
    func btnUpTapped(vote: Int, index: Int)
    func btnProfileTapped(index: Int)
}

class CardCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cardAnswer: UILabel!
    @IBOutlet weak var senderNameLabel: UILabel!
    @IBOutlet weak var senderImage: UIImageView!
    @IBOutlet weak var lblVote: UILabel!
    @IBOutlet weak var btnUpOutlet: UIButton!
    
    var delegate: CardCollectionViewCellDelegate!
    var indexPath: Int!
    var upVote: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowRadius = 6.0
        self.layer.shadowOpacity = 0.3
        self.layer.masksToBounds = false
    }
    
    @IBAction func btnUp(_ sender: Any) {
        delegate?.btnUpTapped(vote: upVote, index: indexPath)
    }
    @IBAction func btnProfile(_ sender: Any) {
        delegate.btnProfileTapped(index: indexPath)
    }
}
