import Foundation
import Combine
import SwiftData

@MainActor
class CatBreedsViewModel: ObservableObject {
    @Published var breeds: [CatBreed] = []
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
        } else {
            // Sem hidratação de favoritos na lista geral
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
                    // Fallback: load requested page from cache (para manter compatibilidade com UI/Tests)
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
                            self.hasLoadedFirstPage = true
                        } else {
                            let existingIDs = Set(self.breeds.map { $0.id })
                            let toAppend = mapped.filter { !existingIDs.contains($0.id) }
                            self.breeds.append(contentsOf: toAppend)
                        }
                        self.currentPage = page
                        self.sortBreedsAlphabetically()
                    } catch {
                        print("❌ Cache load error page \(page): \(error)")
                    }
                }
            }, receiveValue: { [weak self] newBreeds in
                guard let self else { return }
                let pageSlice = Array(newBreeds.prefix(self.limit))

                if page == 0 {
                    self.breeds = pageSlice
                    self.hasLoadedFirstPage = true
                } else {
                    let existingIDs = Set(self.breeds.map { $0.id })
                    let filteredNew = pageSlice.filter { !existingIDs.contains($0.id) }
                    self.breeds.append(contentsOf: filteredNew)
                }
                self.currentPage = page
                self.sortBreedsAlphabetically()
                self.saveToCache(pageSlice, page: page)

                // Prefetch images
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
        catch { print("❌ Cache save error: \(error)") }
    }

    // MARK: - Cache management (Settings)

    func clearCache() {
        do {
            try breedsCacheDB.clearCache()
            breeds = []
            currentPage = 0
            isLoadingPage = false
            pagesRequested.removeAll()
            hasLoadedFirstPage = false

            refreshFavorites()
            // Sem hidratação de favoritos na lista geral
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
                // Não alterar a lista geral
            } catch {
                print("❌ Error removing favorite: \(error)")
            }
        } else {
            do {
                try favoritesRepository.addFavorite(id: id)
                try favoritesRepository.upsertFavoriteDetail(from: breed)
                favoriteIDs.insert(id)
                // Não injetar na lista geral
            } catch {
                print("❌ Error adding favorite: \(error)")
            }
        }
        sortBreedsAlphabetically()
    }

    // MARK: - Life span average for favorites (mantido para compat; pode ser removido se não usado)
    // Nota: A FavoritesViewModel passará a calcular a média diretamente a partir de FavoriteBreedDetail.
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
}

