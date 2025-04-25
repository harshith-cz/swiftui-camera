//
//  CameraManager.swift
//  cameraview
//
//  Created by Harshith on 24/04/25.
//

import SwiftUI
import UIKit
import AVFoundation

@Observable
class CameraManager: NSObject {
    var capturedImage: UIImage?
    var error: CameraError?
    
    let captureSession = AVCaptureSession()
    private var deviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    
    // Current zoom factor
    private(set) var zoomFactor: CGFloat = 1.0
    
    // Minimum and maximum zoom
    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 5.0
    
    // Check if camera is available
    var isCameraAvailable: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    // Initialize and check permissions
    func checkPermissions() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
    
    // Setup camera session
    func configure() async {
        // Avoid configuring twice
        guard !isConfigured else { return }
        
        // Check permissions
        let hasPermission = await checkPermissions()
        guard hasPermission else {
            error = .permissionDenied
            return
        }
        
        // Configure session
        captureSession.sessionPreset = .photo
        
        // Setup device input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            error = .cameraUnavailable
            return
        }
        
        do {
            // Add input
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                deviceInput = input
            }
            
            // Add output
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                photoOutput.isHighResolutionCaptureEnabled = true
                photoOutput.maxPhotoQualityPrioritization = .quality
            }
            
            // Start session on background thread
            Task.detached { [weak self] in
                self?.captureSession.startRunning()
            }
            
            isConfigured = true
        } catch {
            self.error = .setupFailed
        }
    }
    
    // Cleanup when done
    func stop() {
        guard isConfigured, captureSession.isRunning else { return }
        captureSession.stopRunning()
    }
    
    // Capture a photo
    func capturePhoto() {
        guard isConfigured, captureSession.isRunning else { return }
        
        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .quality
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // Set focus at point
    func focus(at point: CGPoint, in size: CGSize) {
        guard let device = deviceInput?.device,
              device.isFocusPointOfInterestSupported else { return }
        
        // Convert screen point to device point
        let focusPoint = CGPoint(
            x: point.y / size.height,
            y: 1.0 - point.x / size.width
        )
        
        do {
            try device.lockForConfiguration()
            device.focusPointOfInterest = focusPoint
            device.focusMode = .autoFocus
            device.exposurePointOfInterest = focusPoint
            device.exposureMode = .autoExpose
            device.unlockForConfiguration()
        } catch {
            print("Could not focus: \(error)")
        }
    }
    
    // Adjust zoom with a delta value
    func zoom(by factor: CGFloat) {
        guard let device = deviceInput?.device else { return }
        
        // Calculate new zoom factor
        let newZoomFactor = max(minZoom, min(zoomFactor * factor, maxZoom))
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = newZoomFactor
            device.unlockForConfiguration()
            zoomFactor = newZoomFactor
        } catch {
            print("Could not zoom: \(error)")
        }
    }
    
    // Reset camera zoom
    func resetZoom() {
        guard let device = deviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = 1.0
            device.unlockForConfiguration()
            zoomFactor = 1.0
        } catch {
            print("Could not reset zoom: \(error)")
        }
    }
    
    // Add new property to store screen dimensions
    private var screenSize: CGSize = UIScreen.main.bounds.size
    
    // Add new method to crop the image
    private func cropImageToPreviewAspectRatio(_ image: UIImage) -> UIImage {
        // First rotate the image to match device orientation if needed
        let imageToProcess = fixImageOrientation(image)
        let imageSize = imageToProcess.size
        
        // Get screen dimensions in portrait orientation
        let screenSize = UIScreen.main.bounds.size
        let screenAspectRatio = screenSize.width / screenSize.height
        
        // Step 1: First crop to match screen width
        var rect: CGRect
        if imageSize.width / imageSize.height > screenAspectRatio {
            // Image is wider than screen
            let targetWidth = imageSize.height * screenAspectRatio
            let x = (imageSize.width - targetWidth) / 2
            rect = CGRect(x: x, y: 0, width: targetWidth, height: imageSize.height)
        } else {
            // Image is taller than screen
            let targetHeight = imageSize.width / screenAspectRatio
            let y = (imageSize.height - targetHeight) / 2
            rect = CGRect(x: 0, y: y, width: imageSize.width, height: targetHeight)
        }
        
        guard let firstCropImage = imageToProcess.cgImage?.cropping(to: rect) else {
            return imageToProcess
        }
        
        // Step 2: Now crop to 4:3 aspect ratio
        let firstCropSize = CGSize(width: firstCropImage.width, height: firstCropImage.height)
        let targetAspectRatio: CGFloat = 4.0 / 3.0
        
        // Calculate height for 4:3 ratio based on width
        let targetHeight = firstCropSize.width / targetAspectRatio
        let yOffset = (firstCropSize.height - targetHeight) / 2
        
        // Create final crop rectangle
        let finalRect = CGRect(x: 0, y: yOffset, 
                              width: firstCropSize.width, 
                              height: targetHeight)
        
        if let finalImage = firstCropImage.cropping(to: finalRect) {
            return UIImage(cgImage: finalImage, scale: imageToProcess.scale, orientation: .up)
        }
        
        return UIImage(cgImage: firstCropImage, scale: imageToProcess.scale, orientation: .up)
    }
    
    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
    
    // Add this method
    func resetSession() {
        capturedImage = nil
        // Ensure the session is running
        if !captureSession.isRunning {
            Task.detached { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            self.error = .captureFailed
            print("Error capturing photo: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            self.error = .captureFailed
            return
        }
        
        // Crop the image to match the preview
        capturedImage = cropImageToPreviewAspectRatio(image)
    }
}
