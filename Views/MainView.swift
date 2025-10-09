import SwiftUI

/// Tab bar principal com 4 separadores: Home, Favorites, Search e Settings.
/// Usa NavigationStack + NavigationPath por separador para permitir "pop to root"
/// quando o utilizador toca na tab. No caso da Home, sempre que selecionada, volta à raiz.
struct MainView: View {
    @ObservedObject var viewModel: CatBreedsViewModel

    // Identificadores das tabs
    private enum Tab: Hashable {
        case home, favorites, search, settings
    }

    // Tab selecionada
    @State private var selectedTab: Tab = .home

    // Navigation paths por separador
    @State private var homePath = NavigationPath()
    @State private var favoritesPath = NavigationPath()
    @State private var searchPath = NavigationPath()
    @State private var settingsPath = NavigationPath()

    // Guarda a última tab tocada para detetar "re-tap"
    @State private var lastSelectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home
            NavigationStack(path: $homePath) {
                HomeListView(viewModel: viewModel)
                    .navigationTitle("Cat Breeds")
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(Tab.home)

            // Favorites
            NavigationStack(path: $favoritesPath) {
                FavoritesView(viewModel: viewModel)
            }
            .tabItem {
                Label("Favorites", systemImage: "heart.fill")
            }
            .tag(Tab.favorites)

            // Search
            NavigationStack(path: $searchPath) {
                SearchView(viewModel: viewModel)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(Tab.search)

            // Settings
            NavigationStack(path: $settingsPath) {
                SettingsView(viewModel: viewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(Tab.settings)
        }
        // Sempre que a seleção muda:
        // - Se for para Home, limpa SEMPRE o path (volta à raiz).
        // - Se for re-tap na mesma tab, limpa o path dessa tab (pop to root).
        .onChange(of: selectedTab) { newValue in
            // Sempre que vamos para Home, garantir pop to root
            if newValue == .home {
                homePath = NavigationPath()
            }

            // Re-tap: se o utilizador toca na mesma tab duas vezes seguidas,
            // limpamos o respetivo NavigationPath (pop to root).
            if lastSelectedTab == newValue {
                switch newValue {
                case .home:
                    homePath = NavigationPath()
                case .favorites:
                    favoritesPath = NavigationPath()
                case .search:
                    searchPath = NavigationPath()
                case .settings:
                    settingsPath = NavigationPath()
                }
            }

            lastSelectedTab = newValue
        }
    }
}
