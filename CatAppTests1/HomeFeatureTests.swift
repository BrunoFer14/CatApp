import XCTest
import ComposableArchitecture
@testable import CatApp

@MainActor
final class HomeFeatureTests: XCTestCase {
    
    func testInitialState() {
        // Arrange & Act
        let state = HomeFeature.State()
        
        // Assert
        XCTAssertTrue(state.breeds.isEmpty)
        XCTAssertTrue(state.favoriteIDs.isEmpty)
        XCTAssertFalse(state.isLoadingPage)
        XCTAssertEqual(state.currentPage, 0)
        XCTAssertFalse(state.hasLoadedFirstPage)
        XCTAssertTrue(state.pagesRequested.isEmpty)
        XCTAssertNil(state.lastErrorMessage)
    }
    
    func testOnAppearTriggersActions() {
        // Arrange
        var state = HomeFeature.State()
        
        // Act
        let reducer = HomeFeature()
        let action = HomeFeature.Action.onAppear
        let effect = reducer.reduce(into: &state, action: action)
        
        // Assert - Should trigger merged actions
        XCTAssertNotNil(effect)
    }
    
    func testFetchPageSuccessUpdatesStateForFirstPage() {
        // Arrange
        var state = HomeFeature.State()
        let page = UIConfig.Pagination.initialPageIndex
        let breeds = [
            CatBreed(id: "test1", name: "Test 1", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil),
            CatBreed(id: "test2", name: "Test 2", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        ]
        
        // Act
        let reducer = HomeFeature()
        let action = HomeFeature.Action.fetchPageSuccess(page: page, breeds: breeds)
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertEqual(state.currentPage, page)
        XCTAssertTrue(state.hasLoadedFirstPage)
        XCTAssertFalse(state.isLoadingPage)
        XCTAssertNil(state.lastErrorMessage)
    }
    
    func testFetchPageFailureHandlesFirstPage() {
        // Arrange
        var state = HomeFeature.State()
        let page = UIConfig.Pagination.initialPageIndex
        
        // Act
        let reducer = HomeFeature()
        let action = HomeFeature.Action.fetchPageFailure(page: page)
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertTrue(state.hasLoadedFirstPage) // Still marks as loaded even on failure
        XCTAssertFalse(state.isLoadingPage)
        XCTAssertNotNil(state.lastErrorMessage)
    }
    
    func testLoadCachedBreedsFinishedUpdatesBreeds() {
        // Arrange
        var state = HomeFeature.State()
        let breeds = [
            CatBreed(id: "cached1", name: "Cached 1", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil),
            CatBreed(id: "cached2", name: "Cached 2", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        ]
        
        // Act
        let reducer = HomeFeature()
        let action = HomeFeature.Action.loadCachedBreedsFinished(breeds)
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertEqual(state.breeds.count, 2)
        XCTAssertEqual(state.breeds[0].id, "cached1")
        XCTAssertEqual(state.breeds[1].id, "cached2")
    }
    
    func testRefreshFavoritesFinishedUpdatesIds() {
        // Arrange
        var state = HomeFeature.State()
        let ids: Set<String> = ["persian", "siamese"]
        
        // Act
        let reducer = HomeFeature()
        let action = HomeFeature.Action.refreshFavoritesFinished(ids)
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertEqual(state.favoriteIDs, ids)
    }
    
    func testToggleFavoriteSuccessAddsToFavorites() {
        // Arrange
        var state = HomeFeature.State()
        state.favoriteIDs = []
        
        // Act
        let reducer = HomeFeature()
        let action = HomeFeature.Action.toggleFavoriteSuccess(id: "test")
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertTrue(state.favoriteIDs.contains("test"))
    }
    
    func testToggleFavoriteSuccessRemovesFromFavorites() {
        // Arrange
        var state = HomeFeature.State()
        state.favoriteIDs = ["test"]
        
        // Act
        let reducer = HomeFeature()
        let action = HomeFeature.Action.toggleFavoriteSuccess(id: "test")
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertFalse(state.favoriteIDs.contains("test"))
    }
    
    func testToggleFavoriteFailureSetsError() {
        // Arrange
        var state = HomeFeature.State()
        
        // Act
        let reducer = HomeFeature()
        let action = HomeFeature.Action.toggleFavoriteFailure
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertNotNil(state.lastErrorMessage)
    }
    
    func testTappedBreedNavigatesToDetail() {
        // Arrange
        var state = HomeFeature.State()
        let breed = CatBreed(
            id: "test-id",
            name: "Test Breed",
            origin: "Test Origin",
            description: "Test Description",
            temperament: "Calm",
            lifeSpan: "12-15",
            image: BreedImage(url: "test-image.jpg"),
            referenceImageId: nil
        )
        
        // Act
        let reducer = HomeFeature()
        let action = HomeFeature.Action.tappedBreed(breed)
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertEqual(state.path.count, 1)
    }
    
    func testRequestNextPageIfNeededWithValidConditions() {
        // Arrange
        var state = HomeFeature.State()
        state.currentPage = 1
        state.hasLoadedFirstPage = true
        state.isLoadingPage = false
        
        // Act
        let reducer = HomeFeature()
        let action = HomeFeature.Action.requestNextPageIfNeeded
        let effect = reducer.reduce(into: &state, action: action)
        
        // Assert - Should trigger async work to fetch next page
        XCTAssertNotNil(effect)
    }
    
    func testCacheFallbackResponseWithData() {
        // Arrange
        var state = HomeFeature.State()
        let page = UIConfig.Pagination.initialPageIndex
        
        // Act
        let reducer = HomeFeature()
        let action = HomeFeature.Action.cacheFallbackResponse(page: page, cachedCount: 5)
        let effect = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertFalse(state.isLoadingPage)
        XCTAssertEqual(state.currentPage, page)
        XCTAssertTrue(state.hasLoadedFirstPage)
        XCTAssertNotNil(effect) // Should trigger loadCachedBreeds
    }
}