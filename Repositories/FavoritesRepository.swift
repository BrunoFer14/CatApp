import Foundation
import SwiftData

/// Repositório para gerir favoritos no SwiftData.
protocol FavoritesRepositoryProtocol {
    // Favorite (IDs)
    func fetchFavorites() throws -> [Favorite]
    func addFavorite(id: String) throws
    func removeFavorite(id: String) throws
    func isFavorite(id: String) -> Bool

    // FavoriteBreedDetail (durable snapshots)
    func upsertFavoriteDetail(from breed: CatBreed) throws
    func deleteFavoriteDetail(id: String) throws
    func fetchFavoriteDetailsByIDs(_ ids: Set<String>) throws -> [FavoriteBreedDetail]
}

@MainActor
class FavoritesRepository: FavoritesRepositoryProtocol {
    private let db: DatabaseServiceProtocol

    init(db: DatabaseServiceProtocol) {
        self.db = db
    }

    convenience init(context: ModelContext) {
        self.init(db: SwiftDataDatabaseService(context: context))
    }

    // MARK: - Favorite (IDs)

    func fetchFavorites() throws -> [Favorite] {
        try db.fetch(FetchDescriptor<Favorite>())
    }

    func addFavorite(id: String) throws {
        let favorite = Favorite(breedId: id)
        try db.insert(favorite)
    }

    func removeFavorite(id: String) throws {
        let predicate = #Predicate<Favorite> { $0.breedId == id }
        var descriptor = FetchDescriptor<Favorite>(predicate: predicate)
        descriptor.fetchLimit = 0

        let matches = try db.fetch(descriptor)
        for fav in matches {
            try db.delete(fav)
        }
    }

    func isFavorite(id: String) -> Bool {
        let predicate = #Predicate<Favorite> { $0.breedId == id }
        var descriptor = FetchDescriptor<Favorite>(predicate: predicate)
        descriptor.fetchLimit = 1

        let result = try? db.fetch(descriptor)
        return (result?.isEmpty == false)
    }

    // MARK: - FavoriteBreedDetail (durable snapshots)

    func upsertFavoriteDetail(from breed: CatBreed) throws {
        // Try to find existing detail
        let all = try db.fetch(FetchDescriptor<FavoriteBreedDetail>())
        if let existing = all.first(where: { $0.id == breed.id }) {
            existing.name = breed.name
            existing.origin = breed.origin
            existing.temperament = breed.temperament
            existing.life_span = breed.life_span
            existing.breedDescription = breed.description
            existing.imageUrl = breed.image?.url ?? breed.referenceImageUrl
            try db.saveIfNeeded()
        } else {
            let detail = FavoriteBreedDetail(
                id: breed.id,
                name: breed.name,
                origin: breed.origin,
                temperament: breed.temperament,
                life_span: breed.life_span,
                breedDescription: breed.description,
                imageUrl: breed.image?.url ?? breed.referenceImageUrl
            )
            try db.insert(detail)
        }
    }

    func deleteFavoriteDetail(id: String) throws {
        let all = try db.fetch(FetchDescriptor<FavoriteBreedDetail>())
        for item in all where item.id == id {
            try db.delete(item)
        }
    }

    func fetchFavoriteDetailsByIDs(_ ids: Set<String>) throws -> [FavoriteBreedDetail] {
        guard !ids.isEmpty else { return [] }
        let all = try db.fetch(FetchDescriptor<FavoriteBreedDetail>())
        return all.filter { ids.contains($0.id) }
    }
}
