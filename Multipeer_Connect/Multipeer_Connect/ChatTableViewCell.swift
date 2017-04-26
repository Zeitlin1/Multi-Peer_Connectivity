//
//  ChatTableViewCell.swift
//  Multipeer_Connect
//
//  Created by Anthony on 4/23/17.
//  Copyright © 2017 Anthony. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userNameText: UILabel!
    
    @IBOutlet weak var chatMssgText: UILabel!
    
    @IBOutlet weak var chatDateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
