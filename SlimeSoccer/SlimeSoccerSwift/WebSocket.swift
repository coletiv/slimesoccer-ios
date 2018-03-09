//
//  WebSocket.swift
//  Phoenix
//
//  Created by Daniel Almeida on 05/02/2018.
//  Copyright © 2018 Catech Labs. All rights reserved.
//

import Birdsong

public class WebSocket: NSObject {
  
  // MARK: - Web Socket
  
  public typealias ChannelEventListener = (event: String, callback: (Response) -> ())
  
  // MARK: Constants
  public static var setStatusEvent = "setStatus"
  public static var restaurantChannel = "restaurant:"
  
  // MARK: Vars
  var host: String = "http://localhost:4000/socket/websocket"
  public var socket: Socket?
  public var channels: [String : Channel] = [:]
  public var retryOnDisconnect = true
  
  // Singleton
  public static let instance = WebSocket()
  
  // MARK: Methods
  
  public func setUp(with webSocketHost: String?, authenticationPayload: [String: String]?) {
    
    if let host = webSocketHost {
      self.host = host
    }
    
    socket = Socket(url: self.host, params: authenticationPayload)
  }
  
  public func connect(with onConnect: @escaping () -> (), retryOnDisconnect: Bool = true) {
    
    guard let socket = self.socket else { return }
    
    self.retryOnDisconnect = retryOnDisconnect
    
    socket.onConnect = onConnect
    socket.onDisconnect = { [weak self] error in
      
      guard let weakSelf = self else { return }
      
      //try to reconnect after a delay
      if weakSelf.retryOnDisconnect == true {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          socket.connect()
        }
      }
    }
    
    if !socket.isConnected {
      socket.connect()
    }
  }
  
  public func disconnect() {
    
    guard let socket = self.socket else { return }
    
    retryOnDisconnect = false
    socket.disconnect()
  }
  
  deinit {
    socket?.disconnect()
  }
  
}


// MARK: - Channel methods

extension WebSocket {
  
  public func joinChannel(with channelId: String,
                          payload: Socket.Payload,
                          channelEventListeners: [ChannelEventListener],
                          onJoinSuccess: @escaping (Socket.Payload) -> (),
                          onJoinError: @escaping (Socket.Payload) -> ()) {
    
    guard let socket = self.socket else { return }
    
    //if the channel was already added and has joined/joining state do nothing
    if let channel = channels[channelId] {
      if channel.state == .Joined || channel.state == .Joining {
        return
      }
    }
    
    let joinChannelBlock: () -> () = { [weak self] in
      
      guard
        let weakSelf = self
        else { return }
      
      let channel: Channel = socket.channel(channelId, payload: payload)
      
      //map listeners to channel
      for listener in channelEventListeners {
        channel.on(listener.event, callback: listener.callback)
      }
      
      channel.join()?
        .receive("ok", callback: onJoinSuccess)
        .receive("error", callback: onJoinError)
      
      weakSelf.channels[channelId] = channel
    }
    
    // Verify if the socket is connected and connect if not
    if !socket.isConnected {
      self.connect(with: joinChannelBlock)
    } else {
      joinChannelBlock()
    }
  }
  
  public func sendMessage(with channelId: String,
                          event: String,
                          payload: Socket.Payload,
                          onSuccess: @escaping (Socket.Payload) -> (),
                          onError: @escaping (Socket.Payload) -> ()) {
    
    guard let socket = socket else { return }
    
    if socket.isConnected {
      socket.channels[channelId]?.send(event, payload: payload)?
        .receive("ok", callback: onSuccess)
        .receive("error", callback: onError)
    } else {
      
      socket.connect()
    }
    
  }
  
  public func leaveChannel(with channelId: String) {
    
    //TODO - there's a remove method on Socket.swift
    
    guard let channel = channels[channelId] else { return }
    channel.leave()
  }
  
}


