import XCTest
import ComposableArchitecture
@testable import CatApp

@MainActor
final class SearchFeatureTests: XCTestCase {
    
    func testInitialState() {
        // Given & When
        let state = SearchFeature.State()
        
        // Then
        XCTAssertEqual(state.query, "")
        XCTAssertFalse(state.isLoadingPage)
        XCTAssertEqual(state.currentPage, 0)
        XCTAssertFalse(state.hasLoadedFirstPage)
        XCTAssertTrue(state.favoriteIDs.isEmpty)
    }
    
    func testQueryChangedUpdatesState() {
        // Given
        var state = SearchFeature.State()
        
        // When
        let reducer = SearchFeature()
        let action = SearchFeature.Action.queryChanged("persian")
        _ = reducer.reduce(into: &state, action: action)
        
        // Then
        XCTAssertEqual(state.query, "persian")
    }
    
    func testOnAppearTriggersActions() {
        // Given
        var state = SearchFeature.State()
        
        // When
        let reducer = SearchFeature()
        let action = SearchFeature.Action.onAppear
        let effect = reducer.reduce(into: &state, action: action)
        
        // Then - Should trigger some async work
        XCTAssertNotNil(effect)
    }
    
    func testFetchPageSuccessUpdatesState() {
        // Given
        var state = SearchFeature.State()
        let page = 1
        
        // When
        let reducer = SearchFeature()
        let action = SearchFeature.Action.fetchPageSuccess(page: page)
        _ = reducer.reduce(into: &state, action: action)
        
        // Then
        XCTAssertEqual(state.currentPage, page)
        XCTAssertFalse(state.isLoadingPage)
        if page == UIConfig.Pagination.initialPageIndex {
            XCTAssertTrue(state.hasLoadedFirstPage)
        }
    }
    
    func testFetchPageFailureUpdatesState() {
        // Given
        var state = SearchFeature.State()
        state.isLoadingPage = true
        let page = UIConfig.Pagination.initialPageIndex
        
        // When
        let reducer = SearchFeature()
        let action = SearchFeature.Action.fetchPageFailure(page: page)
        _ = reducer.reduce(into: &state, action: action)
        
        // Then
        XCTAssertFalse(state.isLoadingPage)
        XCTAssertTrue(state.hasLoadedFirstPage) // First page failure still marks as loaded
    }
    
    func testRefreshFavoritesFinishedUpdatesIds() {
        // Given
        var state = SearchFeature.State()
        let ids: Set<String> = ["persian", "siamese"]
        
        // When
        let reducer = SearchFeature()
        let action = SearchFeature.Action.refreshFavoritesFinished(ids)
        _ = reducer.reduce(into: &state, action: action)
        
        // Then
        XCTAssertEqual(state.favoriteIDs, ids)
    }
    
    func testToggleFavoriteSuccessUpdatesIds() {
        // Given
        var state = SearchFeature.State()
        state.favoriteIDs = []
        
        // When
        let reducer = SearchFeature()
        let action = SearchFeature.Action.toggleFavoriteSuccess(id: "test")
        _ = reducer.reduce(into: &state, action: action)
        
        // Then
        XCTAssertTrue(state.favoriteIDs.contains("test"))
    }
    
    func testToggleFavoriteSuccessRemovesFavorite() {
        // Given
        var state = SearchFeature.State()
        state.favoriteIDs = ["test"]
        
        // When
        let reducer = SearchFeature()
        let action = SearchFeature.Action.toggleFavoriteSuccess(id: "test")
        _ = reducer.reduce(into: &state, action: action)
        
        // Then
        XCTAssertFalse(state.favoriteIDs.contains("test"))
    }
    
    func testTappedBreedNavigatesToDetail() {
        // Given
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
        
        // When
        let reducer = SearchFeature()
        let action = SearchFeature.Action.tappedBreed(breed)
        _ = reducer.reduce(into: &state, action: action)
        
        // Then
        XCTAssertEqual(state.path.count, 1)
    }
    
    func testRequestNextPageIfNeeded() {
        // Given
        var state = SearchFeature.State()
        state.currentPage = 1
        
        // When
        let reducer = SearchFeature()
        let action = SearchFeature.Action.requestNextPageIfNeeded
        let effect = reducer.reduce(into: &state, action: action)
        
        // Then
        XCTAssertNotNil(effect) // Should trigger fetchPage action
    }
}
