import SwiftUI

/// Ecrã de pesquisa local (filtra a lista já carregada).
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
                HStack {
                    CatImageView(
                        urlString: breed.image?.url ?? breed.referenceImageUrl,
                        width: 40,
                        height: 40,
                        cornerRadius: 6
                    )
                    Text(breed.name)
                        .font(.headline)
                }
            }
        }
        .navigationTitle("Search Breeds")
        .searchable(text: $searchText, prompt: "Search breeds...")
    }
}
