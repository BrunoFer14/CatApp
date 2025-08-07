import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = CatBreedsViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.filteredBreeds) { breed in
                HStack {
                    NavigationLink(destination: BreedDetailView(breed: breed, viewModel: viewModel)) {
                        HStack {
                            AsyncImage(url: URL(string: breed.image?.url ?? "")) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

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
