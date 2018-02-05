//
//  ViewController.swift
//  SlimeSoccer
//
//  Created by Andre Silva on 06/01/2018.
//  Copyright © 2018 Coletiv. All rights reserved.
//

import UIKit
import SwiftPhoenixClient

class ViewController: UIViewController {
  
  // MARK: - Properties
  
  var socket: Socket? = nil
  
  // MARK: - IBOutlets
  
  @IBOutlet weak var tableView: UITableView!
  var messages: [[String: Any]] = []
  
  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var messageTextField: UITextField!

}


// MARK: - View Cycle

extension ViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Setup Chat
    setupChat()
  }
  
}

// MARK: - Table View
// MARK: Data Source

extension ViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return messages.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let identifier = ChatCell.reusableIdentifier
    let reusableCell = tableView.dequeueReusableCell(withIdentifier: identifier,
                                                     for: indexPath)
    
    guard let cell = reusableCell as? ChatCell else { return reusableCell }
    
    cell.configure(withMessage: messages[indexPath.item])
    
    return cell
  }
  
}


// MARK: - Chat Connection

extension ViewController {
  
  fileprivate func setupChat() {
    
    let chatServer = "192.168.1.75:4000"
    socket = Socket(domainAndPort: chatServer, path: "socket", transport: "websocket")
    
    let joinMessage = Message(message: ["": ""])
    socket?.join(topic: "chat", message: joinMessage, callback: { object in
      guard let channel = object as? Channel else { return }
      
      channel.on(event: "new_message", callback: { object in
        guard
          let message = object as? Message,
          let dictionary = message.message as? [String: Any] else { return }
        
        self.messages.append(dictionary)
        let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
        self.tableView.insertRows(at: [indexPath], with: .fade)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
      })
    })
    
  }
  
}


// MARK: - Actions

extension ViewController {
  
  @IBAction func setName(_ textField: UITextField) {
    textField.endEditing(true)
  }
  
  @IBAction func sendMessage(_ textField: UITextField) {
    textField.endEditing(true)
    
    let name = nameTextField.text ?? "Annonymous"
    guard let message = messageTextField.text else { return }
    
    print(name)
    print(message)
    
    let socketMessage = Message(message: ["name": name, "message": message])
    
    let payload = Payload(topic: "chat", event: "new_message", message: socketMessage)
    socket?.send(data: payload)
  }
  
}
