//
//  topicCollVCell.swift
//  diskusiSekolah
//
//  Created by Daniel Anadi Bagaskara on 12/05/20.
//  Copyright © 2020 Daniel Anadi Bagaskara. All rights reserved.
//

import UIKit

protocol TopicCollVCellDelegate {
    func btnProfileTapped(index: Int)
}

class topicCollVCell: UICollectionViewCell {
    
    @IBOutlet weak var lblTopic: UILabel!
    @IBOutlet weak var lblSender: UILabel!
    @IBOutlet weak var imgSender: UIImageView!
    
    var delegate: TopicCollVCellDelegate!
    var indexPath: Int!
//    var labelHeight: CGFloat
    
    
    @IBAction func btnProfileTap(_ sender: Any) {
        delegate?.btnProfileTapped(index: indexPath!)
    }
    
    
    //PERUBAHAN
    lazy var width: NSLayoutConstraint = {
           let width = contentView.widthAnchor.constraint(equalToConstant: bounds.size.width)
           width.isActive = true
           return width
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.red
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        width.constant = bounds.size.width
        return contentView.systemLayoutSizeFitting(CGSize(width: targetSize.width, height: 1))
    }
    
    fileprivate func setupViews() {
        if let lastSubview = contentView.subviews.last {
            contentView.bottomAnchor.constraint(equalTo: lastSubview.bottomAnchor, constant: 10).isActive = true
        }
    }
}
