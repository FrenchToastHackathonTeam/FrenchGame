//
//  ViewController.swift
//  ARDemo1
//
//  Created by Itai Bennatan on 9/6/18.
//  Copyright © 2018 Itai Bennatan. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation


class ARViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var buttonOne : UIButton!
    @IBOutlet var buttonTwo : UIButton!
    @IBOutlet var buttonThree : UIButton!
    
    var player: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //Create TapGesture Recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        
        //Add recognizer to sceneview
        sceneView.addGestureRecognizer(tap)
        
        buttonOne.isHidden = true
        buttonTwo.isHidden = true
        buttonThree.isHidden = true
        
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    //Method called when tap
    @objc func handleTap(rec: UITapGestureRecognizer){
        
        if rec.state == .ended {
            let location: CGPoint = rec.location(in: sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
            if !hits.isEmpty{
                print("tapped!!!!")
                
                _ = hits.first?.node
                
                buttonOne.isHidden = false
                buttonTwo.isHidden = false
                buttonThree.isHidden = false
                //                let path = Bundle.main.path(forResource: "elephant4.mp3", ofType:nil)!
                //                let url = URL(fileURLWithPath: path)
                
                //                do {
                //                    elephantSoundEffect = try AVAudioPlayer(contentsOf: url)
                //                    elephantSoundEffect?.play()
                //                } catch {
                //                    // couldn't load file :(
                //                    print("could not load avaudioplayer")
                //                }
                self.playSound("Hello")
            }
        }
    }
    
    @IBAction func buttonClicked(_ sender: UIButton?) {
        let buttonText = sender?.titleLabel!.text
        if(buttonText?.range(of: "chien") != nil){
            print("YES")
            self.playSound("Hello Dog")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                // your code here
                self.playSound("bark")
                
                let alert = UIAlertController(title: "כל הכבוד", message: "הצלחת במשימה", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "המשך", style: UIAlertActionStyle.default, handler: { (alertAction) in
                    self.performSegue(withIdentifier: Segues.ARtoMenu.rawValue, sender: Optional.none)
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
            
            //self.playSound("bark")
        }
            
        else {
            if(buttonText?.range(of: "chat") != nil){
                self.playSound("Hello Cat")
            }
            else if(buttonText?.range(of: "camion") != nil)
            {
                self.playSound("Hello Truck")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                // your code here
                self.playSound("dog_growl")
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

extension ARViewController {
    func playSound(_ filename : String) {
        print("playing sound")
        
        guard let pathStr = Bundle.main.path(forResource: filename, ofType: "mp3") else {
            print("not found success_sound_effect.m4a")
            return
            
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: pathStr), fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = player else { return }
            
            print("playing!!!!")
            player.play()
            
        } catch let error {
            print("errorr!!!!!")
            print(error.localizedDescription)
        }
    }
}
