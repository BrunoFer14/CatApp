import SwiftUI
import SwiftData

/// Raiz da UI.
/// Cria o ViewModel principal com o ModelContext para aceder ao SwiftData.
struct ContentView: View {
    // ModelContext do SwiftData injetado pelo ambiente
    @Environment(\.modelContext) private var context

    var body: some View {
        // Passa o context para o CatBreedsViewModel e mostra a MainView
        MainView(viewModel: CatBreedsViewModel(context: context))
    }
}
