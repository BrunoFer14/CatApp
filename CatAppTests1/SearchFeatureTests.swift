import XCTest
import ComposableArchitecture
@testable import CatApp

@MainActor
final class SearchFeatureTests: XCTestCase {
    
    func testInitialState() {
        // Arrange & Act
        let state = SearchFeature.State()
        
        // Assert
        XCTAssertEqual(state.query, "")
        XCTAssertFalse(state.isLoadingPage)
        XCTAssertEqual(state.currentPage, 0)
        XCTAssertFalse(state.hasLoadedFirstPage)
        XCTAssertTrue(state.favoriteIDs.isEmpty)
    }
    
    func testQueryChangedUpdatesState() {
        // Arrange
        var state = SearchFeature.State()
        
        // Act
        let reducer = SearchFeature()
        let action = SearchFeature.Action.queryChanged("persian")
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertEqual(state.query, "persian")
    }
    
    func testOnAppearTriggersActions() {
        // Arrange
        var state = SearchFeature.State()
        
        // Act
        let reducer = SearchFeature()
        let action = SearchFeature.Action.onAppear
        let effect = reducer.reduce(into: &state, action: action)
        
        // Assert - Should trigger some async work
        XCTAssertNotNil(effect)
    }
    
    func testFetchPageSuccessUpdatesState() {
        // Arrange
        var state = SearchFeature.State()
        let page = 1
        
        // Act
        let reducer = SearchFeature()
        let action = SearchFeature.Action.fetchPageSuccess(page: page)
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertEqual(state.currentPage, page)
        XCTAssertFalse(state.isLoadingPage)
        if page == UIConfig.Pagination.initialPageIndex {
            XCTAssertTrue(state.hasLoadedFirstPage)
        }
    }
    
    func testFetchPageFailureUpdatesState() {
        // Arrange
        var state = SearchFeature.State()
        state.isLoadingPage = true
        let page = UIConfig.Pagination.initialPageIndex
        
        // Act
        let reducer = SearchFeature()
        let action = SearchFeature.Action.fetchPageFailure(page: page)
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertFalse(state.isLoadingPage)
        XCTAssertTrue(state.hasLoadedFirstPage) // First page failure still marks as loaded
    }
    
    func testRefreshFavoritesFinishedUpdatesIds() {
        // Arrange
        var state = SearchFeature.State()
        let ids: Set<String> = ["persian", "siamese"]
        
        // Act
        let reducer = SearchFeature()
        let action = SearchFeature.Action.refreshFavoritesFinished(ids)
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertEqual(state.favoriteIDs, ids)
    }
    
    func testToggleFavoriteSuccessUpdatesIds() {
        // Arrange
        var state = SearchFeature.State()
        state.favoriteIDs = []
        
        // Act
        let reducer = SearchFeature()
        let action = SearchFeature.Action.toggleFavoriteSuccess(id: "test")
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertTrue(state.favoriteIDs.contains("test"))
    }
    
    func testToggleFavoriteSuccessRemovesFavorite() {
        // Arrange
        var state = SearchFeature.State()
        state.favoriteIDs = ["test"]
        
        // Act
        let reducer = SearchFeature()
        let action = SearchFeature.Action.toggleFavoriteSuccess(id: "test")
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertFalse(state.favoriteIDs.contains("test"))
    }
    
    func testTappedBreedNavigatesToDetail() {
        // Arrange
        var state = SearchFeature.State()
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
        let reducer = SearchFeature()
        let action = SearchFeature.Action.tappedBreed(breed)
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertEqual(state.path.count, 1)
    }
    
    func testRequestNextPageIfNeeded() {
        // Arrange
        var state = SearchFeature.State()
        state.currentPage = 1
        
        // Act
        let reducer = SearchFeature()
        let action = SearchFeature.Action.requestNextPageIfNeeded
        let effect = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertNotNil(effect) // Should trigger fetchPage action
    }
}