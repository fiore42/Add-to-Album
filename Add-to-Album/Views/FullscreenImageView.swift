import SwiftUI
import Photos

class ImageViewModel: ObservableObject {
    @Published var currentImage: UIImage?
}

// Global Image Cache
let imageCache = NSCache<NSNumber, UIImage>()

// FullscreenImageView.swift
struct FullscreenImageView: View {
    @Binding var isPresented: Bool
    @Binding var selectedImageIndex: Int
    let imageAssets: [PHAsset]
    @State private var currentImage: UIImage?
    @State private var leftImage: UIImage?
    @State private var rightImage: UIImage?
    @State private var thumbnail: UIImage?
    @State private var offset: CGFloat = 0
    @Environment(\.dismiss) var dismiss
    @State private var imageLoaded: Bool = false
    @StateObject private var imageViewModel = ImageViewModel()
    @State private var isLoadingImages: Bool = false // Track if loadImages is currently running
    @State private var isLoading: Bool = false // Track overall loading state
    // Global Loading Tracker
    var loadingImages = Set<Int>() // Use a Set for efficient checking

    init(isPresented: Binding<Bool>, selectedImageIndex: Binding<Int>, imageAssets: [PHAsset]) { // Corrected init
        self._isPresented = isPresented
        self._selectedImageIndex = selectedImageIndex
        self.imageAssets = imageAssets
        imageCache.totalCostLimit = 100 * 1024 * 1024
    }

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
                                            Logger.log("[Image - onAppear] 🔒 Locking imageLoaded flag")
                                        }
                        } else if let thumb = thumbnail {

                            Image(uiImage: thumb)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .transition(.opacity)
                                .onAppear {
                                    Logger.log("[Image - onAppear] ⚠️ Showing only thumbnail for index: \(selectedImageIndex)")
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
                        Logger.log("[HStack - overlay] Dismissed")
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
                                Logger.log("[HStack - onEnded] Swiped Left to index \(selectedImageIndex)")
                            } else if translation < -threshold && selectedImageIndex < imageAssets.count - 1 {
                                selectedImageIndex += 1
                                offset = -CGFloat(selectedImageIndex) * geometry.size.width
                                Logger.log("[HStack - onEnded] Swiped Right to index \(selectedImageIndex)")
                            } else {
                                offset = -CGFloat(selectedImageIndex) * geometry.size.width // Return to correct position
                            }
                        }
                )
                .onAppear {
                    Logger.log("⚠️ [HStack - onAppear] Attempt to call loadImages for: \(selectedImageIndex)")
                    if !isLoading {  // ✅ Ensure this block runs only once per appearance
                        Logger.log("🔒 [HStack - onAppear] Locking isLoading flag")
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            Logger.log("✅ [HStack - onAppear] Calling loadImages for index: \(selectedImageIndex)")
                            loadImages(for: selectedImageIndex, geometry: geometry)
                            Logger.log("🔓 [HStack - onAppear] Unlocking isLoading flag")
                            isLoading = false  // ✅ Set flag to prevent duplicate loads
                        }
                    } else {
                        Logger.log("⏳ [HStack - onAppear] Skipping redundant loadImages for index \(selectedImageIndex)")
                    }
                    offset = -CGFloat(selectedImageIndex) * geometry.size.width
                }

                .onChange(of: selectedImageIndex) { oldValue, newValue in
                    Logger.log("🟢 [HStack - onChange] selectedImageIndex changed: \(oldValue) → \(newValue)")
                    Logger.log("🔍 [HStack - onChange] currentImage: \(currentImage != nil ? "Loaded" : "Nil")")
                    Logger.log("🔍 [HStack - onChange] Thumbnail: \(thumbnail != nil ? "Loaded" : "Nil")")

                    Logger.log("⚠️ [HStack - onChange] Attempt to call loadImages for: \(newValue)")
                    if !isLoading {
                        Logger.log("🔒 [HStack - onChange] Locking isLoading flag")
                        isLoading = true
                        Logger.log("✅ [HStack - onChange] Call loadImages for: \(newValue)")
                        loadImages(for: newValue, geometry: geometry)
                        Logger.log("🔓 [HStack - onChange] Unlocking isLoading flag")
                        isLoading = false  // ✅ Set flag to prevent duplicate loads
                        offset = -CGFloat(newValue) * geometry.size.width
                    } else {
                        Logger.log("⏳ [HStack - onChange] Skipping redundant loadImages for index \(newValue)")
                    }
                }
                .opacity(imageLoaded ? 1 : 0) // Fade-in effect
                .animation(.default, value: imageLoaded)
            }
            .ignoresSafeArea()
        }
    }
    
    
    private func loadImages(for index: Int, geometry: GeometryProxy) {

        guard !isLoadingImages else {  // ✅ Prevent multiple calls
            Logger.log("⚠️ [loadImages] loadImages is already in progress. Skipping. [index: \(index)]")
            return
        }
        
        if imageViewModel.currentImage != nil, leftImage != nil || index == 0, rightImage != nil || index == imageAssets.count - 1 {
            Logger.log("💔 [loadImages] Image already loaded for index: \(index). Skipping redundant load.")
            return
        }
        
        Logger.log("🔒 [loadImages] Locking isLoadingImages flag")
        isLoadingImages = true // ✅ Set the flag at the start
        
        let targetSize = CGSize(width: geometry.size.width * 1.2, height: geometry.size.height * 1.2)

        Logger.log("📥 [loadImages] loadImages executing for index: \(index)")

        let group = DispatchGroup() // Use a DispatchGroup to track async operations
        
        if index > 0 {
            group.enter() // Enter the group before starting the async operation

            Logger.log("☎️ [loadImages] Calling loadImage for index: \(index - 1)")

            loadImage(at: index - 1, geometry: geometry, targetSize: targetSize, asset: imageAssets[index-1]) { image in
                DispatchQueue.main.async {
                    leftImage = image
                    Logger.log(image != nil ? "[loadImages] ✅ Full-resolution image set for index: \(index - 1)" : "[loadImages] ❌ Failed to load full image for index: \(index - 1)")
                    group.leave() // Leave the group when the operation is complete
                }
            }
        } else
        {
            leftImage = nil
            Logger.log("❌ [loadImages] No left image for index: \(index)")
        }

        group.enter() // Enter the group for the main image load
        Logger.log("☎️ [loadImages] Calling loadImage for index: \(index)")
        loadImage(at: index, geometry: geometry, targetSize: targetSize, asset: imageAssets[index]) { image in
            DispatchQueue.main.async {
                imageViewModel.currentImage = image
                thumbnail = nil
                Logger.log(image != nil ? "[loadImages] ✅ Full-resolution image set for index: \(index)" : "[loadImages] ❌ Failed to load full image for index: \(index)")
                group.leave() // Leave the group when the operation is complete

            }
        }

        if index < imageAssets.count - 1 {
            group.enter() // Enter the group
            Logger.log("☎️ [loadImages] Calling loadImage for index: \(index + 1)")
            loadImage(at: index + 1, geometry: geometry, targetSize: targetSize, asset: imageAssets[index+1]) { image in
                DispatchQueue.main.async {
                    rightImage = image
                    Logger.log(image != nil ? "[loadImages] ✅ Full-resolution image set for index: \(index + 1)" : "[loadImages] ❌ Failed to load full image for index: \(index + 1)")
                    group.leave() // Leave the group
                }
            }
        } else
        {
            rightImage = nil
            Logger.log("❌ [loadImages] No right image for index: \(index)")
        }
        
        
        // Release the lock *only after all asynchronous operations are complete*
        group.notify(queue: .main) { // Use notify to execute code when the group is empty
            self.isLoadingImages = false
            Logger.log("🔓 [loadImages] Unlocking isLoadingImages flag")
        }

    }

    private func loadImage(at index: Int, geometry: GeometryProxy, targetSize: CGSize, asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let nsIndex = NSNumber(value: index)

        guard index >= 0 && index < imageAssets.count else {
            completion(nil)
            return
        }
        
        // Check Cache First
        if let cachedImage = imageCache.object(forKey: nsIndex) {
            Logger.log("[loadImage] Retrieved image from cache for index \(index)")
            completion(cachedImage)
            return
        }

        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false

        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { (image, info) in
            DispatchQueue.main.async {
                if let info = info, let isCancelled = info[PHImageCancelledKey] as? Bool, isCancelled {
                    Logger.log("[loadImage] Image loading cancelled for index \(index)")
                    return
                }

                if let image = image {
                    completion(image)

                    // Cache the Image with cost
                    let imageData = image.jpegData(compressionQuality: 0.8) // Adjust compression
                    let cost = imageData?.count ?? 0
                    imageCache.setObject(image, forKey: nsIndex, cost: cost)

                    Logger.log("[loadImage] Loaded and cached image for index \(index), cost: \(cost)")
                }
            }
        }
    }
    

}
