import SwiftUI
import SwiftData

/// Local search screen over SwiftData storage (CachedBreed),
/// with text filtering and pagination like Home.
struct SearchView: View {
    @ObservedObject var viewModel: CatBreedsViewModel
    @State private var searchText = ""

    // Read directly from SwiftData, ordered by orderIndex
    @Query(sort: [SortDescriptor(\CachedBreed.orderIndex, order: .forward)])
    private var cachedBreeds: [CachedBreed]

    // Filter by name, case-insensitive, over the array coming from @Query
    private var filteredBreeds: [CachedBreed] {
        guard !searchText.isEmpty else { return cachedBreeds }
        return cachedBreeds.filter { cached in
            cached.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        content
            .navigationTitle(UIStrings.Search.title)
            .searchable(text: $searchText, prompt: UIStrings.Common.searchPrompt)
            .onAppear(perform: onAppearSearch)
    }
}

// MARK: - Body composition
private extension SearchView {
    var content: some View {
        List {
            listRowsSection
            loadingRowSection
        }
    }
}

// MARK: - Sections
private extension SearchView {
    var listRowsSection: some View {
        ForEach(filteredBreeds, id: \.id) { cached in
            let breed = mapCachedToBreed(cached)
            NavigationLink(
                destination: BreedDetailView(breed: breed, viewModel: viewModel)
            ) {
                breedRow(breed)
            }
            .onAppear {
                onRowAppear(cached: cached)
            }
        }
    }

    var loadingRowSection: some View {
        Group {
            if viewModel.isLoadingPage {
                HStack(spacing: UILayout.gridSpacing) {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Row
private extension SearchView {
    func breedRow(_ breed: CatBreed) -> some View {
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
            FavoriteButton(isFavorite: viewModel.isFavorite(breed)) {
                viewModel.toggleFavorite(for: breed)
            }
        }
        .padding(.vertical, UILayout.searchRowVerticalPadding)
    }
}

// MARK: - Lifecycle handlers
private extension SearchView {
    func onAppearSearch() {
        // Ensure initial content exists
        if cachedBreeds.isEmpty && !viewModel.isLoadingPage && !viewModel.hasLoadedFirstPage {
            viewModel.fetchPage(page: UIConfig.Pagination.initialPageIndex)
        }
    }

    func onRowAppear(cached: CachedBreed) {
        // Pagination: when the last filtered item appears, request next page
        if cached.id == filteredBreeds.last?.id {
            viewModel.fetchPage(page: viewModel.currentPage + 1)
        }
    }
}

// MARK: - Mapping
private extension SearchView {
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
