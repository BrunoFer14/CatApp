import SwiftUI

/// Ecrã de pesquisa local (filtra a lista já carregada) em lista normal.
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
        List(filteredBreeds) { breed in
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
        }
        .navigationTitle("Search Breeds")
        .searchable(text: $searchText, prompt: "Search breeds...")
    }
}
