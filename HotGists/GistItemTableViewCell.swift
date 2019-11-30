//
//  GistItemTableViewCell.swift
//  HotGists
//
//  Created by William SUN on 29/11/2019.
//  Copyright © 2019 William SUN. All rights reserved.
//

import UIKit

class GistItemTableViewCell: UITableViewCell {
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
