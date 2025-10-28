import Foundation
import SwiftData

/// Repository to manage favorites in SwiftData (async, non-MainActor).
protocol FavoritesRepositoryProtocol {
    // Favorite (IDs)
    func fetchFavorites() async throws -> [Favorite]
    func addFavorite(id: String) async throws
    func removeFavorite(id: String) async throws
    func isFavorite(id: String) async -> Bool

    // FavoriteBreedDetail (durable snapshots)
    func upsertFavoriteDetail(from breed: CatBreed) async throws
    func deleteFavoriteDetail(id: String) async throws
    func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail]
}

final class FavoritesRepository: FavoritesRepositoryProtocol {
    private let actor: FavoritesPersistenceActor

    // Preferido: receber o ModelContainer para criar um contexto de background
    init(container: ModelContainer) {
        self.actor = FavoritesPersistenceActor(container: container)
    }

    // Compat init para cenários onde já tens um DatabaseService principal (não recomendado para background)
    convenience init(context: ModelContext) {
        self.init(container: context.container)
    }

    // MARK: - Favorite (IDs)

    func fetchFavorites() async throws -> [Favorite] {
        try await actor.fetchFavorites()
    }

    func addFavorite(id: String) async throws {
        try await actor.addFavorite(id: id)
    }

    func removeFavorite(id: String) async throws {
        try await actor.removeFavorite(id: id)
    }

    func isFavorite(id: String) async -> Bool {
        await actor.isFavorite(id: id)
    }

    // MARK: - FavoriteBreedDetail

    func upsertFavoriteDetail(from breed: CatBreed) async throws {
        try await actor.upsertFavoriteDetail(from: breed)
    }

    func deleteFavoriteDetail(id: String) async throws {
        try await actor.deleteFavoriteDetail(id: id)
    }

    func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] {
        try await actor.fetchFavoriteDetailsByIDs(ids)
    }
}
