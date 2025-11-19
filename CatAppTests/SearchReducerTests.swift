import Foundation
import Testing
@testable import CatApp
import ComposableArchitecture

struct SearchReducerTests {

    @Test
    func search_fetchPageSuccess_updatesFlags() async {
        // Given
        let breeds = [
            CatBreed(id: "1", name: "One", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil),
            CatBreed(id: "2", name: "Two", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        ]
        let page = UIConfig.Pagination.initialPageIndex
        let store = await makeSUT(
            state: SearchReducer.State(),
            breedsService: BreedsServiceStub(pages: [page: breeds]),
            breedsCacheDB: BreedsCacheDBStub()
        )

        // When
        await store.send(SearchReducer.Action.fetchPage(page)) {
            $0.isLoadingPage = true
        }

        // Then
        await store.receive(SearchReducer.Action.fetchPageSuccess(page: page)) {
            $0.currentPage = page
            $0.hasLoadedFirstPage = true
            $0.isLoadingPage = false
        }
    }

    @Test
    func search_fetchPageFailure_usesCacheFallback() async {
        // Given
        let page = 1
        let cached = [CachedBreed(id: "c1", name: "Cached", origin: nil, temperament: nil, lifeSpan: nil, breedDescription: nil, imageUrl: nil, orderIndex: 1)]
        let store = await makeSUT(
            state: SearchReducer.State(),
            breedsService: BreedsServiceStub(error: URLError(.badServerResponse)),
            breedsCacheDB: BreedsCacheDBStub(cachedPages: [page: cached])
        )

        // When
        await store.send(SearchReducer.Action.fetchPage(page)) {
            $0.isLoadingPage = true
        }

        // Then
        await store.receive(SearchReducer.Action.cacheFallbackResponse(page: page, cachedCount: cached.count)) {
            $0.isLoadingPage = false
            $0.currentPage = page
        }
        await store.receive(SearchReducer.Action.fetchPageFailure(page: page))
    }

    @Test
    func search_refreshFavorites_populatesIDs() async {
        // Given
        struct FavService: FavoritesServiceProtocol {
            func fetchFavorites() async throws -> [Favorite] { [Favorite(breedId: "x"), Favorite(breedId: "y")] }
            func addFavorite(id: String) async throws {}
            func removeFavorite(id: String) async throws {}
            func isFavorite(id: String) async -> Bool { false }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        let store = await makeSUT(
            state: SearchReducer.State(),
            favoritesService: FavService()
        )

        // When
        await store.send(.refreshFavorites)

        // Then
        await store.receive(.refreshFavoritesFinished(Set(["x","y"]))) {
            $0.favoriteIDs = Set(["x","y"])
        }
    }

    @Test
    func search_toggleFavorite_togglesID() async {
        // Given
        let breed = CatBreed(id: "t1", name: "T", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        struct FavStub: FavoritesServiceProtocol {
            func fetchFavorites() async throws -> [Favorite] { [] }
            func addFavorite(id: String) async throws {}
            func removeFavorite(id: String) async throws {}
            func isFavorite(id: String) async -> Bool { false }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        let store = await makeSUT(
            state: SearchReducer.State(),
            favoritesService: FavStub()
        )

        // When
        await store.send(.toggleFavorite(breed))

        // Then
        await store.receive(.toggleFavoriteSuccess(id: "t1")) {
            $0.favoriteIDs = Set(["t1"])
        }
    }

    @Test
    func search_tappedBreed_pushesDetailRoute() async {
        // Given
        let breed = CatBreed(id: "d1", name: "Detail", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        let store = await makeSUT(state: SearchReducer.State())

        // When
        await store.send(.tappedBreed(breed)) {
            $0.path.append(.breedDetail(BreedDetailReducer.State(breed: breed)))
        }

        // Then
        let s = await store.state
        #expect(s.path.count == 1)
    }

    // MARK: - SUT helper
    private func makeSUT(
        state: SearchReducer.State,
        breedsService: (any BreedsServiceProtocol)? = nil,
        breedsCacheDB: (any BreedsCacheDatabaseServiceProtocol)? = nil,
        favoritesService: (any FavoritesServiceProtocol)? = nil
    ) async -> TestStoreOf<SearchReducer> {
        await TestStore(
            initialState: state,
            reducer: { SearchReducer() },
            withDependencies: {
                if let breedsService { $0.breedsService = breedsService }
                if let breedsCacheDB { $0.breedsCacheDB = breedsCacheDB }
                if let favoritesService { $0.favoritesService = favoritesService }
            }
        )
    }
}
