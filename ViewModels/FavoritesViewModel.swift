import Foundation
import Combine

/// ViewModel do ecrã de Favoritos: observa o CatBreedsViewModel.
@MainActor
final class FavoritesViewModel: ObservableObject {
    // Lista só com as raças favoritas (filtrada da lista total)
    @Published private(set) var favoriteBreeds: [CatBreed] = []
    @Published private(set) var isEmpty: Bool = true

    private var cancellables = Set<AnyCancellable>()
    let catViewModel: CatBreedsViewModel

    init(catViewModel: CatBreedsViewModel) {
        self.catViewModel = catViewModel

        // Sempre que a lista de raças ou os IDs favoritos mudam, recalcula lista de favoritos
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

    /// Permite pedir um refresh explícito (por ex., no onAppear do ecrã)
    func refreshFavorites() {
        catViewModel.refreshFavorites()
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
