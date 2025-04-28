//
//  CameraView.swift
//  cameraview
//
//  Created by Harshith on 25/04/25.
//

import SwiftUI
import AVFoundation
import UIKit

struct CameraView: View {
    var cameraManager = CameraManager()
    @State private var focusPoint: CGPoint?
    @State private var showFocusIndicator = false
    @State private var currentPage = 1
    @State private var totalPages = 4
    
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
            
            // Title and pagination at top
            VStack {
                // Top header
                VStack(spacing: 8) {
                    // Back button and title
                    HStack {
                        Button(action: {
                            // Add navigation back action here
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(.leading, 16)
                        }
                        
                        Spacer()
                        
                        Text("Capture up to 3 items at a")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                    
                    Text("time, even at an angle")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    // Pagination indicator
                    Text("\(currentPage) of \(totalPages)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                }
                .background(
                    Rectangle()
                        .fill(.black.opacity(0.6))
                        .ignoresSafeArea(edges: .top)
                )
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Privacy statement
                    Text("By continuing, you agree with our Privacy Statement.")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    
                    // Camera controls
                    HStack {
                        // Gallery button
                        Button(action: {
                            // Add gallery/photo picker action here
                        }) {
                            Image(systemName: "photo")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.leading, 24)
                        
                        Spacer()
                        
                        // Capture button
                        Button {
                            cameraManager.capturePhoto()
                        } label: {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 5)
                                        .frame(width: 80, height: 80)
                                )
                        }
                        
                        Spacer()
                        
                        // Empty space to balance layout
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 50, height: 50)
                            .padding(.trailing, 24)
                    }
                    .padding(.bottom, 30)
                }
                .background(
                    Rectangle()
                        .fill(.black.opacity(0.6))
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .task {
            await cameraManager.configure()
        }
        .onDisappear {
            cameraManager.stop()
        }
    }
}
