import SwiftUI
import SwiftData

/// Ecrã que lista apenas os favoritos, lendo diretamente do SwiftData (FavoriteBreedDetail).
struct FavoritesView: View {
    @StateObject private var viewModel: FavoritesViewModel

    // Recebe o CatBreedsViewModel para partilhar estado
    init(viewModel: CatBreedsViewModel) {
        _viewModel = StateObject(wrappedValue: FavoritesViewModel(catViewModel: viewModel))
    }

    // Lê snapshots persistidos dos favoritos diretamente do SwiftData
    @Query(sort: [SortDescriptor(\FavoriteBreedDetail.name, order: .forward)])
    private var favoriteDetails: [FavoriteBreedDetail]

    var body: some View {
        VStack {
            if favoriteDetails.isEmpty {
                Text("No favorites yet 🐾")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(favoriteDetails, id: \.id) { detail in
                    // Mapear FavoriteBreedDetail -> CatBreed para reutilizar UI existente
                    let breed = CatBreed(
                        id: detail.id,
                        name: detail.name,
                        origin: detail.origin,
                        description: detail.breedDescription,
                        temperament: detail.temperament,
                        life_span: detail.life_span,
                        image: BreedImage(url: detail.imageUrl),
                        referenceImageId: nil
                    )

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

                // Informação extra: média de vida dos favoritos (mantida via ViewModel)
                if let avgText = viewModel.averageLifeSpanText() {
                    Text("Average life span of favorites: \(avgText) years")
                        .font(.subheadline)
                        .padding()
                }
            }
        }
        .navigationTitle("Favorites")
        .onAppear {
            // Recarrega IDs de favoritos ao abrir o ecrã (mantém estado de IDs coerente)
            viewModel.refreshFavorites()
        }
    }
}
