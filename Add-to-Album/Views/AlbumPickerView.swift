import SwiftUI
import Photos

struct AlbumPickerView: View {
    @Binding var selectedAlbum: String
    @Environment(\.dismiss) var dismiss
    let albums: [PHAssetCollection] // ✅ Receive preloaded albums

    var body: some View {
        NavigationView {
            VStack {
//                Text("Albums Count: \(albums.count)") // ✅ Debug UI
//                    .font(.headline)
//                    .foregroundColor(.red)
//                    .padding()
                if albums.isEmpty {
                    Text("⚠️ No Albums Available")
                        .foregroundColor(.gray)
                    ProgressView()
                        .onAppear {
                            Logger.log("⚠️ AlbumPickerView Opened with EMPTY albums list!")
                        }
                } else {
                    List(albums, id: \.localIdentifier) { album in
                        Button(action: {
                            selectedAlbum = formatAlbumName(album.localizedTitle ?? "Unknown")
                            UserDefaultsManager.saveAlbums([selectedAlbum])
                            dismiss()
                        }) {
                            Text(album.localizedTitle ?? "Unknown")
                        }
                    }
                    .navigationTitle("Select Album")
                    .onAppear {
                        Logger.log("✅ AlbumPickerView Opened with Albums Count: \(albums.count)")
                    }                }
                
            }
        }
    }



    private func formatAlbumName(_ name: String) -> String {
        let words = name.split(separator: " ")
        var shortName = ""
        var characterCount = 0

        if let firstWord = words.first, firstWord.count > 14 {
            return String(firstWord.prefix(12)) + "..."
        }

        for word in words {
            if characterCount + word.count + (shortName.isEmpty ? 0 : 1) > 14 {
                break
            }
            shortName += (shortName.isEmpty ? "" : " ") + word
            characterCount += word.count + 1
        }

        return shortName
    }
}
