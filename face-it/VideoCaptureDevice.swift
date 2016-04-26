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
        
        AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).forEach { videoDevice in
            if (videoDevice.position == AVCaptureDevicePosition.Front) {
                device = videoDevice as? AVCaptureDevice
            }
        }
        
        if (nil == device) {
            device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        }
        
        return device!
    }
}