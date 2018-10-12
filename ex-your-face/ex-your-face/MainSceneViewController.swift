//
//  MainSceneViewController.swift
//  ex-your-face
//
//  Created by Fredrik Stålnacke on 2018-10-12.
//  Copyright © 2018 Omegapoint. All rights reserved.
//

import Foundation

import UIKit
import AVFoundation

class MainSceneViewController: UIViewController {
    var gameTimer: Timer!
    var secondsRemaining = 5
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    
    override func viewDidLoad() {
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSecondsRemaining), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        gameTimer.invalidate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) else {
            fatalError("No front facing camera found")
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            
            stillImageOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
        
        
    }
    
    func setupLivePreview() {
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.connection?.videoOrientation = .portrait
        previewView.layer.addSublayer(videoPreviewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
            self.captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.previewView.bounds
            }
        }
        
    }
    
    @objc func updateSecondsRemaining() {
        if let label = timeRemainingLabel {
            secondsRemaining -= 1
            if secondsRemaining < 0 {
                performSegue(withIdentifier: "gameOverSegue", sender: nil)
            }
            else {
                label.text = "\(secondsRemaining)"
            }
        }
        
    }
    
}
