import XCTest
import ComposableArchitecture
@testable import CatApp

@MainActor
final class BreedDetailFeatureTests: XCTestCase {
     
    // MARK: - Test 1: Basic State Initialization
    func testInitialState() async {
        // Given - Create a test breed
//        let testBreed = CatBreed(
//            id: "test-id",
//            name: "Test Breed",
//            origin: "Test Origin",
//            description: "Test Description",
//            temperament: "Calm",
//            lifeSpan: "12-15",
//            image: BreedImage(url: "test-image.jpg"),
//            referenceImageId: nil
//        )
        
        // When - Create TestStore with initial state
//        let store = TestStore(
//            initialState: BreedDetailFeature.State(breed: testBreed)
//        ) {
//            BreedDetailFeature()
//        }
//        
        // Then - Verify initial values from store.state
        //let state = store.state
        //await store.send(.onAppear)
        //XCTAssertEqual(state.breed.id, "test-id")
        //XCTAssertEqual(state.breed.name, "Test Breed")
        //XCTAssertEqual(state.screenState, .loading)
        //XCTAssertFalse(state.isFavorite)
        //XCTAssertFalse(state.isLoading)
        //XCTAssertFalse(state.isLoadingGallery)
        //XCTAssertTrue(state.imageItems.isEmpty)
        //XCTAssertEqual(state.selectedIndex, 0)
        //XCTAssertNil(state.lastErrorMessage)
    }
}
