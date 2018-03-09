//
//  WebSocket.swift
//  Phoenix
//
//  Created by Daniel Almeida on 05/02/2018.
//  Copyright © 2018 Catech Labs. All rights reserved.
//

import Birdsong

public class WebSocket: NSObject {
  
  public typealias ChannelEventListener = (event: String, callback: (Response) -> ())
  
  // MARK: Constants
  
  // Time to wait until a reconnect is performed
  fileprivate static var reconnectInterval = 0.5
  
  // MARK: Vars
  public var socket: Socket?
  private var host: String = "http://localhost:4000/socket/websocket"
  fileprivate var channels: [String : Channel] = [:]
  private var retryOnDisconnect = true
  
  // Singleton
  public static let instance = WebSocket()
  
  // MARK: Socket connection
  
  public func setup(with webSocketHost: String?, authenticationPayload: [String: String]? = nil) {
    
    if let host = webSocketHost {
      self.host = host
    }
    
    socket = Socket(url: host, params: authenticationPayload)
    socket?.enableLogging = true
  }
  
  public func connect(_ retryOnDisconnect: Bool = true) {
    
    guard let socket = socket else { return }
    
    self.retryOnDisconnect = retryOnDisconnect
    socket.connect()
  }
  
  public func connect(with onConnect: @escaping () -> (), retryOnDisconnect: Bool = true) {
    
    guard let socket = socket else { return }
    
    self.retryOnDisconnect = retryOnDisconnect
    
    socket.onConnect = onConnect
    socket.onDisconnect = {[weak self] error in
      
      guard let weakSelf = self else { return }
      weakSelf.reconnect()
    }
    
    if !socket.isConnected {
      socket.connect()
    }
  }
  
  private func reconnect() {
    
    guard let socket = socket else { return }
    
    //try to reconnect after a delay
    if retryOnDisconnect == true {
      DispatchQueue.main.asyncAfter(deadline: .now() + WebSocket.reconnectInterval) {
        socket.connect()
      }
    }
  }
  
  public func disconnect() {
    
    guard let socket = socket else { return }
    
    retryOnDisconnect = false
    socket.disconnect()
  }
  
  deinit {
    socket?.disconnect()
  }
  
}


// MARK: - Channel

extension WebSocket {
  
  public func joinChannel(with channelId: String,
                          payload: Socket.Payload,
                          channelEventListeners: [ChannelEventListener],
                          onJoinSuccess: @escaping (Socket.Payload) -> (),
                          onJoinError: @escaping (Socket.Payload) -> ()) {
    
    guard let socket = socket else { return }
    
    let joinChannelBlock: () -> () = {[weak self] in
      
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
      connect(with: joinChannelBlock)
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
      // Call error callback when the socket is not connected
      onError([:])
      socket.connect()
    }
    
  }
  
  public func leaveChannel(with channelId: String) {
    
    guard
      let channel = channels[channelId],
      let socket = socket
      else { return }
    
    socket.remove(channel)
  }
  
}

