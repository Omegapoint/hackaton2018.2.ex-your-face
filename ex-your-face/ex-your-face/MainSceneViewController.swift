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
import ARKit
import Vision

class MainSceneViewController: UIViewController {
    var gameTimer: Timer!
    var scanTimer: Timer?
    
    var secondsRemaining = 5
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSecondsRemaining), userInfo: nil, repeats: true)
        
        sceneView.session.run(configuration)
        scanTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(scanForFaces), userInfo: nil, repeats: true)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        gameTimer.invalidate()
        
        scanTimer?.invalidate()
        sceneView.session.pause()
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
    
    @objc func scanForFaces() {
        
        //get the captured image of the ARSession's current frame
        guard let capturedImage = sceneView.session.currentFrame?.capturedImage else { return }
        
        let image = CIImage.init(cvPixelBuffer: capturedImage)
        
        let detectFaceRequest = VNDetectFaceRectanglesRequest { (request, error) in
            
            print(request.results)
        }
        
        let imageOrientation: CGImagePropertyOrientation = .up
        
        DispatchQueue.global().async {
            try? VNImageRequestHandler(ciImage: image, orientation: imageOrientation).perform([detectFaceRequest])
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
    
    
    private func faceFrame(from boundingBox: CGRect) -> CGRect {
        
        //translate camera frame to frame inside the ARSKView
        let origin = CGPoint(x: boundingBox.minX * sceneView.bounds.width, y: (1 - boundingBox.maxY) * sceneView.bounds.height)
        let size = CGSize(width: boundingBox.width * sceneView.bounds.width, height: boundingBox.height * sceneView.bounds.height)
        
        return CGRect(origin: origin, size: size)
    }
    
}


extension MainSceneViewController: ARSCNViewDelegate {
    //implement ARSCNViewDelegate functions for things like error tracking
}
