import SwiftUI

struct HamburgerMenuView: View {
    @State private var selectedAlbums: [String] = UserDefaultsManager.getSavedAlbums()
    @State private var isAlbumPickerPresented = false
    @State private var selectedMenuIndex: Int? = nil // Track which menu item is selected

    var body: some View {
        Menu {
            ForEach(0..<4, id: \.self) { index in
                Button(action: {
                    selectedMenuIndex = index
                    isAlbumPickerPresented = true
                }) {
                    Text(selectedAlbums[index])
                }
            }
        } label: {
            HStack {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .frame(width: 30, height: 25)
                    .padding()
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $isAlbumPickerPresented) {
            if let index = selectedMenuIndex {
                AlbumPickerView(selectedAlbum: $selectedAlbums[index])
            }
        }
    }
}
