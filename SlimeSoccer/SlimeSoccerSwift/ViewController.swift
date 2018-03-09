//
//  ViewController.swift
//  SlimeSoccerSwift
//
//  Created by Andre Silva on 02/02/2018.
//  Copyright © 2018 Coletiv. All rights reserved.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {
  
  // MARK: IBOutlet
  
  @IBOutlet var skView: SKView!
  @IBOutlet weak var playerSelectionComboBox: NSComboBox!
  
  // MARK: Properties
  
  var gameSceneNode: GameScene?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    playerSelectionComboBox.selectItem(withObjectValue: "Spectator")
    
    // Load 'GameScene.sks' as a GKScene. This provides gameplay related content
    // including entities and graphs.
    if let scene = GKScene(fileNamed: "GameScene") {
      
      // Get the SKScene from the loaded GKScene
      if let sceneNode = scene.rootNode as! GameScene? {
        
        gameSceneNode = sceneNode
        
        // Copy gameplay related content over to the scene
        sceneNode.entities = scene.entities
        sceneNode.graphs = scene.graphs
        
        // Set the scale mode to scale to fit the window
        sceneNode.scaleMode = .aspectFill
        
        // Present the scene
        if let view = self.skView {
          view.presentScene(sceneNode)
          
          view.ignoresSiblingOrder = true
          
          view.showsFPS = true
          view.showsNodeCount = true
        }
      }
    }
   
  }
  
  @IBAction func changePlayerComboBox(_ sender: NSComboBox) {
    
    let itemIndex = sender.indexOfSelectedItem
    guard let item = sender.itemObjectValue(at: itemIndex) as? String else {
      return
    }
    
    gameSceneNode?.playerHasChanged(item)
  }
  
}

