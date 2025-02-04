import SwiftUI
import Photos
import PhotosUI

class ImageViewModel: ObservableObject {
    @Published var currentImage: UIImage?
}

struct FullscreenImageView: View {
    @Binding var isPresented: Bool
    @Binding var selectedImageIndex: Int
    let imageAssets: [PHAsset]
    @Environment(\.dismiss) var dismiss
    @StateObject private var imageViewModel = ImageViewModel()
    @State private var imageLoadStates: [PHAsset: LoadingState] = [:] // Custom enum

    enum LoadingState {
        case idle
        case loading
        case success
        case failure
    }
    
    init(isPresented: Binding<Bool>, selectedImageIndex: Binding<Int>, imageAssets: [PHAsset]) {
        self._isPresented = isPresented
        self._selectedImageIndex = selectedImageIndex
        self.imageAssets = imageAssets
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                TabView(selection: $selectedImageIndex) {
                    ForEach(imageAssets.indices, id: \.self) { index in
                        ZStack {
                            Color.black.ignoresSafeArea() // Ensure black background

                            // Use PhotosPickerItem for image loading
                            PhotosPicker(
                                selection: .constant(nil),  // We don't need item selection here
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                // Placeholder until image loads
                                if imageLoadStates[imageAssets[index]] == .loading || imageLoadStates[imageAssets[index]] == nil {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                } else {
                                    Color.clear // Transparent placeholder
                                }
                            }
                            .onChange(of: imageAssets[index]) { _, newAsset in
                                loadImage(for: newAsset, targetSize: geometry.size)
                            }
                            .overlay {
                                if let image = imageViewModel.currentImage, imageLoadStates[imageAssets[index]] == .success {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .transition(.opacity)
                                }
                            }
                            .tag(index) // Important for TabView
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never)) // Hide page indicator

                // Dismiss Button
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                                .padding()
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 50) // Adjust as needed
                .padding(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    private func loadImage(for asset: PHAsset, targetSize: CGSize) {
        guard imageLoadStates[asset] != .loading else { return } // Prevent concurrent loads

        imageLoadStates[asset] = .loading

        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false // Important for performance

        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, info in
            DispatchQueue.main.async {
                if let image = image {
                    self.imageViewModel.currentImage = image
                    self.imageLoadStates[asset] = .success
                } else {
                    self.imageLoadStates[asset] = .failure
                }
            }
        }
    }
}
