import Foundation
import Combine

struct FavoriteRowModel: Identifiable, Equatable {
    let id: String
    let name: String
    let imageURL: String?
    // Keep a CatBreed ready for navigation/UI reuse
    let breed: CatBreed
    // Derived flag for the cell (kept in sync with CatBreedsViewModel.favoriteIDs)
    var isFavorite: Bool
}

/// ViewModel for the Favorites screen: also transforms data for the View.
/// The persisted list continues to be read in the View via @Query and passed to the VM.
@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var isEmpty: Bool = true
    @Published private(set) var rows: [FavoriteRowModel] = []
    @Published private(set) var averageLifeSpanText: String?

    private var cancellables = Set<AnyCancellable>()
    let catViewModel: CatBreedsViewModel

    init(catViewModel: CatBreedsViewModel) {
        self.catViewModel = catViewModel

        // Observe IDs to reflect "empty" and update isFavorite flags in the rows
        catViewModel.$favoriteIDs
            .sink { [weak self] ids in
                guard let self else { return }
                self.isEmpty = ids.isEmpty
                // Update isFavorite flags in current rows
                self.rows = self.rows.map { row in
                    var copy = row
                    copy.isFavorite = ids.contains(row.id)
                    return copy
                }
            }
            .store(in: &cancellables)
    }

    /// The View passes the persisted snapshots; the VM builds rows and computes derived values.
    func update(with details: [FavoriteBreedDetail]) {
        // Build ready-to-use rows
        let ids = catViewModel.favoriteIDs
        self.rows = details.map { detail in
            let breed = CatBreed(
                id: detail.id,
                name: detail.name,
                origin: detail.origin,
                description: detail.breedDescription,
                temperament: detail.temperament,
                lifeSpan: detail.lifeSpan,
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

        // Formatted average life span
        self.averageLifeSpanText = Self.computeAverageLifeSpanText(from: details)
    }

    /// Reload favorite IDs (sync with SwiftData)
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
            guard let life = detail.lifeSpan else { return nil }
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
