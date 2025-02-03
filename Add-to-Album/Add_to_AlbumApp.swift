import SwiftUI

@main
struct Add_to_AlbumApp: App {
    
    init() {
        Logger.log("Project History:")
        Logger.log("1. 03 Feb 2025 - 19:30 the thumbnail view works")
        Logger.log("2. 03 Feb 2025 - 21:59 the full screen view almost works")
        Logger.log("🚀 App launched") // ✅ First debug print
    }
    var body: some Scene {
        WindowGroup {
            ImageGridView()
        }
    }
}
