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

class GameScene: SKScene {
  
  // MARK: Properties
  
  var entities = [GKEntity]()
  var graphs = [String : GKGraph]()
  
  var player1 = Player(withId: "1", name: "RedSlime")
  var player2 = Player(withId: "2", name: "BlueSlime")
  var ball = Object()
  
  var scoreLabel: SKLabelNode?
  
  // MARK: Scene Cycle
  
  override func sceneDidLoad() {
    
    player1.sprite = childNode(withName: "RedSlime") as? SKSpriteNode
    player2.sprite = childNode(withName: "BlueSlime") as? SKSpriteNode
    
    ball.sprite = childNode(withName: "Ball") as? SKSpriteNode
    
    scoreLabel = childNode(withName: "ScoreLabel") as? SKLabelNode
    
    connectSocket()
  }
  
  override func update(_ currentTime: TimeInterval) {
    
    let players = localPlayers()
    
    for player in players {
      self.sendActions(with: player)
    }
    
    player1.update()
    player2.update()
    
    if let ballSpritePosition = ball.sprite?.position {
      
      let x = ballSpritePosition.x
      let y = ballSpritePosition.y
      
      if x < -480 && y < -155 {
        player2.score += 1
        goal()
      } else if x > 480 && y < -155 {
        player1.score += 1
        goal()
      }
      
      let score1 = player1.score
      let score2 = player2.score
      scoreLabel?.text = "\(score1) - \(score2)"
    }
  }
}

// MARK: Game Logic

extension GameScene {
  
  func remotePlayers() -> [Player] {
    return [player1, player2].filter {
      $0.remoteControlled == true
    }
  }
  
  func localPlayers() -> [Player] {
    return [player1, player2].filter {
      $0.remoteControlled != true
    }
  }
  
  func resetScene() {
    ball.resetPosition()
    player1.reset()
    player2.reset()
  }
  
  func goal() {
    ball.resetPosition()
    player1.resetPosition()
    player2.resetPosition()
  }
  
}

// MARK: Sockets

extension GameScene {
  
  func connectSocket() {
    WebSocket.instance.setup(with: "http://192.168.1.146:4000/socket/websocket")
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
      
      // Move remote players
      let players = weakSelf.remotePlayers()
      
      for player in players {
        if player.id == id {
          player.isJumping = jump
          player.isMovingLeft = left
          player.isMovingRight = right
          player.sprite?.position.x = x
          player.sprite?.position.y = y
        }
      }

    })]
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
  
  
}

// MARK: UI Actions

extension GameScene {

  func playerHasChanged(_ playerId: String) {
    
    if playerId == "Both" {
      player1.remoteControlled = false
      player2.remoteControlled = false
    } else {
      player1.remoteControlled = !(player1.name == playerId)
      player2.remoteControlled = !(player2.name == playerId)
    }
  }
  
}

// MARK: Player moves

extension GameScene {
  
  func player1Moves(with move: Bool, event: NSEvent) {
    
    guard let key = Key(rawValue: event.keyCode) else { return }
    switch key {
    case .W:
      player1.isJumping = move
    case .A:
      player1.isMovingLeft = move
    case .D:
      player1.isMovingRight = move
    case .ENTER:
      resetScene()
    default: break
    }
  }
  
  func player2Moves(with move: Bool, event: NSEvent) {
    
    guard let key = Key(rawValue: event.keyCode) else { return }
    switch key {
    case .UP:
      player2.isJumping = move
    case .LEFT:
      player2.isMovingLeft = move
    case .RIGHT:
      player2.isMovingRight = move
    case .ENTER:
      resetScene()
    default: break
    }
  }
  
  private func movePlayer(with event: NSEvent, move: Bool) {
    
    let players = localPlayers()
    
    for player in players {
      if (player.id == player1.id) {
        player1Moves(with: move, event: event)
      } else {
        player2Moves(with: move, event: event)
      }
    }
  }
  
  override func keyUp(with event: NSEvent) {
    movePlayer(with: event, move: false)
  }
  
  override func keyDown(with event: NSEvent) {
    movePlayer(with: event, move: true)
  }
  
}
