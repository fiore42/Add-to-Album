import SwiftUI
import Photos
import Accelerate
import CoreGraphics

class ImageViewModel: ObservableObject {
    @Published var images: [PHAsset: UIImage] = [:]
    private let cachingManager = PHCachingImageManager()

    func loadImage(for asset: PHAsset, targetSize: CGSize) {
        guard images[asset] == nil else { return } // Prevent duplicate loads

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        cachingManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
            DispatchQueue.main.async {
                if let image = image {
                    self.images[asset] = image
                }
            }
        }
    }

    func startCaching(assets: [PHAsset], targetSize: CGSize) {
        cachingManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFit, options: nil)
    }

    func stopCaching(assets: [PHAsset], targetSize: CGSize) {
        cachingManager.stopCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFit, options: nil)
    }
}

struct FullscreenImageView: View {
    @Binding var isPresented: Bool
    @Binding var selectedImageIndex: Int
    let imageAssets: [PHAsset]
    @Environment(\.dismiss) var dismiss
    @StateObject private var imageViewModel = ImageViewModel()
    @State private var previousIndex: Int = -1

    @ObservedObject var imageGridViewModel: ImageGridViewModel
    @EnvironmentObject var albumSelectionViewModel: AlbumSelectionViewModel // ✅ Get ViewModel from environment

    @State private var rotationAngles: [String: Double] = [:] // ✅ Store rotation per image
    
    @State private var positionTopBottom: CGFloat = 0.2 // 20% from top and bottom
    @State private var positionLeftRight: CGFloat = 0.1 // 10% from left and right
    
    var body: some View {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    TabView(selection: $selectedImageIndex) {
                        ForEach(imageAssets.indices, id: \.self) { index in
                            ZStack {
                                Color.black.ignoresSafeArea()
                                
                                if let image = imageViewModel.images[imageAssets[index]] {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .rotationEffect(.degrees(rotationAngles[imageAssets[index].localIdentifier] ?? 0))
                                        .animation(.easeInOut(duration: 0.3), value: rotationAngles[imageAssets[index].localIdentifier] ?? 0)
                                        .transition(.opacity)
                                } else {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .onAppear {
                                            imageViewModel.loadImage(for: imageAssets[index], targetSize: geometry.size)
                                        }
                                }
                                
                                // Left separator
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: 20) // Adjust thickness
                                    .edgesIgnoringSafeArea(.all)
                                    .offset(x: -geometry.size.width / 2 + 1) // Position at left edge
                                
                                // Right separator
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: 20) // Adjust thickness
                                    .edgesIgnoringSafeArea(.all)
                                    .offset(x: geometry.size.width / 2 - 1) // Position at right edge
                                
                            }
                            .tag(index)
                            .onAppear {
                                if index == imageAssets.count - 5 && !imageGridViewModel.isLoadingBatch {
                                    imageGridViewModel.loadNextBatch()
                                }
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
                    .onChange(of: selectedImageIndex) { oldIndex, newIndex in
                        handlePreloading(for: newIndex, targetSize: geometry.size)
                    }
                    
                    // Call FunctionBoxes and pass geometry
                    FunctionBoxes(
                        geometry: geometry,
                        currentPhotoID: imageAssets[selectedImageIndex].localIdentifier,
                        selectedAlbums: $albumSelectionViewModel.selectedAlbums,
                        selectedAlbumIDs: $albumSelectionViewModel.selectedAlbumIDs
                        //                        rotateLeft: { rotateImage(left: true) }, // ✅ Rotate and save
                        //                        rotateRight: { rotateImage(left: false) }
                    )
                    
                    GeometryReader { geometry in
                                VStack {
                                    HStack {
                                        Button(action: { dismiss() }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .resizable()
                                                .frame(width: 30, height: 30)
                                                .foregroundColor(.white)
                                                .padding()
                                        }
                                        .frame(width: geometry.size.width * 0.2, alignment: .leading) // Back button (e.g., 20% from left)

                                        Spacer() // Push the rotate buttons to the edges

                                        HStack(spacing: 0) { // Rotate buttons group (no internal spacing)
                                            Button(action: { rotateImage(left: true) }) {
                                                Image(systemName: "arrow.counterclockwise")
                                                    .resizable()
                                                    .frame(width: 30, height: 30)
                                                    .foregroundColor(.white)
                                                    .padding(10)
                                                    .background(Color.black.opacity(0.5))
                                                    .clipShape(Circle())
                                            }
                                            .frame(width: geometry.size.width * 0.2, alignment: .trailing) // Rotate Left (e.g., 20% from right)

                                            Button(action: { rotateImage(left: false) }) {
                                                Image(systemName: "arrow.clockwise")
                                                    .resizable()
                                                    .frame(width: 30, height: 30)
                                                    .foregroundColor(.white)
                                                    .padding(10)
                                                    .background(Color.black.opacity(0.5))
                                                    .clipShape(Circle())
                                            }
                                            .frame(width: geometry.size.width * 0.2, alignment: .leading) // Rotate Right (e.g., 20% from left)
                                        }

                                        Spacer() // Push the rotate buttons to the edges
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 10)

                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            }
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.height < -100 || value.translation.height > 100 { dismiss()
                            }
                        }
                )
            }
        }

        private func handlePreloading(for index: Int, targetSize: CGSize) {
            guard previousIndex != index else { return }
            previousIndex = index

            let prefetchIndices = (index-2...index+2).filter { $0 >= 0 && $0 < imageAssets.count }
            let prefetchAssets = prefetchIndices.map { imageAssets[$0] }

            imageViewModel.startCaching(assets: prefetchAssets, targetSize: targetSize)
        }

    private func rotateImage(left: Bool) {
        let asset = imageAssets[selectedImageIndex]

        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        options.canHandleAdjustmentData = { _ in true }

        asset.requestContentEditingInput(with: options) { editingInput, _ in
            guard let editingInput = editingInput, let fullSizeImageURL = editingInput.fullSizeImageURL else {
                Logger.log("❌ Error: Could not retrieve full-size image URL")
                return
            }

            guard let image = UIImage(contentsOfFile: fullSizeImageURL.path) else {
                Logger.log("❌ Error: Could not create UIImage from URL")
                return
            }

            let angle = left ? -90.0 : 90.0 // Determine rotation angle
            guard let rotatedImage = self.rotateImage(image: image, by: CGFloat(angle)) else {
                Logger.log("❌ Error rotating image using Core Graphics")
                return
            }


            // Write the rotated image data to a temporary file
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("rotated_image.jpg") // or .png, whatever your images are
            guard let imageData = rotatedImage.jpegData(compressionQuality: 0.8) else { // Adjust compression as needed
                Logger.log("❌ Error converting rotated image to data")
                return
            }

            do {
                try imageData.write(to: tempURL)
            } catch {
                Logger.log("❌ Error writing rotated image data to file: \(error)")
                return
            }

            let adjustmentData = PHAdjustmentData(
                formatIdentifier: "com.example.app.image-rotation", // Unique identifier
                formatVersion: "1.0",
                data: Data() // No other data needed for this example
            )

            let output = PHContentEditingOutput(contentEditingInput: editingInput)
                output.adjustmentData = adjustmentData
            
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest(for: asset)
                request.contentEditingOutput = output
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        Logger.log("✅ Image rotation applied")
                        self.refreshCurrentImage() // Call refresh on the main thread
                    } else {
                        Logger.log("❌ Error applying rotation: \(error?.localizedDescription ?? "Unknown error")")
                    }
                    // Clean up the temporary file, even on error.
                    try? FileManager.default.removeItem(at: tempURL)
                }
            }
        }
    }


    private func rotateImage(image: UIImage, by angle: CGFloat) -> UIImage? {
        guard let cgImage = image.cgImage else { // Get the CGImage
            Logger.log("❌ Error: Could not get CGImage from UIImage")
            return nil
        }

        let radians = angle * .pi / 180.0
        let rotatedSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .size

        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context.rotate(by: radians)

        // Use CGImage for drawing
        context.draw(cgImage, in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))

        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return rotatedImage
    }


    private func refreshCurrentImage() {
        let asset = imageAssets[selectedImageIndex]
        
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 1000, height: 1000), contentMode: .aspectFit, options: options) { image, _ in
            DispatchQueue.main.async {
                if let image = image {
                    self.imageViewModel.images[asset] = image // ✅ Update the UI
                    Logger.log("🔄 Image refreshed with new rotation")
                }
            }
        }
    }

}
