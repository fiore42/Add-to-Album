import Photos

extension PHAsset: Identifiable {
    public var id: String {
        localIdentifier
    }
}
