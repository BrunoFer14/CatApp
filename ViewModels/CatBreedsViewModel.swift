import Foundation
import Combine
import SwiftData

@MainActor
class CatBreedsViewModel: ObservableObject {

    @Published var favoriteIDs: Set<String> = []
    @Published var isLoadingPage = false
    @Published var currentPage = 0
    @Published var hasLoadedFirstPage = false

    private var cancellables = Set<AnyCancellable>()
    private let repository: BreedsRepositoryProtocol
    private let detailsRepository: DetailsRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let breedsCacheDB: BreedsCacheDatabaseServiceProtocol

    private let limit = APIConstants.defaultPageLimit
    private var pagesRequested: Set<Int> = []

    // Novo init que recebe o ModelContainer para criar FavoritesRepository de background
    init(
        container: ModelContainer,
        repository: BreedsRepositoryProtocol = BreedsRepository(),
        detailsRepository: DetailsRepositoryProtocol = DetailsRepository(),
        favoritesRepository: FavoritesRepositoryProtocol? = nil,
        breedsCacheDB: BreedsCacheDatabaseServiceProtocol? = nil,
        autoFetchFirstPage: Bool = true
    ) {
        self.repository = repository
        self.detailsRepository = detailsRepository

        // DB base ainda pode ser MainActor para cache de breeds (mantemos como estava)
        let mainContext = container.mainContext
        let baseDB = SwiftDataDatabaseService(context: mainContext)

        // Novo favoritesRepository async baseado em container
        self.favoritesRepository = favoritesRepository ?? FavoritesRepository(container: container)
        self.breedsCacheDB = breedsCacheDB ?? BreedsCacheDatabaseService(db: baseDB)

        // Carregar favoritos async
        fetchFavorites()

        if autoFetchFirstPage {
            fetchPage(page: 0)
        }
    }

    // Mantém compatibilidade com inicialização anterior via ModelContext
    convenience init(
        context: ModelContext,
        repository: BreedsRepositoryProtocol = BreedsRepository(),
        detailsRepository: DetailsRepositoryProtocol = DetailsRepository(),
        favoritesRepository: FavoritesRepositoryProtocol? = nil,
        breedsCacheDB: BreedsCacheDatabaseServiceProtocol? = nil,
        autoFetchFirstPage: Bool = true
    ) {
        self.init(
            container: context.container,
            repository: repository,
            detailsRepository: detailsRepository,
            favoritesRepository: favoritesRepository,
            breedsCacheDB: breedsCacheDB,
            autoFetchFirstPage: autoFetchFirstPage
        )
    }

    func requestNextPageIfNeeded() {
        let next = currentPage + 1
        fetchPage(page: next)
    }

    func fetchPage(page: Int) {
        guard !isLoadingPage else { return }
        guard !pagesRequested.contains(page) else { return }
        pagesRequested.insert(page)
        isLoadingPage = true

        repository.fetchBreeds(page: page, limit: limit)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    self.isLoadingPage = false
                    switch completion {
                    case .failure:
                        // Allow retrying this page later
                        self.pagesRequested.remove(page)

                        // Fallback: try to read the requested page from cache
                        do {
                            let cached = try self.breedsCacheDB.fetchCachedPage(page: page, limit: self.limit)
                            if !cached.isEmpty {
                                self.currentPage = page
                                if page == 0 { self.hasLoadedFirstPage = true }
                            } else if page == 0 {
                                self.hasLoadedFirstPage = true
                            }
                        } catch {
                            print("❌ Cache load error page \(page): \(error)")
                            if page == 0 {
                                self.hasLoadedFirstPage = true
                            }
                        }
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] newBreeds in
                    guard let self else { return }
                    let pageSlice = Array(newBreeds.prefix(self.limit))

                    self.saveToCache(pageSlice, page: page)

                    self.currentPage = page
                    if page == 0 { self.hasLoadedFirstPage = true }

                    self.isLoadingPage = false
                }
            )
            .store(in: &cancellables)
    }

    private func saveToCache(_ breeds: [CatBreed], page: Int) {
        do { try breedsCacheDB.upsertBreeds(breeds, page: page, limit: limit) }
        catch { print("❌ Cache save error: \(error)") }
    }

    // MARK: - Cache management (Settings)

    func clearCache() {
        do {
            try breedsCacheDB.clearCache()
            currentPage = 0
            isLoadingPage = false
            pagesRequested.removeAll()
            hasLoadedFirstPage = false

            refreshFavorites()
            fetchPage(page: 0)
        } catch {
            print("❌ Error clearing cache: \(error)")
        }
    }

    // MARK: - Favorites (async)

    private func fetchFavorites() {
        Task {
            do {
                let favs = try await favoritesRepository.fetchFavorites()
                await MainActor.run {
                    self.favoriteIDs = Set(favs.map { $0.breedId })
                }
            } catch {
                await MainActor.run {
                    self.favoriteIDs = []
                }
                print("❌ Error fetching favorites: \(error)")
            }
        }
    }

    func refreshFavorites() {
        fetchFavorites()
    }

    func isFavorite(_ breed: CatBreed) -> Bool {
        favoriteIDs.contains(breed.id)
    }

    func toggleFavorite(for: CatBreed) {
        let id = `for`.id
        Task {
            if await favoritesRepository.isFavorite(id: id) {
                do {
                    try await favoritesRepository.removeFavorite(id: id)
                    try await favoritesRepository.deleteFavoriteDetail(id: id)
                    await MainActor.run {
                        self.favoriteIDs.remove(id)
                    }
                } catch {
                    print("❌ Error removing favorite: \(error)")
                }
            } else {
                do {
                    try await favoritesRepository.addFavorite(id: id)
                    try await favoritesRepository.upsertFavoriteDetail(from: `for`)
                    await MainActor.run {
                        self.favoriteIDs.insert(id)
                    }
                } catch {
                    print("❌ Error adding favorite: \(error)")
                }
            }
        }
    }
}
