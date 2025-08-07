import Foundation
import Combine
import SwiftData

@MainActor
class CatBreedsViewModel: ObservableObject {
    @Published var breeds: [CatBreed] = []
    @Published var searchText = ""
    @Published var favoriteIDs: Set<String> = []

    var cancellables = Set<AnyCancellable>()
    var favoritesContext: ModelContext

    init(context: ModelContext) {
        self.favoritesContext = context
        fetchFavorites()
        fetchBreeds()
    }

    func fetchBreeds() {
        guard let url = URL(string: "https://api.thecatapi.com/v1/breeds") else { return }

        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [CatBreed].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Erro ao buscar raças: \(error)")
                }
            }, receiveValue: { [weak self] breeds in
                self?.breeds = breeds
            })
            .store(in: &cancellables)
    }

    func fetchFavorites() {
        do {
            let favorites = try favoritesContext.fetch(FetchDescriptor<Favorite>())
            favoriteIDs = Set(favorites.map { $0.breedId })
        } catch {
            print("Erro ao buscar favoritos: \(error)")
        }
    }

    func toggleFavorite(for breed: CatBreed) {
        if isFavorite(breed) {
            // Remover da base
            do {
                let favorites = try favoritesContext.fetch(FetchDescriptor<Favorite>())
                if let toDelete = favorites.first(where: { $0.breedId == breed.id }) {
                    favoritesContext.delete(toDelete)
                    try favoritesContext.save()
                    fetchFavorites()
                }
            } catch {
                print("Erro ao remover favorito: \(error)")
            }
        } else {
            let newFavorite = Favorite(breedId: breed.id)
            favoritesContext.insert(newFavorite)
            do {
                try favoritesContext.save()
                fetchFavorites()
            } catch {
                print("Erro ao adicionar favorito: \(error)")
            }
        }
    }

    func isFavorite(_ breed: CatBreed) -> Bool {
        favoriteIDs.contains(breed.id)
    }

    var filteredBreeds: [CatBreed] {
        if searchText.isEmpty {
            return breeds
        } else {
            return breeds.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
}
