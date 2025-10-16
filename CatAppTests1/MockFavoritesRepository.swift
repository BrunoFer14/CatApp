import Foundation
import SwiftData
@testable import CatApp

@MainActor
final class MockFavoritesRepository: FavoritesRepositoryProtocol {
    private(set) var favorites: Set<String> = []
    private(set) var details: [String: FavoriteBreedDetail] = [:]

    // Tracking de chamadas (opcional)
    private(set) var addCalls: [String] = []
    private(set) var removeCalls: [String] = []
    private(set) var upsertDetailCalls: [String] = []
    private(set) var deleteDetailCalls: [String] = []

    func fetchFavorites() throws -> [Favorite] {
        favorites.map { Favorite(breedId: $0) }
    }

    func addFavorite(id: String) throws {
        favorites.insert(id)
        addCalls.append(id)
    }

    func removeFavorite(id: String) throws {
        favorites.remove(id)
        removeCalls.append(id)
    }

    func isFavorite(id: String) -> Bool {
        favorites.contains(id)
    }

    func upsertFavoriteDetail(from breed: CatBreed) throws {
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

    func deleteFavoriteDetail(id: String) throws {
        details[id] = nil
        deleteDetailCalls.append(id)
    }

    func fetchFavoriteDetailsByIDs(_ ids: Set<String>) throws -> [FavoriteBreedDetail] {
        ids.compactMap { details[$0] }
    }
}
