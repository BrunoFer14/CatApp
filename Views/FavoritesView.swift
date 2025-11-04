import SwiftUI
import SwiftData
import ComposableArchitecture
import Combine

/// Ecrã que lista apenas os favoritos, lendo diretamente do SwiftData (FavoriteBreedDetail),
/// agora controlado por TCA (FavoritesFeature) com navegação em stack para BreedDetailFeature.
struct FavoritesView: View {
    let store: StoreOf<FavoritesFeature>

    // Lê snapshots persistidos dos favoritos diretamente do SwiftData
    @Query(sort: [SortDescriptor(\FavoriteBreedDetail.name, order: .forward)])
    private var favoriteDetails: [FavoriteBreedDetail]

    var body: some View {
        NavigationStackStore(
            store.scope(state: \.path, action: \.path)
        ) {
            WithViewStore(store, observe: { $0 }) { viewStore in
                content(viewStore: viewStore)
                    .navigationTitle(UIStrings.Favorites.title)
                    .onAppear {
                        viewStore.send(.onAppear)
                        viewStore.send(.favoritesSnapshotChanged(favoriteDetails))
                    }
                    // Use a publisher to observe changes to the @Query array.
                    .onReceive(favoriteDetailsPublisher) { newValue in
                        viewStore.send(.favoritesSnapshotChanged(newValue))
                    }
            }
        } destination: { destinationStore in
            SwitchStore(destinationStore) { state in
                switch state {
                case .breedDetail:
                    BreedDetailView(
                        store: destinationStore.scope(
                            state: { $0.breedDetail! },
                            action: { .breedDetail($0) }
                        )
                    )
                }
            }
        }
    }

    // Create a simple publisher from the @Query array using SwiftUI's observation.
    // This works by emitting whenever the view recomputes and the array identity changes.
    private var favoriteDetailsPublisher: AnyPublisher<[FavoriteBreedDetail], Never> {
        Just(favoriteDetails)
            .removeDuplicates(by: { lhs, rhs in
                // Avoid spamming by comparing ids & counts; adjust if needed.
                guard lhs.count == rhs.count else { return false }
                return zip(lhs, rhs).allSatisfy { $0.id == $1.id }
            })
            .eraseToAnyPublisher()
    }
}

// MARK: - Body composition
private extension FavoritesView {
    func content(viewStore: ViewStoreOf<FavoritesFeature>) -> some View {
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

    func favoritesListSection(viewStore: ViewStoreOf<FavoritesFeature>) -> some View {
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
    func averageFooterSection(viewStore: ViewStoreOf<FavoritesFeature>) -> some View {
        if let avgText = viewStore.averageLifeSpanText {
            Text("\(UIStrings.Common.averageLifeSpanOfFavoritesPrefix) \(avgText) \(UIStrings.Common.years)")
                .font(.subheadline)
                .padding()
        }
    }
}

// MARK: - Row
private extension FavoritesView {
    func favoriteRow(_ row: FavoriteRow, viewStore: ViewStoreOf<FavoritesFeature>) -> some View {
        HStack(spacing: UILayout.tileContentSpacing) {
            // Mini
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
