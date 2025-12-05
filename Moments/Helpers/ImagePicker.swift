//
//  ImagePicker.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import PhotosUI

struct ImagePicker: View {
    @Binding var imageData: Data?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            if let imageData = imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(Color.white.clipShape(Circle()))
                    }
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)

                    VStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.largeTitle)
                            .foregroundColor(.gray)

                        Text("Ajouter photo")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    // Compress image if needed
                    if let uiImage = UIImage(data: data),
                       let compressedData = uiImage.jpegData(compressionQuality: 0.7) {
                        imageData = compressedData
                    } else {
                        imageData = data
                    }
                }
            }
        }
    }
}
