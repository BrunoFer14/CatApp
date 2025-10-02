import SwiftUI

struct BreedDetailView: View {
    let breed: CatBreed
    @ObservedObject var viewModel: CatBreedsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // ✅ Usa o CatImageView com fallback (url ou referenceImageUrl)
                CatImageView(
                    urlString: breed.image?.url ?? breed.referenceImageUrl,
                    height: 200,
                    cornerRadius: 12
                )
                .frame(maxWidth: .infinity)

                Text(breed.name)
                    .font(.largeTitle)
                    .bold()

                if let origin = breed.origin {
                    Text("🌍 Origin: \(origin)")
                        .font(.subheadline)
                }

                if let temperament = breed.temperament {
                    Text("😺 Temperament: \(temperament)")
                        .font(.subheadline)
                }

                if let lifeSpan = breed.life_span {
                    Text("⏳ Life span: \(lifeSpan) years")
                        .font(.subheadline)
                }

                if let description = breed.description {
                    Text(description)
                        .padding(.top, 8)
                }

                // ✅ Botão de favoritos
                Button(action: {
                    viewModel.toggleFavorite(for: breed)
                }) {
                    HStack {
                        Image(systemName: viewModel.isFavorite(breed) ? "heart.fill" : "heart")
                            .foregroundColor(.red)
                        Text(viewModel.isFavorite(breed) ? "Remove from Favorites" : "Add to Favorites")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding(.top, 16)
            }
            .padding()
        }
        .navigationTitle(breed.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
