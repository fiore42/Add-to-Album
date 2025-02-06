import SwiftUI
import Photos

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

        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat

        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { imageData, _, _, _ in
            guard let imageData = imageData, let originalImage = UIImage(data: imageData) else {
                Logger.log("❌ Failed to load image data for rotation")
                return
            }

            let rotationAngle = left ? -90.0 : 90.0
            guard let rotatedImage = self.rotateUIImage(image: originalImage, degrees: rotationAngle) else { return }

            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest(for: asset)
                request.contentEditingOutput = self.createEditingOutput(from: asset, rotatedImage: rotatedImage)
            }) { success, error in
                if success { DispatchQueue.main.async { self.refreshCurrentImage() } }
            }
        }
    }

    private func rotateUIImage(image: UIImage, degrees: Double) -> UIImage? {
        let radians = degrees * .pi / 180
        var newSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .integral.size

        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: CGFloat(radians))
        image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))

        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImage
    }

    private func createEditingOutput(from asset: PHAsset, rotatedImage: UIImage) -> PHContentEditingOutput {
        let input = PHContentEditingInputRequestOptions()
        input.canHandleAdjustmentData = { _ in true }

        var output: PHContentEditingOutput?

        asset.requestContentEditingInput(with: input) { editingInput, _ in
            guard let editingInput = editingInput else { return }
            output = PHContentEditingOutput(contentEditingInput: editingInput)

            let outputURL = editingInput.fullSizeImageURL!.deletingPathExtension().appendingPathExtension("jpg")
            try? rotatedImage.jpegData(compressionQuality: 1.0)?.write(to: outputURL)
            output?.adjustmentData = PHAdjustmentData(formatIdentifier: "com.yourapp", formatVersion: "1.0", data: Data())
        }
        return output!
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
