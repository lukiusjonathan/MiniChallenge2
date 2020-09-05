//
//  newestCollVCell.swift
//  diskusiSekolah
//
//  Created by Daniel Anadi Bagaskara on 08/05/20.
//  Copyright © 2020 Daniel Anadi Bagaskara. All rights reserved.
//

import UIKit

class newestCollVCell: UICollectionViewCell {
    
    @IBOutlet weak var lblTopic: UILabel!
    @IBOutlet weak var lblSubject: UILabel!
    
    override func awakeFromNib() {
        lblTopic.numberOfLines = 3
        lblTopic.sizeToFit()
    }
}

