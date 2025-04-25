//
//  ContentView.swift
//  cameraview
//
//  Created by Harshith on 18/04/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        VStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                
                Button("Take Another Photo") {
                    showCamera = true
                }
                .padding()
            } else {
                Button("Open Camera") {
                    showCamera = true
                }
                .padding()
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraModule(onImageCaptured: { image in
                capturedImage = image
                showCamera = false
            })
        }
    }
}

#Preview {
    ContentView()
}
