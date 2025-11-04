import SwiftData
import ComposableArchitecture

// MARK: - Async, non-MainActor protocol

protocol BreedsCacheDatabaseServiceProtocol {
    func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws
    func fetchCachedBreedsSorted() async throws -> [CachedBreed]
    func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed]
    func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed]
    func clearCache() async throws
}

// MARK: - Persistence actor owning a background ModelContext

actor BreedsCachePersistenceActor {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = ModelContext(container)
    }

    init(context: ModelContext) {
        self.context = context
    }

    func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) throws {
        let existingAll = try context.fetch(FetchDescriptor<CachedBreed>())
        var existingById: [String: CachedBreed] = Dictionary(uniqueKeysWithValues: existingAll.map { ($0.id, $0) })

        for (offset, breed) in breeds.enumerated() {
            let idx = page * limit + offset

            if let existing = existingById[breed.id] {
                existing.name = breed.name
                existing.origin = breed.origin
                existing.temperament = breed.temperament
                existing.lifeSpan = breed.lifeSpan
                existing.breedDescription = breed.description
                existing.imageUrl = breed.image?.url ?? breed.referenceImageUrl
                existing.orderIndex = idx
            } else {
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
        try saveIfNeeded()
    }

    func fetchCachedBreedsSorted() throws -> [CachedBreed] {
        let all = try context.fetch(FetchDescriptor<CachedBreed>())
        return all.sorted { $0.orderIndex < $1.orderIndex }
    }

    func fetchBreedsByIDs(_ ids: Set<String>) throws -> [CachedBreed] {
        guard !ids.isEmpty else { return [] }
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
        let all = try context.fetch(FetchDescriptor<CachedBreed>())
        for item in all {
            context.delete(item)
        }
        try saveIfNeeded()
    }

    private func saveIfNeeded() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}

// MARK: - Service implementation

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

// MARK: - TCA Dependency

private enum BreedsCacheDBKey: DependencyKey {
    static var liveValue: BreedsCacheDatabaseServiceProtocol {
        // Use the provider's own liveValue directly; do not access DependencyValues.current
        let container = try! ModelContainerProviderKey.liveValue.make()
        return BreedsCacheDatabaseService(container: container)
    }

    static var testValue: BreedsCacheDatabaseServiceProtocol {
        struct Stub: BreedsCacheDatabaseServiceProtocol {
            func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws {}
            func fetchCachedBreedsSorted() async throws -> [CachedBreed] { [] }
            func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed] { [] }
            func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed] { [] }
            func clearCache() async throws {}
        }
        return Stub()
    }

    static var previewValue: BreedsCacheDatabaseServiceProtocol { liveValue }
}

extension DependencyValues {
    var breedsCacheDB: BreedsCacheDatabaseServiceProtocol {
        get { self[BreedsCacheDBKey.self] }
        set { self[BreedsCacheDBKey.self] = newValue }
    }
}
