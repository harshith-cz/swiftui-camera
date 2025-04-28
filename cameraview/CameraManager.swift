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
    
    // Heights for UI elements (defaults that will be updated)
    var headerHeight: CGFloat = 120
    var controlBarHeight: CGFloat = 150
    
    // Add a property to track if values have been updated
    var uiMeasurementsUpdated = false
    
    // Add properties for top and bottom crop amounts (as percentages of the image height)
    var topCropPercentage: CGFloat = 0.20    // Default 20% from top
    var bottomCropPercentage: CGFloat = 0.25 // Default 15% from bottom
    
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
        guard !isConfigured else { 
            print("Camera already configured, skipping configuration")
            return 
        }
        
        print("Starting camera configuration...")
        
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
            
            // Debug info
            print("=== Camera Session Configuration ===")
            print("Session preset: \(captureSession.sessionPreset.rawValue)")
            print("Session running: \(captureSession.isRunning)")
            print("Inputs: \(captureSession.inputs.count)")
            print("Outputs: \(captureSession.outputs.count)")
            if let connection = photoOutput.connection(with: .video) {
                print("Video connection available: \(connection.isEnabled)")
                print("Video orientation: \(connection.videoOrientation.rawValue)")
            } else {
                print("No video connection available")
            }
            print("===================================")
            
            isConfigured = true
        } catch {
            self.error = .setupFailed
            print("Camera setup failed with error: \(error.localizedDescription)")
        }
    }
    
    // Cleanup when done
    func stop() {
        guard isConfigured, captureSession.isRunning else { return }
        captureSession.stopRunning()
    }
    
    // Capture a photo
    func capturePhoto() {
        guard isConfigured, captureSession.isRunning else {
            print("Cannot capture photo: session not configured or not running")
            return
        }
        
        print("Attempting to capture photo...")
        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .quality
        
        // Force flash off to avoid issues
        settings.flashMode = .off
        
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
    
    // Reset the capture session fully - removes all inputs/outputs
    func resetCameraCompletely() {
        print("Completely resetting camera session")
        captureSession.beginConfiguration()
        
        // Remove all inputs and outputs
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        
        captureSession.commitConfiguration()
        
        // Mark as not configured so we can reconfigure
        self.isConfigured = false
        
        // Reconfigure from scratch
        Task {
            await configure()
        }
    }
    
    // Crop image to match the preview area, then crop specific amounts from top and bottom
    private func cropImageToPreviewAspectRatio(_ image: UIImage) -> UIImage {
        print("Starting precise two-step cropping process")
        
        // STEP 1: Handle image orientation to ensure proper coordinates
        let orientationCorrectedImage = correctImageOrientation(image)
        print("Original image size after orientation correction: \(orientationCorrectedImage.size)")
        
        // STEP 1: Crop to exact device preview dimensions
        // Calculate the visible preview area (screen minus UI elements)
        let screenSize = UIScreen.main.bounds.size
        let visibleHeight = screenSize.height - headerHeight - controlBarHeight
        let visibleArea = CGSize(width: screenSize.width, height: visibleHeight)
        print("Device screen size: \(screenSize)")
        print("Visible preview area: \(visibleArea)")
        
        // Get image dimensions
        let imageWidth = orientationCorrectedImage.size.width
        let imageHeight = orientationCorrectedImage.size.height
        print("Image dimensions: \(imageWidth) × \(imageHeight)")
        
        // Calculate the scaling factor to match device dimensions
        let widthRatio = imageWidth / visibleArea.width
        let heightRatio = imageHeight / visibleArea.height
        let scaleFactor = max(widthRatio, heightRatio)
        
        // Calculate dimensions of the area we need to crop to
        let cropWidth = visibleArea.width * scaleFactor
        let cropHeight = visibleArea.height * scaleFactor
        
        // Calculate offsets to center the crop
        let xOffset = (imageWidth - cropWidth) / 2
        let yOffset = (imageHeight - cropHeight) / 2
        
        let deviceCropRect = CGRect(
            x: xOffset,
            y: yOffset,
            width: cropWidth,
            height: cropHeight
        )
        
        print("First crop to match device preview: \(deviceCropRect)")
        
        // Apply the first crop (to match device preview dimensions)
        guard let deviceCroppedImage = cropImage(orientationCorrectedImage, toRect: deviceCropRect) else {
            print("Warning: First cropping stage failed, using original image")
            return orientationCorrectedImage
        }
        
        print("After first crop (matches device preview): \(deviceCroppedImage.size)")
        
        // STEP 2: Crop specific percentages from top and bottom
        let afterFirstCropHeight = deviceCroppedImage.size.height
        let afterFirstCropWidth = deviceCroppedImage.size.width
        
        // Calculate actual pixels to crop
        let topPixels = afterFirstCropHeight * topCropPercentage
        let bottomPixels = afterFirstCropHeight * bottomCropPercentage
        let remainingHeight = afterFirstCropHeight - topPixels - bottomPixels
        
        print("Cropping \(topCropPercentage * 100)% (\(topPixels) pixels) from top")
        print("Cropping \(bottomCropPercentage * 100)% (\(bottomPixels) pixels) from bottom")
        print("Remaining height: \(remainingHeight) pixels")
        
        // Create the second crop rectangle
        let secondCropRect = CGRect(
            x: 0,
            y: topPixels,
            width: afterFirstCropWidth,
            height: remainingHeight
        )
        
        print("Second crop (removes top/bottom percentages): \(secondCropRect)")
        
        // Apply the second crop (top and bottom percentages)
        guard let finalImage = cropImage(deviceCroppedImage, toRect: secondCropRect) else {
            print("Warning: Second cropping stage failed, using device-cropped image")
            return deviceCroppedImage
        }
        
        print("Final image after both crops: \(finalImage.size)")
        return finalImage
    }
    
    // Helper method to safely crop an image with a rect
    private func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage? {
        // Ensure crop rect is within image bounds
        let imageRect = CGRect(origin: .zero, size: image.size)
        let validRect = imageRect.intersection(rect)
        
        if validRect.isEmpty || validRect.width <= 0 || validRect.height <= 0 {
            print("Error: Invalid crop rectangle: \(rect) for image size: \(image.size)")
            return nil
        }
        
        // Perform actual cropping via CoreGraphics
        if let cgImage = image.cgImage?.cropping(to: validRect) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
        }
        
        print("Error: CGImage cropping failed")
        return nil
    }
    
    // Helper method to correct image orientation
    private func correctImageOrientation(_ image: UIImage) -> UIImage {
        // If the image orientation is already up, no need to modify
        if image.imageOrientation == .up {
            return image
        }
        
        print("Correcting image orientation from: \(image.imageOrientation.rawValue)")
        
        // Create drawing context to normalize orientation
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        print("Image orientation corrected")
        return normalizedImage
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
    
    // A method to forcefully restart the camera session if needed
    func restartCameraSession() {
        print("Restarting camera session...")
        
        // First stop the session
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            // Wait a moment before restarting
            try? await Task.sleep(for: .seconds(0.5))
            
            // Simply start the session again without reconfiguring
            // Do NOT attempt to re-add inputs or outputs
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                print("Camera session restarted: \(self.captureSession.isRunning)")
            }
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("Photo capture completed")
        
        if let error = error {
            self.error = .captureFailed
            print("Error capturing photo: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Failed to get image data representation")
            self.error = .captureFailed
            return
        }
        
        guard let image = UIImage(data: imageData) else {
            print("Failed to create UIImage from image data")
            self.error = .captureFailed
            return
        }
        
        print("Successfully created image, size: \(image.size)")
        
        // Crop the image to match the preview
        let processedImage = cropImageToPreviewAspectRatio(image)
        
        // Update on main thread to ensure UI updates properly
        DispatchQueue.main.async { [weak self] in
            print("Setting captured image on main thread")
            self?.capturedImage = processedImage
        }
    }
}
