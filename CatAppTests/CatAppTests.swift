import Foundation
import Testing
@testable import CatApp
import ComposableArchitecture

struct CatAppTests {

    // Existing tests

    @Test
    func testInitialState() async {
        // Given
        let testBreed = CatBreed(
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
        let store = await TestStore(
            initialState: BreedDetailReducer.State(breed: testBreed),
            reducer: { BreedDetailReducer() }
        )

        // Then
        let state = await store.state
        #expect(state.breed.id == "test-id")
        #expect(state.breed.name == "Test Breed")
        #expect(state.screenState == .loading)
        #expect(state.isFavorite == false)
        #expect(state.isLoading == false)
        #expect(state.isLoadingGallery == false)
        #expect(state.imageItems.isEmpty)
        #expect(state.selectedIndex == UIConfig.Pagination.initialPageIndex)
        #expect(state.lastErrorMessage == nil)
    }

    @Test
    func isFavoriteButtonToggled() async throws {
        // Given
        let testBreed = CatBreed(
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
        let store = await TestStore(
            initialState: BreedDetailReducer.State(breed: testBreed),
            reducer: { BreedDetailReducer() },
            withDependencies: { deps in
                deps.favoritesService = FavoritesStub(initiallyFavorite: false)
            }
        )
        await store.send(.toggleFavorite)

        // Then
        await store.receive(.toggleFavoriteSuccess(id: "test-id", isNowFavorite: true)) { state in
            state.isFavorite = true
            state.lastErrorMessage = nil
        }
    }

    // New
    @Test
    func detail_loadDetail_nil_setsNotFoundError() async {
        // Given
        let breed = CatBreed(id: "x", name: "X", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        let store = await TestStore(
            initialState: BreedDetailReducer.State(breed: breed),
            reducer: { BreedDetailReducer() },
            withDependencies: {
                $0.detailsService = DetailsStub(detail: nil, images: [])
                $0.favoritesService = FavoritesStub(initiallyFavorite: false)
            }
        )

        // When
        await store.send(.loadDetail(id: "x")) { $0.isLoading = true }

        // Then
        await store.receive(.detailResponseSuccess(nil)) {
            $0.isLoading = false
            $0.screenState = .error(UIStrings.Detail.notFoundError)
        }
    }

    @Test
    func detail_loadGallery_success_rebuildsItemsAndResetsIndex() async {
        // Given
        let breed = CatBreed(id: "b", name: "B", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: BreedImage(url: "main.jpg"), referenceImageId: nil)
        let gallery = [BreedGalleryImage(id: "g1", url: "main.jpg"), BreedGalleryImage(id: "g2", url: "g2.jpg")]
        let store = await TestStore(
            initialState: BreedDetailReducer.State(breed: breed),
            reducer: { BreedDetailReducer() },
            withDependencies: {
                $0.detailsService = DetailsStub(detail: breed, images: gallery)
                $0.favoritesService = FavoritesStub(initiallyFavorite: false)
            }
        )

        // When
        await store.send(.loadGallery(id: "b", limit: 10)) { $0.isLoadingGallery = true }

        // Then
        await store.receive(.galleryResponseSuccess(gallery)) {
            $0.isLoadingGallery = false
            $0.galleryImages = gallery
            $0.selectedIndex = 0
        }
        // rebuildImageItems mutates state; reflect that in expectations
        await store.receive(.rebuildImageItems) {
            $0.imageItems = [
                .init(id: "main.jpg", url: "main.jpg"),
                .init(id: "g2.jpg", url: "g2.jpg")
            ]
        }
        // Now assert URLs content
        let urls = await store.state.imageItems.map(\.url)
        #expect(urls.first == "main.jpg")
        #expect(urls.contains("g2.jpg"))
    }

    @Test
    func detail_present_and_dismiss_fullscreen() async {
        // Given
        var state = BreedDetailReducer.State(breed: CatBreed(id: "b", name: "B", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil))
        state.imageItems = [.init(id: "1", url: "1.jpg")]
        let store = await TestStore(initialState: state, reducer: { BreedDetailReducer() })

        // When
        await store.send(.presentFullscreenForSelected) { $0.isPresentingFullscreen = true; $0.fullscreenURL = "1.jpg" }

        // Then
        await store.send(.dismissFullscreen) { $0.isPresentingFullscreen = false; $0.fullscreenURL = nil }
    }

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
        let store = await TestStore(
            initialState: FavoritesReducer.State(),
            reducer: { FavoritesReducer() },
            withDependencies: { $0.favoritesService = FavService() }
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
        let store = await TestStore(initialState: state, reducer: { FavoritesReducer() })

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
        let store = await TestStore(initialState: FavoritesReducer.State(), reducer: { FavoritesReducer() })

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
        let store = await TestStore(initialState: FavoritesReducer.State(), reducer: { FavoritesReducer() })

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
        let store = await TestStore(initialState: state, reducer: { FavoritesReducer() })

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
        let store = await TestStore(initialState: state, reducer: { FavoritesReducer() })

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
    
    // BreedDetailReducer: refreshFavorite (true)
    @Test
    func detail_refreshFavorite_updatesIsFavorite_true() async {
        // Given
        let breed = CatBreed(id: "fav-1", name: "Fav 1", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        let store = await TestStore(
            initialState: BreedDetailReducer.State(breed: breed),
            reducer: { BreedDetailReducer() },
            withDependencies: {
                $0.favoritesService = FavoritesStub(initiallyFavorite: true)
            }
        )

        // When
        await store.send(.refreshFavorite)

        // Then
        await store.receive(.toggleFavoriteSuccess(id: "fav-1", isNowFavorite: true)) {
            $0.isFavorite = true
            $0.lastErrorMessage = nil
        }
    }

    // BreedDetailReducer: refreshFavorite (false)
    @Test
    func detail_refreshFavorite_updatesIsFavorite_false() async {
        // Given
        let breed = CatBreed(id: "fav-2", name: "Fav 2", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        let store = await TestStore(
            initialState: BreedDetailReducer.State(breed: breed),
            reducer: { BreedDetailReducer() },
            withDependencies: {
                $0.favoritesService = FavoritesStub(initiallyFavorite: false)
            }
        )
        
        // When
        await store.send(.refreshFavorite)

        // Then: no state change expected because isFavorite is already false
        await store.receive(.toggleFavoriteSuccess(id: "fav-2", isNowFavorite: false))
        let s = await store.state
        #expect(s.isFavorite == false)
        #expect(s.lastErrorMessage == nil)
    }

    // MARK: - SearchReducer tests

    @Test
    func search_fetchPageSuccess_updatesFlags() async {
        // Given
        let breeds = [
            CatBreed(id: "1", name: "One", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil),
            CatBreed(id: "2", name: "Two", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        ]
        let page = UIConfig.Pagination.initialPageIndex
        let store = await TestStore(
            initialState: SearchReducer.State(),
            reducer: { SearchReducer() },
            withDependencies: {
                $0.breedsService = BreedsServiceStub(pages: [page: breeds])
                $0.breedsCacheDB = BreedsCacheDBStub()
            }
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
        let store = await TestStore(
            initialState: SearchReducer.State(),
            reducer: { SearchReducer() },
            withDependencies: {
                $0.breedsService = BreedsServiceStub(error: URLError(.badServerResponse))
                $0.breedsCacheDB = BreedsCacheDBStub(cachedPages: [page: cached])
            }
        )

        // When
        await store.send(SearchReducer.Action.fetchPage(page)) {
            $0.isLoadingPage = true
        }

        // Then
        await store.receive(SearchReducer.Action.cacheFallbackResponse(page: page, cachedCount: cached.count)) {
            $0.isLoadingPage = false
            $0.currentPage = page
            // hasLoadedFirstPage remains false since page != initial
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
        let store = await TestStore(
            initialState: SearchReducer.State(),
            reducer: { SearchReducer() },
            withDependencies: { $0.favoritesService = FavService() }
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
        // Stub returns false for isFavorite so we simulate adding
        struct FavStub: FavoritesServiceProtocol {
            func fetchFavorites() async throws -> [Favorite] { [] }
            func addFavorite(id: String) async throws {}
            func removeFavorite(id: String) async throws {}
            func isFavorite(id: String) async -> Bool { false }
            func upsertFavoriteDetail(from breed: CatBreed) async throws {}
            func deleteFavoriteDetail(id: String) async throws {}
            func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
        }
        let store = await TestStore(
            initialState: SearchReducer.State(),
            reducer: { SearchReducer() },
            withDependencies: { $0.favoritesService = FavStub() }
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
        let store = await TestStore(
            initialState: SearchReducer.State(),
            reducer: { SearchReducer() }
        )

        // When
        await store.send(.tappedBreed(breed)) {
            $0.path.append(.breedDetail(BreedDetailReducer.State(breed: breed)))
        }

        // Then
        let s = await store.state
        #expect(s.path.count == 1)
    }
}

// - MARK: Stubs
struct FavoritesStub: FavoritesServiceProtocol {
    var initiallyFavorite: Bool
    func fetchFavorites() async throws -> [Favorite] { [] }
    func addFavorite(id: String) async throws {}
    func removeFavorite(id: String) async throws {}
    func isFavorite(id: String) async -> Bool { initiallyFavorite }
    func upsertFavoriteDetail(from breed: CatBreed) async throws {}
    func deleteFavoriteDetail(id: String) async throws {}
    func fetchFavoriteDetailsByIDs(_ ids: Set<String>) async throws -> [FavoriteBreedDetail] { [] }
}

struct DetailsStub: DetailsServiceProtocol {
    var detail: CatBreed?
    var images: [BreedGalleryImage] = []
    func breedDetail(id: String) async throws -> CatBreed? { detail }
    func breedImages(id: String, limit: Int) async throws -> [BreedGalleryImage] { images }
}

// Lightweight stubs for SearchReducer tests
struct BreedsServiceStub: BreedsServiceProtocol {
    var pages: [Int: [CatBreed]] = [:]
    var error: Error? = nil
    func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] {
        if let error { throw error }
        return pages[page] ?? []
    }
}

struct BreedsCacheDBStub: BreedsCacheDatabaseServiceProtocol {
    var cachedPages: [Int: [CachedBreed]] = [:]
    func upsertBreeds(_ breeds: [CatBreed], page: Int, limit: Int) async throws {}
    func fetchCachedBreedsSorted() async throws -> [CachedBreed] { [] }
    func fetchBreedsByIDs(_ ids: Set<String>) async throws -> [CachedBreed] { [] }
    func fetchCachedPage(page: Int, limit: Int) async throws -> [CachedBreed] {
        cachedPages[page] ?? []
    }
    func clearCache() async throws {}
}
