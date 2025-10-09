import SwiftUI

/// Tab bar principal com 4 separadores: Home, Favorites, Search e Settings.
struct MainView: View {
    @ObservedObject var viewModel: CatBreedsViewModel

    var body: some View {
        TabView {
            // Separador Home (lista paginada)
            NavigationView {
                HomeListView(viewModel: viewModel)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            // Separador Favoritos
            NavigationView {
                FavoritesView(viewModel: viewModel)
            }
            .tabItem {
                Label("Favorites", systemImage: "heart.fill")
            }

            // Separador Pesquisa (local sobre a lista carregada)
            NavigationView {
                SearchView(viewModel: viewModel)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            // Separador Settings
            NavigationView {
                SettingsView(viewModel: viewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
