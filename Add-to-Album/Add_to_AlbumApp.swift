import SwiftUI

@main
struct Add_to_AlbumApp: App {
    
    init() {
        Logger.log("🚀 App launched") // ✅ First debug print
    }
    var body: some Scene {
        WindowGroup {
            ImageGridView()
        }
    }
}
