//
//  CameraModule.swift
//  cameraview
//
//  Created by Harshith on 25/04/25.
//

import SwiftUI
import UIKit

struct CameraModule: View {
    @State private var cameraManager = CameraManager()
    @State private var isCameraReady = false
    @State private var showImagePreview = false
    var onImageCaptured: ((UIImage) -> Void)?
    
    var body: some View {
        Group {
            if showImagePreview, let image = cameraManager.capturedImage {
                ImagePreviewView(
                    image: image,
                    onRetake: {
                        // Reset state and go back to camera
                        cameraManager.capturedImage = nil
                        showImagePreview = false
                        // Ensure camera is running again, but don't reconfigure
                        cameraManager.restartCameraSession()
                    },
                    onSave: { image in
                        onImageCaptured?(image)
                    },
                    cameraManager: cameraManager
                )
            } else {
                CameraView(cameraManager: cameraManager)
                    .task {
                        // Only configure the camera once when the module first loads
                        if !isCameraReady {
                            print("CameraModule initializing camera...")
                            await cameraManager.configure()
                            isCameraReady = true
                            print("Camera initialization complete")
                            
                            // No need to restart here, configure() already starts the session
                        }
                    }
            }
        }
        .onChange(of: cameraManager.capturedImage) { _, newImage in
            // When a new image is captured, show the preview
            if newImage != nil {
                print("Captured image detected, showing preview")
                showImagePreview = true
            }
        }
    }
}
