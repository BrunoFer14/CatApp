import SwiftUI
import SwiftData
import ComposableArchitecture
import Combine

/// Screen that only lists favorites, read from SwiftData(FavoriteBreedDetail)
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
                    // Animate list diffs smoothly
                    .animation(.default, value: viewStore.rows)
                    .safeAreaInset(edge: .bottom) {
                        averageFooterInset(viewStore: viewStore)
                    }
            }
        } destination: { routeStore in
            SwitchStore(routeStore) { state in
                switch state {
                case .breedDetail:
                    BreedDetailView(
                        store: routeStore.scope(
                            state: \.breedDetail!,
                            action: \.breedDetail
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
        // The safeAreaInset for the footer will automatically push content above it.
    }

    /// Bottom inset renderer for the average lifespan footer.
    /// Keeps it centered, pretty, and only visible when we have a value.
    @ViewBuilder
    func averageFooterInset(viewStore: ViewStoreOf<FavoritesReducer>) -> some View {
        if let avgText = viewStore.averageLifeSpanText, !avgText.isEmpty, !viewStore.rows.isEmpty {
            HStack {
                Text("\(UIStrings.Common.averageLifeSpanOfFavoritesPrefix) \(avgText) \(UIStrings.Common.years)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial) // Pretty blur background
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 8) // Safe area inset will keep this above the bottom edge
        } else {
            // No footer when there is no average
            EmptyView()
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
        .contentShape(Rectangle())
    }
}
