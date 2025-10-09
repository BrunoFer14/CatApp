import SwiftUI

/// Ecrã de pesquisa local (filtra a lista já carregada) com paginação igual à Home.
struct SearchView: View {
    @ObservedObject var viewModel: CatBreedsViewModel
    @State private var searchText = ""

    // Filtra por nome, ignorando maiúsculas/minúsculas
    private var filteredBreeds: [CatBreed] {
        if searchText.isEmpty {
            return viewModel.breeds
        } else {
            return viewModel.breeds.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List {
            ForEach(filteredBreeds) { breed in
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
                    // Paginação: quando o último item filtrado aparece,
                    // pede a próxima página do catálogo global.
                    if breed.id == filteredBreeds.last?.id {
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
    }
}
