import Photos

struct IdentifiableAsset: Identifiable, Equatable {
    let id = UUID()
    let asset: PHAsset
    
    static func == (lhs: IdentifiableAsset, rhs: IdentifiableAsset) -> Bool {
        lhs.asset.localIdentifier == rhs.asset.localIdentifier
    }
}
