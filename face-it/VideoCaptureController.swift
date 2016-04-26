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
    var videoCapture: VideoCapture?
    
    override func viewDidLoad() {
        videoCapture = VideoCapture()
    }
    
    override func didReceiveMemoryWarning() {
        stopCapturing()
    }
    
    func startCapturing() {
        do {
            try videoCapture!.startCapturing(self.view)
        }
        catch {
            // Error
        }
    }
    
    func stopCapturing() {
        videoCapture!.stopCapturing()
    }
    
    @IBAction func touchDown(sender: AnyObject) {
        let button = sender as! UIButton
        button.setTitle("Stop", forState: UIControlState.Normal)
        
        startCapturing()
    }
    
    @IBAction func touchUp(sender: AnyObject) {
        let button = sender as! UIButton
        button.setTitle("Start", forState: UIControlState.Normal)
        
        stopCapturing()
    }
    
}