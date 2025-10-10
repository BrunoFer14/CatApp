import Foundation
import Combine

struct FavoriteRowModel: Identifiable, Equatable {
    let id: String
    let name: String
    let imageURL: String?
    // Mantemos um CatBreed pronto para navegação/reutilização de UI
    let breed: CatBreed
    // Flag derivada para a célula (sincronizada com CatBreedsViewModel.favoriteIDs)
    var isFavorite: Bool
}

/// ViewModel do ecrã de Favoritos: agora também transforma dados para a View.
/// A lista persistida continua a ser lida na View via @Query e passada para o VM.
@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var isEmpty: Bool = true
    @Published private(set) var rows: [FavoriteRowModel] = []
    @Published private(set) var averageLifeSpanText: String?

    private var cancellables = Set<AnyCancellable>()
    let catViewModel: CatBreedsViewModel

    init(catViewModel: CatBreedsViewModel) {
        self.catViewModel = catViewModel

        // Observa IDs para refletir "vazio" e para atualizar flags isFavorite nas rows
        catViewModel.$favoriteIDs
            .sink { [weak self] ids in
                guard let self else { return }
                self.isEmpty = ids.isEmpty
                // Atualiza flags isFavorite nas rows atuais
                self.rows = self.rows.map { row in
                    var copy = row
                    copy.isFavorite = ids.contains(row.id)
                    return copy
                }
            }
            .store(in: &cancellables)
    }

    /// A View passa os snapshots persistidos; o VM constrói rows e calcula derivados.
    func update(with details: [FavoriteBreedDetail]) {
        // Construir rows prontos
        let ids = catViewModel.favoriteIDs
        self.rows = details.map { detail in
            let breed = CatBreed(
                id: detail.id,
                name: detail.name,
                origin: detail.origin,
                description: detail.breedDescription,
                temperament: detail.temperament,
                life_span: detail.life_span,
                image: BreedImage(url: detail.imageUrl),
                referenceImageId: nil
            )
            return FavoriteRowModel(
                id: detail.id,
                name: detail.name,
                imageURL: detail.imageUrl,
                breed: breed,
                isFavorite: ids.contains(detail.id)
            )
        }

        // Média de life span formatada
        self.averageLifeSpanText = Self.computeAverageLifeSpanText(from: details)
    }

    /// Recarrega os IDs de favoritos (sincroniza com SwiftData)
    func refreshFavorites() {
        catViewModel.refreshFavorites()
    }

    func toggleFavorite(_ row: FavoriteRowModel) {
        catViewModel.toggleFavorite(for: row.breed)
    }

    func isFavorite(_ row: FavoriteRowModel) -> Bool {
        catViewModel.isFavorite(row.breed)
    }

    // MARK: - Helpers

    private static func computeAverageLifeSpanText(from details: [FavoriteBreedDetail]) -> String? {
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
