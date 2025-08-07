import SwiftUI

struct BreedDetailView: View {
    let breed: CatBreed
    @ObservedObject var viewModel: CatBreedsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageUrl = breed.image?.url, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                }

                HStack {
                    Text(breed.name)
                        .font(.largeTitle)
                        .bold()

                    Spacer()

                    Button(action: {
                        viewModel.toggleFavorite(for: breed)
                    }) {
                        Image(systemName: viewModel.isFavorite(breed) ? "heart.fill" : "heart")
                            .foregroundColor(.red)
                            .imageScale(.large)
                    }
                }

                if let origin = breed.origin {
                    Text("🌍 Origem: \(origin)")
                }

                if let life = breed.life_span {
                    Text("🕐 Expectativa de vida: \(life) anos")
                }

                if let temperament = breed.temperament {
                    Text("😺 Temperamento: \(temperament)")
                }

                if let description = breed.description {
                    Text("📄 Descrição:\n\(description)")
                }
            }
            .padding()
        }
        .navigationTitle(breed.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}


