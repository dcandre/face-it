//
//  VideoCaptureDevice.swift
//  face-it
//
//  Created by Derek Andre on 4/25/16.
//  Copyright © 2016 Derek Andre. All rights reserved.
//

import Foundation
import AVFoundation

class VideoCaptureDevice {
    
    static func create() -> AVCaptureDevice {
        var device: AVCaptureDevice?
        
        AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo).forEach { videoDevice in
            if ((videoDevice as AnyObject).position == AVCaptureDevicePosition.front) {
                device = videoDevice as? AVCaptureDevice
            }
        }
        
        if (nil == device) {
            device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        
        return device!
    }
}
