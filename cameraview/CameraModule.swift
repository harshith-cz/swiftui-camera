//
//  CameraModule.swift
//  cameraview
//
//  Created by Harshith on 25/04/25.
//

import SwiftUI

struct CameraModule: View {
    @State private var cameraManager = CameraManager()
    var onImageCaptured: ((UIImage) -> Void)?
    
    var body: some View {
        Group {
            if let image = cameraManager.capturedImage {
                ImagePreviewView(
                    image: image,
                    onRetake: {
                        cameraManager.capturedImage = nil
                    },
                    onSave: { image in
                        onImageCaptured?(image)
                    },
                    cameraManager: cameraManager
                )
            } else {
                CameraView(cameraManager: cameraManager)
            }
        }
    }
}
