import SwiftData

// MARK: - Async, non-MainActor protocol

/// Service to store/read cached breeds (SwiftData).
/// These operations perform I/O and should not be main-thread bound.
protocol BreedsCacheDatabaseServiceProtocol {
    func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws
    func fetchCachedBreedsSorted() async throws -> [CachedBreed]
    func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed]
    /// Fetch only one page (based on orderIndex)
    func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed]
    func clearCache() async throws
}

// MARK: - Persistence actor owning a background ModelContext

actor BreedsCachePersistenceActor {
    private let context: ModelContext

    init(container: ModelContainer) {
        // Create a background context for SwiftData operations
        self.context = ModelContext(container)
    }

    // Secondary designated initializer (Swift 6: no convenience in actors)
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Operations (use this actor's ModelContext directly)

    func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) throws {
        // Fetch all at once and index by id
        let existingAll = try context.fetch(FetchDescriptor<CachedBreed>())
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
                context.insert(cached)
                existingById[breed.id] = cached
            }
        }
        // Persist changes in SwiftData
        try saveIfNeeded()
    }

    func fetchCachedBreedsSorted() throws -> [CachedBreed] {
        // Fetch all and sort in memory
        let all = try context.fetch(FetchDescriptor<CachedBreed>())
        return all.sorted { $0.orderIndex < $1.orderIndex }
    }

    func fetchBreedsByIDs(_ ids: Set<String>) throws -> [CachedBreed] {
        guard !ids.isEmpty else { return [] }
        // Fetch all and filter in memory by requested IDs
        let all = try context.fetch(FetchDescriptor<CachedBreed>())
        return all.filter { ids.contains($0.id) }
    }

    func fetchCachedPage(page: Int, limit: Int) throws -> [CachedBreed] {
        let start = page * limit
        let endExclusive = (page + 1) * limit
        let all = try context.fetch(FetchDescriptor<CachedBreed>())
        let pageItems = all.filter { $0.orderIndex >= start && $0.orderIndex < endExclusive }
        return pageItems.sorted { $0.orderIndex < $1.orderIndex }
    }

    func clearCache() throws {
        // Fetch all CachedBreed and delete
        let all = try context.fetch(FetchDescriptor<CachedBreed>())
        for item in all {
            context.delete(item)
        }
        try saveIfNeeded()
    }

    // MARK: - Helpers

    private func saveIfNeeded() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}

// MARK: - Service implementation (non-MainActor), forwarding to the actor

final class BreedsCacheDatabaseService: BreedsCacheDatabaseServiceProtocol {
    private let actor: BreedsCachePersistenceActor

    init(container: ModelContainer) {
        self.actor = BreedsCachePersistenceActor(container: container)
    }

    convenience init(context: ModelContext) {
        self.init(container: context.container)
    }

    func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws {
        try await actor.upsertBreeds(breeds, page: page, limit: limit)
    }

    func fetchCachedBreedsSorted() async throws -> [CachedBreed] {
        try await actor.fetchCachedBreedsSorted()
    }

    func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed] {
        try await actor.fetchBreedsByIDs(ids)
    }

    func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed] {
        try await actor.fetchCachedPage(page: page, limit: limit)
    }

    func clearCache() async throws {
        try await actor.clearCache()
    }
}
