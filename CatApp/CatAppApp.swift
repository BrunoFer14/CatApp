import SwiftUI
import SwiftData

@main
struct CatAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Favorite.self)
    }
}
