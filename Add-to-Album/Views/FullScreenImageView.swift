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

//    @State private var imageLoadStates: [PHAsset: LoadingState] = [:]
    @ObservedObject var imageGridViewModel: ImageGridViewModel

//   enum LoadingState {
//        case idle, loading, success, failure
//    }
//
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                Color.black.ignoresSafeArea()
//
//                TabView(selection: $selectedImageIndex) {
//                    ForEach(imageAssets.indices, id: \.self) { index in
//                        ZStack {
//                            Color.black.ignoresSafeArea()
//
//                            if let image = imageViewModel.images[imageAssets[index]] {
//                                Image(uiImage: image)
//                                    .resizable()
//                                    .scaledToFit()
//                                    .transition(.opacity)
//                            } else if imageLoadStates[imageAssets[index]] == .loading || imageLoadStates[imageAssets[index]] == .idle {
//                                ProgressView()
//                                    .scaleEffect(1.5)
//                                    .onAppear {
//                                        loadImage(for: imageAssets[index], targetSize: geometry.size)
//                                    }
//                            } else {
//                                Image(systemName: "xmark.circle")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .foregroundColor(.red)
//                            }
//                        }
//                        .tag(index)
//                        .onAppear {
//                            preloadSurroundingImages(for: index, targetSize: geometry.size)
//                            if index == imageAssets.count - 5 && !imageGridViewModel.isLoadingBatch {
//                                imageGridViewModel.loadNextBatch()
//                            }
//                        }
//                    }
//                }
//                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
//                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
//
//                VStack {
//                    HStack {
//                        Button(action: { dismiss() }) {
//                            Image(systemName: "xmark.circle.fill")
//                                .resizable()
//                                .frame(width: 30, height: 30)
//                                .foregroundColor(.white)
//                                .padding()
//                        }
//                        Spacer()
//                    }
//                    Spacer()
//                }
//                .padding(.top, 50)
//                .padding(.leading)
//                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//            }
//        }
//    }
    
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
                    .onChange(of: selectedImageIndex) { newIndex in
                        handlePreloading(for: newIndex, targetSize: geometry.size)
                    }

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
                    .padding(.top, 50)
                    .padding(.leading)
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

//    private func loadImage(for asset: PHAsset, targetSize: CGSize) {
//        guard imageLoadStates[asset] != .loading, imageViewModel.images[asset] == nil else { return }
//
//        imageLoadStates[asset] = .loading
//
//        let manager = PHImageManager.default()
//        let options = PHImageRequestOptions()
//        options.isSynchronous = false
//        options.deliveryMode = .highQualityFormat
//
//        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, info in
//            DispatchQueue.main.async {
//                if let image = image {
//                    self.imageViewModel.images[asset] = image
//                    self.imageLoadStates[asset] = .success
//                } else {
//                    self.imageLoadStates[asset] = .failure
//                }
//            }
//        }
//    }
//
//    private func preloadSurroundingImages(for index: Int, targetSize: CGSize) {
//        let surroundingIndices = [index - 1, index, index + 1].filter { $0 >= 0 && $0 < imageAssets.count }
//        for i in surroundingIndices {
//            loadImage(for: imageAssets[i], targetSize: targetSize)
//        }
//    }
}
