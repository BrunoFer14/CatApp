import Foundation
import Testing
@testable import CatApp
import ComposableArchitecture

struct BreedDetailReducerTests {

    @Test
    func testInitialState() async {
        // Given
        //using testBreed -> teststubs
        // When
        let store = await makeSUT(state: .init(breed: testBreed))

        // Then
        let state = await store.state
        #expect(state.breed.id == "test-id")
        #expect(state.breed.name == "Test Breed")
        #expect(state.screenState == .loading)
        #expect(state.isFavorite == false)
        #expect(state.isLoading == true) // computed from .loading
        #expect(state.isLoadingGallery == false)
        #expect(state.imageItems.isEmpty)
        #expect(state.selectedIndex == UIConfig.Pagination.initialPageIndex)
        #expect(state.lastErrorMessage == nil)
    }

    @Test
    func isFavoriteButtonToggled() async throws {
        // Given
        //using testBreed -> teststubs

        // When
        let store = await makeSUT(
            state: .init(breed: testBreed),
            favorites: FavoritesStub(initiallyFavorite: false)
        )
        await store.send(.toggleFavorite)

        // Then
        await store.receive(.toggleFavoriteSuccess(id: "test-id", isNowFavorite: true)) { state in
            state.isFavorite = true
            state.lastErrorMessage = nil
        }
    }

    @Test
    func detail_loadDetail_nil_setsNotFoundError() async {
        // Given
        let breed = makeBreed(id: "x", name: "X", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil)
        let store = await makeSUT(
            state: .init(breed: breed),
            details: DetailsStub(detail: nil, images: []),
            favorites: FavoritesStub(initiallyFavorite: false)
        )

        // When
        await store.send(.loadDetail(id: "x"))

        // Then
        await store.receive(.detailResponseSuccess(nil)) {
            $0.screenState = .error(UIStrings.Detail.notFoundError)
        }
    }

    @Test
    func detail_loadGallery_success_rebuildsItemsAndResetsIndex() async {
        // Given
        let breed = makeBreed(id: "b", name: "B", image: BreedImage(url: "main.jpg"))
        let gallery = [BreedGalleryImage(id: "g1", url: "main.jpg"), BreedGalleryImage(id: "g2", url: "g2.jpg")]
        let store = await makeSUT(
            state: .init(breed: breed),
            details: DetailsStub(detail: breed, images: gallery),
            favorites: FavoritesStub(initiallyFavorite: false)
        )

        // When
        await store.send(.loadGallery(id: "b", limit: 10)) { $0.isLoadingGallery = true }

        // Then
        await store.receive(.galleryResponseSuccess(gallery)) {
            $0.isLoadingGallery = false
            $0.galleryImages = gallery
            $0.selectedIndex = 0
        }
        await store.receive(.rebuildImageItems) {
            $0.imageItems = [
                .init(id: "main.jpg", url: "main.jpg"),
                .init(id: "g2.jpg", url: "g2.jpg")
            ]
        }
    }

    @Test
    func detail_present_and_dismiss_fullscreen() async {
        // Given
        var state = BreedDetailReducer.State(breed: makeBreed(id: "b", name: "B", image: nil))
        state.imageItems = [.init(id: "1", url: "1.jpg")]
        let store = await makeSUT(state: state)

        // When
        await store.send(.presentFullscreenForSelected) { $0.isPresentingFullscreen = true; $0.fullscreenURL = "1.jpg" }

        // Then
        await store.send(.dismissFullscreen) { $0.isPresentingFullscreen = false; $0.fullscreenURL = nil }
    }

    @Test
    func detail_refreshFavorite_updatesIsFavorite_true() async {
        // Given
        let breed = makeBreed(id: "fav-1", name: "Fav 1", image: nil)
        let store = await makeSUT(
            state: .init(breed: breed),
            favorites: FavoritesStub(initiallyFavorite: true)
        )

        // When
        await store.send(.refreshFavorite)

        // Then
        await store.receive(.toggleFavoriteSuccess(id: "fav-1", isNowFavorite: true)) {
            $0.isFavorite = true
            $0.lastErrorMessage = nil
        }
    }

    @Test
    func detail_refreshFavorite_updatesIsFavorite_false() async {
        // Given
        let breed = makeBreed(id: "fav-2", name: "Fav 2", image: nil)
        let store = await makeSUT(
            state: .init(breed: breed),
            favorites: FavoritesStub(initiallyFavorite: false)
        )
        
        // When
        await store.send(.refreshFavorite)

        // Then: no state change expected because isFavorite is already false
        await store.receive(.toggleFavoriteSuccess(id: "fav-2", isNowFavorite: false))
        let s = await store.state
        #expect(s.isFavorite == false)
        #expect(s.lastErrorMessage == nil)
    }

    // MARK: - SUT helper
    private func makeSUT(
        state: BreedDetailReducer.State,
        details: DetailsStub? = nil,
        favorites: FavoritesStub? = nil
    ) async -> TestStoreOf<BreedDetailReducer> {
        await TestStore(
            initialState: state,
            reducer: { BreedDetailReducer() },
            withDependencies: {
                if let details { $0.detailsService = details }
                if let favorites { $0.favoritesService = favorites }
            }
        )
    }
}
