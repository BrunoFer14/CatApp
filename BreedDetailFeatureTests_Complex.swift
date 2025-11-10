import XCTest
import ComposableArchitecture
@testable import CatApp

@MainActor
final class BreedDetailFeatureTests: XCTestCase {
    
    // MARK: - State Tests
    
    func testInitialState() async {
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
    
    func testPrepareActionUpdatesImageItems() async {
        // Arrange  
        let breed = CatBreed(
            id: "test-id",
            name: "Test Breed", 
            origin: nil,
            description: nil,
            temperament: nil,
            lifeSpan: nil,
            image: BreedImage(url: "test-image.jpg"),
            referenceImageId: nil
        )
        
        let store = TestStore(initialState: BreedDetailFeature.State(breed: breed)) {
            BreedDetailFeature()
        } withDependencies: {
            $0.detailsService = MockDetailsService()
            $0.favoritesService = MockFavoritesService()
        }
        store.exhaustivity = .off // Disable exhaustive checking for simplicity
        
        // Act & Assert
        await store.send(.prepare) {
            // prepare should update image items based on breed image
            $0.imageItems = [
                BreedDetailFeature.State.ImageItem(id: "test-image.jpg", url: "test-image.jpg")
            ]
        }
        await store.receive(.galleryResponseSuccess([])) {
            $0.isLoadingGallery = false
            $0.galleryImages = []
            $0.selectedIndex = UIConfig.Pagination.initialPageIndex
        }
        await store.receive(.rebuildImageItems)
    }
    
    // MARK: - Favorites Tests
    
    func testRefreshFavoriteUpdatesFavoriteStatus() async {
        // Arrange
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        
        struct FavoriteStub: FavoritesServiceProtocol {
            func fetchFavorites() async throws -> [Favorite] { [] }
            func addFavorite(id: String) async throws {}
            func removeFavorite(id: String) async throws {}
            func isFavorite(id: String) async -> Bool { true } // This breed is favorited
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        
        let store = await TestStore(initialState: BreedDetailFeature.State(breed: breed)) {
            BreedDetailFeature()
        } withDependencies: {
            $0.detailsService = MockDetailsService()
            $0.favoritesService = FavoriteStub()
        }
        
        // Act & Assert
        await store.send(.refreshFavorite)
        await store.receive(.toggleFavoriteSuccess(id: "test-id", isNowFavorite: true)) {
            $0.isFavorite = true
            $0.lastErrorMessage = nil
        }
    }
    
    func testToggleFavoriteAddsWhenNotFavorite() async {
        // Arrange
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        
        final class TogglableStub: FavoritesServiceProtocol {
            var favorites: Set<String> = []
            var addCalled = false
            var upsertCalled = false
            
            func fetchFavorites() async throws -> [Favorite] { [] }
            func addFavorite(id: String) async throws {
                favorites.insert(id)
                addCalled = true
            }
            func removeFavorite(id: String) async throws {
                favorites.remove(id)
            }
            func isFavorite(id: String) async -> Bool { favorites.contains(id) }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {
                upsertCalled = true
            }
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        
        let favoritesStub = TogglableStub()
        
        let store = await TestStore(initialState: BreedDetailFeature.State(breed: breed)) {
            BreedDetailFeature()
        } withDependencies: {
            $0.detailsService = MockDetailsService()
            $0.favoritesService = favoritesStub
        }
        
        // Act & Assert
        await store.send(.toggleFavorite)
        await store.receive(.toggleFavoriteSuccess(id: "test-id", isNowFavorite: true)) {
            $0.isFavorite = true
            $0.lastErrorMessage = nil
        }
        
        XCTAssertTrue(favoritesStub.addCalled)
        XCTAssertTrue(favoritesStub.upsertCalled)
    }
    
    func testToggleFavoriteRemovesWhenFavorite() async {
        // Arrange
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        
        final class TogglableStub: FavoritesServiceProtocol {
            var favorites: Set<String> = ["test-id"] // Start as favorite
            var removeCalled = false
            var deleteCalled = false
            
            func fetchFavorites() async throws -> [Favorite] { [] }
            func addFavorite(id: String) async throws {
                favorites.insert(id)
            }
            func removeFavorite(id: String) async throws {
                favorites.remove(id)
                removeCalled = true
            }
            func isFavorite(id: String) async -> Bool { favorites.contains(id) }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {
                deleteCalled = true
            }
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        
        let favoritesStub = TogglableStub()
        
        let store = await TestStore(initialState: BreedDetailFeature.State(breed: breed)) {
            BreedDetailFeature()
        } withDependencies: {
            $0.detailsService = MockDetailsService()
            $0.favoritesService = favoritesStub
        }
        
        // Act & Assert
        await store.send(.toggleFavorite)
        await store.receive(.toggleFavoriteSuccess(id: "test-id", isNowFavorite: false)) {
            $0.isFavorite = false
            $0.lastErrorMessage = nil
        }
        
        XCTAssertTrue(favoritesStub.removeCalled)
        XCTAssertTrue(favoritesStub.deleteCalled)
    }
    
    func testToggleFavoriteFailureSetsError() async {
        // Arrange
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        
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
        
        let store = await TestStore(initialState: BreedDetailFeature.State(breed: breed)) {
            BreedDetailFeature()
        } withDependencies: {
            $0.detailsService = MockDetailsService()
            $0.favoritesService = FailingStub()
        }
        
        // Act & Assert
        await store.send(.toggleFavorite)
        await store.receive(.toggleFavoriteFailure) {
            $0.lastErrorMessage = UIStrings.Common.favoriteUpdateFailure
        }
    }
    
    // MARK: - Detail Loading Tests
    
    func testLoadDetailSuccess() async {
        // Arrange
        let initialBreed = CatBreed(id: "test-id", name: "Initial", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        let detailedBreed = CatBreed(
            id: "test-id",
            name: "Detailed Breed",
            origin: "Test Origin",
            description: "Test Description",
            temperament: "Friendly",
            lifeSpan: "12-15",
            image: BreedImage(url: "detailed-image.jpg"),
            referenceImageId: nil
        )
        
        struct DetailStub: DetailsServiceProtocol {
            let breed: CatBreed
            func breedDetail(id: String) async throws -> CatBreed? { breed }
            func breedImages(id: String, limit: Int) async throws -> [BreedGalleryImage] { [] }
        }
        
        let store = await TestStore(initialState: BreedDetailFeature.State(breed: initialBreed)) {
            BreedDetailFeature()
        } withDependencies: {
            $0.detailsService = DetailStub(breed: detailedBreed)
            $0.favoritesService = MockFavoritesService()
        }
        
        // Act & Assert
        await store.send(.loadDetail(id: "test-id")) {
            $0.screenState = .loading
            $0.isLoading = true
            $0.lastErrorMessage = nil
        }
        
        await store.receive(.detailResponseSuccess(detailedBreed)) {
            $0.isLoading = false
            $0.breed = detailedBreed
            $0.screenState = .content
        }
        
        await store.receive(.rebuildImageItems) {
            $0.imageItems = [
                BreedDetailFeature.State.ImageItem(id: "detailed-image.jpg", url: "detailed-image.jpg")
            ]
        }
    }
    
    func testLoadDetailFailure() async {
        // Arrange
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        
        struct FailingStub: DetailsServiceProtocol {
            struct TestError: Error {
                var localizedDescription: String { "Test error message" }
            }
            
            func breedDetail(id: String) async throws -> CatBreed? { throw TestError() }
            func breedImages(id: String, limit: Int) async throws -> [BreedGalleryImage] { [] }
        }
        
        let store = await TestStore(initialState: BreedDetailFeature.State(breed: breed)) {
            BreedDetailFeature()
        } withDependencies: {
            $0.detailsService = FailingStub()
            $0.favoritesService = MockFavoritesService()
        }
        
        // Act & Assert
        await store.send(.loadDetail(id: "test-id")) {
            $0.screenState = .loading
            $0.isLoading = true
            $0.lastErrorMessage = nil
        }
        
        await store.receive(.detailResponseFailure("Test error message")) {
            $0.isLoading = false
            $0.screenState = .error("Erro: Test error message")
        }
    }
    
    // MARK: - Gallery Tests
    
    func testLoadGallerySuccess() async {
        // Arrange
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        let galleryImages = [
            BreedGalleryImage(id: "g1", url: "gallery1.jpg"),
            BreedGalleryImage(id: "g2", url: "gallery2.jpg")
        ]
        
        struct GalleryStub: DetailsServiceProtocol {
            let images: [BreedGalleryImage]
            func breedDetail(id: String) async throws -> CatBreed? { nil }
            func breedImages(id: String, limit: Int) async throws -> [BreedGalleryImage] { images }
        }
        
        let store = await TestStore(initialState: BreedDetailFeature.State(breed: breed)) {
            BreedDetailFeature()
        } withDependencies: {
            $0.detailsService = GalleryStub(images: galleryImages)
            $0.favoritesService = MockFavoritesService()
        }
        
        // Act & Assert
        await store.send(.loadGallery(id: "test-id", limit: 10)) {
            $0.isLoadingGallery = true
            $0.galleryError = nil
        }
        
        await store.receive(.galleryResponseSuccess(galleryImages)) {
            $0.isLoadingGallery = false
            $0.galleryImages = galleryImages
            $0.selectedIndex = UIConfig.Pagination.initialPageIndex
        }
        
        await store.receive(.rebuildImageItems) {
            $0.imageItems = [
                BreedDetailFeature.State.ImageItem(id: "gallery1.jpg", url: "gallery1.jpg"),
                BreedDetailFeature.State.ImageItem(id: "gallery2.jpg", url: "gallery2.jpg")
            ]
        }
    }
    
    // MARK: - Navigation Tests
    
    func testImageCarouselNavigation() async {
        // Arrange
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        var state = BreedDetailFeature.State(breed: breed)
        state.imageItems = [
            BreedDetailFeature.State.ImageItem(id: "1", url: "image1.jpg"),
            BreedDetailFeature.State.ImageItem(id: "2", url: "image2.jpg"),
            BreedDetailFeature.State.ImageItem(id: "3", url: "image3.jpg")
        ]
        state.selectedIndex = 1 // Start at middle
        
        let store = await TestStore(initialState: state) {
            BreedDetailFeature()
        } withDependencies: {
            $0.detailsService = MockDetailsService()
            $0.favoritesService = MockFavoritesService()
        }
        
        // Act & Assert - Test navigation
        await store.send(.goNext) {
            $0.selectedIndex = 2
        }
        
        await store.send(.goPrev) {
            $0.selectedIndex = 1
        }
        
        await store.send(.selectImage(index: 0)) {
            $0.selectedIndex = 0
        }
    }
    
    func testFullscreenPresentation() async {
        // Arrange
        let breed = CatBreed(id: "test-id", name: "Test", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        var state = BreedDetailFeature.State(breed: breed)
        state.imageItems = [
            BreedDetailFeature.State.ImageItem(id: "1", url: "image1.jpg"),
            BreedDetailFeature.State.ImageItem(id: "2", url: "image2.jpg")
        ]
        state.selectedIndex = 1
        
        let store = await TestStore(initialState: state) {
            BreedDetailFeature()
        } withDependencies: {
            $0.detailsService = MockDetailsService()
            $0.favoritesService = MockFavoritesService()
        }
        
        // Act & Assert
        await store.send(.presentFullscreenForSelected) {
            $0.fullscreenURL = "image2.jpg"
            $0.isPresentingFullscreen = true
        }
        
        await store.send(.dismissFullscreen) {
            $0.isPresentingFullscreen = false
            $0.fullscreenURL = nil
        }
    }
}

// MARK: - Test Helpers

private struct MockDetailsService: DetailsServiceProtocol {
    func breedDetail(id: String) async throws -> CatBreed? { nil }
    func breedImages(id: String, limit: Int) async throws -> [BreedGalleryImage] { [] }
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
