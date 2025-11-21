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

// Protocol witness for FavoritesServiceProtocol
struct FavoritesServiceWitness: FavoritesServiceProtocol {
    var fetchFavoritesImpl: () async throws -> [Favorite] = { [] }
    var addFavoriteImpl: (_ id: String) async throws -> Void = { _ in }
    var removeFavoriteImpl: (_ id: String) async throws -> Void = { _ in }
    var isFavoriteImpl: (_ id: String) async -> Bool = { _ in false }
    var upsertFavoriteDetailImpl: (_ breed: CatBreed) async throws -> Void = { _ in }
    var deleteFavoriteDetailImpl: (_ id: String) async throws -> Void = { _ in }
    var fetchFavoriteDetailsByIDsImpl: (_ ids: Set<String>) async throws -> [FavoriteBreedDetail] = { _ in [] }

    func fetchFavorites() async throws -> [Favorite] { try await fetchFavoritesImpl() }
    func addFavorite(id: String) async throws { try await addFavoriteImpl(id) }
    func removeFavorite(id: String) async throws { try await removeFavoriteImpl(id) }
    func isFavorite(id: String) async -> Bool { await isFavoriteImpl(id) }
    func upsertFavoriteDetail(from breed: CatBreed) async throws { try await upsertFavoriteDetailImpl(breed) }
    func deleteFavoriteDetail(id: String) async throws { try await deleteFavoriteDetailImpl(id) }
    func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] {
        try await fetchFavoriteDetailsByIDsImpl(ids)
    }
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

// Base test breed (default values shared across tests)
let testBreed = CatBreed(
    id: "test-id",
    name: "Test Breed",
    origin: "Test Origin",
    description: "Test Description",
    temperament: "Calm",
    lifeSpan: "12-15",
    image: BreedImage(url: "test-image.jpg"),
    referenceImageId: nil
)

// Factory to create CatBreed with overridable defaults
func makeBreed(
    id: String = "test-id",
    name: String = "Test Breed",
    origin: String? = "Test Origin",
    description: String? = "Test Description",
    temperament: String? = "Calm",
    lifeSpan: String? = "12-15",
    image: BreedImage? = BreedImage(url: "test-image.jpg"),
    referenceImageId: String? = nil
) -> CatBreed {
    CatBreed(
        id: id,
        name: name,
        origin: origin,
        description: description,
        temperament: temperament,
        lifeSpan: lifeSpan,
        image: image,
        referenceImageId: referenceImageId
    )
}
