import Foundation
import SwiftData

actor FavoritesPersistenceActor {
    private let context: ModelContext

    init(container: ModelContainer) {
        // Cria um contexto de background próprio deste actor
        self.context = ModelContext(container)
    }

    // MARK: - Favorite (IDs)

    func fetchFavorites() throws -> [Favorite] {
        try context.fetch(FetchDescriptor<Favorite>())
    }

    func addFavorite(id: String) throws {
        let favorite = Favorite(breedId: id)
        context.insert(favorite)
        try saveIfNeeded()
    }

    func removeFavorite(id: String) throws {
        let predicate = #Predicate<Favorite> { $0.breedId == id }
        let descriptor = FetchDescriptor<Favorite>(predicate: predicate)
        let matches = try context.fetch(descriptor)
        for fav in matches {
            context.delete(fav)
        }
        try saveIfNeeded()
    }

    func isFavorite(id: String) -> Bool {
        let predicate = #Predicate<Favorite> { $0.breedId == id }
        var descriptor = FetchDescriptor<Favorite>(predicate: predicate)
        descriptor.fetchLimit = 1
        let result = try? context.fetch(descriptor)
        return (result?.isEmpty == false)
    }

    // MARK: - FavoriteBreedDetail (durable snapshots)

    func upsertFavoriteDetail(from breed: CatBreed) throws {
        let predicate = #Predicate<FavoriteBreedDetail> { $0.id == breed.id }
        var descriptor = FetchDescriptor<FavoriteBreedDetail>(predicate: predicate)
        descriptor.fetchLimit = 1
        let existing = try context.fetch(descriptor).first

        if let existing {
            existing.name = breed.name
            existing.origin = breed.origin
            existing.temperament = breed.temperament
            existing.lifeSpan = breed.lifeSpan
            existing.breedDescription = breed.description
            existing.imageUrl = breed.image?.url ?? breed.referenceImageUrl
            try saveIfNeeded()
        } else {
            let detail = FavoriteBreedDetail(
                id: breed.id,
                name: breed.name,
                origin: breed.origin,
                temperament: breed.temperament,
                lifeSpan: breed.lifeSpan,
                breedDescription: breed.description,
                imageUrl: breed.image?.url ?? breed.referenceImageUrl
            )
            context.insert(detail)
            try saveIfNeeded()
        }
    }

    func deleteFavoriteDetail(id: String) throws {
        let predicate = #Predicate<FavoriteBreedDetail> { $0.id == id }
        let descriptor = FetchDescriptor<FavoriteBreedDetail>(predicate: predicate)
        let matches = try context.fetch(descriptor)
        for item in matches {
            context.delete(item)
        }
        try saveIfNeeded()
    }

    func fetchFavoriteDetailsByIDs(_ ids: Set<String>) throws -> [FavoriteBreedDetail] {
        guard !ids.isEmpty else { return [] }
        let idsArray = Array(ids)
        let predicate = #Predicate<FavoriteBreedDetail> { detail in
            idsArray.contains(detail.id)
        }
        let descriptor = FetchDescriptor<FavoriteBreedDetail>(predicate: predicate)
        return try context.fetch(descriptor)
    }

    // MARK: - Helpers

    private func saveIfNeeded() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
