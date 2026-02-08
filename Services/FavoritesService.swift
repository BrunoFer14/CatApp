import Foundation
import ComposableArchitecture
import SwiftData

protocol FavoritesServiceProtocol {
    func fetchFavorites() async throws -> [Favorite]
    func addFavorite(id: String) async throws
    func removeFavorite(id: String) async throws
    func isFavorite(id: String) async -> Bool

    func upsertFavoriteDetail(from breed: CatBreed) async throws
    func deleteFavoriteDetail(id: String) async throws
    func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail]
}

struct FavoritesService: FavoritesServiceProtocol {
    private let actor: FavoritesPersistenceActor

    init(container: ModelContainer) {
        self.actor = FavoritesPersistenceActor(container: container)
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

    // MARK: - Favorite details
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

// MARK: - TCA Dependency

private enum FavoritesServiceKey: DependencyKey {
    static var liveValue: FavoritesServiceProtocol {
        let container = try! ModelContainerProviderKey.liveValue.make()
        return FavoritesService(container: container)
    }

    static var testValue: FavoritesServiceProtocol {
        struct Stub: FavoritesServiceProtocol {
            var favorites: [Favorite] = []
            var details: [String: FavoriteBreedDetail] = [:]
            var favoriteIDs: Set<String> = []

            func fetchFavorites() async throws -> [Favorite] { favorites }
            func addFavorite(id: String) async throws {}
            func removeFavorite(id: String) async throws {}
            func isFavorite(id: String) async -> Bool { favoriteIDs.contains(id) }

            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] {
                ids.compactMap { details[$0] }
            }
        }
        return Stub()
    }

    static var previewValue: FavoritesServiceProtocol { liveValue }
}

extension DependencyValues {
    var favoritesService: FavoritesServiceProtocol {
        get { self[FavoritesServiceKey.self] }
        set { self[FavoritesServiceKey.self] = newValue }
    }
}
