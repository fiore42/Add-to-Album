import SwiftUI
import Photos

class ImageViewModel: ObservableObject {
    @Published var currentImage: UIImage?
}


// FullscreenImageView.swift
struct FullscreenImageView: View {
    @Binding var isPresented: Bool
    @Binding var selectedImageIndex: Int
    let imageAssets: [PHAsset]
    @State private var currentImage: UIImage?
    @State private var leftImage: UIImage?
    @State private var rightImage: UIImage?
    @State private var imageRequestIDs: [Int: PHImageRequestID] = [:]
    @State private var thumbnail: UIImage?
    @State private var offset: CGFloat = 0
    @Environment(\.dismiss) var dismiss
    @State private var imageLoaded: Bool = false
    @State private var reloadTrigger = false
    @StateObject private var imageViewModel = ImageViewModel()


    var body: some View {
        GeometryReader { geometry in
            ZStack {
                 Color.black
                     .frame(height: 20)
                     .offset(y: imageViewModel.currentImage != nil ? 0 : -geometry.size.height) // Use imageViewModel
                     .animation(.default, value: imageViewModel.currentImage != nil) // Use imageViewModel

                HStack(spacing: 0) { // Use HStack for smooth transitions
                    if leftImage != nil {
                        Image(uiImage: leftImage!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        Color.clear.frame(width: geometry.size.width, height: geometry.size.height) // Placeholder
                    }
                        if let img = imageViewModel.currentImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .transition(.opacity) // ✅ Smooth fade-in
                                .onAppear {
                                            imageLoaded = true // Set the flag when the image is displayed
                                        }
                        } else if let thumb = thumbnail {

                            Image(uiImage: thumb)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .transition(.opacity)
                                .onAppear {
                                    Logger.log("⚠️ Showing only thumbnail for index: \(selectedImageIndex)")
                                }
                        } else {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }


                    if rightImage != nil {
                        Image(uiImage: rightImage!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        Color.clear.frame(width: geometry.size.width, height: geometry.size.height) // Placeholder
                    }
                }
                .frame(width: geometry.size.width * 3, height: geometry.size.height) // 3 images side by side
                .offset(x: offset)
                .animation(.interactiveSpring(), value: offset) // Smooth animation
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .overlay(
                    Button(action: {
                        isPresented = false
                        dismiss()
                        Logger.log("FullscreenImageView: Dismissed")
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 50)
                    .padding(.leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation.width - CGFloat(selectedImageIndex) * geometry.size.width
                        }
                        .onEnded { value in
                            let translation = value.translation.width
                            let threshold = geometry.size.width / 4

                            if translation > threshold && selectedImageIndex > 0 {
                                selectedImageIndex -= 1
                                offset = -CGFloat(selectedImageIndex) * geometry.size.width
                                Logger.log("FullscreenImageView: Swiped Left to index \(selectedImageIndex)")
                            } else if translation < -threshold && selectedImageIndex < imageAssets.count - 1 {
                                selectedImageIndex += 1
                                offset = -CGFloat(selectedImageIndex) * geometry.size.width
                                Logger.log("FullscreenImageView: Swiped Right to index \(selectedImageIndex)")
                            } else {
                                offset = -CGFloat(selectedImageIndex) * geometry.size.width // Return to correct position
                            }
                        }
                )
                .onAppear {
                    if imageViewModel.currentImage == nil {  // ✅ Prevents duplicate calls
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            loadImages(for: selectedImageIndex, geometry: geometry)
                        }
                        Logger.log("📥 First time loading images for index \(selectedImageIndex)")
                    } else {
                        Logger.log("⏳ Skipping redundant load for index \(selectedImageIndex) (Already Loaded)")
                    }
                    offset = -CGFloat(selectedImageIndex) * geometry.size.width
                }

                .onChange(of: selectedImageIndex) { oldValue, newValue in
                    Logger.log("🟢 selectedImageIndex changed: \(oldValue) → \(newValue)")
                    Logger.log("🔍 currentImage: \(currentImage != nil ? "Loaded" : "Nil")")
                    Logger.log("🔍 Thumbnail: \(thumbnail != nil ? "Loaded" : "Nil")")
                    Logger.log("🔍 Image Cache contains: \(imageRequestIDs.keys)")

                    loadImages(for: newValue, geometry: geometry)
                    offset = -CGFloat(newValue) * geometry.size.width
                }
                .opacity(imageLoaded ? 1 : 0) // Fade-in effect
                .animation(.default, value: imageLoaded)
            }
            .ignoresSafeArea()
        }
    }
    
    private func loadImage(at index: Int, geometry: GeometryProxy, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) { // Add geometry parameter
        guard index >= 0 && index < imageAssets.count else {
            completion(nil)
            return
        }

        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false

        // Load Thumbnail
        let thumbnailTargetSize = CGSize(width: geometry.size.width / 3, height: geometry.size.height / 3) // Use geometry here
        let _ = manager.requestImage(for: imageAssets[index], targetSize: thumbnailTargetSize, contentMode: .aspectFit, options: options) { (image, info) in
            DispatchQueue.main.async {
                if let image = image {
                    thumbnail = image
                    Logger.log("FullscreenImageView: Loaded thumbnail for index \(index)")
                }
            }
        }

        if let existingRequestID = imageRequestIDs[index], currentImage == nil {
            manager.cancelImageRequest(existingRequestID)
            Logger.log("🛑 Cancelling in-progress request for index: \(index)")
        }

        let requestID = manager.requestImage(for: imageAssets[index], targetSize: targetSize, contentMode: .aspectFit, options: options) { (image, info) in
            DispatchQueue.main.async {
                if let info = info, let isCancelled = info[PHImageCancelledKey] as? Bool, isCancelled {
                    Logger.log("FullscreenImageView: Image loading cancelled for index \(index)")
                    return
                }
                if let image = image {
                    completion(image)
                    thumbnail = nil // Remove the thumbnail once high-res is loaded
                    Logger.log("FullscreenImageView: Loaded image for index \(index)")
                }
                imageRequestIDs.removeValue(forKey: index)
            }
        }
        imageRequestIDs[index] = requestID
    }

    private func loadImages(for index: Int, geometry: GeometryProxy) {
        let targetSize = CGSize(width: geometry.size.width * 1.2, height: geometry.size.height * 1.2)

        Logger.log("📥 loadImages called for index: \(index)")

        // ✅ Fix Off-by-One Error: Ensure we correctly cancel previous requests
        imageRequestIDs.forEach { key, requestID in
            PHImageManager.default().cancelImageRequest(requestID)
            Logger.log("🛑 Cancelled image request for index: \(key)")
        }
        imageRequestIDs.removeAll()

        // ✅ Load the Current Image
        loadImage(at: index, geometry: geometry, targetSize: targetSize) { image in
            DispatchQueue.main.async {
                imageViewModel.currentImage = image
                thumbnail = nil
                Logger.log(image != nil ? "✅ Loaded full image for index: \(index)" : "❌ Failed to load full image for index: \(index)")
            }
        }

        // ✅ Load the Left Image (Only If Within Bounds)
        if index > 0 {
            loadImage(at: index - 1, geometry: geometry, targetSize: targetSize) { image in
                DispatchQueue.main.async {
                    leftImage = image
                    Logger.log("↩️ Loaded left image for index: \(index - 1)")
                }
            }
        } else {
            leftImage = nil
            Logger.log("❌ No left image for index: \(index)")
        }

        // ✅ Load the Right Image (Only If Within Bounds)
        if index < imageAssets.count - 1 {
            loadImage(at: index + 1, geometry: geometry, targetSize: targetSize) { image in
                DispatchQueue.main.async {
                    rightImage = image
                    Logger.log("↪️ Loaded right image for index: \(index + 1)")
                }
            }
        } else {
            rightImage = nil
            Logger.log("❌ No right image for index: \(index)")
        }
    }


    private func loadImage(at index: Int, geometry: GeometryProxy) { // Modified call
        let targetSize = CGSize(width: geometry.size.width * 1.2, height: geometry.size.height * 1.2)
        loadImage(at: index, geometry: geometry, targetSize: targetSize) { image in // Pass geometry
            DispatchQueue.main.async {
                currentImage = image
            }
        }
    }


}
