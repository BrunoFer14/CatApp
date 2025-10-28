import SwiftUI
import SwiftData

/// Ponto de entrada da app.
/// Cria a janela e configura o container do SwiftData com os modelos persistidos.
@main
struct CatAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Favorite.self, CachedBreed.self, FavoriteBreedDetail.self])
    }
}
