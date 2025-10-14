import Foundation
import Combine
import SwiftData

@MainActor
class CatBreedsViewModel: ObservableObject {
    // Removido: @Published var breeds
    @Published var favoriteIDs: Set<String> = []
    @Published var isLoadingPage = false
    @Published var currentPage = 0
    @Published var hasLoadedFirstPage = false

    private var cancellables = Set<AnyCancellable>()
    private let repository: BreedsRepositoryProtocol
    private let detailsRepository: DetailsRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let breedsCacheDB: BreedsCacheDatabaseServiceProtocol

    private let limit = 20
    private var pagesRequested: Set<Int> = []

    init(
        context: ModelContext,
        repository: BreedsRepositoryProtocol = BreedsRepository(),
        detailsRepository: DetailsRepositoryProtocol = DetailsRepository(),
        favoritesRepository: FavoritesRepositoryProtocol? = nil,
        breedsCacheDB: BreedsCacheDatabaseServiceProtocol? = nil,
        autoFetchFirstPage: Bool = true
    ) {
        self.repository = repository
        self.detailsRepository = detailsRepository

        let baseDB = SwiftDataDatabaseService(context: context)
        self.favoritesRepository = favoritesRepository ?? FavoritesRepository(db: baseDB)
        self.breedsCacheDB = breedsCacheDB ?? BreedsCacheDatabaseService(db: baseDB)

        fetchFavorites()
        if autoFetchFirstPage {
            fetchPage(page: 0)
        }
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
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.isLoadingPage = false
                if case .failure = completion {
                    // Fallback: tenta ler a página pedida do SwiftData (não atualiza arrays em memória)
                    do {
                        let _ = try self.breedsCacheDB.fetchCachedPage(page: page, limit: self.limit)
                        // Mesmo em erro de rede, consideramos a "navegação" de página para manter UX consistente
                        self.currentPage = page
                        if page == 0 { self.hasLoadedFirstPage = true }
                    } catch {
                        print("❌ Cache load error page \(page): \(error)")
                    }
                }
            }, receiveValue: { [weak self] newBreeds in
                guard let self else { return }
                let pageSlice = Array(newBreeds.prefix(self.limit))

                // Escreve no SwiftData; as Views com @Query atualizam automaticamente
                self.saveToCache(pageSlice, page: page)

                // Atualiza estado de paginação
                self.currentPage = page
                if page == 0 { self.hasLoadedFirstPage = true }

                // Removido: prefetch de imagens.
                // A imagem é carregada sob demanda na UI (CatImageView).

                self.isLoadingPage = false
            })
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
            // Recarrega a primeira página para repovoar o store
            fetchPage(page: 0)
        } catch {
            print("❌ Error clearing cache: \(error)")
        }
    }

    // MARK: - Favorites

    private func fetchFavorites() {
        do {
            let favs = try favoritesRepository.fetchFavorites()
            favoriteIDs = Set(favs.map { $0.breedId })
        } catch {
            favoriteIDs = []
            print("❌ Error fetching favorites: \(error)")
        }
    }

    func refreshFavorites() {
        fetchFavorites()
    }

    func isFavorite(_ breed: CatBreed) -> Bool {
        favoriteIDs.contains(breed.id)
    }

    func toggleFavorite(for breed: CatBreed) {
        let id = breed.id
        if favoriteIDs.contains(id) {
            do {
                try favoritesRepository.removeFavorite(id: id)
                try favoritesRepository.deleteFavoriteDetail(id: id)
                favoriteIDs.remove(id)
            } catch {
                print("❌ Error removing favorite: \(error)")
            }
        } else {
            do {
                try favoritesRepository.addFavorite(id: id)
                try favoritesRepository.upsertFavoriteDetail(from: breed)
                favoriteIDs.insert(id)
            } catch {
                print("❌ Error adding favorite: \(error)")
            }
        }
    }
}
