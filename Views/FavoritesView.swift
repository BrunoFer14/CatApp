import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: CatBreedsViewModel

    var body: some View {
        VStack {
            if viewModel.favoriteIDs.isEmpty {
                Text("No favorites yet 🐾")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(favoriteBreeds) { breed in
                    NavigationLink(destination: BreedDetailView(breed: breed, viewModel: viewModel)) {
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

                // ✅ Mostra a média calculada no ViewModel
                if let avg = viewModel.averageLifeSpanForFavorites() {
                    Text("Average life span of favorites: \(String(format: "%.1f", avg)) years")
                        .font(.subheadline)
                        .padding()
                }
            }
        }
        .navigationTitle("Favorites")
    }

    // Só filtra os favoritos para mostrar na lista
    private var favoriteBreeds: [CatBreed] {
        viewModel.breeds.filter { viewModel.favoriteIDs.contains($0.id) }
    }
}
