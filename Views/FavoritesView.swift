import SwiftUI

/// Ecrã que lista apenas os favoritos.
struct FavoritesView: View {
    @StateObject private var viewModel: FavoritesViewModel

    // Recebe o CatBreedsViewModel para partilhar estado
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
                            // Miniatura
                            CatImageView(
                                urlString: breed.image?.url ?? breed.referenceImageUrl,
                                width: 40,
                                height: 40,
                                cornerRadius: 6
                            )
                            Text(breed.name)
                                .font(.headline)
                            Spacer()
                            // Botão coração dentro da célula
                            FavoriteButton(isFavorite: viewModel.isFavorite(breed)) {
                                viewModel.toggleFavorite(breed)
                            }
                        }
                    }
                }

                // Informação extra: média de vida dos favoritos
                if let avgText = viewModel.averageLifeSpanText() {
                    Text("Average life span of favorites: \(avgText) years")
                        .font(.subheadline)
                        .padding()
                }
            }
        }
        .navigationTitle("Favorites")
        .onAppear {
            // Recarrega favoritos ao abrir o ecrã
            viewModel.refreshFavorites()
        }
    }
}
