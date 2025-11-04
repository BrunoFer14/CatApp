import Foundation
import ComposableArchitecture
import Combine

@Reducer
struct SearchFeature {
    //Navigation Route
    @Reducer
    struct Route {
        @CasePathable
        enum State: Equatable {
            case breedDetail(BreedDetailFeature.State)
        }
        enum Action: Equatable {
            case breedDetail(BreedDetailFeature.Action)
        }
        var body: some ReducerOf<Self> {
            Scope(state: \.breedDetail, action: \.breedDetail) {
                BreedDetailFeature()
            }
        }
    }
    // MARK: - State
    @ObservableState
    struct State: Equatable {
        // Query for .searchable binding in the view (explicit action-driven binding to avoid macro collisions)
        var query: String = ""

        // Pagination/loading/favorites
        var isLoadingPage: Bool = false
        var currentPage: Int = 0
        var hasLoadedFirstPage: Bool = false
        var favoriteIDs: Set<String> = []

        // Navigation path for TCA stack
        var path = StackState<Route.State>()
    }

    // MARK: - Action
    enum Action: Equatable {
        // Query binding (explicit)
        case queryChanged(String)

        // Lifecycle
        case onAppear

        // Pagination
        case requestNextPageIfNeeded
        case fetchPage(Int)
        case fetchPageSuccess(page: Int)
        case fetchPageFailure(page: Int)
        case cacheFallbackResponse(page: Int, cachedCount: Int)

        // Favorites
        case refreshFavorites
        case refreshFavoritesFinished(Set<String>)
        case toggleFavorite(CatBreed)
        case toggleFavoriteSuccess(id: String)
        case toggleFavoriteFailure

        // Navigation
        case tappedBreed(CatBreed)
        case path(StackActionOf<Route>)
    }

    // MARK: - Dependencies
    @Dependency(\.breedsService) var breedsService
    @Dependency(\.favoritesService) var favoritesService
    @Dependency(\.breedsCacheDB) var breedsCacheDB

    private let limit: Int = APIConstants.defaultPageLimit

    // MARK: - Body
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            // Query binding
            case let .queryChanged(text):
                state.query = text
                return .none

            // Lifecycle
            case .onAppear:
                return .merge(
                    .send(.refreshFavorites),
                    state.hasLoadedFirstPage ? .none : .send(.fetchPage(UIConfig.Pagination.initialPageIndex))
                )

            // Pagination
            case .requestNextPageIfNeeded:
                let next = state.currentPage + 1
                return .send(.fetchPage(next))

            case let .fetchPage(page):
                if state.isLoadingPage { return .none }
                state.isLoadingPage = true

                return .run { [limit] send in
                    do {
                        let breeds = try await breedsService.pagedBreeds(page: page, limit: limit)
                        // Persist best-effort
                        try? await breedsCacheDB.upsertBreeds(Array(breeds.prefix(limit)), page: page, limit: limit)
                        await send(.fetchPageSuccess(page: page))
                    } catch {
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

            case let .fetchPageSuccess(page):
                state.currentPage = page
                if page == UIConfig.Pagination.initialPageIndex {
                    state.hasLoadedFirstPage = true
                }
                state.isLoadingPage = false
                return .none

            case let .fetchPageFailure(page):
                if page == UIConfig.Pagination.initialPageIndex, !state.hasLoadedFirstPage {
                    state.hasLoadedFirstPage = true
                }
                state.isLoadingPage = false
                return .none

            case let .cacheFallbackResponse(page, cachedCount):
                state.isLoadingPage = false
                if cachedCount > 0 {
                    state.currentPage = page
                    if page == UIConfig.Pagination.initialPageIndex {
                        state.hasLoadedFirstPage = true
                    }
                } else if page == UIConfig.Pagination.initialPageIndex {
                    state.hasLoadedFirstPage = true
                }
                return .none

            // Favorites
            case .refreshFavorites:
                return .run { send in
                    do {
                        let favs = try await favoritesService.fetchFavorites()
                        await send(.refreshFavoritesFinished(Set(favs.map { $0.breedId })))
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
                return .none

            // Navigation
            case let .tappedBreed(breed):
                state.path.append(.breedDetail(BreedDetailFeature.State(breed: breed)))
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            Route()
        }
    }
}

// MARK: - Helper: await first value from a Combine publisher
import Combine
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
