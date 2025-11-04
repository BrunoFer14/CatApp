import SwiftUI
import SwiftData
import ComposableArchitecture

/// Local search screen over SwiftData storage (CachedBreed)
struct SearchView: View {
    let store: StoreOf<SearchFeature>

    // Read directly from SwiftData, ordered by orderIndex
    @Query(sort: [SortDescriptor(\CachedBreed.orderIndex, order: .forward)])
    private var cachedBreeds: [CachedBreed]

    // Filter by name, case-insensitive, over the array coming from @Query
    private func filteredBreeds(_ breeds: [CachedBreed], query: String) -> [CachedBreed] {
        guard !query.isEmpty else { return breeds }
        return breeds.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStackStore(
            store.scope(state: \.path, action: \.path)
        ) {
            WithViewStore(store, observe: { $0 }) { viewStore in
                // Precompute filtered array to simplify type inference inside List/ForEach
                let filtered: [CachedBreed] = filteredBreeds(cachedBreeds, query: viewStore.query)

                List {
                    ForEach(filtered, id: \.id) { cached in
                        // Precompute mapped model outside the label to reduce inference load
                        let breed: CatBreed = mapCachedToBreed(cached)

                        Button {
                            viewStore.send(.tappedBreed(breed))
                        } label: {
                            breedRow(breed, viewStore: viewStore)
                        }
                        .onAppear {
                            onRowAppear(cached: cached, viewStore: viewStore, filtered: filtered)
                        }
                    }

                    if viewStore.isLoadingPage {
                        HStack(spacing: UILayout.gridSpacing) {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    }
                }
                .navigationTitle(UIStrings.Search.title)
                .searchable(
                    text: Binding(
                        get: { viewStore.query },
                        set: { viewStore.send(.queryChanged($0)) }
                    ),
                    prompt: UIStrings.Common.searchPrompt
                )
                .onAppear {
                    viewStore.send(.onAppear)
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
}

// MARK: - Row
private extension SearchView {
    func breedRow(_ breed: CatBreed, viewStore: ViewStoreOf<SearchFeature>) -> some View {
        HStack(spacing: UILayout.searchRowHorizontalSpacing) {
            CatImageView(
                urlString: breed.image?.url ?? breed.referenceImageUrl,
                width: UIDimensions.searchThumbnailSize,
                height: UIDimensions.searchThumbnailSize,
                cornerRadius: UILayout.searchThumbnailCornerRadius
            )
            VStack(alignment: .leading, spacing: UILayout.searchRowVerticalSpacing) {
                Text(breed.name)
                    .font(.headline)
                if let origin = breed.origin, !origin.isEmpty {
                    Text(origin)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            FavoriteButton(isFavorite: viewStore.favoriteIDs.contains(breed.id)) {
                viewStore.send(.toggleFavorite(breed))
            }
        }
        .padding(.vertical, UILayout.searchRowVerticalPadding)
    }

    func onRowAppear(cached: CachedBreed, viewStore: ViewStoreOf<SearchFeature>, filtered: [CachedBreed]) {
        // Pagination: when the last filtered item appears, request next page
        if cached.id == filtered.last?.id {
            viewStore.send(.requestNextPageIfNeeded)
        }
    }

    func mapCachedToBreed(_ cached: CachedBreed) -> CatBreed {
        CatBreed(
            id: cached.id,
            name: cached.name,
            origin: cached.origin,
            description: cached.breedDescription,
            temperament: cached.temperament,
            lifeSpan: cached.lifeSpan,
            image: BreedImage(url: cached.imageUrl),
            referenceImageId: nil
        )
    }
}
