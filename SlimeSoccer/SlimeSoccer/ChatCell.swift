//
//  ChatCell.swift
//  SlimeSoccer
//
//  Created by Andre Silva on 19/01/2018.
//  Copyright © 2018 Coletiv. All rights reserved.
//

import UIKit
import SwiftPhoenixClient

class ChatCell: UITableViewCell {
  static let reusableIdentifier = "ChatCell"
  
  // MARK: - IBOutlet
  
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var messageLabel: UILabel!
  
  // MARK: Configuration
  
  func configure(withMessage message: [String: Any]) {
    nameLabel.text = message["name"] as? String
    messageLabel.text = message["message"] as? String
  }
  
}
