import Foundation
import Combine
import SwiftData

@MainActor
class CatBreedsViewModel: ObservableObject {
    @Published var breeds: [CatBreed] = []
    @Published var favoriteIDs: Set<String> = []
    @Published var isLoadingPage = false
    @Published var currentPage = 0

    private var cancellables = Set<AnyCancellable>()
    private let repository: BreedsRepositoryProtocol
    private let detailsRepository: DetailsRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let breedsCacheDB: BreedsCacheDatabaseServiceProtocol

    private let limit = 20

    // Evita pedidos repetidos/precoces
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

        // Não carregar a cache global no arranque; apenas usar cache por página em fallback
        fetchFavorites()
        if autoFetchFirstPage {
            fetchPage(page: 0)
        }
    }

    private func sortBreedsAlphabetically() {
        breeds.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
                    // Fallback: carregar apenas a página pedida a partir da cache
                    do {
                        let cached = try self.breedsCacheDB.fetchCachedPage(page: page, limit: self.limit)
                        let mapped: [CatBreed] = cached.map {
                            CatBreed(
                                id: $0.id,
                                name: $0.name,
                                origin: $0.origin,
                                description: $0.breedDescription,
                                temperament: $0.temperament,
                                life_span: $0.life_span,
                                image: BreedImage(url: $0.imageUrl),
                                referenceImageId: nil
                            )
                        }
                        if page == 0 {
                            self.breeds = mapped
                        } else {
                            let existingIDs = Set(self.breeds.map { $0.id })
                            let toAppend = mapped.filter { !existingIDs.contains($0.id) }
                            self.breeds.append(contentsOf: toAppend)
                        }
                        self.currentPage = page
                        self.sortBreedsAlphabetically()
                    } catch {
                        print("❌ Erro ao carregar página \(page) da cache: \(error)")
                    }
                }
            }, receiveValue: { [weak self] newBreeds in
                guard let self else { return }

                // Clampa ao limit para não poluir a cache se a API devolver mais
                let pageSlice = Array(newBreeds.prefix(self.limit))

                if page == 0 {
                    self.breeds = pageSlice
                } else {
                    let existingIDs = Set(self.breeds.map { $0.id })
                    let filteredNew = pageSlice.filter { !existingIDs.contains($0.id) }
                    self.breeds.append(contentsOf: filteredNew)
                }
                self.currentPage = page
                self.sortBreedsAlphabetically()
                self.saveToCache(pageSlice, page: page)

                // Prefetch de imagens principais
                let urls = pageSlice
                    .compactMap { $0.image?.url ?? $0.referenceImageUrl }
                    .compactMap(URL.init(string:))
                if !urls.isEmpty {
                    Task { await ImageCache.shared.prefetch(urls: urls) }
                }

                self.isLoadingPage = false
            })
            .store(in: &cancellables)
    }

    private func saveToCache(_ breeds: [CatBreed], page: Int) {
        do { try breedsCacheDB.upsertBreeds(breeds, page: page, limit: limit) }
        catch { print("❌ Erro ao guardar cache: \(error)") }
    }

    // MARK: - Cache management (Settings)

    func clearCache() {
        do {
            try breedsCacheDB.clearCache()
            // Limpa estado em memória da lista e da paginação
            breeds = []
            currentPage = 0
            isLoadingPage = false
            pagesRequested.removeAll()

            // Recarrega favoritos (persistem em Favorite) e volta a buscar a primeira página
            refreshFavorites()
            fetchPage(page: 0)
        } catch {
            print("❌ Erro ao limpar cache: \(error)")
        }
    }

    // MARK: - Favorites

    private func fetchFavorites() {
        do {
            let favs = try favoritesRepository.fetchFavorites()
            favoriteIDs = Set(favs.map { $0.breedId })
            // Completa breeds com favoritos que ainda não estão carregados
            mergeMissingFavoriteBreedsFromCache()
        } catch {
            favoriteIDs = []
            print("❌ Erro ao buscar favoritos: \(error)")
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
                favoriteIDs.remove(id)
            } catch {
                print("❌ Erro ao remover favorito: \(error)")
            }
        } else {
            do {
                try favoritesRepository.addFavorite(id: id)
                favoriteIDs.insert(id)
                mergeMissingFavoriteBreedsFromCache()
            } catch {
                print("❌ Erro ao adicionar favorito: \(error)")
            }
        }
    }

    // MARK: - Life span average for favorites

    func averageLifeSpanForFavorites() -> Double? {
        let favoriteBreeds = breeds.filter { favoriteIDs.contains($0.id) }

        let values: [Double] = favoriteBreeds.compactMap { breed in
            guard let life = breed.life_span else { return nil }
            let parts = life
                .components(separatedBy: "-")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .compactMap(Double.init)

            switch parts.count {
            case 2: return (parts[0] + parts[1]) / 2.0
            case 1: return parts[0]
            default: return nil
            }
        }

        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0, +)
        return sum / Double(values.count)
    }

    // MARK: - Helpers

    private func mergeMissingFavoriteBreedsFromCache() {
        let existingIDs = Set(breeds.map { $0.id })
        let missingIDs = favoriteIDs.subtracting(existingIDs)
        guard !missingIDs.isEmpty else { return }

        do {
            let cached = try breedsCacheDB.fetchBreedsByIDs(missingIDs)
            guard !cached.isEmpty else { return }

            let mapped: [CatBreed] = cached.map {
                CatBreed(
                    id: $0.id,
                    name: $0.name,
                    origin: $0.origin,
                    description: $0.breedDescription,
                    temperament: $0.temperament,
                    life_span: $0.life_span,
                    image: BreedImage(url: $0.imageUrl),
                    referenceImageId: nil
                )
            }

            let existingSet = Set(breeds.map { $0.id })
            let toAppend = mapped.filter { !existingSet.contains($0.id) }
            guard !toAppend.isEmpty else { return }

            breeds.append(contentsOf: toAppend)
            sortBreedsAlphabetically()
        } catch {
            print("❌ Erro ao completar favoritos do cache: \(error)")
        }
    }
}
