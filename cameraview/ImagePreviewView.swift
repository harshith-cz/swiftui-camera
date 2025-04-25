//
//  ImagePreviewView.swift
//  cameraview
//
//  Created by Harshith on 25/04/25.
//

import SwiftUI

struct ImagePreviewView: View {
    let image: UIImage
    let onRetake: () -> Void
    let onSave: (UIImage) -> Void
    var cameraManager: CameraManager
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(4/3, contentMode: .fit)  // Force 4:3 ratio
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                HStack(spacing: 60) {
                    // Retake button
                    Button(action: {
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
                    Button(action: { onSave(image) }) {
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
