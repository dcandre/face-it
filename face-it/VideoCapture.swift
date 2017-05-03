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
    var dataOutputQueue: DispatchQueue?
    var previewView: UIView?
    
    enum VideoCaptureError: Error {
        case sessionPresetNotAvailable
        case inputDeviceNotAvailable
        case inputCouldNotBeAddedToSession
        case dataOutputCouldNotBeAddedToSession
    }
    
    override init() {
        super.init()
        
        device = VideoCaptureDevice.create()
        
        faceDetector = FaceDetector()
    }
    
    fileprivate func setSessionPreset() throws {
        if (session!.canSetSessionPreset(AVCaptureSessionPreset640x480)) {
            session!.sessionPreset = AVCaptureSessionPreset640x480
        }
        else {
            throw VideoCaptureError.sessionPresetNotAvailable
        }
    }
    
    fileprivate func setDeviceInput() throws {
        do {
            self.input = try AVCaptureDeviceInput(device: self.device)
        }
        catch {
            throw VideoCaptureError.inputDeviceNotAvailable
        }
    }
    
    fileprivate func addInputToSession() throws {
        if (session!.canAddInput(self.input)) {
            session!.addInput(self.input)
        }
        else {
            throw VideoCaptureError.inputCouldNotBeAddedToSession
        }
    }
    
    fileprivate func addPreviewToView(_ view: UIView) {
        self.preview = AVCaptureVideoPreviewLayer(session: session!)
        self.preview!.frame = view.bounds
        
        view.layer.addSublayer(self.preview!)
    }
    
    fileprivate func stopSession() {
        if let runningSession = session {
            runningSession.stopRunning()
        }
    }
    
    fileprivate func removePreviewFromView() {
        if let previewLayer = preview {
            previewLayer.removeFromSuperlayer()
        }
    }
    
    fileprivate func setDataOutput() {
        self.dataOutput = AVCaptureVideoDataOutput()
        
        var videoSettings = [AnyHashable: Any]()
        videoSettings[kCVPixelBufferPixelFormatTypeKey as AnyHashable] = Int(CInt(kCVPixelFormatType_32BGRA))
        
        self.dataOutput!.videoSettings = videoSettings
        self.dataOutput!.alwaysDiscardsLateVideoFrames = true
        
        self.dataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue", attributes: [])
        
        self.dataOutput!.setSampleBufferDelegate(self, queue: self.dataOutputQueue!)
    }
    
    fileprivate func addDataOutputToSession() throws {
        if (self.session!.canAddOutput(self.dataOutput!)) {
            self.session!.addOutput(self.dataOutput!)
        }
        else {
            throw VideoCaptureError.dataOutputCouldNotBeAddedToSession
        }
    }
    
    fileprivate func getImageFromBuffer(_ buffer: CMSampleBuffer) -> CIImage {
        let pixelBuffer = CMSampleBufferGetImageBuffer(buffer)
        
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, buffer, kCMAttachmentMode_ShouldPropagate)
      
        let image = CIImage(cvPixelBuffer: pixelBuffer!, options: attachments as? [String : AnyObject])
        
        return image
    }
    
    fileprivate func getFacialFeaturesFromImage(_ image: CIImage) -> [CIFeature] {
        let imageOptions = [CIDetectorImageOrientation : 6]
        
        return self.faceDetector!.getFacialFeaturesFromImage(image, options: imageOptions as [String : AnyObject])
    }
    
    fileprivate func transformFacialFeaturePosition(_ xPosition: CGFloat, yPosition: CGFloat, videoRect: CGRect, previewRect: CGRect, isMirrored: Bool) -> CGRect {
    
        var featureRect = CGRect(origin: CGPoint(x: xPosition, y: yPosition), size: CGSize(width: 0, height: 0))
        let widthScale = previewRect.size.width / videoRect.size.height
        let heightScale = previewRect.size.height / videoRect.size.width
        
        let transform = isMirrored ? CGAffineTransform(a: 0, b: heightScale, c: -widthScale, d: 0, tx: previewRect.size.width, ty: 0) :
            CGAffineTransform(a: 0, b: heightScale, c: widthScale, d: 0, tx: 0, ty: 0)
        
        featureRect = featureRect.applying(transform)
        
        featureRect = featureRect.offsetBy(dx: previewRect.origin.x, dy: previewRect.origin.y)
        
        return featureRect
    }

    
    fileprivate func getFeatureView() -> UIView {
        let heartView = Bundle.main.loadNibNamed("HeartView", owner: self, options: nil)?[0] as? UIView
        heartView!.backgroundColor = UIColor.clear
        heartView!.layer.removeAllAnimations()
        heartView!.tag = 1001
        
        return heartView!
    }
    
    fileprivate func removeFeatureViews() {
        if let pv = previewView {
            for view in pv.subviews {
                if (view.tag == 1001) {
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    fileprivate func addEyeViewToPreview(_ xPosition: CGFloat, yPosition: CGFloat, cleanAperture: CGRect) {
        let eyeView = getFeatureView()
        let isMirrored = preview!.contentsAreFlipped()
        let previewBox = preview!.frame
        
        previewView!.addSubview(eyeView)
        
        var eyeFrame = transformFacialFeaturePosition(xPosition, yPosition: yPosition, videoRect: cleanAperture, previewRect: previewBox, isMirrored: isMirrored)
        
        eyeFrame.origin.x -= 37
        eyeFrame.origin.y -= 37
        
        eyeView.frame = eyeFrame
    }
    
    fileprivate func alterPreview(_ features: [CIFeature], cleanAperture: CGRect) {
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
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        let image = getImageFromBuffer(sampleBuffer)
        
        let features = getFacialFeaturesFromImage(image)
        
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        
        let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription!, false)
        
        DispatchQueue.main.async {
            self.alterPreview(features, cleanAperture: cleanAperture)
        }
    }
    
    func startCapturing(_ previewView: UIView) throws {
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







