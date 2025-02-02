import SwiftUI
import PhotosUI
import Foundation // ✅ Ensure Foundation is imported

// This is where IdentifiableAsset goes:
struct IdentifiableAsset: Identifiable {
    let id = UUID() // Or use asset.localIdentifier if you prefer
    let asset: PHAsset
}

class ViewModel: ObservableObject {
    let albumAssociationManager = AlbumAssociationManager()
    @Published var pairedAlbums: [String: PHAssetCollection?] = [:] {
        didSet {
            albumAssociationManager.pairedAlbums = pairedAlbums // Synchronize when ViewModel's pairedAlbums changes
        }
    }

    init() {
        albumAssociationManager.loadFunctionAlbumAssociations()
        pairedAlbums = albumAssociationManager.pairedAlbums // Initialize ViewModel's pairedAlbums
    }
}
struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    @State private var photoAssets: [PHAsset] = []
    @State private var selectedImage: IdentifiableAsset? = nil
    @State private var isLoadingMore = false
    @State private var albums: [PHAssetCollection] = [] // Store available albums
    @AppStorage("functionAlbumAssociations") private var functionAlbumAssociations: Data = Data()
//    @State private var pairedAlbums: [String: PHAssetCollection] = [:] // Now in ContentView

//    @State private var pairedAlbums: [String: PHAssetCollection?] = [
//        "Function 1": nil,
//        "Function 2": nil,
//        "Function 3": nil,
//        "Function 4": nil
//    ] // Store paired albums
    
    private let imageManager = PHImageManager.default()
    private let batchSize = 30
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(photoAssets, id: \.localIdentifier) { asset in
                        ImageThumbnailView(asset: asset, imageManager: imageManager)
                            .onTapGesture {
                                selectedImage = IdentifiableAsset(asset: asset)
                            }
                            .onAppear {
                                if asset == photoAssets.last && !isLoadingMore {
                                    loadNextBatch()
                                }
                            }
                    }
                }
                if isLoadingMore {
                    ProgressView()
                }
            }
            .navigationTitle("Photo Gallery")
            .navigationBarItems(trailing: albumSelectionMenu) // ✅ Add Hamburger Menu
            .onAppear {
                requestPhotoLibraryAccess()
                fetchAlbums() // ✅ Fetch available albums
//                viewModel.albumAssociationManager.loadFunctionAlbumAssociations()
//                viewModel.albumAssociationManager.checkAlbumExistence()
            }
            .fullScreenCover(item: $selectedImage) { identifiableAsset in
                FullScreenImageView(
                    viewModel: viewModel,
                    assets: photoAssets,
                    imageManager: imageManager,
                    selectedIndex: photoAssets.firstIndex(where: { $0.localIdentifier == identifiableAsset.asset.localIdentifier }) ?? 0,
//                    pairedAlbums: $viewModel.albumAssociationManager.pairedAlbums, // Pass the binding through the viewModel
//                    pairedAlbums: $pairedAlbums, // Pass a binding
//                    pairedAlbums: viewModel.pairedAlbumsBinding, // Use the computed property
                    pairedAlbums: $viewModel.pairedAlbums, // Directly use the ViewModel's pairedAlbums
                    loadMoreAssets: loadNextBatch,
                    onDismiss: { selectedImage = nil }
                )
            }
        }
    }
    
    // ✅ Hamburger Menu for selecting albums
    var albumSelectionMenu: some View {
        Menu {
            // ✅ Ensure functions are always listed in the correct order
            let orderedFunctions = ["Fu 1", "Fu 2", "Fu 3", "Fu 4"]

            let functionMap: [String: String] = [
                "Fu 1": "Function 1",
                "Fu 2": "Function 2",
                "Fu 3": "Function 3",
                "Fu 4": "Function 4"
            ]
            
            ForEach(orderedFunctions, id: \.self) { shortFunctionName in
                let fullFunctionName = functionMap[shortFunctionName] ?? shortFunctionName
//                let albumName = viewModel.albumAssociationManager.pairedAlbums[fullFunctionName]??.localizedTitle ?? "Not Set"
                let albumName = viewModel.pairedAlbums[fullFunctionName]??.localizedTitle ?? "Not Set"
                let truncatedAlbumName = truncateAlbumName(albumName, maxLength: 16)

                Menu("\(shortFunctionName): \(truncatedAlbumName)") {
                    ForEach(albums, id: \.localIdentifier) { album in
                        Button(album.localizedTitle ?? "Unnamed Album") {
                            viewModel.pairedAlbums[fullFunctionName] = album
//                            viewModel.albumAssociationManager.updatePairedAlbum(for: fullFunctionName, with: album) // Use the new function
//                            viewModel.albumAssociationManager.pairedAlbums[fullFunctionName] = album // Update through viewModel
                            print("📂 Paired \(fullFunctionName) with album: \(album.localizedTitle ?? "Unnamed")")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.horizontal.3") // Hamburger icon
                .font(.title2)
        }
    }

    func updateFunctionAlbumAssociation(for function: String, with collection: PHAssetCollection?) {
        viewModel.albumAssociationManager.pairedAlbums[function] = collection // Directly update pairedAlbums

//        let associationsToSave = viewModel.albumAssociationManager.pairedAlbums.compactMapValues { $0?.localIdentifier }
        viewModel.albumAssociationManager.saveFunctionAlbumAssociations() // No need to pass associationsToSave anymore
    }


    
    // ✅ Fetch user albums
    func fetchAlbums() {
        let fetchOptions = PHFetchOptions()
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        var fetchedAlbums: [PHAssetCollection] = []
        collections.enumerateObjects { (collection, _, _) in
            fetchedAlbums.append(collection)
        }
        
        DispatchQueue.main.async {
            self.albums = fetchedAlbums
        }
    }
    
    func requestPhotoLibraryAccess() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                if status == .authorized {
                    loadNextBatch()
                    fetchAlbums()
                }
            }
        case .authorized:
            loadNextBatch()
            fetchAlbums()
        default:
            print("Photo library access denied or restricted")
        }
    }
    
    func loadNextBatch() {
        guard !isLoadingMore else { return }
        isLoadingMore = true

        let startTime = Date()
        print("🔄 Starting to load next batch of images at \(startTime) (current count: \(photoAssets.count))")

        DispatchQueue.global(qos: .userInitiated).async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = self.photoAssets.count + self.batchSize

            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

            let startIndex = self.photoAssets.count
            let endIndex = min(fetchResult.count, startIndex + self.batchSize)

            guard startIndex < endIndex else {
                print("⚠️ No new assets found to load")
                DispatchQueue.main.async {
                    self.isLoadingMore = false
                }
                return
            }

            let newAssets = fetchResult.objects(at: IndexSet(startIndex..<endIndex))

            DispatchQueue.main.async {
                let mainThreadStart = Date()
                self.photoAssets.append(contentsOf: newAssets)
                self.isLoadingMore = false

                let mainThreadEnd = Date()
                print("✅ Batch loaded: \(newAssets.count) images added. Total images: \(self.photoAssets.count)")
                print("⏳ Time taken: \(mainThreadEnd.timeIntervalSince(startTime)) seconds (UI update: \(mainThreadEnd.timeIntervalSince(mainThreadStart)) seconds)")
            }
        }
    }
}
