import Foundation
import SwiftData
@testable import CatApp

final class MockFavoritesRepository: FavoritesRepositoryProtocol {
    private(set) var favorites: Set<String> = []
    private(set) var details: [String: FavoriteBreedDetail] = [:]

    // Tracking de chamadas (opcional)
    private(set) var addCalls: [String] = []
    private(set) var removeCalls: [String] = []
    private(set) var upsertDetailCalls: [String] = []
    private(set) var deleteDetailCalls: [String] = []

    func fetchFavorites() async throws -> [Favorite] {
        favorites.map { Favorite(breedId: $0) }
    }

    func addFavorite(id: String) async throws {
        favorites.insert(id)
        addCalls.append(id)
    }

    func removeFavorite(id: String) async throws {
        favorites.remove(id)
        removeCalls.append(id)
    }

    func isFavorite(id: String) async -> Bool {
        favorites.contains(id)
    }

    func upsertFavoriteDetail(from breed: CatBreed) async throws {
        let detail = FavoriteBreedDetail(
            id: breed.id,
            name: breed.name,
            origin: breed.origin,
            temperament: breed.temperament,
            lifeSpan: breed.lifeSpan,
            breedDescription: breed.description,
            imageUrl: breed.image?.url ?? breed.referenceImageUrl
        )
        details[breed.id] = detail
        upsertDetailCalls.append(breed.id)
    }

    func deleteFavoriteDetail(id: String) async throws {
        details[id] = nil
        deleteDetailCalls.append(id)
    }

    func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] {
        ids.compactMap { details[$0] }
    }
}
