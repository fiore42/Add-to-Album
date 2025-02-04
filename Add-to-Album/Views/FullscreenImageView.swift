import SwiftUI
import Photos

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

                    if currentImage != nil {
                        Image(uiImage: currentImage!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
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
                    loadImage(at: selectedImageIndex, geometry: geometry)
                    loadAdjacentImages(geometry: geometry)
                    offset = -CGFloat(selectedImageIndex) * geometry.size.width // Initial offset
                    Logger.log("FullscreenImageView: Appeared for index \(selectedImageIndex)")
                }
                .onChange(of: selectedImageIndex) { oldValue, newValue in
                    loadImage(at: newValue, geometry: geometry)
                    loadAdjacentImages(geometry: geometry)
                    offset = -CGFloat(newValue) * geometry.size.width
                    Logger.log("FullscreenImageView: selectedImageIndex changed to \(newValue)")
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
        options.deliveryMode = .fastFormat

        // Load Thumbnail
        let thumbnailTargetSize = CGSize(width: geometry.size.width / 3, height: geometry.size.height / 3) // Use geometry here
        let thumbnailRequestID = manager.requestImage(for: imageAssets[index], targetSize: thumbnailTargetSize, contentMode: .aspectFit, options: options) { (image, info) in
            DispatchQueue.main.async {
                if let image = image {
                    thumbnail = image
                    Logger.log("FullscreenImageView: Loaded thumbnail for index \(index)")
                }
            }
        }

        if let existingRequestID = imageRequestIDs[index] {
            manager.cancelImageRequest(existingRequestID)
            Logger.log("FullscreenImageView: Cancelled image request for index \(index)")
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
