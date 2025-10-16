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
        List {
            ForEach(filteredBreeds, id: \.id) { cached in
                // Map to CatBreed only for navigation and existing widgets
                let breed = CatBreed(
                    id: cached.id,
                    name: cached.name,
                    origin: cached.origin,
                    description: cached.breedDescription,
                    temperament: cached.temperament,
                    lifeSpan: cached.lifeSpan,
                    image: BreedImage(url: cached.imageUrl),
                    referenceImageId: nil
                )

                NavigationLink(
                    destination: BreedDetailView(breed: breed, viewModel: viewModel)
                ) {
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
                .onAppear {
                    // Pagination: when the last filtered item appears, request next page
                    if cached.id == filteredBreeds.last?.id {
                        viewModel.fetchPage(page: viewModel.currentPage + 1)
                    }
                }
            }

            if viewModel.isLoadingPage {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
        }
        .navigationTitle("Search Breeds")
        .searchable(text: $searchText, prompt: "Search breeds...")
        .onAppear {
            // Ensure initial content exists
            if cachedBreeds.isEmpty && !viewModel.isLoadingPage && !viewModel.hasLoadedFirstPage {
                viewModel.fetchPage(page: UIDimensions.initialPageIndex)
            }
        }
    }
}
