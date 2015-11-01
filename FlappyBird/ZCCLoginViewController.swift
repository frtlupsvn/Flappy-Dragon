//
//  ZCCLoginViewController.swift
//  FlappyBird
//
//  Created by Zoom Nguyen on 11/1/15.
//  Copyright © 2015 ZoomCanCode.com. All rights reserved.
//

import UIKit
import Parse
import ParseFacebookUtilsV4

class ZCCLoginViewController: UIViewController {
    @IBOutlet weak var btnFacebook: UIButton!
    @IBOutlet weak var lblFacebookName: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if ((PFUser.currentUser()) == nil){
            // Show Message
            // User must login facebook to continue playing game
            showPopUp()
        }else {
            updateFacebookStatus()
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        //Check User login facebook
        if ((PFUser.currentUser()) == nil){
            btnFacebook .setImage(UIImage(named: "facebookBtn.png"), forState: .Normal)
            self.lblFacebookName.text = "Login Facebook"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnFacebookTapped(sender: AnyObject) {
        
        if ((PFUser.currentUser()) != nil){
            
        }else{
            let permissions = ["public_profile","email","user_friends"]
            PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) {
                (user: PFUser?, error: NSError?) -> Void in
                if let user = user {
                    if user.isNew {
                        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"name,email,picture"])
                        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                            if ((error) != nil){
                                
                            } else {
                                let userFullName = result.valueForKey("name") as? String
                                let userEmail = result.valueForKey("email") as? String
                                
                                let facebookId = result.valueForKey("id") as? String
                                let imageFile = PFFile(name: "profileImage.png", data: self.getProfPic(facebookId!)!)
                                
                                // Here I try to add the retrieved Facebook data to the PFUser object
                                user["fullname"] = userFullName
                                user.email = userEmail
                                user["facebookProfilePicture"] = imageFile
                                user.saveInBackgroundWithBlock({ (boolValue, error) -> Void in
                                    self.updateFacebookStatus()
                                })
                            }
                        })
                    } else {
                        print("User logged in through Facebook!")
                        self.updateFacebookStatus()
                    }
                } else {
                    print("Uh oh. The user cancelled the Facebook login.")
                }
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
    
    func updateFacebookStatus(){
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let currentUser = PFUser.currentUser()
            let imageFile = currentUser?.objectForKey("facebookProfilePicture")
            let imageURL = NSURL(string: (imageFile?.url)!)
            let imageData = NSData(contentsOfURL: imageURL!)
            
            dispatch_async(dispatch_get_main_queue()) {
                self.btnFacebook.layer.cornerRadius = 0.5 * self.btnFacebook.bounds.size.width
                self.btnFacebook.clipsToBounds = true
                self.btnFacebook.setImage(UIImage(data: imageData!), forState: .Normal)
                self.lblFacebookName.text = currentUser?.objectForKey("fullname") as? String
                self.getUserRecord()
                
                
            }
        }
    }

    
    func startGame(){
        self.performSegueWithIdentifier("LoginSuccess", sender: self)
    }
    
    func showPopUp(){
        let alertView = SCLAlertView()
        alertView.showInfo("Flappy Bat", subTitle: "You have to login with Facebook for play")
    }
    
    func showLoginFBSuccess(name:String){
        let alertView = SCLAlertView()
        alertView.showCloseButton = false
        alertView.addButton("Start Game") {
            self.startGame()
        }
        let highestScore = NSUserDefaults.standardUserDefaults().objectForKey("highestScore") as! NSInteger
        alertView.showSuccess("Flappy Bat", subTitle: "Hello " + name + "\n Your record:" + String(highestScore) + "\n You can start a game now !")
    }
    
    func getUserRecord(){

        var scoreUser = 0
        // get device information
        let currentUser = PFUser.currentUser()
        
        //Check this device has data exist on Parse?
        let query = PFQuery(className:"GameScore")
        query.whereKey("facebookUser", equalTo:currentUser!)
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                // The find succeeded.
                print("Successfully retrieved \(objects!.count) scores.")
                if (objects!.count == 0){
                    
                }else{
                    for object in objects! {
                        let query = PFQuery(className:"GameScore")
                        query.getObjectInBackgroundWithId(object.objectId!) {
                            (gameScore: PFObject?, error: NSError?) -> Void in
                            if error != nil {
                                print(error)
                            } else if let gameScore = gameScore {
                                scoreUser = (gameScore["score"] as? NSInteger)!
                                // Save score to local database
                                NSUserDefaults.standardUserDefaults().setObject(scoreUser, forKey: "highestScore")
                                NSUserDefaults.standardUserDefaults().synchronize()
                                
                                self.showLoginFBSuccess((currentUser?.objectForKey("fullname") as? String)!)
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


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
