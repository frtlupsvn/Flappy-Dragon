//
//  GameScene.swift
//  FlappyBird
//
//  Created by Zoom NGUYEN on 01/10/2015.
//  Copyright (c) 2015 ZoomCanCode. All rights reserved.
//

import UIKit
import SpriteKit

extension SKNode {
    class func unarchiveFromFile(file : String) -> SKNode? {
        
        let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks")
        
        let sceneData: NSData?
        do {
            sceneData = try NSData(contentsOfFile: path!, options: .DataReadingMappedIfSafe)
        } catch _ {
            sceneData = nil
        }
        let archiver = NSKeyedUnarchiver(forReadingWithData: sceneData!)
        
        archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
        let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
        archiver.finishDecoding()
        return scene
    }
}

class GameViewController: UIViewController,GameScenePlayDelegate {

    @IBOutlet weak var lblHighestScore: UILabel!
    @IBOutlet weak var viewScoreBoard: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load highest Score
        if ((NSUserDefaults.standardUserDefaults().objectForKey("highestScore")) != nil){
            
            self.lblHighestScore.text = (String) (NSUserDefaults.standardUserDefaults().objectForKey("highestScore") as! NSInteger)
            
        } else{
            
            NSUserDefaults.standardUserDefaults().setObject(0, forKey: "highestScore")
            NSUserDefaults.standardUserDefaults().synchronize()
            self.lblHighestScore.text = (String) (NSUserDefaults.standardUserDefaults().objectForKey("highestScore") as! NSInteger)
            
        }
        
        //

        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            // Configure the view.
            let skView = self.view as! SKView
            skView.showsFPS = false
            skView.showsNodeCount = false
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            skView.presentScene(scene)
            scene.scoreDelegate = self
            
            
        }
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func updateHighestScore(score: NSInteger) {
        
        var highestScore = NSUserDefaults.standardUserDefaults().objectForKey("highestScore") as! NSInteger
        
        if (score > highestScore){
            
            NSUserDefaults.standardUserDefaults().setObject(score, forKey: "highestScore")
            NSUserDefaults.standardUserDefaults().synchronize()
            self.lblHighestScore.text = (String) (NSUserDefaults.standardUserDefaults().objectForKey("highestScore") as! NSInteger)
            
        }
        
    }
    
    func gameStarted(){
       self.viewScoreBoard.hidden = true
    }
    
    func gameOver(){
        self.viewScoreBoard.hidden = false
    }
    
}
