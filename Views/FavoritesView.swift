import SwiftUI
import SwiftData
import ComposableArchitecture
import Combine

/// Ecrã que lista apenas os favoritos, lendo diretamente do SwiftData (FavoriteBreedDetail),
/// agora controlado por TCA (FavoritesFeature) com navegação em stack para BreedDetailFeature.
struct FavoritesView: View {
    let store: StoreOf<FavoritesReducer>

    // Observe SwiftData changes live
    @Query(sort: [SortDescriptor(\FavoriteBreedDetail.name)])
    private var favorites: [FavoriteBreedDetail]

    var body: some View {
        NavigationStackStore(
            store.scope(state: \.path, action: \.path)
        ) {
            WithViewStore(store, observe: { $0 }) { viewStore in
                content(viewStore: viewStore)
                    .navigationTitle(UIStrings.Favorites.title)
                    .onAppear {
                        // Load favorite IDs for heart state
                        viewStore.send(.onAppear)
                        // Send initial snapshot
                        viewStore.send(.favoritesSnapshotChanged(favorites))
                    }
                    // Forward live SwiftData changes to the reducer
                    .onChange(of: favorites) { _, newValue in
                        viewStore.send(.favoritesSnapshotChanged(newValue))
                    }
                    // Optional: animate removals/insertions
                    .animation(.default, value: viewStore.rows)
            }
        } destination: { routeStore in
            SwitchStore(routeStore) { state in
                switch state {
                case .breedDetail:
                    BreedDetailView(
                        store: routeStore.scope(
                            state: { $0.breedDetail! },
                            action: { .breedDetail($0) }
                        )
                    )
                }
            }
        }
    }
}

// MARK: - Body composition
private extension FavoritesView {
    func content(viewStore: ViewStoreOf<FavoritesReducer>) -> some View {
        VStack(alignment: .leading, spacing: UILayout.sectionSpacing) {
            if viewStore.rows.isEmpty {
                emptyStateSection
            } else {
                favoritesListSection(viewStore: viewStore)
                averageFooterSection(viewStore: viewStore)
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

    func favoritesListSection(viewStore: ViewStoreOf<FavoritesReducer>) -> some View {
        List(viewStore.rows) { row in
            Button {
                viewStore.send(.tappedRow(row.breed))
            } label: {
                favoriteRow(row, viewStore: viewStore)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    func averageFooterSection(viewStore: ViewStoreOf<FavoritesReducer>) -> some View {
        if let avgText = viewStore.averageLifeSpanText {
            Text("\(UIStrings.Common.averageLifeSpanOfFavoritesPrefix) \(avgText) \(UIStrings.Common.years)")
                .font(.subheadline)
                .padding()
        }
    }
}

// MARK: - Row
private extension FavoritesView {
    func favoriteRow(_ row: FavoriteRow, viewStore: ViewStoreOf<FavoritesReducer>) -> some View {
        HStack(spacing: UILayout.tileContentSpacing) {
            // Thumbnail
            CatImageView(
                urlString: row.imageURL ?? row.breed.referenceImageUrl,
                width: UIDimensions.favoriteThumbnailSize,
                height: UIDimensions.favoriteThumbnailSize,
                cornerRadius: UILayout.favoriteThumbnailCornerRadius
            )
            Text(row.name)
                .font(.headline)
            Spacer()
            // Heart Button
            FavoriteButton(isFavorite: row.isFavorite) {
                viewStore.send(.toggleFavorite(row.breed))
            }
        }
    }
}
