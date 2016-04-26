//
//  VideoCapture.swift
//  face-it
//
//  Created by Derek Andre on 4/21/16.
//  Copyright © 2016 Derek Andre. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import CoreMotion
import ImageIO

class VideoCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var isCapturing: Bool = false
    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var input: AVCaptureInput?
    var preview: CALayer?
    var faceDetector: FaceDetector?
    var dataOutput: AVCaptureVideoDataOutput?
    var dataOutputQueue: dispatch_queue_t?
    var previewView: UIView?
    
    enum VideoCaptureError: ErrorType {
        case SessionPresetNotAvailable
        case InputDeviceNotAvailable
        case InputCouldNotBeAddedToSession
        case DataOutputCouldNotBeAddedToSession
    }
    
    override init() {
        super.init()
        
        device = VideoCaptureDevice.create()
        
        faceDetector = FaceDetector()
    }
    
    private func setSessionPreset() throws {
        if (session!.canSetSessionPreset(AVCaptureSessionPreset640x480)) {
            session!.sessionPreset = AVCaptureSessionPreset640x480
        }
        else {
            throw VideoCaptureError.SessionPresetNotAvailable
        }
    }
    
    private func setDeviceInput() throws {
        do {
            self.input = try AVCaptureDeviceInput(device: self.device)
        }
        catch {
            throw VideoCaptureError.InputDeviceNotAvailable
        }
    }
    
    private func addInputToSession() throws {
        if (session!.canAddInput(self.input)) {
            session!.addInput(self.input)
        }
        else {
            throw VideoCaptureError.InputCouldNotBeAddedToSession
        }
    }
    
    private func addPreviewToView(view: UIView) {
        self.preview = AVCaptureVideoPreviewLayer(session: session!)
        self.preview!.frame = view.bounds
        
        view.layer.addSublayer(self.preview!)
    }
    
    private func stopSession() {
        if let runningSession = session {
            runningSession.stopRunning()
        }
    }
    
    private func removePreviewFromView() {
        if let previewLayer = preview {
            previewLayer.removeFromSuperlayer()
        }
    }
    
    private func setDataOutput() {
        if (nil == self.dataOutput) {
            self.dataOutput = AVCaptureVideoDataOutput()
            
            var videoSettings = [NSObject : AnyObject]()
            videoSettings[kCVPixelBufferPixelFormatTypeKey] = Int(CInt(kCVPixelFormatType_32BGRA))
            
            self.dataOutput!.videoSettings = videoSettings
            self.dataOutput!.alwaysDiscardsLateVideoFrames = true
            
            self.dataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL)
            
            self.dataOutput!.setSampleBufferDelegate(self, queue: self.dataOutputQueue!)
        }
    }
    
    private func addDataOutputToSession() throws {
        if (self.session!.canAddOutput(self.dataOutput!)) {
            self.session!.addOutput(self.dataOutput!)
        }
        else {
            throw VideoCaptureError.DataOutputCouldNotBeAddedToSession
        }
    }
    
    private func getImageFromBuffer(buffer: CMSampleBuffer) -> CIImage {
        let pixelBuffer = CMSampleBufferGetImageBuffer(buffer)
        
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, buffer, kCMAttachmentMode_ShouldPropagate)
      
        let image = CIImage(CVPixelBuffer: pixelBuffer!, options: attachments as? [String : AnyObject])
        
        return image
    }
    
    private func getFacialFeaturesFromImage(image: CIImage) -> [CIFeature] {
        let imageOptions = [CIDetectorImageOrientation : 6]
        
        return self.faceDetector!.getFacialFeaturesFromImage(image, options: imageOptions)
    }
    
    private func transformFacialFeaturePosition(xPosition: CGFloat, yPosition: CGFloat, videoRect: CGRect, previewRect: CGRect, isMirrored: Bool) -> CGRect {
    
        var featureRect = CGRect(origin: CGPoint(x: xPosition, y: yPosition), size: CGSize(width: 0, height: 0))
        let widthScale = previewRect.size.width / videoRect.size.height
        let heightScale = previewRect.size.height / videoRect.size.width
        
        let transform = isMirrored ? CGAffineTransformMake(0, heightScale, -widthScale, 0, previewRect.size.width, 0) :
            CGAffineTransformMake(0, heightScale, widthScale, 0, 0, 0)
        
        featureRect = CGRectApplyAffineTransform(featureRect, transform)
        
        featureRect = CGRectOffset(featureRect, previewRect.origin.x, previewRect.origin.y)
        
        return featureRect
    }

    
    private func getFeatureView() -> UIView {
        let heartView = NSBundle.mainBundle().loadNibNamed("HeartView", owner: self, options: nil)[0] as? UIView
        heartView!.backgroundColor = UIColor.clearColor()
        heartView!.layer.removeAllAnimations()
        heartView!.tag = 1001
        
        return heartView!
    }
    
    private func removeFeatureViews() {
        if let pv = previewView {
            for view in pv.subviews {
                if (view.tag == 1001) {
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    private func addEyeViewToPreview(xPosition: CGFloat, yPosition: CGFloat, cleanAperture: CGRect) {
        let eyeView = getFeatureView()
        let isMirrored = preview!.contentsAreFlipped()
        let previewBox = preview!.frame
        
        previewView!.addSubview(eyeView)
        
        var eyeFrame = transformFacialFeaturePosition(xPosition, yPosition: yPosition, videoRect: cleanAperture, previewRect: previewBox, isMirrored: isMirrored)
        
        eyeFrame.origin.x -= 37
        eyeFrame.origin.y -= 37
        
        eyeView.frame = eyeFrame
    }
    
    private func alterPreview(features: [CIFeature], cleanAperture: CGRect) {
        removeFeatureViews()
        
        if (features.count == 0 || cleanAperture == CGRect.zero || !isCapturing) {
            return
        }
        
        for feature in features {
            let faceFeature = feature as? CIFaceFeature
            
            if (faceFeature!.hasLeftEyePosition) {
                
                addEyeViewToPreview(faceFeature!.leftEyePosition.x, yPosition: faceFeature!.leftEyePosition.y, cleanAperture: cleanAperture)
            }
            
            if (faceFeature!.hasRightEyePosition) {
                
                addEyeViewToPreview(faceFeature!.rightEyePosition.x, yPosition: faceFeature!.rightEyePosition.y, cleanAperture: cleanAperture)
            }
            
        }
        
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        let image = getImageFromBuffer(sampleBuffer)
        
        let features = getFacialFeaturesFromImage(image)
        
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        
        let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription!, false)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.alterPreview(features, cleanAperture: cleanAperture)
        }
    }
    
    func startCapturing(previewView: UIView) throws {
        isCapturing = true
        
        self.previewView = previewView
        
        self.session = AVCaptureSession()
        
        try setSessionPreset()
        
        try setDeviceInput()
        
        try addInputToSession()
        
        setDataOutput()
        
        try addDataOutputToSession()
        
        addPreviewToView(self.previewView!)
        
        session!.startRunning()
    }
    
    func stopCapturing() {
        isCapturing = false
        
        stopSession()
        
        removePreviewFromView()
        
        removeFeatureViews()
        
        preview = nil
        dataOutput = nil
        dataOutputQueue = nil
        session = nil
        previewView = nil
    }
}







