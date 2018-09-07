//
//  ViewController.swift
//  FrenchGame
//
//  Created by Ido Ben-Natan on 9/6/18.
//

import UIKit

class MenuViewController: UIViewController {
    @IBOutlet weak var pinInputField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("hello world")

        pinInputField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        if (textField.text == "1234") {
            print("transitioning")
            Chapter.getChapters(pin: 1234) { (chapters) in
                print(chapters)
                self.performSegue(withIdentifier: Segues.CodeToWelcome.rawValue, sender: chapters)
            }
        }
    }
}

extension MenuViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.CodeToWelcome.rawValue {
            print("here!!!!")
            if let chapters = sender as? Chapters {
                let welcomeViewController = segue.destination as! WelcomeViewController
                welcomeViewController.chapters = chapters.data
                welcomeViewController.intro = chapters.intro
                print("here!!!! 2222")
            }
        }
    }
}

