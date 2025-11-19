import Foundation
@testable import CatApp

// Shared stubs for tests across reducers

struct FavoritesStub: FavoritesServiceProtocol {
    var initiallyFavorite: Bool
    func fetchFavorites() async throws -> [Favorite] { [] }
    func addFavorite(id: String) async throws {}
    func removeFavorite(id: String) async throws {}
    func isFavorite(id: String) async -> Bool { initiallyFavorite }
    func upsertFavoriteDetail(from breed: CatBreed) async throws {}
    func deleteFavoriteDetail(id: String) async throws {}
    func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
}

struct DetailsStub: DetailsServiceProtocol {
    var detail: CatBreed?
    var images: [BreedGalleryImage] = []
    func breedDetail(id: String) async throws -> CatBreed? { detail }
    func breedImages(id: String, limit: Int) async throws -> [BreedGalleryImage] { images }
}

struct BreedsServiceStub: BreedsServiceProtocol {
    var pages: [Int: [CatBreed]] = [:]
    var error: Error? = nil
    func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] {
        if let error { throw error }
        return pages[page] ?? []
    }
}

struct BreedsCacheDBStub: BreedsCacheDatabaseServiceProtocol {
    var cachedPages: [Int: [CachedBreed]] = [:]
    func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws {}
    func fetchCachedBreedsSorted() async throws -> [CachedBreed] { [] }
    func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed] { [] }
    func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed] {
        cachedPages[page] ?? []
    }
    func clearCache() async throws {}
}
