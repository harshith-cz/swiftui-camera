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
    @State private var isViewAppeared = false
    
    var body: some View {
        ZStack {
            // Camera preview
            Group {
                if cameraManager.isCameraAvailable {
                    CameraPreview(
                        session: cameraManager.captureSession,
                        headerHeight: cameraManager.headerHeight,
                        controlBarHeight: cameraManager.controlBarHeight
                    )
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
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: HeaderHeightPreferenceKey.self, value: geometry.size.height)
                            .onPreferenceChange(HeaderHeightPreferenceKey.self) { height in
                                if height > 0 {
                                    cameraManager.headerHeight = height
                                    updateMeasurementStatus()
                                    print("Updated header height: \(height)")
                                }
                            }
                    }
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
                            print("Capture button tapped")
                            // Disable the UI during capture
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            // Capture the photo
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
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ControlBarHeightPreferenceKey.self, value: geometry.size.height)
                            .onPreferenceChange(ControlBarHeightPreferenceKey.self) { height in
                                if height > 0 {
                                    cameraManager.controlBarHeight = height
                                    updateMeasurementStatus()
                                    print("Updated control bar height: \(height)")
                                }
                            }
                    }
                )
            }
        }
        .task {
            print("Camera view task started")
            // Don't configure here since CameraModule already handles this
            // This avoids the "Multiple audio/video AVCaptureInputs" error
            // await cameraManager.configure()
            
            // Just ensure the camera is running, but don't reconfigure
            if cameraManager.captureSession.isRunning == false {
                cameraManager.restartCameraSession()
            }
        }
        .onAppear {
            print("Camera view appeared")
            // Ensure the camera session is running when the view appears
            if !isViewAppeared {
                isViewAppeared = true
                // No need to restart again here, just check if it's not running
                if cameraManager.captureSession.isRunning == false {
                    print("Camera session not running, restarting...")
                    cameraManager.restartCameraSession()
                }
            }
        }
        .onDisappear {
            cameraManager.stop()
        }
    }
    
    // Helper function to update measurement status
    private func updateMeasurementStatus() {
        // If both measurements are non-zero, mark as updated
        if cameraManager.headerHeight > 0 && cameraManager.controlBarHeight > 0 {
            cameraManager.uiMeasurementsUpdated = true
            print("UI measurements updated - Header: \(cameraManager.headerHeight), Control: \(cameraManager.controlBarHeight)")
        }
    }
}

// Preference keys for view measurements
struct HeaderHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ControlBarHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
