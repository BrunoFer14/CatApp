import XCTest
import ComposableArchitecture
@testable import CatApp

final class HomeFeatureTests: XCTestCase {
    
    // MARK: - Lifecycle Tests
    
    func testOnAppearBootstrapsInitialOperations() async {
        // Arrange
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.onAppear)
        
        // Should trigger all initial data loading operations
        await store.receive(.loadCachedBreeds)
        await store.receive(.refreshFavorites)
        await store.receive(.requestNextPageIfNeeded)
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
        
        let store = TestStore(initialState: HomeFeature.State()) {
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
        
        let store = TestStore(initialState: HomeFeature.State()) {
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
    
    // MARK: - Pagination Tests
    
    func testRequestNextPageWhenNoPageRequested() async {
        // Arrange
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.requestNextPageIfNeeded)
        await store.receive(.fetchPage(0)) {
            $0.isLoadingPage = true
            $0.pagesRequested = [0]
        }
    }
    
    func testRequestNextPageWhenCurrentPageAlreadyRequested() async {
        // Arrange
        var initialState = HomeFeature.State()
        initialState.pagesRequested = [0]
        initialState.currentPage = 0
        
        let store = TestStore(initialState: initialState) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert - Should not request the same page again
        await store.send(.requestNextPageIfNeeded)
        await store.receive(.fetchPage(1)) {
            $0.isLoadingPage = true
            $0.pagesRequested = [0, 1]
        }
    }
    
    func testFetchPageSuccess() async {
        // Arrange
        let testBreeds = [
            CatBreed(id: "bengal", name: "Bengal", origin: "USA", description: "Wild-looking", temperament: "Active", lifeSpan: "13-16", image: BreedImage(url: "bengal.jpg"), referenceImageId: nil)
        ]
        
        struct BreedsStub: BreedsServiceProtocol {
            let breeds: [CatBreed]
            func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] { breeds }
        }
        
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = BreedsStub(breeds: testBreeds)
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.fetchPage(0)) {
            $0.isLoadingPage = true
            $0.pagesRequested = [0]
        }
        
        await store.receive(.fetchPageSuccess(page: 0, breeds: testBreeds)) {
            $0.isLoadingPage = false
            $0.currentPage = 0
            $0.hasLoadedFirstPage = true
            $0.breeds = testBreeds
            $0.lastErrorMessage = nil
        }
    }
    
    func testFetchPageFailureWithCacheFallback() async {
        // Arrange
        struct BreedsErrorStub: BreedsServiceProtocol {
            struct TestError: Error {}
            func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] { throw TestError() }
        }
        
        let cachedBreeds = [
            CachedBreed(id: "cached", name: "Cached Breed", origin: nil, temperament: nil, lifeSpan: nil, breedDescription: nil, imageUrl: nil, orderIndex: 0)
        ]
        
        final class CacheStub: BreedsCacheDatabaseServiceProtocol {
            let cached: [CachedBreed]
            var fetchCachedPageCalled = false
            
            init(cached: [CachedBreed]) {
                self.cached = cached
            }
            
            func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws {}
            func fetchCachedBreedsSorted() async throws -> [CachedBreed] { [] }
            func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed] { [] }
            func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed] {
                fetchCachedPageCalled = true
                return cached
            }
            func clearCache() async throws {}
        }
        
        let cacheStub = CacheStub(cached: cachedBreeds)
        
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = BreedsErrorStub()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = cacheStub
        }
        
        // Act & Assert
        await store.send(.fetchPage(0)) {
            $0.isLoadingPage = true
            $0.pagesRequested = [0]
        }
        
        await store.receive(.cacheFallbackResponse(page: 0, cachedCount: 1)) {
            $0.isLoadingPage = false
            $0.currentPage = 0
            $0.hasLoadedFirstPage = true
            $0.breeds = [
                CatBreed(id: "cached", name: "Cached Breed", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: BreedImage(url: nil), referenceImageId: nil)
            ]
        }
        
        await store.receive(.fetchPageFailure(page: 0)) {
            // Failure doesn't change state since cache fallback already handled it
        }
        
        XCTAssertTrue(cacheStub.fetchCachedPageCalled)
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
        
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
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
    
    func testToggleFavoriteSuccess() async {
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
        
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = favoritesStub
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.toggleFavorite(breed: breed))
        await store.receive(.toggleFavoriteSuccess(id: "test")) {
            $0.favoriteIDs = ["test"]
            $0.lastErrorMessage = nil
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
        
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = FailingStub()
            $0.breedsCacheDB = MockBreedsCacheService()
        }
        
        // Act & Assert
        await store.send(.toggleFavorite(breed: breed))
        await store.receive(.toggleFavoriteFailure) {
            $0.lastErrorMessage = UIStrings.Common.favoriteUpdateFailure
        }
    }
    
    // MARK: - Cache Management Tests
    
    func testClearCacheSuccess() async {
        // Arrange
        final class CacheStub: BreedsCacheDatabaseServiceProtocol {
            var clearCacheCalled = false
            
            func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws {}
            func fetchCachedBreedsSorted() async throws -> [CachedBreed] { [] }
            func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed] { [] }
            func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed] { [] }
            func clearCache() async throws {
                clearCacheCalled = true
            }
        }
        
        let cacheStub = CacheStub()
        
        var initialState = HomeFeature.State()
        initialState.breeds = [CatBreed(id: "test", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)]
        initialState.currentPage = 5
        initialState.hasLoadedFirstPage = true
        initialState.pagesRequested = [0, 1, 2]
        
        let store = TestStore(initialState: initialState) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = MockBreedsService()
            $0.favoritesService = MockFavoritesService()
            $0.breedsCacheDB = cacheStub
        }
        
        // Act & Assert
        await store.send(.clearCache)
        await store.receive(.clearCacheFinished) {
            $0.breeds = []
            $0.currentPage = 0
            $0.hasLoadedFirstPage = false
            $0.pagesRequested = []
            $0.lastErrorMessage = nil
        }
        
        XCTAssertTrue(cacheStub.clearCacheCalled)
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
        
        let store = TestStore(initialState: HomeFeature.State()) {
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

        // Provide deterministic favorites and API response for first page
        let sampleBreed = CatBreed(
            id: "abys", name: "Abyssinian", origin: "Egypt", description: "Desc",
            temperament: "Active", lifeSpan: "14 - 15", image: BreedImage(url: "u1"), referenceImageId: nil
        )
        // Breeds service returns 1 item for page 0
        struct BreedsStub: BreedsServiceProtocol {
            let pages: [Int: [CatBreed]]
            func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] {
                return pages[page] ?? []
            }
        }
        breedsService = BreedsStub(pages: [0: [sampleBreed]])

        // Favorites service returns one favorite id
        struct FavoritesStub: FavoritesServiceProtocol {
            func fetchFavorites() async throws -> [Favorite] { [Favorite(breedId: "abys")] }
            func addFavorite(id: String) async throws {}
            func removeFavorite(id: String) async throws {}
            func isFavorite(id: String) async -> Bool { id == "abys" }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        favoritesService = FavoritesStub()

        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = breedsService
            $0.favoritesService = favoritesService
            $0.breedsCacheDB = breedsCacheDB
        }

        // onAppear triggers loadCachedBreeds, refreshFavorites and initial fetchPage(0)
        await store.send(.onAppear)

        // loadCachedBreeds runs and finishes with empty (test stub returns [])
        await store.receive(.loadCachedBreeds)

        await store.receive(.refreshFavorites)
        await store.receive(.fetchPage(UIConfig.Pagination.initialPageIndex))

        // fetchPage marks loading
        await store.receive(.refreshFavoritesFinished(["abys"])) {
            $0.favoriteIDs = ["abys"]
        }

        // Because the fetchPage effect runs, we should receive fetchPageSuccess then loadCachedBreeds again
        await store.receive(.fetchPageSuccess(page: 0, breeds: [sampleBreed])) {
            $0.currentPage = 0
            $0.hasLoadedFirstPage = true
            $0.isLoadingPage = false
            $0.lastErrorMessage = nil
        }

        // After success, reducer sends .loadCachedBreeds again
        await store.receive(.loadCachedBreeds)
        // Then finishes loadCachedBreedsFinished with the stubbed DB (empty)
        await store.receive(.loadCachedBreedsFinished([])) {
            $0.breeds = []
        }
    }

    func testFetchPageFailureUsesCacheFallbackAndSetsError() async {
        // Breeds service throws
        struct BreedsErrorStub: BreedsServiceProtocol {
            struct E: Error {}
            func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] { throw E() }
        }
        let breedsService: BreedsServiceProtocol = BreedsErrorStub()

        // Cache returns empty for the requested page
        struct EmptyCacheStub: BreedsCacheDatabaseServiceProtocol {
            func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws {}
            func fetchCachedBreedsSorted() async throws -> [CachedBreed] { [] }
            func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed] { [] }
            func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed] { [] }
            func clearCache() async throws {}
        }
        let breedsCacheDB: BreedsCacheDatabaseServiceProtocol = EmptyCacheStub()

        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = breedsService
            $0.favoritesService = FavoritesServiceKey.testValue
            $0.breedsCacheDB = breedsCacheDB
        }

        await store.send(.fetchPage(0)) {
            $0.isLoadingPage = true
            $0.lastErrorMessage = nil
            $0.pagesRequested = [0]
        }

        // Failure path emits cacheFallbackResponse then fetchPageFailure
        await store.receive(.cacheFallbackResponse(page: 0, cachedCount: 0)) {
            $0.isLoadingPage = false
            $0.hasLoadedFirstPage = true
        }
        await store.receive(.fetchPageFailure(page: 0)) {
            $0.lastErrorMessage = "\(UIStrings.Common.pageLoadFailure) 0."
        }
    }

    func testToggleFavoriteAddThenRemove() async {
        // Build a favorites service that toggles state based on internal flag
        final class FavoritesToggleStub: FavoritesServiceProtocol {
            var isFav = false
            func fetchFavorites() async throws -> [Favorite] { [] }
            func addFavorite(id: String) async throws { isFav = true }
            func removeFavorite(id: String) async throws { isFav = false }
            func isFavorite(id: String) async -> Bool { isFav }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        let favStub = FavoritesToggleStub()

        let breed = CatBreed(
            id: "b1", name: "B1", origin: nil, description: nil,
            temperament: nil, lifeSpan: nil, image: nil, referenceImageId: "ref"
        )

        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = BreedsServiceKey.testValue
            $0.favoritesService = favStub
            $0.breedsCacheDB = BreedsCacheDBKey.testValue
        }

        // Add
        await store.send(.toggleFavorite(breed: breed))
        await store.receive(.toggleFavoriteSuccess(id: "b1")) {
            $0.favoriteIDs.insert("b1")
        }

        // Remove
        await store.send(.toggleFavorite(breed: breed))
        await store.receive(.toggleFavoriteSuccess(id: "b1")) {
            $0.favoriteIDs.remove("b1")
        }
    }

    func testTappedBreedPushesDetail() async {
        let sample = CatBreed(
            id: "id", name: "Name", origin: nil, description: nil,
            temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil
        )

        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.breedsService = BreedsServiceKey.testValue
            $0.favoritesService = FavoritesServiceKey.testValue
            $0.breedsCacheDB = BreedsCacheDBKey.testValue
        }

        await store.send(.tappedBreed(sample)) {
            $0.path.append(.breedDetail(BreedDetailFeature.State(breed: sample)))
        }
    }
}

