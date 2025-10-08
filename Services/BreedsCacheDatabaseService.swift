import SwiftData

/// Serviço para guardar/ler raças em cache (SwiftData).
@MainActor
protocol BreedsCacheDatabaseServiceProtocol {
    func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) throws
    func fetchCachedBreedsSorted() throws -> [CachedBreed]
    func fetchBreedsByIDs(_ ids: Set<String>) throws -> [CachedBreed]
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
        // Busca todos de uma vez e indexa por id (evita #Predicate)
        let existingAll = try db.fetch(FetchDescriptor<CachedBreed>())
        var existingById: [String: CachedBreed] = Dictionary(uniqueKeysWithValues: existingAll.map { ($0.id, $0) })

        for (offset, breed) in breeds.enumerated() {
            let idx = page * limit + offset

            if let existing = existingById[breed.id] {
                // Atualiza campos
                existing.name = breed.name
                existing.origin = breed.origin
                existing.temperament = breed.temperament
                existing.life_span = breed.life_span
                existing.breedDescription = breed.description
                existing.imageUrl = breed.image?.url ?? breed.referenceImageUrl
                existing.orderIndex = idx
            } else {
                // Insere novo
                let cached = CachedBreed(
                    id: breed.id,
                    name: breed.name,
                    origin: breed.origin,
                    temperament: breed.temperament,
                    life_span: breed.life_span,
                    breedDescription: breed.description,
                    imageUrl: breed.image?.url ?? breed.referenceImageUrl,
                    orderIndex: idx
                )
                try db.insert(cached)
                existingById[breed.id] = cached
            }
        }
        // Guarda alterações no SwiftData
        try db.saveIfNeeded()
    }

    func fetchCachedBreedsSorted() throws -> [CachedBreed] {
        // Busca tudo e ordena em memória (evita SortDescriptor)
        let all = try db.fetch(FetchDescriptor<CachedBreed>())
        return all.sorted { $0.orderIndex < $1.orderIndex }
    }

    func fetchBreedsByIDs(_ ids: Set<String>) throws -> [CachedBreed] {
        guard !ids.isEmpty else { return [] }
        // Busca tudo e filtra em memória pelos IDs pedidos
        let all = try db.fetch(FetchDescriptor<CachedBreed>())
        return all.filter { ids.contains($0.id) }
    }

    func clearCache() throws {
        try db.deleteAll(CachedBreed.self)
    }
}
