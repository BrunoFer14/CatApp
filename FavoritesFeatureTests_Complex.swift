import XCTest
import ComposableArchitecture
@testable import CatApp

@MainActor
final class FavoritesFeatureTests: XCTestCase {
    
    // MARK: - Lifecycle Tests
    
    func testOnAppearTriggersRefreshFavorites() async {
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
        
        let store = await TestStore(initialState: FavoritesFeature.State()) {
            FavoritesFeature()
        } withDependencies: {
            $0.favoritesService = FavoritesStub()
        }
        
        // Act & Assert
        await store.send(.onAppear)
        await store.receive(.refreshFavorites)
        await store.receive(.refreshFavoritesFinished(["persian", "siamese"])) {
            $0.favoriteIDs = ["persian", "siamese"]
        }
    }
    
    func testRefreshFavoritesSuccess() async {
        // Arrange
        struct FavoritesStub: FavoritesServiceProtocol {
            func fetchFavorites() async throws -> [Favorite] {
                [Favorite(breedId: "breed1"), Favorite(breedId: "breed2")]
            }
            func addFavorite(id: String) async throws {}
            func removeFavorite(id: String) async throws {}
            func isFavorite(id: String) async -> Bool { false }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        
        let store = await TestStore(initialState: FavoritesFeature.State()) {
            FavoritesFeature()
        } withDependencies: {
            $0.favoritesService = FavoritesStub()
        }
        
        // Act & Assert
        await store.send(.refreshFavorites)
        await store.receive(.refreshFavoritesFinished(["breed1", "breed2"])) {
            $0.favoriteIDs = ["breed1", "breed2"]
        }
    }
    
    func testRefreshFavoritesFailureReturnsEmptySet() async {
        // Arrange
        struct FailingStub: FavoritesServiceProtocol {
            struct TestError: Error {}
            
            func fetchFavorites() async throws -> [Favorite] { throw TestError() }
            func addFavorite(id: String) async throws {}
            func removeFavorite(id: String) async throws {}
            func isFavorite(id: String) async -> Bool { false }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        
        let store = await TestStore(initialState: FavoritesFeature.State()) {
            FavoritesFeature()
        } withDependencies: {
            $0.favoritesService = FailingStub()
        }
        
        // Act & Assert
        await store.send(.refreshFavorites)
        await store.receive(.refreshFavoritesFinished([])) {
            $0.favoriteIDs = []
        }
    }
    
    // MARK: - Snapshot Processing Tests
    
    func testFavoritesSnapshotBuildsRowsCorrectly() async {
        // Arrange
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
        
        var initialState = FavoritesFeature.State()
        initialState.favoriteIDs = ["persian"] // Only persian is marked as favorite
        
        let store = await TestStore(initialState: initialState) {
            FavoritesFeature()
        } withDependencies: {
            $0.favoritesService = MockFavoritesService()
        }
        
        // Act & Assert
        await store.send(.favoritesSnapshotChanged(details)) {
            $0.rows = [
                FavoriteRow(
                    id: "persian",
                    name: "Persian",
                    imageURL: "persian.jpg",
                    breed: CatBreed(
                        id: "persian",
                        name: "Persian",
                        origin: "Iran",
                        description: "Long-haired breed",
                        temperament: "Calm",
                        lifeSpan: "12 - 17",
                        image: BreedImage(url: "persian.jpg"),
                        referenceImageId: nil
                    ),
                    isFavorite: true
                ),
                FavoriteRow(
                    id: "siamese",
                    name: "Siamese",
                    imageURL: "siamese.jpg",
                    breed: CatBreed(
                        id: "siamese",
                        name: "Siamese",
                        origin: "Thailand",
                        description: "Vocal breed",
                        temperament: "Active",
                        lifeSpan: "15 - 20",
                        image: BreedImage(url: "siamese.jpg"),
                        referenceImageId: nil
                    ),
                    isFavorite: false
                )
            ]
            // Average: (12+17)/2=14.5 and (15+20)/2=17.5 → mean = 16.0
            $0.averageLifeSpanText = "16.0"
        }
    }
    
    func testAverageLifeSpanCalculation() async {
        // Arrange
        let details = [
            FavoriteBreedDetail(id: "a", name: "A", origin: nil, temperament: nil, lifeSpan: "10", breedDescription: nil, imageUrl: nil),
            FavoriteBreedDetail(id: "b", name: "B", origin: nil, temperament: nil, lifeSpan: "15 - 20", breedDescription: nil, imageUrl: nil),
            FavoriteBreedDetail(id: "c", name: "C", origin: nil, temperament: nil, lifeSpan: nil, breedDescription: nil, imageUrl: nil) // Should be ignored
        ]
        
        let store = await TestStore(initialState: FavoritesFeature.State()) {
            FavoritesFeature()
        } withDependencies: {
            $0.favoritesService = MockFavoritesService()
        }
        
        // Act
        await store.send(.favoritesSnapshotChanged(details)) {
            // Average should be (10 + 17.5) / 2 = 13.75 ≈ 13.8
            $0.averageLifeSpanText = "13.8"
            // rows are built for each detail; favorite flags are based on empty favoriteIDs
            // We don't assert row equality here, but we can assert the count outside the closure.
        }
        
        // Assert outside the mutation closure
        let view = await store.state
        XCTAssertEqual(view.rows.count, 3)
    }
    
    // MARK: - Toggle Favorite Tests
    
    func testToggleFavoriteFromNotFavoriteToFavorite() async {
        // Arrange
        final class ToggleStub: FavoritesServiceProtocol {
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
        
        let favoritesStub = ToggleStub()
        let breed = CatBreed(id: "test", name: "Test Breed", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        
        var initialState = FavoritesFeature.State()
        initialState.rows = [
            FavoriteRow(id: "test", name: "Test Breed", imageURL: nil, breed: breed, isFavorite: false)
        ]
        
        let store = await TestStore(initialState: initialState) {
            FavoritesFeature()
        } withDependencies: {
            $0.favoritesService = favoritesStub
        }
        
        // Act & Assert
        await store.send(.toggleFavorite(breed))
        await store.receive(.toggleFavoriteSuccess(id: "test")) {
            $0.favoriteIDs = ["test"]
            $0.rows[0].isFavorite = true
        }
        
        XCTAssertTrue(favoritesStub.addCalled)
        XCTAssertTrue(favoritesStub.upsertCalled)
    }
    
    func testToggleFavoriteFromFavoriteToNotFavorite() async {
        // Arrange
        final class ToggleStub: FavoritesServiceProtocol {
            var favorites: Set<String> = ["test"] // Start as favorite
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
        
        let favoritesStub = ToggleStub()
        let breed = CatBreed(id: "test", name: "Test Breed", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        
        var initialState = FavoritesFeature.State()
        initialState.favoriteIDs = ["test"]
        initialState.rows = [
            FavoriteRow(id: "test", name: "Test Breed", imageURL: nil, breed: breed, isFavorite: true)
        ]
        
        let store = await TestStore(initialState: initialState) {
            FavoritesFeature()
        } withDependencies: {
            $0.favoritesService = favoritesStub
        }
        
        // Act & Assert
        await store.send(.toggleFavorite(breed))
        await store.receive(.toggleFavoriteSuccess(id: "test")) {
            $0.favoriteIDs = []
            $0.rows[0].isFavorite = false
        }
        
        XCTAssertTrue(favoritesStub.removeCalled)
        XCTAssertTrue(favoritesStub.deleteCalled)
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
        
        let store = await TestStore(initialState: FavoritesFeature.State()) {
            FavoritesFeature()
        } withDependencies: {
            $0.favoritesService = FailingStub()
        }
        
        // Act & Assert
        await store.send(.toggleFavorite(breed))
        await store.receive(.toggleFavoriteFailure)
    }
    
    // MARK: - Navigation Tests
    
    func testTappedRowNavigatesToBreedDetail() async {
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
        
        let store = await TestStore(initialState: FavoritesFeature.State()) {
            FavoritesFeature()
        } withDependencies: {
            $0.favoritesService = MockFavoritesService()
        }
        
        // Act & Assert
        await store.send(.tappedRow(breed)) {
            $0.path.append(.breedDetail(BreedDetailFeature.State(breed: breed)))
        }
    }
    
    // MARK: - State Synchronization Tests
    
    func testRefreshFavoritesFinishedUpdatesBothIdsAndRowFlags() async {
        // Arrange
        let breed1 = CatBreed(id: "a", name: "A", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        let breed2 = CatBreed(id: "b", name: "B", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        
        var initialState = FavoritesFeature.State()
        initialState.rows = [
            FavoriteRow(id: "a", name: "A", imageURL: nil, breed: breed1, isFavorite: false),
            FavoriteRow(id: "b", name: "B", imageURL: nil, breed: breed2, isFavorite: true)
        ]
        
        let store = await TestStore(initialState: initialState) {
            FavoritesFeature()
        } withDependencies: {
            $0.favoritesService = MockFavoritesService()
        }
        
        // Act & Assert - Update favorites to only include 'a'
        await store.send(.refreshFavoritesFinished(["a"])) {
            $0.favoriteIDs = ["a"]
            $0.rows[0].isFavorite = true  // 'a' should now be favorite
            $0.rows[1].isFavorite = false // 'b' should no longer be favorite
        }
    }
}

// MARK: - Test Helpers

private struct MockFavoritesService: FavoritesServiceProtocol {
    func fetchFavorites() async throws -> [Favorite] { [] }
    func addFavorite(id: String) async throws {}
    func removeFavorite(id: String) async throws {}
    func isFavorite(id: String) async -> Bool { false }
    func upsertFavoriteDetail(from breed: CatBreed) async throws {}
    func deleteFavoriteDetail(id: String) async throws {}
    func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
}
