//
//  ViewController.swift
//  testCamera
//
//  Created by Jordan Kiley on 7/19/16.
//  Copyright © 2016 Jordan Kiley. All rights reserved.
//

import UIKit
import AVFoundation
import CoreGraphics
import CoreImage

class ViewController: UIViewController {
    let stillImageOutput = AVCaptureStillImageOutput()
    var imageToSave = UIImage()
    var imageLocation = CGPoint()
    lazy var cameraSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetHigh
        session.usesApplicationAudioSession = false
        return session
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        self.previewLayer =  AVCaptureVideoPreviewLayer(session: self.cameraSession)
        self.previewLayer.bounds = CGRect(x: 10, y: 10, width: self.view.bounds.width - 20, height: self.view.bounds.height - 20)
        self.previewLayer.position = CGPoint(x: CGRectGetMidX(self.view.bounds), y: CGRectGetMidY(self.view.bounds))
        // stretches to fit screen
        //        self.previewLayer.videoGravity = AVLayerVideoGravityResize
        
        let stickerLayer = CALayer(layer: self.sticker)
        
        self.previewLayer.addSublayer(stickerLayer)
        self.previewLayer.insertSublayer(stickerLayer, above: self.previewLayer)
        
        return self.previewLayer
    }()
    
    override func viewWillLayoutSubviews() {
        let orientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
        print(orientation)
        
        switch orientation {
        case .Portrait:
            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
            self.previewLayer.frame = self.view.bounds
            
            break
        case .LandscapeLeft:
            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
            self.previewLayer.frame = self.view.bounds
            
            break
        case .LandscapeRight:
            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
            self.previewLayer.frame = self.view.bounds
            break
        case .PortraitUpsideDown:
            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.PortraitUpsideDown
            self.previewLayer.frame = self.view.bounds
            break
        default:
            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
            self.previewLayer.frame = self.view.bounds
            break
        }
    }
    
    
    @IBOutlet weak var sticker: UIImageView!
    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var save: UIButton!
    @IBOutlet weak var selectSticker: UIButton!
    @IBOutlet weak var takePicture: UIButton!
    @IBOutlet weak var cancel: UIButton!
    
    @IBAction func handlePan(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translationInView(self.view)
        if let view = recognizer.view {
            view.center = CGPoint(x:view.center.x + translation.x, y: view.center.y + translation.y)
        }
        recognizer.setTranslation(CGPointZero, inView: self.view)
        self.imageLocation = CGPoint(x:view.center.x + translation.x, y: view.center.y + translation.y)
        print(self.imageLocation)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.bringSubviewToFront(self.picture)
        
        setupCameraSession()
        view.layer.addSublayer(previewLayer)
        cameraSession.startRunning()
        
        self.view.bringSubviewToFront(self.save)
        
        self.view.bringSubviewToFront(self.selectSticker)
        self.view.bringSubviewToFront(self.takePicture)
        self.view.bringSubviewToFront(self.sticker)
        
        self.save.hidden = true
        self.save.enabled = false
        
        self.cancel.hidden = true
        self.cancel.enabled = false
        
        self.takePicture.hidden = false
        self.takePicture.enabled = true
        self.takePicture.layer.cornerRadius = 0.50 * self.takePicture.bounds.size.width
        
        self.selectSticker.hidden = false
        self.selectSticker.enabled = true
        
        self.sticker.addObserver(<#T##observer: NSObject##NSObject#>, forKeyPath: <#T##String#>, options: <#T##NSKeyValueObservingOptions#>, context: <#T##UnsafeMutablePointer<Void>#>)
        //        self.imageLocation = self.sticker.center.x
        //
        //        print(self.imageLocation)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    //        let touch : UITouch =
    //    }
    func setupCameraSession() {
        if let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) as? AVCaptureDevice {
            
            do {
                let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
                
                cameraSession.beginConfiguration()
                
                if (cameraSession.canAddInput(deviceInput) == true) {
                    cameraSession.addInput(deviceInput)
                }
                
                
                let dataOutput = AVCaptureVideoDataOutput()
                dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
                dataOutput.alwaysDiscardsLateVideoFrames = true
                
                if (cameraSession.canAddOutput(dataOutput) == true) {
                    cameraSession.addOutput(dataOutput)
                }
                cameraSession.commitConfiguration()
                
                
            }
            catch let error as NSError {
                print("Sorry, \(error), \(error.localizedDescription)")
            }
            //Makes camera session's output a StillImage
            if cameraSession.canAddOutput(stillImageOutput) {
                cameraSession.addOutput(stillImageOutput)
                
            }
            
        } else {
            print("Sorry, no camera available")
        }
    }
    
    @IBAction func openPreview(sender: AnyObject) {
        self.save.hidden = false
        self.save.enabled = true
        self.view.bringSubviewToFront(save)
        
        self.selectSticker.hidden = true
        self.selectSticker.enabled = false
        
        self.cancel.hidden = false
        self.cancel.enabled = true
        self.view.bringSubviewToFront(self.cancel)
        
        self.takePicture.hidden = true
        
        self.sticker.center = self.imageLocation
        
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                if imageDataSampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    self.imageToSave = (UIImage(data: imageData))!
                }
            }
            self.sticker.center = self.imageLocation
            
        }
        self.picture.image = self.imageToSave
        self.view.bringSubviewToFront(self.sticker)
        cameraSession.stopRunning()
    }
    
    //     Saves the camera's output
    @IBAction func savePicture(sender: AnyObject) {
        self.picture.image = self.imageToSave
        //        self.view.bringSubviewToFront(sticker)
        
        let layer = UIApplication.sharedApplication().keyWindow!.layer
        self.sticker.center = self.imageLocation
        self.save.hidden = true
        self.selectSticker.hidden = true
        self.cancel.hidden = true
        let scale = UIScreen.mainScreen().scale
        
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        
        layer.renderInContext(UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        //        UIGraphicsEndImageContext()
        
        //        var image = UIImage()
        //        if let imageAsCI = CIImage(image: self.imageToSave) {
        //            if let stickerAsCI = CIImage(image: self.sticker.image!) {
        //                let picAsCI = stickerAsCI.imageByCompositingOverImage(imageAsCI)
        //                image = UIImage(CIImage: picAsCI)
        //            }
        //        }
        //Save it to the camera roll
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        self.save.hidden = false
        self.selectSticker.hidden = false
        
        viewDidLoad()
    }
    
    @IBAction func cancelPhoto(sender: AnyObject) {
        viewDidLoad()
    }
    
}

