//
//  CameraPreview.swift
//  cameraview
//
//  Created by Harshith on 25/04/25.
//

import SwiftUI
import UIKit
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

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

