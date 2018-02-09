//
//  WebSocketManager.swift
//  Ketch-up-restaurant
//
//  Created by Daniel Almeida on 26/01/2018.
//  Copyright © 2018 Catech. All rights reserved.
//

import Birdsong

class WebSocketManager {
  
  var socket: Socket?
  var channels: [String : Channel]?
  
  // Singleton
  static let shared = WebSocketManager()
  
  func connect(to channelString: String) {
    
    let url = "http://192.168.1.129:4000/socket/websocket"
    socket = Socket(url: url)
    
    socket?.onConnect = { [weak self] in
      guard
        let weakSelf = self,
        let socket = weakSelf.socket
        else { return }
      
      let channel: Channel = socket.channel(channelString, payload: ["email": "atua@mae.pt"])
      
      channel.on(channelString, callback: weakSelf.receivedMessage)
      
      channel.join()?.receive("ok", callback: { payload in
        print("Successfully joined: \(channel.topic)")
      })
      
      //      channel.send("status", payload: ["message": "Hello!", "name": "Tyron"])?
      //        .receive("ok", callback: { response in
      //          print("Sent a message!")
      //        })
      //        .receive("error", callback: { reason in
      //          print("Message didn’t send: \(reason)")
      //        })
      
    }
    
    socket?.onDisconnect = { error in
      print(error?.localizedDescription ?? "")
    }
    
    socket?.connect()
  }
  
  func receivedMessage(message: Response) {
    print("Successfully joined Lobby 1: \(message)")
  }
  
  func sendMessage(with channel: String) {
    
    socket?.channels[channel]?.send("setstatus", payload: ["status": true])?
      .receive("ok", callback: { response in
        print("Sent a message!")
      })
      .receive("error", callback: { reason in
        print("Message didn’t send: \(reason)")
      })
  }
  
  deinit {
    socket?.disconnect()
  }
  
}
