//
//  FaceDetector.swift
//  face-it
//
//  Created by Derek Andre on 4/22/16.
//  Copyright © 2016 Derek Andre. All rights reserved.
//

import Foundation
import CoreImage
import AVFoundation

class FaceDetector {
    var detector: CIDetector?
    var options: [String : AnyObject]?
    var context: CIContext?
    
    init() {
        context = CIContext()
        
        options = [String : AnyObject]()
        options![CIDetectorAccuracy] = CIDetectorAccuracyLow as AnyObject
        
        detector = CIDetector(ofType: CIDetectorTypeFace, context: context!, options: options!)
    }
    
    func getFacialFeaturesFromImage(_ image: CIImage, options: [String : AnyObject]) -> [CIFeature] {
        return self.detector!.features(in: image, options: options)
    }
}
