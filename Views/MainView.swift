import SwiftUI
import ComposableArchitecture

struct MainView: View {
    // tab identifier
    private enum Tab: Hashable {
        case home, favorites, search
    }
    // Tab selected
    @State private var selectedTab: Tab = .home

    // Navigation paths
    @State private var homePath = NavigationPath()
    @State private var favoritesPath = NavigationPath()
    @State private var searchPath = NavigationPath()

    // Stores TCA for Home, Favorites e Search
    private let homeStore: StoreOf<HomePageReducer>
    private let favoritesStore: StoreOf<FavoritesReducer>
    private let searchStore: StoreOf<SearchReducer>

    init() {
        self.homeStore = Store(initialState: HomePageReducer.State(), reducer: { HomePageReducer() })
        self.favoritesStore = Store(initialState: FavoritesReducer.State(), reducer: { FavoritesReducer() })
        self.searchStore = Store(initialState: SearchReducer.State(), reducer: { SearchReducer() })
    }

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
                .tabItem { Label(UIStrings.Home.title, systemImage: UIStrings.Icons.house) }
                .tag(Tab.home)

            favoritesTab
                .tabItem { Label(UIStrings.Favorites.title, systemImage: UIStrings.Icons.heartFill) }
                .tag(Tab.favorites)

            searchTab
                .tabItem { Label(UIStrings.Search.title, systemImage: UIStrings.Icons.magnifyingglass) }
                .tag(Tab.search)
        }
    }

    var homeTab: some View {
        NavigationStack(path: $homePath) {
            HomeListView(store: homeStore)
        }
    }

    var favoritesTab: some View {
        FavoritesView(store: favoritesStore)
    }

    var searchTab: some View {
        NavigationStack(path: $searchPath) {
            SearchView(store: searchStore)
        }
    }
}

// MARK: - Handlers
private extension MainView {
    private func onSelectedTabChange(old: Tab, new: Tab) {
        // Back to root when clicked
        if old == new {
            switch new {
            case .home:
                homePath = NavigationPath()
            case .favorites:
                // No path reset behavior needed for Favorites
                break
            case .search:
                searchPath = NavigationPath()
            }
        }
    }
}
