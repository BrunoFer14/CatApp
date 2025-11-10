import XCTest
import ComposableArchitecture
@testable import CatApp

@MainActor
final class HomeFeatureTests: XCTestCase {
    
    // MARK: - Lifecycle Tests
    
    func testOnAppearBootstrapsInitialOperations() async {
        // Arrange
        let store = await TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.onAppear)
        
        // Reducer sends these immediately
        await store.receive(.loadCachedBreeds)
        await store.receive(.refreshFavorites)
        await store.receive(.fetchPage(UIConfig.Pagination.initialPageIndex))
        
        // Subsequent effects will flow; we don't care about them here
        await store.skipReceivedActions()
    }
    
    // MARK: - Cache Loading Tests
    
    func testLoadCachedBreedsSuccess() async {
        // Arrange
        let cachedBreeds = [
            CachedBreed(id: "persian", name: "Persian", origin: "Iran", temperament: "Calm", lifeSpan: "12-17", breedDescription: "Long-haired", imageUrl: "persian.jpg", orderIndex: 0),
            CachedBreed(id: "siamese", name: "Siamese", origin: "Thailand", temperament: "Active", lifeSpan: "15-20", breedDescription: "Vocal", imageUrl: "siamese.jpg", orderIndex: 1)
        ]
        
        struct CacheStub: BreedsCacheDatabaseServiceProtocol {
            let breeds: [CachedBreed]
            func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws {}
            func fetchCachedBreedsSorted() async throws -> [CachedBreed] { breeds }
            func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed] { [] }
            func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed] { [] }
            func clearCache() async throws {}
        }
        
        let store = await TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = CacheStub(breeds: cachedBreeds)
        }
        
        // Act & Assert
        await store.send(.loadCachedBreeds)
        await store.receive(.loadCachedBreedsFinished([
            CatBreed(id: "persian", name: "Persian", origin: "Iran", description: "Long-haired", temperament: "Calm", lifeSpan: "12-17", image: BreedImage(url: "persian.jpg"), referenceImageId: nil),
            CatBreed(id: "siamese", name: "Siamese", origin: "Thailand", description: "Vocal", temperament: "Active", lifeSpan: "15-20", image: BreedImage(url: "siamese.jpg"), referenceImageId: nil)
        ])) {
            $0.breeds = [
                CatBreed(id: "persian", name: "Persian", origin: "Iran", description: "Long-haired", temperament: "Calm", lifeSpan: "12-17", image: BreedImage(url: "persian.jpg"), referenceImageId: nil),
                CatBreed(id: "siamese", name: "Siamese", origin: "Thailand", description: "Vocal", temperament: "Active", lifeSpan: "15-20", image: BreedImage(url: "siamese.jpg"), referenceImageId: nil)
            ]
        }
    }
    
    func testLoadCachedBreedsEmpty() async {
        // Arrange
        struct EmptyCacheStub: BreedsCacheDatabaseServiceProtocol {
            func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws {}
            func fetchCachedBreedsSorted() async throws -> [CachedBreed] { [] }
            func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed] { [] }
            func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed] { [] }
            func clearCache() async throws {}
        }
        
        let store = await TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = EmptyCacheStub()
        }
        
        // Act & Assert
        await store.send(.loadCachedBreeds)
        await store.receive(.loadCachedBreedsFinished([])) {
            $0.breeds = []
        }
    }
    
    // MARK: - Navigation Tests
    
    func testTappedBreedNavigatesToDetail() async {
        // Arrange
        let breed = CatBreed(
            id: "persian",
            name: "Persian",
            origin: "Iran",
            description: "Long-haired breed",
            temperament: "Calm",
            lifeSpan: "12 - 17",
            image: BreedImage(url: "persian.jpg"),
            referenceImageId: nil
        )
        
        let store = await TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.tappedBreed(breed)) {
            $0.path.append(.breedDetail(BreedDetailFeature.State(breed: breed)))
        }
    }
}

// MARK: - Test Helpers

private struct MockBreedsService: BreedsServiceProtocol {
    func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] { [] }
}

private struct MockFavoritesService: FavoritesServiceProtocol {
    func fetchFavorites() async throws -> [Favorite] { [] }
    func addFavorite(id: String) async throws {}
    func removeFavorite(id: String) async throws {}
    func isFavorite(id: String) async -> Bool { false }
    func upsertFavoriteDetail(from breed: CatBreed) async throws {}
    func deleteFavoriteDetail(id: String) async throws {}
    func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
}

private struct MockBreedsCacheService: BreedsCacheDatabaseServiceProtocol {
    func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws {}
    func fetchCachedBreedsSorted() async throws -> [CachedBreed] { [] }
    func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed] { [] }
    func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed] { [] }
    func clearCache() async throws {}
}
