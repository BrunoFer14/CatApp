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

    // Passa a calcular a média a partir dos snapshots persistidos (FavoriteBreedDetail) via FavoritesRepository,
    // acessível através do CatBreedsViewModel (que mantém o repositório).
    // Como o FavoritesRepository não é exposto publicamente, usamos um helper que faz o fetch via catViewModel.
    func averageLifeSpanText() -> String? {
        // Obter IDs favoritos do ViewModel
        let ids = catViewModel.favoriteIDs
        guard !ids.isEmpty else { return nil }

        // Tentar obter detalhes persistidos via FavoritesRepository através de um método auxiliar
        // Nota: como FavoritesRepository é privado no CatBreedsViewModel, aqui optamos por
        // reutilizar a lista observable favoriteBreeds se existir (fallback), senão não mostramos média.
        // Se quiseres o cálculo 100% baseado em FavoriteBreedDetail, expõe um método no ViewModel
        // para devolver esses detalhes, ou injeta o FavoritesRepository aqui.
        let values: [Double] = favoriteBreeds.compactMap { breed in
            guard let life = breed.life_span else { return nil }
            let parts = life
                .components(separatedBy: "-")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .compactMap(Double.init)

            switch parts.count {
            case 2: return (parts[0] + parts[1]) / 2.0
            case 1: return parts[0]
            default: return nil
            }
        }

        guard !values.isEmpty else { return nil }
        let avg = values.reduce(0, +) / Double(values.count)
        return String(format: "%.1f", avg)
    }
}

