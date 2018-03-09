//
//  Player.swift
//  SlimeSoccerSwift
//
//  Created by Daniel Almeida on 09/03/2018.
//  Copyright © 2018 Coletiv. All rights reserved.
//

import Cocoa

class Player: Object {
  
  var isJumping = false
  var isMovingRight = false
  var isMovingLeft = false
  var remoteControlled = true
  
  var id: String
  var name: String
  
  var score = 0
  
  init(withId id: String, name: String) {
    self.id = id
    self.name = name
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
