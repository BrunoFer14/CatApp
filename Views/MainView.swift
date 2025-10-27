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

    var body: some View {
        content
            .onChange(of: selectedTab, initial: false) { oldValue, newValue in
                onSelectedTabChange(old: oldValue, new: newValue)
            }
    }
}

// MARK: - Body composition
private extension MainView {
    var content: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tabItem { Label(UIStrings.Home.title, systemImage: "house") }
                .tag(Tab.home)

            favoritesTab
                .tabItem { Label(UIStrings.Favorites.title, systemImage: "heart.fill") }
                .tag(Tab.favorites)

            searchTab
                .tabItem { Label(UIStrings.Search.title, systemImage: "magnifyingglass") }
                .tag(Tab.search)

            settingsTab
                // TODO: criar UIStrings.Settings.title para consistência
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
    }

    var homeTab: some View {
        NavigationStack(path: $homePath) {
            HomeListView(viewModel: viewModel)
            // O título já é definido em HomeListView via UIStrings.Home.title
        }
    }

    var favoritesTab: some View {
        NavigationStack(path: $favoritesPath) {
            FavoritesView(viewModel: viewModel)
        }
    }

    var searchTab: some View {
        NavigationStack(path: $searchPath) {
            SearchView(viewModel: viewModel)
        }
    }

    var settingsTab: some View {
        NavigationStack(path: $settingsPath) {
            SettingsView(viewModel: viewModel)
        }
    }
}

// MARK: - Handlers
private extension MainView {
    private func onSelectedTabChange(old: Tab, new: Tab) {
        // Sempre que vamos para Home, garantir pop to root
        if new == .home {
            homePath = NavigationPath()
        }

        // Re-tap: se o utilizador toca na mesma tab duas vezes seguidas,
        // limpamos o respetivo NavigationPath (pop to root).
        if old == new {
            switch new {
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
    }
}
