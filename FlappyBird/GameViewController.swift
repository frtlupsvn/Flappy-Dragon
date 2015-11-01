//
//  GameScene.swift
//  FlappyBird
//
//  Created by Zoom NGUYEN on 01/10/2015.
//  Copyright (c) 2015 ZoomCanCode. All rights reserved.
//

import UIKit
import SpriteKit
import Social
import iAd
import Parse
import ParseFacebookUtilsV4

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

class GameViewController: UIViewController,GameScenePlayDelegate,ADBannerViewDelegate {
    
    //MARK: - IBOulet
    @IBOutlet weak var lblHighestScore: UILabel!
    @IBOutlet weak var lblHighestScoreBoard: UILabel!
    @IBOutlet weak var lblHighScoreBoard: UILabel!
    @IBOutlet weak var viewScoreBoard: UIView!
    @IBOutlet weak var imgMedal: UIImageView!
    @IBOutlet weak var btnShareFacebook: UIButton!
    @IBOutlet weak var lblFacebookName: UILabel!
    
    
    
    //MARK: - IBAction
    @IBAction func btnShareFacebookTapped(sender: AnyObject) {
        shareButtonPress()
    }
    
    //MARK: - Parameters
    var bannerView: ADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bannerView = ADBannerView(adType: .Banner)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.delegate = self
        bannerView.hidden = true
        view.addSubview(bannerView)
        
        let viewsDictionary = ["bannerView": bannerView]
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[bannerView]|", options: [], metrics: nil, views: viewsDictionary))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[bannerView]|", options: [], metrics: nil, views: viewsDictionary))
        
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
        
        //Facebook
        if ((PFUser.currentUser()) != nil){
            self.updateFacebookStatus()
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
    
    // MARK: - BUTTON TAPPED
    func shareButtonPress() {
        
        let postPhrase = "New high score"
        
        //Generate the screenshot
        let image = capture()
        let shareToFacebook = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
        
        shareToFacebook.setInitialText(postPhrase)
        shareToFacebook.addImage(image)
        presentViewController(shareToFacebook, animated: true, completion: nil)
    }
    
    func capture() -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(self.viewScoreBoard.frame.size, self.viewScoreBoard.opaque, 0.0)
        self.viewScoreBoard.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    @IBOutlet weak var btnFacebook: UIButton!
    
    @IBAction func btnFacebookTapped(sender: AnyObject) {
        
        if ((PFUser.currentUser()) != nil){
            self.showLogoutPopup()
        }
}

    func showLogoutPopup(){
        let alertView = SCLAlertView()
        
        alertView.addButton("Log Out") {
            PFUser.logOutInBackgroundWithBlock({ (error) -> Void in
                if (error == nil){
                    print("user log out")
                    self.navigationController?.popToRootViewControllerAnimated(true)
                    
                }
            })
        }
        alertView.showWarning("Flappy Bat", subTitle: "Do you want to log out ?")
    }
    
    func updateFacebookStatus(){
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let currentUser = PFUser.currentUser()
            let imageFile = currentUser?.objectForKey("facebookProfilePicture")
            let imageURL = NSURL(string: (imageFile?.url)!)
            let imageData = NSData(contentsOfURL: imageURL!)
            
            dispatch_async(dispatch_get_main_queue()) {
                self.btnFacebook.setImage(UIImage(data: imageData!), forState: .Normal)
                self.btnFacebook.layer.cornerRadius = 0.5 * self.btnFacebook.bounds.size.width
                self.btnFacebook.clipsToBounds = true
                self.lblFacebookName.text = currentUser?.objectForKey("fullname") as? String
            }
        }
    }
    
    // MARK: - GameScene Delegate
    
    func updateHighestScore(score: NSInteger) {
        
        var highestScore = NSUserDefaults.standardUserDefaults().objectForKey("highestScore") as! NSInteger
        
        self.lblHighScoreBoard.text = String(score)
        
        if (score > highestScore){
            
            highestScore = score
        }
        
        self.lblHighestScore.text = String(highestScore)
        self.lblHighestScoreBoard.text = String(highestScore)
        
        //Medel Bronze
        if (score < 20 ){
            self.imgMedal.image = UIImage(named: "bronze.png")
        }
        
        //Medal Silver
        if (score > 20 ){
            self.imgMedal.image = UIImage(named: "silver.png")
        }
        
        //Medal Gold
        if (score > 50 ){
            self.imgMedal.image = UIImage(named: "gold.png")
        }
    }
    
    
    func gameStarted(){
        viewScoreBoard.hidden = true
        btnShareFacebook.hidden = true
    }
    
    func gameOver(score: NSInteger){
        self.viewScoreBoard.hidden = false
        self.btnShareFacebook.hidden = false
        
        
        // Send highest score to parse.com
        let highestScore = NSUserDefaults.standardUserDefaults().objectForKey("highestScore") as! NSInteger
        if (score > highestScore){
            
            // Save score to local database
            NSUserDefaults.standardUserDefaults().setObject(score, forKey: "highestScore")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            // save record to PARSE
            saveRecordToParse(score)
            
        }
        
    }
    
    //MARK: - iAd Delegate
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        bannerView.hidden = false
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        bannerView.hidden = true
    }
    
    
    //MARK: - PARSE
    func saveRecordToParse(score:NSInteger){
        
        func createNewGameScore(score:NSInteger,device:PFInstallation){
            
            let gameScore = PFObject(className:"GameScore")
            gameScore["score"] = score
            gameScore["device"] = device
            if ((PFUser.currentUser()) != nil){
                gameScore["facebookUser"] = PFUser.currentUser()

            }
            gameScore.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    // The object has been saved.
                } else {
                    // There was a problem, check error.description
                }
            }
        }
        
        
        // get device information
        let installation = PFInstallation.currentInstallation()
        
        //Check this device has data exist on Parse?
        let query = PFQuery(className:"GameScore")
        query.whereKey("device", equalTo:installation)
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                // The find succeeded.
                print("Successfully retrieved \(objects!.count) scores.")
                if (objects!.count == 0){
                    // create new 
                    createNewGameScore(score, device: installation)
                    
                }else{
                    //update
                        for object in objects! {
                            let query = PFQuery(className:"GameScore")
                            query.getObjectInBackgroundWithId(object.objectId!) {
                                (gameScore: PFObject?, error: NSError?) -> Void in
                                if error != nil {
                                    print(error)
                                } else if let gameScore = gameScore {
                                    gameScore["score"] = score
                                    gameScore.saveInBackground()
                                }
                            }
                        }
                }
                
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.userInfo)")
            }
        }
        
    }
    
    func getProfPic(fid: String) -> NSData? {
        if (fid != "") {
            let imgURLString = "http://graph.facebook.com/" + fid + "/picture?type=large" //type=normal
            let imgURL = NSURL(string: imgURLString)
            let imageData = NSData(contentsOfURL: imgURL!)
            return imageData
        }
        return nil
    }
}
