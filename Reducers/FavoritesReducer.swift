import Foundation
import ComposableArchitecture

struct FavoriteRow: Identifiable, Equatable {
    let id: String
    let name: String
    let imageURL: String?
    let breed: CatBreed
    var isFavorite: Bool
}

@Reducer
struct FavoritesReducer {
    
    // MARK: - Navigation Route
    //@Reducer(state: .equatable, action: .equatable)
    //enum Route {
        //case breedDetail(BreedDetailReducer)
    //}
    @Reducer
       struct Route {
           @ObservableState
           @CasePathable
           enum State: Equatable {
               case breedDetail(BreedDetailReducer.State)
           }
           enum Action: Equatable {
               case breedDetail(BreedDetailReducer.Action)
           }
           var body: some ReducerOf<Self> {
               Scope(state: \.breedDetail, action: \.breedDetail) {
                   BreedDetailReducer()
               }
           }
       }

    // MARK: - State
    @ObservableState
    struct State: Equatable {
        var rows: [FavoriteRow] = []
        var favoriteIDs: Set<String> = []
        var averageLifeSpanText: String?
        // Path holds Route.State elements
        var path = StackState<Route.State>()
    }

    // MARK: - Action
    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)

        // Lifecycle
        case onAppear

        // Favorites snapshot from SwiftData (@Query in the view will send this)
        case favoritesSnapshotChanged([FavoriteBreedDetail])

        // IDs refresh (from service)
        case refreshFavoritesFinished(Set<String>)

        // Toggle favorite
        case toggleFavorite(CatBreed)
        case toggleFavoriteSuccess(id: String)
        case toggleFavoriteFailure

        // Navigation
        case tappedRow(CatBreed)
        case path(StackActionOf<Route>)
    }

    // MARK: - Dependencies
    @Dependency(\.favoritesService) var favoritesService
    
    
    // MARK: - Body
    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            // Lifecycle
            case .onAppear:
                return refreshFavoritesEffect()

            // Snapshot coming from SwiftData via the view
            case let .favoritesSnapshotChanged(details):
                // Build rows from persisted details and mark favorites based on state.favoriteIDs
                let ids = state.favoriteIDs
                state.rows = details.map { detail in
                    let breed = CatBreed(
                        id: detail.id,
                        name: detail.name,
                        origin: detail.origin,
                        description: detail.breedDescription,
                        temperament: detail.temperament,
                        lifeSpan: detail.lifeSpan,
                        image: BreedImage(url: detail.imageUrl),
                        referenceImageId: nil
                    )
                    return FavoriteRow(
                        id: detail.id,
                        name: detail.name,
                        imageURL: detail.imageUrl,
                        breed: breed,
                        isFavorite: ids.contains(detail.id)
                    )
                }
                state.averageLifeSpanText = computeAverageLifeSpanText(from: details)
                return .none

            // Refresh IDs finished
            case let .refreshFavoritesFinished(ids):
                state.favoriteIDs = ids
                state.rows = state.rows.map { row in
                    var copy = row
                    copy.isFavorite = ids.contains(row.id)
                    return copy
                }
                return .none

            // Toggle favorite
            case let .toggleFavorite(breed):
                return toggleFavorite(for: breed)

            case let .toggleFavoriteSuccess(id):
                if state.favoriteIDs.contains(id) {
                    state.favoriteIDs.remove(id)
                } else {
                    state.favoriteIDs.insert(id)
                }
                let ids = state.favoriteIDs
                state.rows = state.rows.map { row in
                    var copy = row
                    copy.isFavorite = ids.contains(row.id)
                    return copy
                }
                return .none

            case .toggleFavoriteFailure:
                return .none

            // Navigation
            case let .tappedRow(breed):
                // Push new destination
                state.path.append(.breedDetail(BreedDetailReducer.State(breed: breed)))
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

    // MARK: - Effects helpers 
    
    private func refreshFavoritesEffect() -> EffectOf<Self> {
        FavoriteToggleHelper.createRefreshEffect(
            favoritesService: favoritesService,
            onComplete: { ids in .refreshFavoritesFinished(ids) }
        )
    }

    private func toggleFavorite(for breed: CatBreed) -> EffectOf<Self> {
        FavoriteToggleHelper.createToggleEffect(
            breed: breed,
            favoritesService: favoritesService,
            onSuccess: { id in .toggleFavoriteSuccess(id: id) },
            onFailure: { .toggleFavoriteFailure }
        )
    }
}

// MARK: - Helpers
private func computeAverageLifeSpanText(from details: [FavoriteBreedDetail]) -> String? {
    func extractNumbers(from string: String) -> [Double] {
        var numbers: [Double] = []
        var current = ""
        for ch in string {
            if ch.isNumber || ch == "." {
                current.append(ch)
            } else {
                if !current.isEmpty, let val = Double(current) {
                    numbers.append(val)
                }
                current.removeAll(keepingCapacity: true)
            }
        }
        if !current.isEmpty, let val = Double(current) {
            numbers.append(val)
        }
        return numbers
    }

    let values: [Double] = details.compactMap { detail in
        guard let life = detail.lifeSpan, !life.isEmpty else { return nil }
        let nums = extractNumbers(from: life)
        switch nums.count {
        case 2:
            return (nums[0] + nums[1]) / 2.0
        case 1:
            return nums[0]
        default:
            return nil
        }
    }

    guard !values.isEmpty else { return nil }
    let avg = values.reduce(0, +) / Double(values.count)

    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 1
    formatter.locale = .current

    return formatter.string(from: NSNumber(value: avg))
}
