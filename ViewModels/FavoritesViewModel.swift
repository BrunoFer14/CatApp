import Foundation
import Combine

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var favoriteBreeds: [CatBreed] = []
    @Published private(set) var isEmpty: Bool = true

    private var cancellables = Set<AnyCancellable>()
    let catViewModel: CatBreedsViewModel

    init(catViewModel: CatBreedsViewModel) {
        self.catViewModel = catViewModel

        Publishers.CombineLatest(catViewModel.$breeds, catViewModel.$favoriteIDs)
            .map { breeds, favIDs in
                breeds.filter { favIDs.contains($0.id) }
            }
            .sink { [weak self] favorites in
                self?.favoriteBreeds = favorites
                self?.isEmpty = favorites.isEmpty
            }
            .store(in: &cancellables)
    }

    func toggleFavorite(_ breed: CatBreed) {
        catViewModel.toggleFavorite(for: breed)
    }

    func isFavorite(_ breed: CatBreed) -> Bool {
        catViewModel.isFavorite(breed)
    }

    func averageLifeSpanText() -> String? {
        guard let avg = catViewModel.averageLifeSpanForFavorites() else { return nil }
        return String(format: "%.1f", avg)
    }
}
