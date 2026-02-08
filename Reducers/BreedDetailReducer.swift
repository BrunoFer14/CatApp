import Foundation
import ComposableArchitecture
import Combine

@Reducer
struct BreedDetailReducer {
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
            case loading
            case content
            case error(String)
        }
        var screenState: ScreenState = .loading
        var isLoading: Bool { screenState == .loading }

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
                // Show the passed-in breed immediately so UI isn't blocked by network.
                state.screenState = .content
                state.lastErrorMessage = nil
                rebuildImageItems(into: &state)

                var effects: [EffectOf<Self>] = []
                effects.append(refreshFavoriteEffect(for: state.breed.id))
                effects.append(loadDetailEffect(id: state.breed.id))

                state.isLoadingGallery = true
                state.galleryError = nil
                effects.append(loadGalleryEffect(id: state.breed.id, limit: APIConstants.defaultGalleryLimit))

                return .merge(effects)

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
                // Keep showing content; update in background
                state.lastErrorMessage = nil
                return loadDetailEffect(id: id)

            case let .detailResponseSuccess(fetched):
                if let fetched {
                    state.breed = fetched
                    return .send(.rebuildImageItems)
                } else {
                    // Keep showing initial content; record a non-blocking error
                    state.lastErrorMessage = UIStrings.Detail.notFoundError
                }
                return .none

            case let .detailResponseFailure(message):
                // Keep UI usable, just surface error message
                state.lastErrorMessage = "Erro: \(message)"
                return .none

            // Gallery
            case let .loadGallery(id, limit):
                state.isLoadingGallery = true
                state.galleryError = nil
                return loadGalleryEffect(id: id, limit: limit)

            case let .galleryResponseSuccess(images):
                state.isLoadingGallery = false
                state.galleryImages = images
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
        FavoriteToggleHelper.createToggleEffectWithBool(
            breed: breed,
            favoritesService: favoritesService,
            onSuccess: { id, isFavorite in .toggleFavoriteSuccess(id: id, isNowFavorite: isFavorite) },
            onFailure: { .toggleFavoriteFailure }
        )
    }

    private func refreshFavoriteEffect(for id: String) -> EffectOf<Self> {
        FavoriteToggleHelper.createSingleFavoriteRefreshEffect(
            id: id,
            favoritesService: favoritesService,
            onComplete: { id, isFavorite in .toggleFavoriteSuccess(id: id, isNowFavorite: isFavorite) }
        )
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
private func rebuildImageItems(into state: inout BreedDetailReducer.State) {
    var items: [BreedDetailReducer.State.ImageItem] = []

    // 1) Main image by URL (if present)
    let mainURL = state.breed.image?.url ?? state.breed.referenceImageUrl
    if let mainURL {
        items.append(.init(id: "main:\(mainURL)", url: mainURL))
    }

    // 2) Gallery images: prefer uniqueness by gallery ID, and also skip if URL equals main
    var seenGalleryIDs = Set<String>()
    var seenURLs = Set<String>()
    if let mainURL { seenURLs.insert(mainURL) }

    for img in state.galleryImages {
        // Skip if duplicate gallery ID
        if seenGalleryIDs.contains(img.id) { continue }
        // Skip if same URL as main or already added
        if seenURLs.contains(img.url) { continue }

        seenGalleryIDs.insert(img.id)
        seenURLs.insert(img.url)
        items.append(.init(id: img.id, url: img.url))
    }

    state.imageItems = items
    if state.selectedIndex >= state.imageItems.count {
        state.selectedIndex = max(UIConfig.Pagination.initialPageIndex, state.imageItems.count - 1)
    }
}
