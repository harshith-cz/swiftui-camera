//
//  CameraView.swift
//  cameraview
//
//  Created by Harshith on 25/04/25.
//

import SwiftUI
import UIKit

struct CameraView: View {
    var cameraManager = CameraManager()
    @State private var focusPoint: CGPoint?
    @State private var showFocusIndicator = false
    
    var body: some View {
        ZStack {
            // Camera preview
            Group {
                if cameraManager.isCameraAvailable {
                    CameraPreview(session: cameraManager.captureSession)
                        .ignoresSafeArea()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .gesture(
                            SpatialTapGesture()
                                    .onEnded { tapValue in
                                        let location = tapValue.location
                                        focusPoint = location
                                        cameraManager.focus(at: location, in: UIScreen.main.bounds.size)
                                        showFocusIndicator = true
                                        
                                        Task {
                                            try? await Task.sleep(for: .seconds(1))
                                            showFocusIndicator = false
                                        }
                                    }
                        )
                        .gesture(
                            // Pinch to zoom
                            MagnificationGesture()
                                .onChanged { value in
                                    cameraManager.zoom(by: value)
                                }
                        )
                } else {
                    Color.black
                        .ignoresSafeArea()
                }
            }
            
            // Focus indicator
            if showFocusIndicator, let point = focusPoint {
                FocusIndicator(position: point)
            }
            
            // Capture button
            VStack {
                Spacer()
                
                Button {
                    cameraManager.capturePhoto()
                } label: {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 2)
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.bottom, 30)
            }
        }
//        .alert(item: cameraManager.error) { error in
//            Alert(
//                title: Text("Camera Error"),
//                message: Text(error.description),
//                dismissButton: .default(Text("OK"))
//            )
//        }
        .task {
            await cameraManager.configure()
        }
        .onDisappear {
            cameraManager.stop()
        }
    }
}
