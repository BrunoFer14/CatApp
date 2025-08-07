import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: CatBreedsViewModel
    
    var favoriteBreeds: [CatBreed] {
        viewModel.breeds.filter { viewModel.isFavorite($0) }
    }

    var averageLifeSpan: Double {
        let spans = favoriteBreeds.compactMap { breed -> Double? in
            guard let span = breed.life_span else { return nil }
            let parts = span.components(separatedBy: " - ").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            if parts.count == 2 {
                return (parts[0] + parts[1]) / 2.0
            } else if parts.count == 1 {
                return parts[0]
            }
            return nil
        }
        guard !spans.isEmpty else { return 0 }
        return spans.reduce(0, +) / Double(spans.count)
    }

    var body: some View {
        VStack {
            if favoriteBreeds.isEmpty {
                Text("Sem favoritos ainda 😿")
                    .font(.title3)
                    .padding()
            } else {
                Text("Média expectativa de vida: \(String(format: "%.1f", averageLifeSpan)) anos")
                    .font(.headline)
                    .padding()

                List(favoriteBreeds) { breed in
                    HStack {
                        Text(breed.name)
                            .font(.headline)

                        Spacer()

                        Button(action: {
                            viewModel.toggleFavorite(for: breed)
                        }) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .navigationTitle("Favoritos")
    }
}


