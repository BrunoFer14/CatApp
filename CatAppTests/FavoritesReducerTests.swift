import Foundation
import Testing
@testable import CatApp
import ComposableArchitecture

struct FavoritesReducerTests {

    @Test
    func favorites_onAppear_loadsIDs() async {
        // Given
        struct FavService: FavoritesServiceProtocol {
            func fetchFavorites() async throws -> [Favorite] { [Favorite(breedId: "a"), Favorite(breedId: "b")] }
            func addFavorite(id: String) async throws {}
            func removeFavorite(id: String) async throws {}
            func isFavorite(id: String) async -> Bool { false }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        let store = await makeSUT(
            state: FavoritesReducer.State(),
            favoritesService: FavService()
        )

        // When
        await store.send(.onAppear)

        // Then
        await store.receive(.refreshFavoritesFinished(Set(["a","b"]))) { $0.favoriteIDs = Set(["a","b"]) }
    }

    @Test
    func favorites_refreshFavoritesFinished_updatesIDsAndRowFlags() async {
        // Given
        var state = FavoritesReducer.State()
        state.rows = [
            FavoriteRow(id: "a", name: "A", imageURL: nil, breed: CatBreed(id: "a", name: "A", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil), isFavorite: false),
            FavoriteRow(id: "b", name: "B", imageURL: nil, breed: CatBreed(id: "b", name: "B", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil), isFavorite: false)
        ]
        let store = await makeSUT(state: state)

        // When
        await store.send(.refreshFavoritesFinished(Set(["a"]))) {
            $0.favoriteIDs = Set(["a"])
            $0.rows[0].isFavorite = true
            $0.rows[1].isFavorite = false
        }

        // Then
        let s = await store.state
        #expect(s.favoriteIDs == Set(["a"]))
        #expect(s.rows.first?.isFavorite == true)
        #expect(s.rows.last?.isFavorite == false)
    }

    @Test
    func favorites_favoritesSnapshotChanged_buildsRowsAndAverage() async {
        // Given
        let details = [
            FavoriteBreedDetail(id: "a", name: "A", origin: nil, temperament: nil, lifeSpan: "10 - 14", breedDescription: nil, imageUrl: "a.jpg"),
            FavoriteBreedDetail(id: "b", name: "B", origin: nil, temperament: nil, lifeSpan: "12", breedDescription: nil, imageUrl: "b.jpg")
        ]
        let store = await makeSUT(state: FavoritesReducer.State())

        // When
        await store.send(.favoritesSnapshotChanged(details)) {
            $0.rows = [
                FavoriteRow(id: "a", name: "A", imageURL: "a.jpg", breed: CatBreed(id: "a", name: "A", origin: nil, description: nil, temperament: nil, lifeSpan: "10 - 14", image: BreedImage(url: "a.jpg"), referenceImageId: nil), isFavorite: false),
                FavoriteRow(id: "b", name: "B", imageURL: "b.jpg", breed: CatBreed(id: "b", name: "B", origin: nil, description: nil, temperament: nil, lifeSpan: "12", image: BreedImage(url: "b.jpg"), referenceImageId: nil), isFavorite: false)
            ]
            $0.averageLifeSpanText = "12.0"
        }

        // Then
        let s = await store.state
        #expect(s.rows.count == 2)
        #expect(s.averageLifeSpanText == "12.0")
    }

    @Test
    func favorites_tappedRow_pushesBreedDetail() async {
        // Given
        let breed = CatBreed(id: "x", name: "X", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        let store = await makeSUT(state: FavoritesReducer.State())

        // When
        await store.send(.tappedRow(breed)) {
            $0.path.append(.breedDetail(BreedDetailReducer.State(breed: breed)))
        }

        // Then
        let s = await store.state
        #expect(s.path.count == 1)
    }

    @Test
    func favorites_toggleFavoriteSuccess_insertsIDAndTogglesRow() async {
        // Given
        var state = FavoritesReducer.State()
        state.rows = [
            FavoriteRow(id: "a", name: "A", imageURL: nil, breed: CatBreed(id: "a", name: "A", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil), isFavorite: false)
        ]
        let store = await makeSUT(state: state)

        // When
        await store.send(.toggleFavoriteSuccess(id: "a")) {
            $0.favoriteIDs = Set(["a"])
            $0.rows[0].isFavorite = true
        }

        // Then
        let s = await store.state
        #expect(s.favoriteIDs.contains("a"))
        #expect(s.rows.first?.isFavorite == true)
    }

    @Test
    func favorites_toggleFavoriteSuccess_removesIDAndTogglesRowOff() async {
        // Given
        var state = FavoritesReducer.State()
        state.favoriteIDs = Set(["a"])
        state.rows = [
            FavoriteRow(id: "a", name: "A", imageURL: nil, breed: CatBreed(id: "a", name: "A", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil), isFavorite: true)
        ]
        let store = await makeSUT(state: state)

        // When
        await store.send(.toggleFavoriteSuccess(id: "a")) {
            $0.favoriteIDs = []
            $0.rows[0].isFavorite = false
        }

        // Then
        let s = await store.state
        #expect(!s.favoriteIDs.contains("a"))
        #expect(s.rows.first?.isFavorite == false)
    }

    // MARK: - SUT helper
    private func makeSUT(
        state: FavoritesReducer.State,
        favoritesService: (any FavoritesServiceProtocol)? = nil
    ) async -> TestStoreOf<FavoritesReducer> {
        await TestStore(
            initialState: state,
            reducer: { FavoritesReducer() },
            withDependencies: {
                if let favoritesService { $0.favoritesService = favoritesService }
            }
        )
    }
}
