import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: CatBreedsViewModel

    var body: some View {
        TabView {
            NavigationView {
                HomeListView(viewModel: viewModel)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationView {
                FavoritesView(viewModel: viewModel)
            }
            .tabItem {
                Label("Favorites", systemImage: "heart.fill")
            }

            NavigationView {
                SearchView(viewModel: viewModel)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
        }
    }
}
