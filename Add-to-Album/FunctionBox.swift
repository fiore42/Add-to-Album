import SwiftUI
import PhotosUI

struct FunctionBox: View {
    
    let title: String
    let album: String?
    let position: Alignment
    let topOffsetPercentage: CGFloat // Percentage from the top (0-100)
    let bottomOffsetPercentage: CGFloat // Percentage from the bottom (0-100)
    let isPaired: Bool // Add isPaired property
    let onTap: () -> Void // Add onTap closure

    init(
              title: String,
              album: String?,
              position: Alignment,
              topOffsetPercentage: CGFloat = 10,
              bottomOffsetPercentage: CGFloat = 10,
              isPaired: Bool, // isPaired *after* other properties
              onTap: @escaping () -> Void // onTap after isPaired in init
    ) {
              self.title = title
              self.album = album
              self.position = position
              self.topOffsetPercentage = topOffsetPercentage
              self.bottomOffsetPercentage = bottomOffsetPercentage
              self.isPaired = isPaired
              self.onTap = onTap
    }
    

    var body: some View {
            GeometryReader { geometry in // Use GeometryReader
                let truncatedAlbum = truncateAlbumName(album ?? "Not Set", maxLength: 16)

                Text("\(title): \(truncatedAlbum)")
                    .font(.system(size: 16))
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: position)
                    .offset(y: {
                        switch position {
                        case .topLeading, .topTrailing:
                            return -geometry.size.height * (topOffsetPercentage / 100) // Calculate offset based on height
                        case .bottomLeading, .bottomTrailing:
                            return geometry.size.height * (1 - (bottomOffsetPercentage / 100)) // Calculate offset based on height
                        default:
                            return 0
                        }
                    }())
            }
            .frame(maxWidth: .infinity) // Ensure the GeometryReader takes full width
        }
}


extension FunctionBox {
    static func isImagePaired(asset: PHAsset, with album: PHAssetCollection?) -> Bool {
        guard let album = album else { return false }
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", asset.localIdentifier)
        let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
        return fetchResult.count > 0
    }
}

//func isImagePaired(asset: PHAsset, with album: PHAssetCollection?) -> Bool {
//          guard let album = album else { return false }
//
//          let fetchOptions = PHFetchOptions()
//          fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", asset.localIdentifier) // Fetch only the given asset
//
//          let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions) // Fetch assets *in the album*
//
//          return fetchResult.count > 0 // Check if the asset is in the album
//}

// ✅ Truncates an album name to a maximum length, ensuring words are not cut off randomly.
func truncateAlbumName(_ name: String, maxLength: Int) -> String {
    if name.count <= maxLength {
        return name
    }
    
    let words = name.split(separator: " ")
    var truncatedName = ""

    for word in words {
        if (truncatedName.count + word.count + 1) > maxLength {
            break
        }
        truncatedName += (truncatedName.isEmpty ? "" : " ") + word
    }
    
    return truncatedName
}


