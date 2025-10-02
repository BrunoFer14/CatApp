import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: CatBreedsViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.breeds) { breed in
                    NavigationLink(destination: BreedDetailView(breed: breed, viewModel: viewModel)) {
                        HStack {
                            CatImageView(
                                urlString: breed.image?.url ?? breed.referenceImageUrl,
                                width: 60,
                                height: 60,
                                cornerRadius: 8
                            )
                            Text(breed.name)
                                .font(.headline)
                        }
                    }
                    // 👉 trigger da paginação
                    .onAppear {
                        if breed.id == viewModel.breeds.last?.id {
                            viewModel.fetchPage(page: viewModel.currentPage + 1)
                        }
                    }
                }
            }
            .navigationTitle("Cat Breeds")
            .toolbar {
                HStack {
                    NavigationLink(destination: SearchView(viewModel: viewModel)) {
                        Image(systemName: "magnifyingglass")
                    }
                    NavigationLink(destination: FavoritesView(viewModel: viewModel)) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}
