import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        MainView(viewModel: CatBreedsViewModel(context: context))
    }
}
