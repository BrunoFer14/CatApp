import Foundation
import Combine
import ComposableArchitecture

// MARK: - Home Feature (Cat Breeds List with TCA)
/// Main feature for displaying paginated cat breeds with favorites support
/// Follows TCA architecture with proper state management and side effects
@Reducer
struct HomeFeature {
    // MARK: - Navigation Route
    /// Defines possible navigation destinations from the home screen
    @Reducer
    struct Route {
        /// Available destination states for navigation
        @ObservableState
        @CasePathable
        enum State: Equatable {
            case breedDetail(BreedDetailFeature.State)
        }
        
        /// Actions that can be performed on navigation destinations
        enum Action: Equatable {
            case breedDetail(BreedDetailFeature.Action)
        }
        
        /// Composes child reducers for navigation destinations
        var body: some ReducerOf<Self> {
            Scope(state: \.breedDetail, action: \.breedDetail) {
                BreedDetailFeature()
            }
        }
    }

    // MARK: - State
    /// Complete state for the home feature including breeds, favorites, and pagination
    @ObservableState
    struct State: Equatable {
        /// Array of cat breeds ready for display (converted from cache)
        var breeds: [CatBreed] = []
        var favoriteIDs: Set<String> = []
        var isLoadingPage: Bool = false
        var currentPage: Int = 0
        var hasLoadedFirstPage: Bool = false
        var pagesRequested: Set<Int> = []
        var lastErrorMessage: String?
        var path = StackState<Route.State>()
    }

    // MARK: - Actions
    /// All possible actions that can occur in the home feature
    enum Action: Equatable, BindableAction {
        /// Binding actions for two-way data flow
        case binding(BindingAction<State>)

        // MARK: Lifecycle Actions
        /// Triggered when the view appears for the first time
        case onAppear

        // MARK: Data Loading Actions
        /// Request to load cached breeds from local storage
        case loadCachedBreeds
        /// Successful completion of cached breeds loading
        case loadCachedBreedsFinished([CatBreed])

        // MARK: Pagination Actions
        /// Request to load the next page if needed (triggered by scroll)
        case requestNextPageIfNeeded
        /// Start fetching a specific page from the API
        case fetchPage(Int)
        /// Successfully received breeds for a page
        case fetchPageSuccess(page: Int, breeds: [CatBreed])
        /// Failed to fetch a page from the API
        case fetchPageFailure(page: Int)
        /// Fallback response when using cached data after API failure
        case cacheFallbackResponse(page: Int, cachedCount: Int)

        // MARK: Cache Management Actions
        /// Request to clear all cached data
        case clearCache
        /// Cache clearing operation completed
        case clearCacheFinished

        // MARK: Favorites Actions
        /// Request to refresh the favorites list
        case refreshFavorites
        /// Successfully loaded favorites from storage
        case refreshFavoritesFinished(Set<String>)
        /// Toggle favorite status for a specific breed
        case toggleFavorite(breed: CatBreed)
        /// Successfully updated favorite status
        case toggleFavoriteSuccess(id: String)
        /// Failed to update favorite status
        case toggleFavoriteFailure

        // MARK: Navigation Actions
        /// Handle navigation stack actions
        case path(StackActionOf<Route>)
        /// User tapped on a breed to view details
        case tappedBreed(CatBreed)
    }

    // MARK: - Dependencies
    /// Injected dependencies for accessing external services
    @Dependency(\.breedsService) var breedsService
    @Dependency(\.favoritesService) var favoritesService
    @Dependency(\.breedsCacheDB) var breedsCacheDB

    // MARK: - Configuration
    /// Number of breeds to fetch per page
    private let limit: Int = APIConstants.defaultPageLimit

    // MARK: - Body
    /// Main reducer logic that handles all actions and state transitions
    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {

            // MARK: Lifecycle Handling
            case .onAppear:
                /// Load cached breeds and favorites, start initial page if needed
                return .merge(
                    .send(.loadCachedBreeds),
                    .send(.refreshFavorites),
                    state.hasLoadedFirstPage ? .none : .send(.fetchPage(UIConfig.Pagination.initialPageIndex))
                )

            // MARK: Data Loading
            case .loadCachedBreeds:
                /// Load all cached breeds from local storage and convert to CatBreed models
                return .run { send in
                    do {
                        let cachedBreeds = try await breedsCacheDB.fetchCachedBreedsSorted()
                        let breeds = cachedBreeds.map { cached in
                            CatBreed(
                                id: cached.id,
                                name: cached.name,
                                origin: cached.origin,
                                description: cached.breedDescription,
                                temperament: cached.temperament,
                                lifeSpan: cached.lifeSpan,
                                image: BreedImage(url: cached.imageUrl),
                                referenceImageId: nil
                            )
                        }
                        await send(.loadCachedBreedsFinished(breeds))
                    } catch {
                        await send(.loadCachedBreedsFinished([]))
                    }
                }

            case let .loadCachedBreedsFinished(breeds):
                /// Update state with loaded breeds
                state.breeds = breeds
                return .none

            // MARK: Pagination Handling
            case .requestNextPageIfNeeded:
                /// Trigger loading of the next page in sequence
                let next = state.currentPage + 1
                return .send(.fetchPage(next))

            case let .fetchPage(page):
                /// Fetch a specific page from the API with duplicate prevention
                // Prevent duplicate requests for the same page
                if state.isLoadingPage || state.pagesRequested.contains(page) {
                    return .none
                }
                state.pagesRequested.insert(page)
                state.isLoadingPage = true
                state.lastErrorMessage = nil

                return .run { [limit] send in
                    do {
                        // Try to fetch from API using async/await service
                        let breeds = try await breedsService.pagedBreeds(page: page, limit: limit)
                        let pageSlice = Array(breeds.prefix(limit))
                        // Persist to cache (best effort - don't fail if cache write fails)
                        try? await breedsCacheDB.upsertBreeds(pageSlice, page: page, limit: limit)
                        await send(.fetchPageSuccess(page: page, breeds: pageSlice))
                    } catch {
                        // On API failure, try to use cached data as fallback
                        do {
                            let cached = try await breedsCacheDB.fetchCachedPage(page: page, limit: limit)
                            await send(.cacheFallbackResponse(page: page, cachedCount: cached.count))
                            await send(.fetchPageFailure(page: page))
                        } catch {
                            await send(.cacheFallbackResponse(page: page, cachedCount: 0))
                            await send(.fetchPageFailure(page: page))
                        }
                    }
                }

            case let .fetchPageSuccess(page, _):
                state.currentPage = page
                if page == UIConfig.Pagination.initialPageIndex {
                    state.hasLoadedFirstPage = true
                }
                state.isLoadingPage = false
                state.lastErrorMessage = nil
                // Reload cached breeds to update state
                return .send(.loadCachedBreeds)

            case let .fetchPageFailure(page):
                if page == UIConfig.Pagination.initialPageIndex, !state.hasLoadedFirstPage {
                    state.hasLoadedFirstPage = true
                }
                state.lastErrorMessage = "\(UIStrings.Common.pageLoadFailure) \(page)."
                return .none

            case let .cacheFallbackResponse(page, cachedCount):
                state.isLoadingPage = false
                if cachedCount > 0 {
                    state.currentPage = page
                    if page == UIConfig.Pagination.initialPageIndex {
                        state.hasLoadedFirstPage = true
                    }
                    // Reload cached breeds to update state
                    return .send(.loadCachedBreeds)
                } else if page == UIConfig.Pagination.initialPageIndex {
                    state.hasLoadedFirstPage = true
                }
                return .none

            // Cache management
            case .clearCache:
                // local reset and clear
                state.currentPage = 0
                state.isLoadingPage = false
                state.pagesRequested.removeAll()
                state.hasLoadedFirstPage = false
                state.lastErrorMessage = nil

                return .run { send in
                    do { try await breedsCacheDB.clearCache() }
                    catch { /* log opcional */ }
                    await send(.clearCacheFinished)
                }

            case .clearCacheFinished:
                state.breeds = []
                return .merge(
                    .send(.refreshFavorites),
                    .send(.fetchPage(UIConfig.Pagination.initialPageIndex))
                )

            // Favorites
            case .refreshFavorites:
                return .run { send in
                    do {
                        let favs = try await favoritesService.fetchFavorites()
                        let ids = Set(favs.map { $0.breedId })
                        await send(.refreshFavoritesFinished(ids))
                    } catch {
                        await send(.refreshFavoritesFinished([]))
                    }
                }

            case let .refreshFavoritesFinished(ids):
                state.favoriteIDs = ids
                return .none

            case let .toggleFavorite(breed):
                return .run { send in
                    let id = breed.id
                    if await favoritesService.isFavorite(id: id) {
                        do {
                            try await favoritesService.removeFavorite(id: id)
                            try await favoritesService.deleteFavoriteDetail(id: id)
                            await send(.toggleFavoriteSuccess(id: id))
                        } catch {
                            await send(.toggleFavoriteFailure)
                        }
                    } else {
                        do {
                            try await favoritesService.addFavorite(id: id)
                            try await favoritesService.upsertFavoriteDetail(from: breed)
                            await send(.toggleFavoriteSuccess(id: id))
                        } catch {
                            await send(.toggleFavoriteFailure)
                        }
                    }
                }

            case let .toggleFavoriteSuccess(id):
                if state.favoriteIDs.contains(id) {
                    state.favoriteIDs.remove(id)
                } else {
                    state.favoriteIDs.insert(id)
                }
                return .none

            case .toggleFavoriteFailure:
                state.lastErrorMessage = UIStrings.Common.favoriteUpdateFailure
                return .none

            // Navigation
            case let .tappedBreed(breed):
                state.path.append(.breedDetail(BreedDetailFeature.State(breed: breed)))
                return .none

            case .path:
                return .none

            case .binding:
                return .none
            }
        }
        // Compose child reducers for stack elements
        .forEach(\.path, action: \.path) {
            Route()
        }
    }
}

// MARK: - Helper: await first value from a Combine publisher
private extension Publisher {
    func asyncFirst() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = self.first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        _ = cancellable
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        _ = cancellable
                    }
                )
        }
    }
}
