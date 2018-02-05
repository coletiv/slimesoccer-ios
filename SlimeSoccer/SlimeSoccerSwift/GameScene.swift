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
  
  var score = 0

  func reset() {
    resetPosition()
    
    isJumping = false
    isMovingRight = false
    isMovingLeft = false
    
    score = 0
  }
  
  func update() {
    
    // Called before each frame is rendered
    if isJumping {
      if sprite?.position.y ?? 0 > -200 {
        isJumping = false
      } else {
        let jumpVector = CGVector(dx: 0, dy: 7000)
        sprite?.physicsBody?.applyForce(jumpVector)
      }
    }
    
    if isMovingRight {
      let jumpVector = CGVector(dx: 3000, dy: 0)
      sprite?.physicsBody?.applyForce(jumpVector)
    }
    if isMovingLeft {
      let jumpVector = CGVector(dx: -3000, dy: 0)
      sprite?.physicsBody?.applyForce(jumpVector)
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
    
    player1 = Player()
    player1?.sprite = childNode(withName: "RedSlime") as? SKSpriteNode
    
    player2 = Player()
    player2?.sprite = childNode(withName: "BlueSlime") as? SKSpriteNode
    
    ball = Object()
    ball?.sprite = childNode(withName: "Ball") as? SKSpriteNode
    
    scoreLabel = childNode(withName: "ScoreLabel") as? SKLabelNode
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
  
  override func keyUp(with event: NSEvent) {
    guard let key = Key(rawValue: event.keyCode) else { return }
    switch key {
    case .UP:
      player2?.isJumping = false
    case .LEFT:
      player2?.isMovingLeft = false
    case .RIGHT:
      player2?.isMovingRight = false
    case .W:
      player1?.isJumping = false
    case .A:
      player1?.isMovingLeft = false
    case .D:
      player1?.isMovingRight = false
    case .ENTER:
      resetScene()
    default: break
    }
  }
  
  override func keyDown(with event: NSEvent) {
    guard let key = Key(rawValue: event.keyCode) else { return }
    switch key {
    case .UP:
      player2?.isJumping = true
    case .LEFT:
      player2?.isMovingLeft = true
    case .RIGHT:
      player2?.isMovingRight = true
    case .W:
      player1?.isJumping = true
    case .A:
      player1?.isMovingLeft = true
    case .D:
      player1?.isMovingRight = true
    default: break
    }
  }
  
  
  override func update(_ currentTime: TimeInterval) {
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
