//
//  ViewController.swift
//  BarcodeScanner
//
//  Created by Zheng on 2/3/21.
//

import UIKit
import AVFoundation
import CoreMotion
import Vision

class ViewController: UIViewController {

    // MARK: Camera
    @IBOutlet weak var cameraView: CameraView!
    var cameraDevice: AVCaptureDevice?
    let avSession = AVCaptureSession()
    let videoDataOutput = AVCaptureVideoDataOutput()
    
    //MARK: Motion (Accelerometer and Gyroscope)
    /// motionManager will be what we'll use to get device motion
    var motionManager = CMMotionManager()
    
    /// this will be the "device’s true orientation in space" (Source: https://nshipster.com/cmdevicemotion/)
    var initialAttitude: CMAttitude?
    
    /// we'll later read these values to update the highlight's position
    var motionX = Double(0) /// aka Roll
    var motionY = Double(0) /// aka Pitch
    
    // MARK: Vision
    /// We can't have multiple Vision requests at the same time so we have this variable that keeps track if there is a request going on or not
    var busyPerformingVisionRequest = false
    
    /// We'll use this for converting the Vision coordinates (they are written like a percentage, for example 0.0123123032984% of the view's width)
    /// We must multiply what Vision returns by the device's size
    var aspectRatioWidthOverHeight: CGFloat = 0
    var deviceSize = CGSize()
    
    
    var imageSize = CGSize(width: 0, height: 0)
    
    // MARK: Drawing (The frame to put around detected barcode)
    
    /// add as subviews of this later
    @IBOutlet weak var drawingView: UIView!
    
    /// detection indicator view
    var previousTrackingView: UIView?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        /// viewDidLoad() is often too early to get the first initial attitude, so we use viewDidLayoutSubviews() instead
        if let currentAttitude = motionManager.deviceMotion?.attitude {
            /// we populate initialAttitude with the current attitude
            initialAttitude = currentAttitude
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraView.clipsToBounds = true
        
        /// This is how often we will get device motion updates
        /// 0.03 is more than often enough and is about the rate that the video frame changes
        motionManager.deviceMotionUpdateInterval = 0.03
        
        motionManager.startDeviceMotionUpdates(to: .main) {
            [weak self] (data, error) in
            guard let data = data, error == nil else {
                return
            }
            
            /// This function will be called every 0.03 seconds
            self?.updateTrackingFrames(attitude: data.attitude)
        }
        
        /// Asks for permission to use the camera
        if isAuthorized() {
            configureCamera()
        }
        
        deviceSize = view.frame.size
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    // MARK: Camera Delegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        if busyPerformingVisionRequest == false {
            lookForBarcodes(in: pixelBuffer)
        }
    }
}


extension ViewController {
    func isAuthorized() -> Bool {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video,
                                          completionHandler: { (granted:Bool) -> Void in
                if granted {
                    DispatchQueue.main.async {
                        self.configureCamera()
                    }
                }
            })
            return true
        case .authorized:
            return true
        case .denied, .restricted: return false
        @unknown default:
            fatalError()
        }
    }
    func getCamera() -> AVCaptureDevice? {
        if let cameraDevice = AVCaptureDevice.default(.builtInDualCamera,
                                                for: .video, position: .back) {
            return cameraDevice
        } else if let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video, position: .back) {
            return cameraDevice
        } else {
            print("Missing Camera.")
            return nil
        }
    }
    
    func configureCamera() {
        cameraView.session = avSession
        if let cameraDevice = getCamera() {
            do {
                let captureDeviceInput = try AVCaptureDeviceInput(device: cameraDevice)
                if avSession.canAddInput(captureDeviceInput) {
                    avSession.addInput(captureDeviceInput)
                }
            }
            catch {
                print("Error occured \(error)")
                return
            }
            avSession.sessionPreset = .photo
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Buffer Queue", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil))
            if avSession.canAddOutput(videoDataOutput) {
                avSession.addOutput(videoDataOutput)
            }
            cameraView.videoPreviewLayer.videoGravity = .resizeAspectFill
            let newBounds = view.layer.bounds
            cameraView.videoPreviewLayer.bounds = newBounds
            cameraView.videoPreviewLayer.position = CGPoint(x: newBounds.midX, y: newBounds.midY);
            avSession.startRunning()
        }
    }
}
