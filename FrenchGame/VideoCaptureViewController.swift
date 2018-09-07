import UIKit
import Vision
import CoreMedia
import AVFoundation

class VideoCaptureViewController: UIViewController {
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var copSuccess: UIImageView!
    @IBOutlet weak var speachBubbleSuccess: UIImageView!
    @IBOutlet weak var riddleLabel: UILabel!
    
    let model = Inceptionv3()
    var player: AVAudioPlayer?
    var chapters: [Chapter]!
    var currentIndex = 0
    
    var videoCapture: VideoCapture!
    var request: VNCoreMLRequest!
    var startTimes: [CFTimeInterval] = []
    var stringToFind: String!
    var found = true {
        willSet(myNewValue) {
            if myNewValue {
                self.playSound()
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            }
        }
    }
    
    var framesDone = 0
    var frameCapturingStartTime = CACurrentMediaTime()
    let semaphore = DispatchSemaphore(value: 2)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        predictionLabel.text = ""
//        timeLabel.text = ""
        self.stringToFind = chapters[currentIndex].word
        self.riddleLabel.text = chapters[currentIndex].text
        
        setUpVision()
        setUpCamera()
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleSingleTap)))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print(#function)
    }
    
    // MARK: - Initialization
    
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 50
        videoCapture.setUp { success in
            if success {
                // Add the video preview into the UI.
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                self.videoCapture.start()
            }
        }
    }
    
    func setUpVision() {
        guard let visionModel = try? VNCoreMLModel(for: model.model) else {
            print("Error: could not create Vision model")
            return
        }
        
        request = VNCoreMLRequest(model: visionModel, completionHandler: requestDidComplete)
        //maybe here...
//        request.imageCropAndScaleOption = .scaleFit
    }
    
    
    // MARK: - UITapGesture
    
    @objc func handleSingleTap(sender:UITapGestureRecognizer){
        print("tapped")
        if found {
//            if currentIndex < chapters.count - 1 {
//                currentIndex = currentIndex + 1
//                self.stringToFind = chapters[currentIndex].word
            self.found = false
            hide()
//            }
        }
    }
    
    func unhide() {
        copSuccess.isHidden = false
        speachBubbleSuccess.isHidden = false
        riddleLabel.isHidden = false
        riddleLabel.text = chapters[currentIndex].text
    }
    
    func hide() {
        copSuccess.isHidden = true
        speachBubbleSuccess.isHidden = true
        riddleLabel.isHidden = true
    }
    
    // MARK: - UI stuff
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resizePreviewLayer()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
    
    // MARK: - Doing inference
    
    typealias Prediction = (String, Double)
    
    func predict(pixelBuffer: CVPixelBuffer) {
        // Measure how long it takes to predict a single video frame. Note that
        // predict() can be called on the next frame while the previous one is
        // still being processed. Hence the need to queue up the start times.
        startTimes.append(CACurrentMediaTime())
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
    
    func requestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNClassificationObservation] {
            
            // The observations appear to be sorted by confidence already, so we
            // take the top 5 and map them to an array of (String, Double) tuples.
            let top5 = observations.prefix(through: 4)
                .map { ($0.identifier, Double($0.confidence)) }
            
            DispatchQueue.main.async {
                self.show(results: top5)
                self.semaphore.signal()
            }
        }
    }
    
    func show(results: [Prediction]) {
        if !found {
            var s: [String] = []
            print("-------------")
            for (i, pred) in results.enumerated() {
                if (pred.0.contains(self.stringToFind)) {
                    if currentIndex + 1 < chapters.count {
                        currentIndex = currentIndex + 1
                        self.stringToFind = chapters[currentIndex].word
                        unhide()
                        found = true
                    } else {
                        self.performSegue(withIdentifier: Segues.VideoToWelcome.rawValue, sender: Optional.none)
                        found = true
                        hide()
                        return
                    }
                    break
                }
                print(String(format: "%d: %@ (%3.2f%%)", i + 1, pred.0, pred.1 * 100))
                s.append(String(format: "%d: %@ (%3.2f%%)", i + 1, pred.0, pred.1 * 100))
            }
            print("-------------")
    //        predictionLabel.text = s.joined(separator: "\n\n")
            
            _ = CACurrentMediaTime() - startTimes.remove(at: 0)
            _ = self.measureFPS()
    //        timeLabel.text = String(format: "Elapsed %.5f seconds - %.2f FPS", elapsed, fps)
        }
    }
    
    func measureFPS() -> Double {
        // Measure how many frames were actually delivered per second.
        framesDone += 1
        let frameCapturingElapsed = CACurrentMediaTime() - frameCapturingStartTime
        let currentFPSDelivered = Double(framesDone) / frameCapturingElapsed
        if frameCapturingElapsed > 1 {
            framesDone = 0
            frameCapturingStartTime = CACurrentMediaTime()
        }
        return currentFPSDelivered
    }
}

extension VideoCaptureViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        if let pixelBuffer = pixelBuffer {
            // For better throughput, perform the prediction on a background queue
            // instead of on the VideoCapture queue. We use the semaphore to block
            // the capture queue and drop frames when Core ML can't keep up.
            semaphore.wait()
            DispatchQueue.global().async {
                self.predict(pixelBuffer: pixelBuffer)
            }
        }
    }
}

extension VideoCaptureViewController {
    func playSound() {
        print("playing sound")
        
        guard let pathStr = Bundle.main.path(forResource: "success_sound_effect", ofType: "m4a") else {
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

//extension VideoCaptureViewController {
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == Segues.VideoToWelcome.rawValue {
////            let welcomeVC = segue.destination as! WelcomeViewController
//        }
//    }
//}
