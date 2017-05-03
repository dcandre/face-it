//
//  VideoCaptureController.swift
//  face-it
//
//  Created by Derek Andre on 4/21/16.
//  Copyright © 2016 Derek Andre. All rights reserved.
//

import Foundation
import UIKit

class VideoCaptureController: UIViewController {
    var isCapturing : Bool = false;
    
    var videoCapture: VideoCapture?
    
    override func viewDidLoad() {
        videoCapture = VideoCapture()
    }
    
    override func didReceiveMemoryWarning() {
        stopCapturing()
    }
    
    func startCapturing() -> Bool {
        do {
            try videoCapture!.startCapturing(self.view)
            return true;
        }
        catch {
            // Error
            return false;
        }
    }
    
    func stopCapturing() {
        videoCapture!.stopCapturing()
    }
    
    @IBAction func startButton_touchedUpInside(_ sender: Any) {
        if !self.isCapturing{
            if self.startCapturing(){
                self.isCapturing = true;
                let button = sender as! UIButton
                button.setTitle("Stop", for: .normal)
            }
        }
        else{
            self.stopCapturing();
            self.isCapturing = false;
            let button = sender as! UIButton
            button.setTitle("Start", for: .normal)
        }
    }
}
