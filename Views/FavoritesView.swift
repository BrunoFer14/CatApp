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
        content
            .navigationTitle(UIStrings.Favorites.title)
            .onAppear(perform: onAppear)
            .onChange(of: favoriteDetails) {
                onFavoritesChanged(favoriteDetails)
            }
    }
}

// MARK: - Body composition
private extension FavoritesView {
    var content: some View {
        VStack(alignment: .leading, spacing: UILayout.sectionSpacing) {
            if favoriteDetails.isEmpty {
                emptyStateSection
            } else {
                favoritesListSection
                averageFooterSection
            }
        }
    }
}

// MARK: - Sections
private extension FavoritesView {
    var emptyStateSection: some View {
        Text(UIStrings.Common.noFavoritesYet)
            .foregroundColor(.gray)
            .padding()
    }

    var favoritesListSection: some View {
        List(viewModel.rows) { row in
            NavigationLink(
                destination: BreedDetailView(breed: row.breed, viewModel: viewModel.catViewModel)
            ) {
                favoriteRow(row)
            }
        }
    }

    @ViewBuilder
    var averageFooterSection: some View {
        if let avgText = viewModel.averageLifeSpanText {
            Text("\(UIStrings.Common.averageLifeSpanOfFavoritesPrefix) \(avgText) \(UIStrings.Common.years)")
                .font(.subheadline)
                .padding()
        }
    }
}

// MARK: - Row
private extension FavoritesView {
    func favoriteRow(_ row: FavoriteRowModel) -> some View {
        HStack(spacing: UILayout.tileContentSpacing) {
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

// MARK: - Lifecycle handlers
private extension FavoritesView {
    func onAppear() {
        // Atualiza IDs e constrói rows iniciais
        viewModel.refreshFavorites()
        viewModel.update(with: favoriteDetails)
    }

    func onFavoritesChanged(_ new: [FavoriteBreedDetail]) {
        // Sempre que SwiftData mudar, reconstruir rows e derivados
        viewModel.update(with: new)
    }
}
