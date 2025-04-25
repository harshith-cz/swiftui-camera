//
//  CameraError.swift
//  cameraview
//
//  Created by Harshith on 24/04/25.
//

import Foundation


enum CameraError: Error, Identifiable {
    case permissionDenied
    case cameraUnavailable
    case setupFailed
    case captureFailed
    
    var id: Self { self }
    
    var description: String {
        switch self {
        case .permissionDenied:
            return "Camera permission is required to capture photos."
        case .cameraUnavailable:
            return "Camera is unavailable on this device."
        case .setupFailed:
            return "Failed to setup camera."
        case .captureFailed:
            return "Failed to capture photo."
        }
    }
}
