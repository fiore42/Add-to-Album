import SwiftUI
import Photos

struct ContentView: View {
    @StateObject var viewModel = PhotoViewModel()
    @State private var selectedAsset: PHAsset? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(viewModel.displayedAssets, id: \.localIdentifier) { asset in
                        ImageThumbnailView(asset: asset)
                            .onTapGesture {
                                selectedAsset = asset
                            }
                            .onAppear {
                                if asset == viewModel.displayedAssets.last {
                                    viewModel.fetchNextBatchIfNeeded()
                                }
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Photo Gallery")
            .navigationBarItems(trailing: albumSelectionMenu)
            .onAppear {
                viewModel.loadAllAssetsIfNeeded()
                viewModel.fetchUserAlbums()
            }
            .fullScreenCover(item: $selectedAsset) { asset in
                FullScreenImageView(
                    selectedAsset: asset,
                    allAssets: viewModel.allAssets,
                    displayedAssets: viewModel.displayedAssets,
                    onLoadMore: {
                        viewModel.fetchNextBatchIfNeeded()
                    },
                    onDismiss: {
                        selectedAsset = nil
                    }
                )
                .environmentObject(viewModel.albumManager)
            }
        }
    }
    
    // MARK: - Album Menu
    var albumSelectionMenu: some View {
        Menu {
            let orderedFunctions = ["Fu 1", "Fu 2", "Fu 3", "Fu 4"]
            let map: [String: String] = [
                "Fu 1": "Function 1",
                "Fu 2": "Function 2",
                "Fu 3": "Function 3",
                "Fu 4": "Function 4"
            ]
            
            ForEach(orderedFunctions, id: \.self) { shortName in
                let longName = map[shortName] ?? shortName
                let albumTitle = viewModel.albumManager.pairedAlbums[longName]??.localizedTitle ?? "Not Set"
                Menu("\(shortName): \(truncateAlbumName(albumTitle, maxLength: 16))") {
                    ForEach(viewModel.userAlbums, id: \.localIdentifier) { album in
                        Button {
                            viewModel.albumManager.updatePairedAlbum(for: longName, with: album)
                        } label: {
                            Text(album.localizedTitle ?? "Unnamed")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.horizontal.3")
        }
    }
}
