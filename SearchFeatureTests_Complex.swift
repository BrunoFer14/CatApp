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
        
        let store = await TestStore(initialState: SearchFeature.State()) {
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
        
        let store = await TestStore(initialState: initialState) {
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
    
    // MARK: - Query Tests
    
    func testQueryChanged() async {
        // Arrange
        let store = await TestStore(initialState: SearchFeature.State()) {
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
        
        let store = await TestStore(initialState: SearchFeature.State()) {
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