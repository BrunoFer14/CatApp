import SwiftData

/// Service to store/read cached breeds (SwiftData).
@MainActor
protocol BreedsCacheDatabaseServiceProtocol {
    func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) throws
    func fetchCachedBreedsSorted() throws -> [CachedBreed]
    func fetchBreedsByIDs(_ ids: Set<String>) throws -> [CachedBreed]
    func fetchCachedPage(page: Int, limit: Int) throws -> [CachedBreed] // NEW: fetch only one page
    func clearCache() throws
}

@MainActor
final class BreedsCacheDatabaseService: BreedsCacheDatabaseServiceProtocol {
    private let db: DatabaseServiceProtocol

    init(db: DatabaseServiceProtocol) {
        self.db = db
    }

    convenience init(context: ModelContext) {
        self.init(db: SwiftDataDatabaseService(context: context))
    }

    func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) throws {
        // Fetch all at once and index by id (avoids #Predicate)
        let existingAll = try db.fetch(FetchDescriptor<CachedBreed>())
        var existingById: [String: CachedBreed] = Dictionary(uniqueKeysWithValues: existingAll.map { ($0.id, $0) })

        for (offset, breed) in breeds.enumerated() {
            let idx = page * limit + offset

            if let existing = existingById[breed.id] {
                // Update fields
                existing.name = breed.name
                existing.origin = breed.origin
                existing.temperament = breed.temperament
                existing.lifeSpan = breed.lifeSpan
                existing.breedDescription = breed.description
                existing.imageUrl = breed.image?.url ?? breed.referenceImageUrl
                existing.orderIndex = idx
            } else {
                // Insert new
                let cached = CachedBreed(
                    id: breed.id,
                    name: breed.name,
                    origin: breed.origin,
                    temperament: breed.temperament,
                    lifeSpan: breed.lifeSpan,
                    breedDescription: breed.description,
                    imageUrl: breed.image?.url ?? breed.referenceImageUrl,
                    orderIndex: idx
                )
                try db.insert(cached)
                existingById[breed.id] = cached
            }
        }
        // Persist changes in SwiftData
        try db.saveIfNeeded()
    }

    func fetchCachedBreedsSorted() throws -> [CachedBreed] {
        // Fetch all and sort in memory (avoids SortDescriptor)
        let all = try db.fetch(FetchDescriptor<CachedBreed>())
        return all.sorted { $0.orderIndex < $1.orderIndex }
    }

    func fetchBreedsByIDs(_ ids: Set<String>) throws -> [CachedBreed] {
        guard !ids.isEmpty else { return [] }
        // Fetch all and filter in memory by requested IDs
        let all = try db.fetch(FetchDescriptor<CachedBreed>())
        return all.filter { ids.contains($0.id) }
    }

    // NEW: returns only the items from that page (based on orderIndex)
    func fetchCachedPage(page: Int, limit: Int) throws -> [CachedBreed] {
        let start = page * limit
        let endExclusive = (page + 1) * limit
        let all = try db.fetch(FetchDescriptor<CachedBreed>())
        let pageItems = all.filter { $0.orderIndex >= start && $0.orderIndex < endExclusive }
        return pageItems.sorted { $0.orderIndex < $1.orderIndex }
    }

    func clearCache() throws {
        try db.deleteAll(CachedBreed.self)
    }
}
