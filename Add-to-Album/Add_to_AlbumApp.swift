import SwiftUI

@main
struct Add_to_AlbumApp: App {
    
    init() {
        Logger.log("03 Feb 2025 - 19:30 the thumbnail view works") // ✅ First debug print
        Logger.log("🚀 App launched") // ✅ First debug print
    }
    var body: some Scene {
        WindowGroup {
            ImageGridView()
        }
    }
}
