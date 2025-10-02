import SwiftUI
import SwiftData

@main
struct CatAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Inclui TODOS os modelos que queres persistir
        .modelContainer(for: [Favorite.self, CachedBreed.self])
    }
}
