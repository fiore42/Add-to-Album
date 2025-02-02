

import SwiftUI
import PhotosUI

struct FunctionBox: View {
    let title: String
    let album: String?
    let isPaired: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(title): \(truncateAlbumName(album ?? "Not Set", maxLength: 16))")
                .font(.system(size: 16))
            Image(systemName: isPaired ? "circle.fill" : "circle")
                .foregroundColor(isPaired ? .green : .red)
                .imageScale(.small)
        }
        .padding(12)
        .background(Color.black.opacity(0.5))
        .foregroundColor(.white)
        .cornerRadius(8)
        .onTapGesture { onTap() }
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
    
    static func togglePairing(asset: PHAsset, with album: PHAssetCollection?, for function: String) {
        guard let album = album else { return }
        PHPhotoLibrary.shared().performChanges({
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", asset.localIdentifier)
            let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
            if fetchResult.count > 0 {
                let changeRequest = PHAssetCollectionChangeRequest(for: album)
                changeRequest?.removeAssets([asset] as NSArray)
                print("Removed asset from \(function)")
            } else {
                let changeRequest = PHAssetCollectionChangeRequest(for: album)
                changeRequest?.addAssets([asset] as NSArray)
                print("Added asset to \(function)")
            }
        }, completionHandler: { success, error in
            if success {
                print("Toggle pairing successful for \(function)")
            } else if let error = error {
                print("Error toggling pairing for \(function): \(error)")
            }
        })
    }
}


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
