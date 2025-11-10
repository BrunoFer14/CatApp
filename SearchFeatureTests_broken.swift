import XCTest
import ComposableArchitecture
@testable import CatApp

final class SearchFeatureTests: XCTestCase {
    
    // MARK: - Lifecycle Tests
    
    func testOnAppearBootstrapsInitialLoad() async {
        // Arrange
        struct BreedsStub: BreedsServiceProtocol {
            func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] {
                // Return some test breeds for page 0
                guard page == 0 else { return [] }
                return [
                    CatBreed(id: "persian", name: "Persian", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil),
                    CatBreed(id: "siamese", name: "Siamese", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
                ]
            }
        }
        
        struct FavoritesStub: FavoritesServiceProtocol {
            func fetchFavorites() async throws -> [Favorite] { [Favorite(breedId: "persian")] }
            func addFavorite(id: String) async throws {}
            func removeFavorite(id: String) async throws {}
            func isFavorite(id: String) async -> Bool { false }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = BreedsStub()
            $0.favoritesService = FavoritesStub()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.onAppear)
        
        // Should trigger both refresh favorites and initial page load
        await store.receive(.refreshFavorites)
        await store.receive(.fetchPage(UIConfig.Pagination.initialPageIndex)) {
            $0.isLoadingPage = true
        }
        
        // Favorites should complete
        await store.receive(.refreshFavoritesFinished(["persian"])) {
            $0.favoriteIDs = ["persian"]
        }
        
        // Page load should succeed
        await store.receive(.fetchPageSuccess(page: 0)) {
            $0.currentPage = 0
            $0.hasLoadedFirstPage = true
            $0.isLoadingPage = false
        }
    }
    
    func testOnAppearSkipsPageLoadWhenAlreadyLoaded() async {
        // Arrange
        var initialState = SearchFeature.State()
        initialState.hasLoadedFirstPage = true // Already loaded
        
        let store = TestStore(initialState: initialState) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.onAppear)
        
        // Should only refresh favorites, not fetch page
        await store.receive(.refreshFavorites)
        await store.receive(.refreshFavoritesFinished([])) {
            $0.favoriteIDs = []
        }
    }
    
    // MARK: - Pagination Tests
    
    func testFetchPageSuccess() async {
        // Arrange
        struct BreedsStub: BreedsServiceProtocol {
            func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] {
                [CatBreed(id: "test-\(page)", name: "Test \(page)", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)]
            }
        }
        
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = BreedsStub()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.fetchPage(1)) {
            $0.isLoadingPage = true
        }
        
        await store.receive(.fetchPageSuccess(page: 1)) {
            $0.currentPage = 1
            $0.isLoadingPage = false
            // First page should remain false since this is page 1, not initial page
        }
    }
    
    func testFetchFirstPageMarksAsLoaded() async {
        // Arrange
        struct BreedsStub: BreedsServiceProtocol {
            func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] {
                [CatBreed(id: "first", name: "First", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)]
            }
        }
        
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = BreedsStub()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.fetchPage(UIConfig.Pagination.initialPageIndex)) {
            $0.isLoadingPage = true
        }
        
        await store.receive(.fetchPageSuccess(page: UIConfig.Pagination.initialPageIndex)) {
            $0.currentPage = UIConfig.Pagination.initialPageIndex
            $0.hasLoadedFirstPage = true // Should mark as loaded for initial page
            $0.isLoadingPage = false
        }
    }
    
    func testFetchPageFailureWithCacheFallback() async {
        // Arrange
        struct BreedsErrorStub: BreedsServiceProtocol {
            struct TestError: Error {}
            func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] { throw TestError() }
        }
        
        final class CacheStub: BreedsCacheDatabaseServiceProtocol {
            var fetchCachedPageCalled = false
            let cachedBreeds: [CachedBreed]
            
            init(cachedBreeds: [CachedBreed] = []) {
                self.cachedBreeds = cachedBreeds
            }
            
            func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws {}
            func fetchCachedBreedsSorted() async throws -> [CachedBreed] { [] }
            func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed] { [] }
            func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed] {
                fetchCachedPageCalled = true
                return cachedBreeds
            }
            func clearCache() async throws {}
        }
        
        let cacheStub = CacheStub(cachedBreeds: [
            CachedBreed(id: "cached1", name: "Cached 1", origin: nil, temperament: nil, lifeSpan: nil, breedDescription: nil, imageUrl: nil, orderIndex: 0)
        ])
        
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = BreedsErrorStub()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = cacheStub
        }
        
        // Act & Assert
        await store.send(.fetchPage(0)) {
            $0.isLoadingPage = true
        }
        
        // Should fall back to cache
        await store.receive(.cacheFallbackResponse(page: 0, cachedCount: 1)) {
            $0.isLoadingPage = false
            $0.currentPage = 0
            $0.hasLoadedFirstPage = true
        }
        
        await store.receive(.fetchPageFailure(page: 0)) {
            // Failure doesn't change state since cache fallback already handled it
        }
        
        XCTAssertTrue(cacheStub.fetchCachedPageCalled)
    }
    
    func testFetchPageFailureWithEmptyCache() async {
        // Arrange
        struct BreedsErrorStub: BreedsServiceProtocol {
            struct TestError: Error {}
            func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] { throw TestError() }
        }
        
        struct EmptyCacheStub: BreedsCacheDatabaseServiceProtocol {
            func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws {}
            func fetchCachedBreedsSorted() async throws -> [CachedBreed] { [] }
            func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed] { [] }
            func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed] { [] }
            func clearCache() async throws {}
        }
        
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = BreedsErrorStub()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = EmptyCacheStub()
        }
        
        // Act & Assert
        await store.send(.fetchPage(0)) {
            $0.isLoadingPage = true
        }
        
        // Should fall back to empty cache
        await store.receive(.cacheFallbackResponse(page: 0, cachedCount: 0)) {
            $0.isLoadingPage = false
            $0.hasLoadedFirstPage = true // Still marks first page as loaded even with empty cache
        }
        
        await store.receive(.fetchPageFailure(page: 0)) {
            // No additional state changes
        }
    }
    
    func testRequestNextPageIfNeeded() async {
        // Arrange
        var initialState = SearchFeature.State()
        initialState.currentPage = 2
        
        let store = TestStore(initialState: initialState) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.requestNextPageIfNeeded)
        await store.receive(.fetchPage(3)) {
            $0.isLoadingPage = true
        }
    }
    
    func testFetchPageIgnoredWhenAlreadyLoading() async {
        // Arrange
        var initialState = SearchFeature.State()
        initialState.isLoadingPage = true // Already loading
        
        let store = TestStore(initialState: initialState) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.fetchPage(1)) {
            // No state change since already loading
        }
    }
    
    // MARK: - Favorites Tests
    
    func testRefreshFavoritesSuccess() async {
        // Arrange
        struct FavoritesStub: FavoritesServiceProtocol {
            func fetchFavorites() async throws -> [Favorite] {
                [Favorite(breedId: "persian"), Favorite(breedId: "siamese")]
            }
            func addFavorite(id: String) async throws {}
            func removeFavorite(id: String) async throws {}
            func isFavorite(id: String) async -> Bool { false }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = FavoritesStub()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.refreshFavorites)
        await store.receive(.refreshFavoritesFinished(["persian", "siamese"])) {
            $0.favoriteIDs = ["persian", "siamese"]
        }
    }
    
    func testRefreshFavoritesFailure() async {
        // Arrange
        struct FailingStub: FavoritesServiceProtocol {
            struct TestError: Error {}
            
            func fetchFavorites() async throws -> [Favorite] { throw TestError() }
            func addFavorite(id: String) async throws {}
            func removeFavorite(id: String) async throws {}
            func isFavorite(id: String) async -> Bool { false }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = FailingStub()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.refreshFavorites)
        await store.receive(.refreshFavoritesFinished([])) {
            $0.favoriteIDs = []
        }
    }
    
    func testToggleFavoriteFromNotFavoriteToFavorite() async {
        // Arrange
        final class ToggleStub: FavoritesServiceProtocol {
            var favorites: Set<String> = []
            
            func fetchFavorites() async throws -> [Favorite] { [] }
            func addFavorite(id: String) async throws { favorites.insert(id) }
            func removeFavorite(id: String) async throws { favorites.remove(id) }
            func isFavorite(id: String) async -> Bool { favorites.contains(id) }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        
        let favoritesStub = ToggleStub()
        let breed = CatBreed(id: "test", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = favoritesStub
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.toggleFavorite(breed))
        await store.receive(.toggleFavoriteSuccess(id: "test")) {
            $0.favoriteIDs = ["test"]
        }
    }
    
    func testToggleFavoriteFromFavoriteToNotFavorite() async {
        // Arrange
        final class ToggleStub: FavoritesServiceProtocol {
            var favorites: Set<String> = ["test"] // Start as favorite
            
            func fetchFavorites() async throws -> [Favorite] { [] }
            func addFavorite(id: String) async throws { favorites.insert(id) }
            func removeFavorite(id: String) async throws { favorites.remove(id) }
            func isFavorite(id: String) async -> Bool { favorites.contains(id) }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        
        let favoritesStub = ToggleStub()
        let breed = CatBreed(id: "test", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        
        // Start with the breed already favorited
        var initialState = SearchFeature.State()
        initialState.favoriteIDs = ["test"]
        
        let store = TestStore(initialState: initialState) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = favoritesStub
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.toggleFavorite(breed))
        await store.receive(.toggleFavoriteSuccess(id: "test")) {
            $0.favoriteIDs = []
        }
    }
    
    func testToggleFavoriteFailure() async {
        // Arrange
        struct FailingStub: FavoritesServiceProtocol {
            struct TestError: Error {}
            
            func fetchFavorites() async throws -> [Favorite] { [] }
            func addFavorite(id: String) async throws { throw TestError() }
            func removeFavorite(id: String) async throws { throw TestError() }
            func isFavorite(id: String) async -> Bool { false }
            func upsertFavoriteDetail(from breed: CatBreed) async throws { throw TestError() }
            func deleteFavoriteDetail(id: String) async throws { throw TestError() }
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        
        let breed = CatBreed(id: "test", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = FailingStub()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.toggleFavorite(breed))
        await store.receive(.toggleFavoriteFailure) {
            // No state changes on failure in current implementation
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
        
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
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
    
    // MARK: - Query Tests
    
    func testQueryChanged() async {
        // Arrange
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.queryChanged("Persian")) {
            $0.query = "Persian"
        }
        
        await store.send(.queryChanged("")) {
            $0.query = ""
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
            func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed] { [] }
            func clearCache() async throws {}
        }

        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = BreedsErrorStub()
            $0.favoritesService = FavoritesServiceKey.testValue
            $0.breedsCacheDB = EmptyCacheStub()
        }

        await store.send(.fetchPage(0)) {
            $0.isLoadingPage = true
        }
        await store.receive(.cacheFallbackResponse(page: 0, cachedCount: 0)) {
            $0.isLoadingPage = false
            $0.hasLoadedFirstPage = true
        }
        await store.receive(.fetchPageFailure(page: 0)) {
            $0.isLoadingPage = false
        }
    }

    func testToggleFavorite() async {
        final class FavoritesToggleStub: FavoritesServiceProtocol {
            var set: Set<String> = []
            func fetchFavorites() async throws -> [Favorite] { [] }
            func addFavorite(id: String) async throws { set.insert(id) }
            func removeFavorite(id: String) async throws { set.remove(id) }
            func isFavorite(id: String) async -> Bool { set.contains(id) }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        let favStub = FavoritesToggleStub()
        let breed = CatBreed(id: "z", name: "Z", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)

        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = BreedsServiceKey.testValue
            $0.favoritesService = favStub
            $0.breedsCacheDB = BreedsCacheDBKey.testValue
        }

        await store.send(.toggleFavorite(breed))
        await store.receive(.toggleFavoriteSuccess(id: "z")) {
            $0.favoriteIDs = ["z"]
        }
        await store.send(.toggleFavorite(breed))
        await store.receive(.toggleFavoriteSuccess(id: "z")) {
            $0.favoriteIDs = []
        }
    }

    func testTappedBreedPushesDetail() async {
        let breed = CatBreed(id: "i", name: "I", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)

        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.breedsService = BreedsServiceKey.testValue
            $0.favoritesService = FavoritesServiceKey.testValue
            $0.breedsCacheDB = BreedsCacheDBKey.testValue
        }

        await store.send(.tappedBreed(breed)) {
            $0.path.append(.breedDetail(BreedDetailFeature.State(breed: breed)))
        }
    }
}

