import Foundation
import Combine

/// ViewModel do ecrã de Favoritos: foca-se em ações e derivados.
/// A lista de favoritos é lida diretamente do SwiftData na View via @Query (FavoriteBreedDetail).
@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var isEmpty: Bool = true

    private var cancellables = Set<AnyCancellable>()
    let catViewModel: CatBreedsViewModel

    init(catViewModel: CatBreedsViewModel) {
        self.catViewModel = catViewModel

        // Observa apenas a lista de IDs para refletir "vazio" (a lista real vem do @Query na View)
        catViewModel.$favoriteIDs
            .map { $0.isEmpty }
            .assign(to: &$isEmpty)
    }

    /// Recarrega os IDs de favoritos (sincroniza com SwiftData)
    func refreshFavorites() {
        catViewModel.refreshFavorites()
    }

    func toggleFavorite(_ breed: CatBreed) {
        catViewModel.toggleFavorite(for: breed)
    }

    func isFavorite(_ breed: CatBreed) -> Bool {
        catViewModel.isFavorite(breed)
    }

    /// Calcula a média de life span a partir de uma lista de snapshots (FavoriteBreedDetail) fornecida pela View.
    /// Isto evita dependência da lista geral e usa a fonte persistida.
    func averageLifeSpanText(from details: [FavoriteBreedDetail]) -> String? {
        let values: [Double] = details.compactMap { detail in
            guard let life = detail.life_span else { return nil }
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

