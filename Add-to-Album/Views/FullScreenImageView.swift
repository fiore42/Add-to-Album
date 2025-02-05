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
                                        .transition(.opacity)
                                } else {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .onAppear {
                                            imageViewModel.loadImage(for: imageAssets[index], targetSize: geometry.size)
                                        }
                                }
                                // Add a vertical black separator on the right edge of each image
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: 30) // Adjust thickness
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
                    FunctionBoxes(geometry: geometry)

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
//                    .padding(.top, 50)
//                    .padding(.leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }

        private func handlePreloading(for index: Int, targetSize: CGSize) {
            guard previousIndex != index else { return }
            previousIndex = index

            let prefetchIndices = (index-2...index+2).filter { $0 >= 0 && $0 < imageAssets.count }
            let prefetchAssets = prefetchIndices.map { imageAssets[$0] }

            imageViewModel.startCaching(assets: prefetchAssets, targetSize: targetSize)
        }

}
