//
//  ImagePreviewView.swift
//  cameraview
//
//  Created by Harshith on 25/04/25.
//

import SwiftUI
import UIKit

struct ImagePreviewView: View {
    let image: UIImage
    let onRetake: () -> Void
    let onSave: (UIImage) -> Void
    var cameraManager: CameraManager
    
    // Fixed 4:3 aspect ratio
    private let previewAspectRatio: CGFloat = 4.0 / 3.0
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Display the image with 4:3 aspect ratio
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(previewAspectRatio, contentMode: .fit)  // Force 4:3 ratio
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.3))
                    .onAppear {
                        // Debug info on appear
                        print("Image preview appeared")
                        print("Image size: \(image.size)")
                        print("Aspect ratio: \(image.size.width / image.size.height)")
                        print("Using 4:3 aspect ratio for display")
                    }
                
                Spacer()
                
                HStack(spacing: 60) {
                    // Retake button
                    Button(action: {
                        print("Retake button tapped")
                        cameraManager.resetSession()
                        onRetake()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    // Save button
                    Button(action: { 
                        print("Save button tapped")
                        onSave(image) 
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.green.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
}
