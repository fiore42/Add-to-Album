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
    @State private var isLoading: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black // Background for the separator
                    .frame(height: 20) // Height of the separator
                    .offset(y: currentImage != nil ? 0 : -geometry.size.height) // Show separator only when image is loaded
                    .animation(.default, value: currentImage != nil)

                if let image = currentImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }

            }
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
                .padding(.top, 50) // Adjust as needed
                .padding(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.width
                        let threshold = geometry.size.width / 4 // Adjust as needed

                        if translation > threshold && selectedImageIndex > 0 {
                            // Swipe to the left (previous image)
                            loadAndDisplayImage(at: selectedImageIndex - 1, geometry: geometry)
                        } else if translation < -threshold && selectedImageIndex < imageAssets.count - 1 {
                            // Swipe to the right (next image)
                            loadAndDisplayImage(at: selectedImageIndex + 1, geometry: geometry)
                        }
                    }
                    .onEnded { value in
                        let translation = value.translation.width
                        let threshold = geometry.size.width / 4

                        if translation > threshold && selectedImageIndex > 0 {
                            selectedImageIndex -= 1
                            Logger.log("FullscreenImageView: Swiped Left to index \(selectedImageIndex)")
                        } else if translation < -threshold && selectedImageIndex < imageAssets.count - 1 {
                            selectedImageIndex += 1
                            Logger.log("FullscreenImageView: Swiped Right to index \(selectedImageIndex)")
                        }
                    }
            )
            .onAppear {
                loadAndDisplayImage(at: selectedImageIndex, geometry: geometry)
                Logger.log("FullscreenImageView: Appeared for index \(selectedImageIndex)")
            }
            .onChange(of: selectedImageIndex) { newValue in
                loadAndDisplayImage(at: newValue, geometry: geometry)
                Logger.log("FullscreenImageView: selectedImageIndex changed to \(newValue)")
            }
        }
        .ignoresSafeArea()
    }


    private func loadImage(at index: Int, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        guard index >= 0 && index < imageAssets.count else {
            completion(nil)
            return
        }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .fastFormat

        manager.requestImage(for: imageAssets[index], targetSize: targetSize, contentMode: .aspectFit, options: options) { (image, info) in
            completion(image)
            if let info = info, let isCancelled = info[PHImageCancelledKey] as? Bool, isCancelled {
                Logger.log("FullscreenImageView: Image loading cancelled for index \(index)")
            }
        }
    }

    private func loadAndDisplayImage(at index: Int, geometry: GeometryProxy) {
        guard index >= 0 && index < imageAssets.count && !isLoading else { return }

        isLoading = true
        let targetSize = CGSize(width: geometry.size.width * 1.2, height: geometry.size.height * 1.2)

        loadImage(at: index, targetSize: targetSize) { image in
            DispatchQueue.main.async {
                currentImage = image
                isLoading = false
            }
        }
    }
}
