//
//  GameScene.swift
//  SlimeSoccerSwift
//
//  Created by Andre Silva on 02/02/2018.
//  Copyright © 2018 Coletiv. All rights reserved.
//

import SpriteKit
import GameplayKit

enum Key: UInt16 {
  
  // Arrows
  case UP = 126
  case DOWN = 125
  case LEFT = 123
  case RIGHT = 124
  
  // Keys
  case W = 13
  case S = 1
  case A = 0
  case D = 2
  
  // Other
  case ENTER = 36
}

class Object {
  
  var sprite: SKSpriteNode? {
    didSet {
      originalPosition = sprite?.position
    }
  }
  var originalPosition: CGPoint?
  
  func resetPosition() {
    sprite?.position = originalPosition ?? CGPoint.zero
    sprite?.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
  }
  
}

class Player: Object {
  
  var isJumping = false
  var isMovingRight = false
  var isMovingLeft = false
  var remoteControlled = false
  
  var id: String
  
  var score = 0

  init(with id: String) {
    self.id = id
  }
  
  func reset() {
    resetPosition()
    
    isJumping = false
    isMovingRight = false
    isMovingLeft = false
    
    score = 0
  }
  
  func moveRight() {
    let rightVector = CGVector(dx: 3000, dy: 0)
    sprite?.physicsBody?.applyForce(rightVector)
  }
  
  func moveLeft() {
    let leftVector = CGVector(dx: -3000, dy: 0)
    sprite?.physicsBody?.applyForce(leftVector)
  }
  
  func jump() {
    if sprite?.position.y ?? 0 > -200 {
      isJumping = false
    } else {
      let jumpVector = CGVector(dx: 0, dy: 7000)
      sprite?.physicsBody?.applyForce(jumpVector)
    }
  }
  
  func update() {
    
    // Called before each frame is rendered
    if isJumping {
      jump()
    }
    
    if isMovingRight {
      moveRight()
    }
    
    if isMovingLeft {
      moveLeft()
    }
  }
}

class GameScene: SKScene {
  
  var entities = [GKEntity]()
  var graphs = [String : GKGraph]()
  
  var player1: Player?
  var player2: Player?
  var ball: Object?
  
  var scoreLabel: SKLabelNode?
  
  override func sceneDidLoad() {
    
    player1 = Player(with: "1")
    player1?.sprite = childNode(withName: "RedSlime") as? SKSpriteNode
    
    player2 = Player(with: "2")
    player2?.sprite = childNode(withName: "BlueSlime") as? SKSpriteNode
    
    ball = Object()
    ball?.sprite = childNode(withName: "Ball") as? SKSpriteNode
    
    scoreLabel = childNode(withName: "ScoreLabel") as? SKLabelNode
    
    WebSocket.instance.setUp(with: "http://192.168.1.168:4000/socket/websocket", authenticationPayload: nil)
    WebSocket.instance.connect(with: { [weak self] in
      
      guard
        let weakSelf = self
        else { return }
      
      WebSocket.instance.joinChannel(with: "game:slimeSoccer",
                                     payload: ["email":"email@email.com"],
                                     channelEventListeners: weakSelf.channelListeners(),
                                     onJoinSuccess: { (payload) in },
                                     onJoinError: { (payload) in })
    })
    
    let isPlayer1 = false
    if isPlayer1 {
      player1?.remoteControlled = true
      player2?.remoteControlled = false
    } else {
      player1?.remoteControlled = false
      player2?.remoteControlled = true
    }
  }
  
  func channelListeners() -> [WebSocket.ChannelEventListener] {
    
    return [(("playerAction"), { [weak self] response in
      
      guard
        let weakSelf = self,
        let id = response.payload["player"] as? String,
        let right = response.payload["right"] as? Bool,
        let left = response.payload["left"] as? Bool,
        let jump = response.payload["jump"] as? Bool,
        let x = response.payload["x"] as? CGFloat,
        let y = response.payload["y"] as? CGFloat
        else { return }
      
      let player = weakSelf.remotePlayer()
      
      //own messages will be discarded
      if player.id != id { return }
      
      player.isJumping = jump
      player.isMovingLeft = left
      player.isMovingRight = right
      player.sprite?.position.x = x
      player.sprite?.position.y = y
    })]
  }
  
  func remotePlayer() -> Player {
    
    return (player1?.remoteControlled == true ? player1 : player2)!
  }
  
  func resetScene() {
    ball?.resetPosition()
    player1?.reset()
    player2?.reset()
  }
  
  func goal() {
    ball?.resetPosition()
    player1?.resetPosition()
    player2?.resetPosition()
  }
  
  func sendActions(with player: Player) {
    
    // SEND MESSAGE
    WebSocket.instance.sendMessage(with: "game:slimeSoccer",
                                   event: "playerAction",
                                   payload: [
                                             "player" : player.id,
                                             "jump": player.isJumping,
                                             "left": player.isMovingLeft,
                                             "right": player.isMovingRight,
                                             "x": player.sprite?.position.x as Any,
                                             "y": player.sprite?.position.y as Any],
                                   onSuccess: { (message) in },
                                   onError: { (reason) in })
  }
  
  func player1Moves(with move: Bool, event: NSEvent) {
    
    guard let key = Key(rawValue: event.keyCode) else { return }
    switch key {
    case .W:
      player1?.isJumping = move
    case .A:
      player1?.isMovingLeft = move
    case .D:
      player1?.isMovingRight = move
    case .ENTER:
      resetScene()
    default: break
    }
  }
  
  func player2Moves(with move: Bool, event: NSEvent) {
    
    guard let key = Key(rawValue: event.keyCode) else { return }
    switch key {
    case .UP:
      player2?.isJumping = move
    case .LEFT:
      player2?.isMovingLeft = move
    case .RIGHT:
      player2?.isMovingRight = move
    case .ENTER:
      resetScene()
    default: break
    }
  }
  
  override func keyUp(with event: NSEvent) {
    
    let player = remotePlayer()
    
    if (player.id == player1?.id) {
      player2Moves(with: false, event: event)
    } else {
      player1Moves(with: false, event: event)
    }
    
  }
  
  override func keyDown(with event: NSEvent) {
    
    let player = remotePlayer()
    
    if (player.id == player1?.id) {
      player2Moves(with: true, event: event)
    } else {
      player1Moves(with: true, event: event)
    }
    
  }
  
  override func update(_ currentTime: TimeInterval) {
    
    if !self.player1!.remoteControlled {
      self.sendActions(with: self.player1!)
    }
    if !self.player2!.remoteControlled {
      self.sendActions(with: self.player2!)
    }
    
    player1?.update()
    player2?.update()
    
    if let ballSpritePosition = ball?.sprite?.position {
      
      let x = ballSpritePosition.x
      let y = ballSpritePosition.y
      
      if x < -480 && y < -155 {
        player2?.score += 1
        goal()
      } else if x > 480 && y < -155 {
        player1?.score += 1
        goal()
      }
      
      if let score1 = player1?.score,
        let score2 = player2?.score {
        scoreLabel?.text = "\(score1) - \(score2)"
      }
    }
  }
  
}
