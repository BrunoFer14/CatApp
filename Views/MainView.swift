import SwiftUI

struct MainView: View {
    @StateObject var viewModel: CatBreedsViewModel

    var body: some View {
        NavigationStack {
            List(viewModel.filteredBreeds) { breed in
                HStack {
                    NavigationLink(destination: BreedDetailView(breed: breed, viewModel: viewModel)) {
                        HStack {
                            if let urlString = breed.image?.url, let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                            }

                            VStack(alignment: .leading) {
                                Text(breed.name)
                                    .font(.headline)
                            }

                            Spacer()
                        }
                    }

                    Button(action: {
                        viewModel.toggleFavorite(for: breed)
                    }) {
                        Image(systemName: viewModel.isFavorite(breed) ? "heart.fill" : "heart")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .searchable(text: $viewModel.searchText)
            .navigationTitle("Cat Breeds")
            .toolbar {
                NavigationLink(destination: FavoritesView(viewModel: viewModel)) {
                    Image(systemName: "heart.circle")
                        .imageScale(.large)
                }
            }
        }
    }
}
