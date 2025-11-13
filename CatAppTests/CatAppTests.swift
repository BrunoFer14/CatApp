import Testing
@testable import CatApp
import ComposableArchitecture

struct CatAppTests {
    
    @Test
    func testInitialState() async {
        // Given - Create a test breed
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
        
        // When - Create TestStore with initial state
        let store = await TestStore(
            initialState: BreedDetailReducer.State(breed: testBreed),
            reducer: { BreedDetailReducer() }
        )
        
        // Then - Verify initial values from store.state
        let state = await store.state
        #expect(state.breed.id == "test-id")
        #expect(state.breed.name == "Test Breed")
        #expect(state.screenState == .loading)
        #expect(state.isFavorite == false)
        #expect(state.isLoading == false)
        #expect(state.isLoadingGallery == false)
        #expect(state.imageItems.isEmpty)
        #expect(state.selectedIndex == UIConfig.Pagination.initialPageIndex)
        #expect(state.lastErrorMessage == nil)
    }
    
    @Test
    func isFavoriteButtonToggled() async throws {
        // Given
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
        
        // When - Build store and override dependency to simulate "not favorite" -> toggled to favorite
        let store = await TestStore(
            initialState: BreedDetailReducer.State(breed: testBreed),
            reducer: { BreedDetailReducer() },
            withDependencies: { deps in
                deps.favoritesService = FavoritesStub(initiallyFavorite: false)
            }
        )
        
        //send the toggle action
        await store.send(.toggleFavorite)
        
        // Then - expect the reducer to emit success and flip isFavorite to true
        await store.receive(.toggleFavoriteSuccess(id: "test-id", isNowFavorite: true)) { state in
            state.isFavorite = true
            state.lastErrorMessage = nil
        }
    }
}

    // - MARK: Stubs
    // A default stub for FavoritesServiceProtocol
    struct FavoritesStub: FavoritesServiceProtocol {
        var initiallyFavorite: Bool
        var addCalled = false
        var removeCalled = false

        func fetchFavorites() async throws -> [Favorite] { [] }
        func addFavorite(id: String) async throws { }
        func removeFavorite(id: String) async throws { }
        func isFavorite(id: String) async -> Bool { initiallyFavorite }
        func upsertFavoriteDetail(from breed: CatBreed) async throws { }
        func deleteFavoriteDetail(id: String) async throws { }
        func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws ->  [FavoriteBreedDetail] { [] }
    }
