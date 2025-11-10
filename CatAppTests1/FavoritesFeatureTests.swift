import XCTest
import ComposableArchitecture
@testable import CatApp

@MainActor
final class FavoritesFeatureTests: XCTestCase {
    
    func testInitialState() {
        // Given & When
        let state = FavoritesFeature.State()
        
        // Then
        XCTAssertTrue(state.rows.isEmpty)
        XCTAssertTrue(state.favoriteIDs.isEmpty)
        XCTAssertNil(state.averageLifeSpanText)
    }
    
    func testOnAppear() {
        // Given
        var state = FavoritesFeature.State()
        
        // When
        let reducer = FavoritesFeature()
        let action = FavoritesFeature.Action.onAppear
        let effect = reducer.reduce(into: &state, action: action)
        
        // Then - Should trigger some async work
        XCTAssertNotNil(effect)
    }
    
    func testFavoritesSnapshotChangedUpdatesRowsAndAverage() {
        // Given
        var state = FavoritesFeature.State()
        state.favoriteIDs = ["persian", "siamese"] // Mark both as favorites
        
        let details = [
            FavoriteBreedDetail(
                id: "persian",
                name: "Persian",
                origin: "Iran",
                temperament: "Calm",
                lifeSpan: "12 - 17",
                breedDescription: "Long-haired breed",
                imageUrl: "persian.jpg"
            ),
            FavoriteBreedDetail(
                id: "siamese",
                name: "Siamese",
                origin: "Thailand",
                temperament: "Active",
                lifeSpan: "15 - 20",
                breedDescription: "Vocal breed",
                imageUrl: "siamese.jpg"
            )
        ]
        
        // When
        let reducer = FavoritesFeature()
        let action = FavoritesFeature.Action.favoritesSnapshotChanged(details)
        _ = reducer.reduce(into: &state, action: action)
        
        // Then
        XCTAssertEqual(state.rows.count, 2)
        XCTAssertEqual(state.rows[0].name, "Persian")
        XCTAssertEqual(state.rows[1].name, "Siamese")
        XCTAssertTrue(state.rows[0].isFavorite)
        XCTAssertTrue(state.rows[1].isFavorite)
        XCTAssertNotNil(state.averageLifeSpanText)
    }
    
    func testRefreshFavoritesFinishedUpdatesIds() {
        // Given
        var state = FavoritesFeature.State()
        let ids: Set<String> = ["persian", "siamese"]
        
        // When
        let reducer = FavoritesFeature()
        let action = FavoritesFeature.Action.refreshFavoritesFinished(ids)
        _ = reducer.reduce(into: &state, action: action)
        
        // Then
        XCTAssertEqual(state.favoriteIDs, ids)
    }
    
    func testToggleFavoriteSuccessUpdatesState() {
        // Given
        var state = FavoritesFeature.State()
        state.favoriteIDs = []
        state.rows = [
            FavoriteRow(
                id: "test",
                name: "Test Breed",
                imageURL: nil,
                breed: CatBreed(id: "test", name: "Test Breed", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil),
                isFavorite: false
            )
        ]
        
        // When
        let reducer = FavoritesFeature()
        let action = FavoritesFeature.Action.toggleFavoriteSuccess(id: "test")
        _ = reducer.reduce(into: &state, action: action)
        
        // Then
        XCTAssertTrue(state.favoriteIDs.contains("test"))
        XCTAssertTrue(state.rows[0].isFavorite)
    }
    
    func testTappedRowNavigatesToBreedDetail() {
        // Given
        var state = FavoritesFeature.State()
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
        let reducer = FavoritesFeature()
        let action = FavoritesFeature.Action.tappedRow(breed)
        _ = reducer.reduce(into: &state, action: action)
        
        // Then
        XCTAssertEqual(state.path.count, 1)
    }
}
