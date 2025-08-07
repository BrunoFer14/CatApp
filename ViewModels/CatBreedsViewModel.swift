import Foundation
import Combine

class CatBreedsViewModel: ObservableObject {
    @Published var breeds: [CatBreed] = []
    @Published var searchText = ""
    @Published var favoriteBreeds: Set<String> = []

    
    var cancellables = Set<AnyCancellable>()
    
    init() {
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
    
    var filteredBreeds: [CatBreed] {
        if searchText.isEmpty {
            return breeds
        } else {
            return breeds.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func toggleFavorite(for breed: CatBreed) {
        if favoriteBreeds.contains(breed.id) {
            favoriteBreeds.remove(breed.id)
        } else {
            favoriteBreeds.insert(breed.id)
        }
    }

    func isFavorite(_ breed: CatBreed) -> Bool {
        return favoriteBreeds.contains(breed.id)
    }

}

