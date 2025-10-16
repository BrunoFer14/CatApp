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
                List(viewModel.rows) { row in
                    NavigationLink(
                        destination: BreedDetailView(breed: row.breed, viewModel: viewModel.catViewModel)
                    ) {
                        HStack {
                            // Miniatura
                            CatImageView(
                                urlString: row.imageURL ?? row.breed.referenceImageUrl,
                                width: UIDimensions.favoriteThumbnailSize,
                                height: UIDimensions.favoriteThumbnailSize,
                                cornerRadius: UILayout.favoriteThumbnailCornerRadius
                            )
                            Text(row.name)
                                .font(.headline)
                            Spacer()
                            // Botão coração dentro da célula
                            FavoriteButton(isFavorite: row.isFavorite) {
                                viewModel.toggleFavorite(row)
                            }
                        }
                    }
                }

                if let avgText = viewModel.averageLifeSpanText {
                    Text("Average life span of favorites: \(avgText) years")
                        .font(.subheadline)
                        .padding()
                }
            }
        }
        .navigationTitle("Favorites")
        .onAppear {
            // Atualiza IDs e constrói rows iniciais
            viewModel.refreshFavorites()
            viewModel.update(with: favoriteDetails)
        }
        .onChange(of: favoriteDetails) { _, newValue in
            // Sempre que SwiftData mudar, reconstruir rows e derivados
            viewModel.update(with: newValue)
        }
    }
}
