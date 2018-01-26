//
//  KeyboardUtility.swift
//  Ketch-up
//
//  Created by André Silva on 30/03/2017.
//  Copyright © 2017 Catech Labs. All rights reserved.
//

import UIKit

class KeyboardUtility: NSObject {
  
  @IBOutlet weak var scrollView: UIScrollView?
  
  @IBAction func dismissKeyboard(_ sender: AnyObject) {
    if let textField: UITextField = sender as? UITextField {
      textField.endEditing(true)
    }
  }
  
  deinit {
    removeKeyboardNotifications()
  }
  
  override func awakeFromNib() {
    addKeyboardNotifications()
  }
  
}

// MARK: - Keyboard

extension KeyboardUtility {
  
  func addKeyboardNotifications() {
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
  }
  
  func removeKeyboardNotifications() {
    NotificationCenter.default.removeObserver(self)
  }
  
  func keyboardWillShow(sender: NSNotification) {
    guard
      let scrollView = scrollView,
      let info = sender.userInfo,
      let size = info[UIKeyboardFrameEndUserInfoKey] as? CGRect else { return }
    
    let keyboardExtraPadding = CGFloat(20.0)
    let contentInsets = UIEdgeInsetsMake(0, 0, size.height + keyboardExtraPadding, 0)
    scrollView.contentInset = contentInsets
    scrollView.scrollIndicatorInsets = contentInsets
  }
  
  func keyboardWillHide(sender: NSNotification) {
    guard let scrollView = scrollView else { return }
    
    let insets = UIEdgeInsets.zero
    scrollView.contentInset = insets
    scrollView.scrollIndicatorInsets = insets
  }
  
}
