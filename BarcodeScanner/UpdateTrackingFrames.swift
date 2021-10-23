//
//  UpdateTrackingFrames.swift
//  BarcodeScanner
//
//  Created by Zheng on 2/3/21.
//

import UIKit
import CoreMotion

extension ViewController {
    func updateTrackingFrames(attitude: CMAttitude) {
        /// initialAttitude is an optional that points to the reference frame that the device started at
        /// we set this when the device lays out it's subviews on the first launch
        if let initAttitude = initialAttitude {
            
            /// We can now translate the current attitude to the reference frame
            attitude.multiply(byInverseOf: initAttitude)
            
            /// Roll is the movement of the phone left and right, Pitch is forwards and backwards
            let rollValue = attitude.roll.radiansToDegrees
            let pitchValue = attitude.pitch.radiansToDegrees
            
            /// This is a magic number, but for simplicity, we won't do any advanced trigonometry -- also, 3 works pretty well
            let conversion = Double(3)
            
            /// Here, we figure out how much the values changed by comparing against the previous values (motionX and motionY)
            let differenceInX = (rollValue - motionX) * conversion
            let differenceInY = (pitchValue - motionY) * conversion
            
            /// Now we adjust the tracking view's position
            if let previousTrackingView = previousTrackingView {
                previousTrackingView.frame.origin.x += CGFloat(differenceInX)
                previousTrackingView.frame.origin.y += CGFloat(differenceInY)
            }
            
            /// finally, we put the new attitude values into motionX and motionY so we can compare against them in 0.03 seconds (the next time this function is called)
            motionX = rollValue
            motionY = pitchValue
        }
    }
    
    func drawTrackingView(at rect: CGRect) {
        if let previousTrackingView = previousTrackingView { /// already drawn one previously, just change the frame now
            UIView.animate(withDuration: 0.8) {
                previousTrackingView.frame = rect
            }
            
        } else { /// add it as a subview
            let trackingView = UIView(frame: rect)
            drawingView.addSubview(trackingView)
            trackingView.backgroundColor = UIColor.orange.withAlphaComponent(0.2)
            trackingView.layer.borderWidth = 3
            trackingView.layer.borderColor = UIColor.orange.cgColor
            
            
            previousTrackingView = trackingView
        }
    }
}
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
