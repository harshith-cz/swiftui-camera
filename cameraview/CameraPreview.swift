//
//  CameraPreview.swift
//  cameraview
//
//  Created by Harshith on 25/04/25.
//

import SwiftUI
import AVFoundation
import UIKit

// This is the SwiftUI wrapper for our UIKit camera preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var headerHeight: CGFloat = 0
    var controlBarHeight: CGFloat = 0
    
    // Create the UIView
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.previewLayer.session = session
        
        // Configure the preview layer
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.connection?.videoOrientation = .portrait
        
        return view
    }
    
    // Update the view
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Not needed for this implementation
    }
}

// A specialized UIView subclass for camera preview
class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

// Focus indicator that shows where the user tapped to focus
struct FocusIndicator: View {
    var position: CGPoint
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .stroke(Color.yellow, lineWidth: 2)
            .frame(width: 75, height: 75)
            .position(position)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .opacity(isAnimating ? 0 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isAnimating = true
                }
            }
    }
}

