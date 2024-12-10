//
//  ViewModel.swift
//  SmoothBlur
//
//  Created by voonhueh on 10/12/24.
//

import Foundation
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import MetalKit

class ImageControlViewModel: ObservableObject {
    @Published var imageControl = ImageControl()
    @Published var selectedImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var selectedCIImage: CIImage?

    private let context = CIContext()
    private let device = MTLCreateSystemDefaultDevice()!
    private lazy var textureLoader = MTKTextureLoader(device: device)

    func loadImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.selectedImage = image
            self.processedImage = image
            self.selectedCIImage = self.createCIImageFromTexture(image: self.selectedImage)
            self.applyFilters()
        }
    }

    private func createCIImageFromTexture(image: UIImage?) -> CIImage? {
        guard let uiimage = image else {return nil}
        guard let cgImage = uiimage.cgImage else { return nil }
        
        //clear selectedImage from memory
        self.selectedImage = nil

        do {
            let texture = try textureLoader.newTexture(cgImage: cgImage, options: nil)
            return CIImage(mtlTexture: texture, options: nil)?
                .oriented(.downMirrored)
        } catch {
            print("Failed to create texture: \(error)")
            return nil
        }
    }

    func applyFilters() {
        guard let ciimage = self.selectedCIImage else {return}
        
        DispatchQueue.main.async {
            let blurredImage = self.applyGaussianBlur(
                to: ciimage,
                radius: self.imageControl.gaussianRadius
            )
            
            guard let finalImage = blurredImage,
                  let cgImage = self.context.createCGImage(finalImage, from: finalImage.extent) else { return }
            self.processedImage = UIImage(cgImage: cgImage)
        }
    }

    private func applyGaussianBlur(to image: CIImage, radius: Double) -> CIImage? {
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = image.clampedToExtent()
        filter.radius = Float(radius)
        
        guard let outputImage = filter.outputImage else { return nil }
        return outputImage.cropped(to: image.extent)
    }
}
