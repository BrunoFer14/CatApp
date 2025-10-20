import SwiftUI
import SwiftData

/// Raiz da UI.
/// Cria o ViewModel principal com o ModelContainer para aceder ao SwiftData (inclui background context).
struct ContentView: View {
    // ModelContext do SwiftData injetado pelo ambiente
    @Environment(\.modelContext) private var context

    var body: some View {
        // Passa o container para o CatBreedsViewModel (permite background context no repo de favoritos)
        MainView(viewModel: CatBreedsViewModel(container: context.container))
    }
}
