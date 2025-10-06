import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel: FavoritesViewModel

    // Mantém compatibilidade com o MainView atual
    init(viewModel: CatBreedsViewModel) {
        _viewModel = StateObject(wrappedValue: FavoritesViewModel(catViewModel: viewModel))
    }

    var body: some View {
        VStack {
            if viewModel.isEmpty {
                Text("No favorites yet 🐾")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(viewModel.favoriteBreeds) { breed in
                    NavigationLink(
                        destination: BreedDetailView(breed: breed, viewModel: viewModel.catViewModel)
                    ) {
                        HStack {
                            CatImageView(
                                urlString: breed.image?.url ?? breed.referenceImageUrl,
                                width: 40,
                                height: 40,
                                cornerRadius: 6
                            )
                            Text(breed.name)
                                .font(.headline)
                            Spacer()
                            // Exemplo: botão para remover dos favoritos direto na lista (opcional)
                            FavoriteButton(isFavorite: viewModel.isFavorite(breed)) {
                                viewModel.toggleFavorite(breed)
                            }
                        }
                    }
                }

                if let avgText = viewModel.averageLifeSpanText() {
                    Text("Average life span of favorites: \(avgText) years")
                        .font(.subheadline)
                        .padding()
                }
            }
        }
        .navigationTitle("Favorites")
    }
}
