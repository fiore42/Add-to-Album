import SwiftUI
import Photos

class ImageViewModel: ObservableObject {
    @Published var currentImage: UIImage?
}

//struct LogView: ViewModifier {
//    let message: String
//
//    func body(content: Content) -> some View {
//        content
//            .onAppear {
//                Logger.log(message)
//            }
//    }
//}
//
//extension View {
//    func log(_ message: String) -> some View {
//        modifier(LogView(message: message))
//    }
//}

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
                    .offset(y: currentImage != nil ? 0 : -geometry.size.height)
                    .animation(.default, value: currentImage != nil)

                if currentImage == nil && thumbnail != nil { // Show thumbnail while loading high-res
                    Image(uiImage: thumbnail!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(y: currentImage != nil ? 0 : -geometry.size.height)
                        .animation(.default, value: currentImage != nil)
                }

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
//                                .log("🔍 Image Rendering: \(selectedImageIndex) - Full-resolution image found")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .transition(.opacity) // ✅ Smooth fade-in
                        } else if let thumb = thumbnail {

                            Image(uiImage: thumb)
//                                .log("🔍 Image Rendering: \(selectedImageIndex) - Showing thumbnail")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .onAppear {
                                    Logger.log("⚠️ Showing only thumbnail for index: \(selectedImageIndex)")
                                }
                        } else {
                            ProgressView()
//                                .log("🔍 Image Rendering: \(selectedImageIndex) - No image available")
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
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { // Small delay
                        loadImages(for: selectedImageIndex, geometry: geometry)
                        imageLoaded = true
                    }
                    offset = -CGFloat(selectedImageIndex) * geometry.size.width // Initial offset
                    Logger.log("FullscreenImageView: Appeared for index \(selectedImageIndex)")
                }
                .onChange(of: selectedImageIndex) { oldValue, newValue in
                    Logger.log("🟢 selectedImageIndex changed: \(oldValue) → \(newValue)")
                    Logger.log("🔍 currentImage: \(currentImage != nil ? "Loaded" : "Nil")")
                    Logger.log("🔍 Thumbnail: \(thumbnail != nil ? "Loaded" : "Nil")")
                    Logger.log("🔍 Image Cache contains: \(imageRequestIDs.keys)")

                    loadImages(for: newValue, geometry: geometry)
                    offset = -CGFloat(newValue) * geometry.size.width
                }
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

        Logger.log("loadImages called for index: \(index)") // Added log entry

        // Cancel any existing requests
        if let leftRequestID = imageRequestIDs[index - 1] {
            PHImageManager.default().cancelImageRequest(leftRequestID)
            imageRequestIDs.removeValue(forKey: index - 1)
            Logger.log("Cancelled left image request for index: \(index - 1)") // Added log entry
        }
        if let currentRequestID = imageRequestIDs[index] {
            PHImageManager.default().cancelImageRequest(currentRequestID)
            imageRequestIDs.removeValue(forKey: index)
            Logger.log("Cancelled current image request for index: \(index)") // Added log entry
        }
        if let rightRequestID = imageRequestIDs[index + 1] {
            PHImageManager.default().cancelImageRequest(rightRequestID)
            imageRequestIDs.removeValue(forKey: index + 1)
            Logger.log("Cancelled right image request for index: \(index + 1)") // Added log entry
        }

        if index > 0 {
            loadImage(at: index - 1, geometry: geometry, targetSize: targetSize) { image in
                DispatchQueue.main.async {
                    leftImage = image
                    Logger.log("Loaded left image for index: \(index - 1)") // Added log entry
                }
            }
        } else {
            leftImage = nil
            Logger.log("No left image to load for index: \(index)") // Added log entry
        }

        loadImage(at: index, geometry: geometry, targetSize: targetSize) { image in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // ✅ Small delay to force UI update
                if let image = image {
                    self.currentImage = image
                    self.thumbnail = nil  // Ensure thumbnail disappears
                    self.reloadTrigger.toggle()
                    Logger.log("✅ Full-resolution image set for index: \(index)")
                } else {
                    Logger.log("❌ Failed to load current image for index: \(index)")
                }
            }
        }


        if index < imageAssets.count - 1 {
            loadImage(at: index + 1, geometry: geometry, targetSize: targetSize) { image in
                DispatchQueue.main.async {
                    rightImage = image
                    Logger.log("Loaded right image for index: \(index + 1)") // Added log entry
                }
            }
        } else {
            rightImage = nil
            Logger.log("No right image to load for index: \(index)") // Added log entry
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

    private func loadAdjacentImages(geometry: GeometryProxy) { // Modified call
        let targetSize = CGSize(width: geometry.size.width * 1.2, height: geometry.size.height * 1.2)

        if selectedImageIndex > 0 {
            loadImage(at: selectedImageIndex - 1, geometry: geometry, targetSize: targetSize) { image in // Pass geometry
                DispatchQueue.main.async {
                    leftImage = image
                }
            }
        } else {
            leftImage = nil
        }

        if selectedImageIndex < imageAssets.count - 1 {
            loadImage(at: selectedImageIndex + 1, geometry: geometry, targetSize: targetSize) { image in // Pass geometry
                DispatchQueue.main.async {
                    rightImage = image
                }
            }
        } else {
            rightImage = nil
        }
    }
    


}
