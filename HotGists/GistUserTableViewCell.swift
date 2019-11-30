//
//  GistUserTableViewCell.swift
//  HotGists
//
//  Created by William SUN on 28/11/2019.
//  Copyright © 2019 William SUN. All rights reserved.
//

import UIKit

final class GistUserTableViewCell: UITableViewCell {

    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var gistCountLabel: UILabel!
    @IBOutlet weak var userDetailLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
