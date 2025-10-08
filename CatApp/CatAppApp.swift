import SwiftUI
import SwiftData

/// Ponto de entrada da app.
/// Cria a janela e configura o container do SwiftData com os modelos persistidos.
@main
struct CatAppApp: App {
    var body: some Scene {
        WindowGroup {
            // Primeira vista da app
            ContentView()
        }
        // Regista modelos do SwiftData que vão ser guardados localmente
        .modelContainer(for: [Favorite.self, CachedBreed.self])
    }
}
