//
//  LookForBarcodes.swift
//  BarcodeScanner
//
//  Created by Zheng on 2/3/21.
//

import Vision
import UIKit
import AVFoundation

extension ViewController {
    func lookForBarcodes(in pixelBuffer: CVPixelBuffer) {
        
        busyPerformingVisionRequest = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let width = ciImage.extent.width
            let height = ciImage.extent.height
            
            self.aspectRatioWidthOverHeight = height / width /// opposite, because the pixelbuffer is given to us sideways
            
            self.imageSize = CGSize(width: height, height: width)
            
            let request = VNDetectBarcodesRequest { request, error in
                /// this function will be called when the Vision request finishes
                self.resultClassificationTracker(request: request, error: error)
            }
            
            /// It needs to be .right because the pixelbuffer is given to us sideways
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
            
            do {
                try imageRequestHandler.perform([request])
            } catch let error {
                print("Error: \(error)")
            }
        }
        
    }
    
    func resultClassificationTracker(request: VNRequest?, error: Error?) {
        busyPerformingVisionRequest = false
        
        if let results = request?.results {
            if let observation = results.first as? VNBarcodeObservation {
                
                var x = observation.boundingBox.origin.x
                var y = 1 - observation.boundingBox.origin.y
                var height = CGFloat(0) /// ignore the bounding height
                var width = observation.boundingBox.width
                
                /// we're going to do some converting
                let convertedOriginalWidthOfBigImage = aspectRatioWidthOverHeight * deviceSize.height
                let offsetWidth = convertedOriginalWidthOfBigImage - deviceSize.width
                
                /// The pixelbuffer that we got Vision to process is bigger then the device's screen, so we need to adjust it
                let offHalf = offsetWidth / 2
                
                width *= convertedOriginalWidthOfBigImage
                height = width * (CGFloat(9) / CGFloat(16))
                x *= convertedOriginalWidthOfBigImage
                x -= offHalf
                y *= deviceSize.height
                y -= height
                
                let convertedRect = CGRect(x: x, y: y, width: width, height: height)
                
                DispatchQueue.main.async {
                    self.drawTrackingView(at: convertedRect)
                }
                
            }
        }
    }
}
