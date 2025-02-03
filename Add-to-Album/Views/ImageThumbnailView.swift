import SwiftUI
import PhotosUI

struct ImageThumbnailView: View {
    let asset: PHAsset
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack {
            if let uiImg = thumbnail {
                Image(uiImage: uiImg)
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
        let targetSize = CGSize(width: 150, height: 150)
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .opportunistic
        requestOptions.resizeMode = .fast
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: requestOptions
        ) { image, _ in
            if let img = image {
                DispatchQueue.main.async {
                    self.thumbnail = img
                }
            }
        }
    }
}
