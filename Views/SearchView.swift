import SwiftUI
import SwiftData

/// Ecrã de pesquisa local sobre o armazenamento SwiftData (CachedBreed),
/// com filtro por texto e paginação igual à Home.
struct SearchView: View {
    @ObservedObject var viewModel: CatBreedsViewModel
    @State private var searchText = ""

    // Lê diretamente do SwiftData, ordenado pelo orderIndex
    @Query(sort: [SortDescriptor(\CachedBreed.orderIndex, order: .forward)])
    private var cachedBreeds: [CachedBreed]

    // Filtra por nome, ignorando maiúsculas/minúsculas, sobre o array vindo do @Query
    private var filteredBreeds: [CachedBreed] {
        guard !searchText.isEmpty else { return cachedBreeds }
        return cachedBreeds.filter { cached in
            cached.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredBreeds, id: \.id) { cached in
                // Mapeia para CatBreed apenas para navegação e widgets existentes
                let breed = CatBreed(
                    id: cached.id,
                    name: cached.name,
                    origin: cached.origin,
                    description: cached.breedDescription,
                    temperament: cached.temperament,
                    life_span: cached.life_span,
                    image: BreedImage(url: cached.imageUrl),
                    referenceImageId: nil
                )

                NavigationLink(
                    destination: BreedDetailView(breed: breed, viewModel: viewModel)
                ) {
                    HStack(spacing: 12) {
                        CatImageView(
                            urlString: breed.image?.url ?? breed.referenceImageUrl,
                            width: 60,
                            height: 60,
                            cornerRadius: 8
                        )
                        VStack(alignment: .leading, spacing: 4) {
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
                    .padding(.vertical, 4)
                }
                .onAppear {
                    // Paginação: quando o último item filtrado aparece, pede próxima página
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
            // Garante que existe conteúdo inicial
            if cachedBreeds.isEmpty && !viewModel.isLoadingPage && !viewModel.hasLoadedFirstPage {
                viewModel.fetchPage(page: 0)
            }
        }
    }
}
