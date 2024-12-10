//
//  ContentView.swift
//  SmoothBlur
//
//  Created by voonhueh on 10/12/24.
//

import SwiftUI
import PhotosUI
import Combine

struct ContentView: View {
    @StateObject private var viewModel = ImageControlViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isPresentAlbum: Bool = false

    var body: some View {
        VStack {
            ZStack {
                if let processedImage = viewModel.processedImage {
                    Image(uiImage: processedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .padding()
                } else {
                    Text("Tap to Select an Image")
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .background(Color.gray.opacity(0.2))
                }
            }
            .onTapGesture {
                isPresentAlbum = true
            }

            VStack {
                HStack {
                    Text("Gaussian Radius")
                    Spacer()
                    Text("\(viewModel.imageControl.gaussianRadius, specifier: "%.0f")")
                }
                Slider(
                    value: Binding(
                        get: { viewModel.imageControl.gaussianRadius },
                        set: { newValue in
                            viewModel.imageControl.gaussianRadius = min(newValue, 50.0)
                            viewModel.applyFilters()
                        }
                    ),
                    in: 0...50,
                    step: 0.1
                )
            }
            .padding()

            Spacer()
        }
        .padding()
        .photosPicker(
            isPresented: $isPresentAlbum, selection: $selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhoto) { oldItem, newItem in
            if let newItem {
                loadImage(from: newItem)
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data, let uiImage = UIImage(data: data) {
                    viewModel.loadImage(uiImage)
                }
            case .failure(let error):
                print("Error loading image: \(error.localizedDescription)")
            }
        }
    }
}

