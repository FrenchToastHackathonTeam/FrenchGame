//
//  WelcomeViewController.swift
//  FrenchGame
//
//  Created by Ido Ben-Natan on 9/6/18.
//

import UIKit

class WelcomeViewController: UIViewController {
    
    @IBOutlet weak var riddleLabel: UILabel!
    var chapters: [Chapter]!
    var intro: [String]!
    var introIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad!!!!")
        riddleLabel.text = intro[introIndex]
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        if intro.count - 1 == introIndex {
            self.performSegue(withIdentifier: Segues.WelcomeToVideo.rawValue, sender: Optional.none)
            return
        }
        
        introIndex = introIndex + 1
        riddleLabel.text = intro[introIndex]
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("welcome segue")
        if segue.identifier == Segues.WelcomeToVideo.rawValue {
            let videoCaptureViewController = segue.destination as! VideoCaptureViewController
            videoCaptureViewController.chapters = self.chapters
        }
    }

}
