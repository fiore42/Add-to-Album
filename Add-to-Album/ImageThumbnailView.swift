import SwiftUI
import PhotosUI

struct ImageThumbnailView: View {
    let asset: PHAsset
    let imageManager: PHImageManager
    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
            } else {
                Color.gray
                    .frame(width: 100, height: 100)
                    .overlay(ProgressView())
                    .onAppear {
                        loadThumbnail()
                    }
            }
        }
    }

    func loadThumbnail() {
        let targetSize = CGSize(width: 200, height: 200)
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .opportunistic
        requestOptions.resizeMode = .exact

        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    thumbnail = image
                }
            }
        }
    }
}
