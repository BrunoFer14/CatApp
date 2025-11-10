import Foundation
import ComposableArchitecture
import Combine

@Reducer
struct BreedDetailFeature {
    // MARK: - State
    @ObservableState
    struct State: Equatable {
        // Core
        var breed: CatBreed

        // Favorites
        var isFavorite: Bool = false
        var lastErrorMessage: String?

        // Detail loading state
        enum ScreenState: Equatable {
            case idle
            case loading
            case content
            case error(String)
        }
        var screenState: ScreenState = .idle
        var isLoading: Bool = false

        // Gallery
        var galleryImages: [BreedGalleryImage] = []
        var isLoadingGallery: Bool = false
        var galleryError: String?

        // Carousel items (URLs) and selection
        struct ImageItem: Equatable, Identifiable {
            let id: String
            let url: String
        }
        var imageItems: [ImageItem] = []
        var selectedIndex: Int = UIConfig.Pagination.initialPageIndex

        // Fullscreen
        var isPresentingFullscreen: Bool = false
        var fullscreenURL: String?

        init(breed: CatBreed) {
            self.breed = breed
        }
    }

    // MARK: - Actions
    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)

        // Lifecycle
        case onAppear

        // Favorites
        case refreshFavorite
        case toggleFavorite
        case toggleFavoriteSuccess(id: String, isNowFavorite: Bool)
        case toggleFavoriteFailure

        // Detail loading
        case loadDetail(id: String)
        case detailResponseSuccess(CatBreed?)
        case detailResponseFailure(String)

        // Gallery
        case loadGallery(id: String, limit: Int)
        case galleryResponseSuccess([BreedGalleryImage])
        case galleryResponseFailure(String)

        // Carousel / selection
        case selectImage(index: Int)
        case goPrev
        case goNext

        // Fullscreen
        case presentFullscreenForSelected
        case dismissFullscreen

        // Internal
        case rebuildImageItems
    }

    // MARK: - Dependencies
    @Dependency(\.favoritesService) var favoritesService
    @Dependency(\.detailsService) var detailsService

    // MARK: - Body
    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {

            // Lifecycle
            case .onAppear:
                // Build initial image items from the current breed and kick off loads
                rebuildImageItems(into: &state)
                return .merge(
                    .send(.refreshFavorite),
                    .send(.loadDetail(id: state.breed.id)),
                    .send(.loadGallery(id: state.breed.id, limit: APIConstants.defaultGalleryLimit))
                )

            // Favorites
            case .refreshFavorite:
                return refreshFavoriteEffect(for: state.breed.id)

            case .toggleFavorite:
                return toggleFavorite(for: state.breed)

            case let .toggleFavoriteSuccess(id, isNowFavorite):
                if state.breed.id == id {
                    state.isFavorite = isNowFavorite
                    state.lastErrorMessage = nil
                }
                return .none

            case .toggleFavoriteFailure:
                state.lastErrorMessage = UIStrings.Common.favoriteUpdateFailure
                return .none

            // Detail loading
            case let .loadDetail(id):
                // Only fetch if we don't have a fully loaded breed yet; current code uses presence of content state
                if case .content = state.screenState {
                    return .none
                }
                state.screenState = .loading
                state.isLoading = true
                state.lastErrorMessage = nil
                return loadDetailEffect(id: id)

            case let .detailResponseSuccess(fetched):
                state.isLoading = false
                if let fetched {
                    state.breed = fetched
                    state.screenState = .content
                    // If the main image changed, rebuild
                    return .send(.rebuildImageItems)
                } else {
                    state.screenState = .error(UIStrings.Detail.notFoundError)
                }
                return .none

            case let .detailResponseFailure(message):
                state.isLoading = false
                state.screenState = .error("Erro: \(message)")
                return .none

            // Gallery
            case let .loadGallery(id, limit):
                state.isLoadingGallery = true
                state.galleryError = nil
                return loadGalleryEffect(id: id, limit: limit)

            case let .galleryResponseSuccess(images):
                state.isLoadingGallery = false
                state.galleryImages = images
                // Reset selection to initial page when gallery updates
                state.selectedIndex = UIConfig.Pagination.initialPageIndex
                return .send(.rebuildImageItems)

            case let .galleryResponseFailure(message):
                state.isLoadingGallery = false
                state.galleryError = "Erro: \(message)"
                return .none

            // Carousel / selection
            case let .selectImage(index):
                if state.imageItems.indices.contains(index) {
                    state.selectedIndex = index
                }
                return .none

            case .goPrev:
                state.selectedIndex = max(UIConfig.Pagination.initialPageIndex, state.selectedIndex - 1)
                return .none

            case .goNext:
                state.selectedIndex = min(max(0, state.imageItems.count - 1), state.selectedIndex + 1)
                return .none

            // Fullscreen
            case .presentFullscreenForSelected:
                guard state.imageItems.indices.contains(state.selectedIndex) else { return .none }
                state.fullscreenURL = state.imageItems[state.selectedIndex].url
                state.isPresentingFullscreen = true
                return .none

            case .dismissFullscreen:
                state.isPresentingFullscreen = false
                state.fullscreenURL = nil
                return .none

            // Internal
            case .rebuildImageItems:
                rebuildImageItems(into: &state)
                return .none

            case .binding:
                return .none
            }
        }
    }

    // MARK: - Effects helpers
    private func toggleFavorite(for breed: CatBreed) -> EffectOf<Self> {
        .run { send in
            let id = breed.id
            if await favoritesService.isFavorite(id: id) {
                do {
                    try await favoritesService.removeFavorite(id: id)
                    try await favoritesService.deleteFavoriteDetail(id: id)
                    await send(.toggleFavoriteSuccess(id: id, isNowFavorite: false))
                } catch {
                    await send(.toggleFavoriteFailure)
                }
            } else {
                do {
                    try await favoritesService.addFavorite(id: id)
                    try await favoritesService.upsertFavoriteDetail(from: breed)
                    await send(.toggleFavoriteSuccess(id: id, isNowFavorite: true))
                } catch {
                    await send(.toggleFavoriteFailure)
                }
            }
        }
    }

    private func refreshFavoriteEffect(for id: String) -> EffectOf<Self> {
        .run { [id] send in
            let isFav = await favoritesService.isFavorite(id: id)
            await send(.toggleFavoriteSuccess(id: id, isNowFavorite: isFav))
        }
    }

    private func loadDetailEffect(id: String) -> EffectOf<Self> {
        .run { [id] send in
            do {
                let result = try await detailsService.breedDetail(id: id)
                await send(.detailResponseSuccess(result))
            } catch {
                await send(.detailResponseFailure(error.localizedDescription))
            }
        }
    }

    private func loadGalleryEffect(id: String, limit: Int) -> EffectOf<Self> {
        .run { [id, limit] send in
            do {
                let images = try await detailsService.breedImages(id: id, limit: limit)
                await send(.galleryResponseSuccess(images))
            } catch {
                await send(.galleryResponseFailure(error.localizedDescription))
            }
        }
    }
}

// MARK: - Helpers
private func rebuildImageItems(into state: inout BreedDetailFeature.State) {
    var urls: [String] = []

    // main image (from breed)
    if let main = state.breed.image?.url ?? state.breed.referenceImageUrl {
        urls.append(main)
    }
    // gallery urls
    let gallery = state.galleryImages.map { $0.url }

    // deduplicate while preserving order (main first)
    var seen = Set<String>()
    var result: [BreedDetailFeature.State.ImageItem] = []
    for url in urls + gallery {
        if !seen.contains(url) {
            seen.insert(url)
            result.append(.init(id: url, url: url))
        }
    }

    state.imageItems = result
    if state.selectedIndex >= state.imageItems.count {
        state.selectedIndex = max(UIConfig.Pagination.initialPageIndex, state.imageItems.count - 1)
    }
}
