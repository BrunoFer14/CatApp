import SwiftUI
import SwiftData

/// Main entry point for the Cat Breeds application
/// Sets up the app window and configures SwiftData container with persistent models
@main
struct CatAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        /// Configure SwiftData model container for local persistence
        /// Includes all models: Favorite, CachedBreed, and FavoriteBreedDetail
        .modelContainer(for: [Favorite.self, CachedBreed.self, FavoriteBreedDetail.self])
    }
}
