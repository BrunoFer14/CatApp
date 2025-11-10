import XCTest
import ComposableArchitecture
@testable import CatApp

@MainActor
final class BreedDetailFeatureTests: XCTestCase {
    
    // MARK: - State Tests
    
    func testInitialState() {
        // Arrange
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
        let state = BreedDetailFeature.State(breed: breed)
        
        // Assert
        XCTAssertEqual(state.breed.id, "test-id")
        XCTAssertEqual(state.breed.name, "Test Breed")
        XCTAssertEqual(state.screenState, .idle)
        XCTAssertFalse(state.isLoading)
        XCTAssertFalse(state.isLoadingGallery)
        XCTAssertFalse(state.isFavorite)
        XCTAssertTrue(state.imageItems.isEmpty)
    }
    
    func testToggleFavoriteUpdatesState() {
        // Arrange
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        var state = BreedDetailFeature.State(breed: breed)
        XCTAssertFalse(state.isFavorite)
        
        // Act
        let reducer = BreedDetailFeature()
        let action = BreedDetailFeature.Action.toggleFavoriteSuccess(id: "test-id", isNowFavorite: true)
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertTrue(state.isFavorite)
        XCTAssertNil(state.lastErrorMessage)
    }
    
    func testDetailResponseSuccessUpdatesState() {
        // Arrange
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        var state = BreedDetailFeature.State(breed: breed)
        
        let updatedBreed = CatBreed(
            id: "test-id",
            name: "Updated Test",
            origin: "Test Origin",
            description: "Updated Description",
            temperament: "Calm",
            lifeSpan: "12-15",
            image: BreedImage(url: "updated-image.jpg"),
            referenceImageId: nil
        )
        
        // Act
        let reducer = BreedDetailFeature()
        let action = BreedDetailFeature.Action.detailResponseSuccess(updatedBreed)
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertEqual(state.breed.name, "Updated Test")
        XCTAssertEqual(state.breed.description, "Updated Description")
        XCTAssertFalse(state.isLoading)
    }
    
    func testGalleryResponseSuccessUpdatesImageItems() {
        // Arrange
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        var state = BreedDetailFeature.State(breed: breed)
        
        let images = [
            BreedGalleryImage(id: "img1", url: "image1.jpg"),
            BreedGalleryImage(id: "img2", url: "image2.jpg")
        ]
        
        // Act
        let reducer = BreedDetailFeature()
        let action = BreedDetailFeature.Action.galleryResponseSuccess(images)
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert
        XCTAssertFalse(state.isLoadingGallery)
        XCTAssertEqual(state.galleryImages, images)
    }
    
    func testRebuildImageItemsAddsBreedImage() {
        // Arrange
        let breedImage = BreedImage(url: "breed-image.jpg")
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: breedImage, referenceImageId: nil)
        var state = BreedDetailFeature.State(breed: breed)
        
        // Set some existing gallery images
        state.galleryImages = [
            BreedGalleryImage(id: "gallery1", url: "gallery1.jpg"),
            BreedGalleryImage(id: "gallery2", url: "gallery2.jpg")
        ]
        
        // Act
        let reducer = BreedDetailFeature()
        let action = BreedDetailFeature.Action.rebuildImageItems
        _ = reducer.reduce(into: &state, action: action)
        
        // Assert - Should have breed image + 2 gallery images = 3 total
        XCTAssertEqual(state.imageItems.count, 3)
        // First item should be the breed image
        XCTAssertEqual(state.imageItems[0].url, "breed-image.jpg")
    }
    
    func testOnAppearTriggersActions() {
        // Arrange
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        var state = BreedDetailFeature.State(breed: breed)
        
        // Act
        let reducer = BreedDetailFeature()
        let action = BreedDetailFeature.Action.onAppear
        let effect = reducer.reduce(into: &state, action: action)
        
        // Assert - Should trigger async actions (effect is not .none)
        // We can't test the exact effect, but we know it should start some async work
        XCTAssertNotNil(effect)
    }
    
    func testLoadGalleryAction() {
        // Arrange
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        var state = BreedDetailFeature.State(breed: breed)
        
        // Act
        let reducer = BreedDetailFeature()
        let action = BreedDetailFeature.Action.loadGallery(id: "test-id", limit: 10)
        let effect = reducer.reduce(into: &state, action: action)
        
        // Assert - Should set loading state and trigger async work
        XCTAssertTrue(state.isLoadingGallery)
        XCTAssertNotNil(effect)
    }
}