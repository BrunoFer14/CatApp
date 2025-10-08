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

        loadFromCache()
        fetchFavorites()
        if autoFetchFirstPage {
            fetchPage(page: 0)
        }
    }

    private func sortBreedsAlphabetically() {
        breeds.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func fetchPage(page: Int) {
        guard !isLoadingPage else { return }
        isLoadingPage = true

        repository.fetchBreeds(page: page, limit: limit)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.loadFromCache()
                }
                self?.isLoadingPage = false
            }, receiveValue: { [weak self] newBreeds in
                guard let self else { return }
                if page == 0 {
                    self.breeds = newBreeds
                } else {
                    let existingIDs = Set(self.breeds.map { $0.id })
                    let filteredNew = newBreeds.filter { !existingIDs.contains($0.id) }
                    self.breeds.append(contentsOf: filteredNew)
                }
                self.currentPage = page
                self.sortBreedsAlphabetically()
                self.saveToCache(newBreeds, page: page)

                let urls = newBreeds
                    .compactMap { $0.image?.url ?? $0.referenceImageUrl }
                    .compactMap(URL.init(string:))
                if !urls.isEmpty {
                    Task { await ImageCache.shared.prefetch(urls: urls) }
                }
            })
            .store(in: &cancellables)
    }

    private func saveToCache(_ breeds: [CatBreed], page: Int) {
        do { try breedsCacheDB.upsertBreeds(breeds, page: page, limit: limit) }
        catch { print("❌ Erro ao guardar cache: \(error)") }
    }

    private func loadFromCache() {
        do {
            let cachedBreeds = try breedsCacheDB.fetchCachedBreedsSorted()
            self.breeds = cachedBreeds.map {
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
            sortBreedsAlphabetically()
        } catch {
            print("❌ Erro ao carregar cache: \(error)")
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
            // In tests, prefer silent failure but keep state consistent
            favoriteIDs = []
            print("❌ Erro ao buscar favoritos: \(error)")
        }
    }

    // Public/internal wrapper to allow external refresh without exposing internals
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
                // Remover dos favoritos não exige mexer em breeds
            } catch {
                print("❌ Erro ao remover favorito: \(error)")
            }
        } else {
            do {
                try favoritesRepository.addFavorite(id: id)
                favoriteIDs.insert(id)
                // Se o item favorito ainda não está em breeds, tenta completar via cache
                mergeMissingFavoriteBreedsFromCache()
            } catch {
                print("❌ Erro ao adicionar favorito: \(error)")
            }
        }
    }

    // MARK: - Life span average for favorites

    /// Computes the average life span (in years) across the current favorite breeds.
    /// - Returns: The mean of each favorite's life span value, where a range like "10 - 12"
    ///            is interpreted as its midpoint (11). Returns nil if no parsable values.
    func averageLifeSpanForFavorites() -> Double? {
        let favoriteBreeds = breeds.filter { favoriteIDs.contains($0.id) }

        let values: [Double] = favoriteBreeds.compactMap { breed in
            guard let life = breed.life_span else { return nil }
            // Split by hyphen and trim spaces, then parse to Double
            let parts = life
                .components(separatedBy: "-")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .compactMap(Double.init)

            switch parts.count {
            case 2:
                return (parts[0] + parts[1]) / 2.0
            case 1:
                return parts[0]
            default:
                return nil
            }
        }

        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0, +)
        return sum / Double(values.count)
    }

    // MARK: - Helpers

    /// Garante que todas as raças favoritas existam em `breeds`, preenchendo a partir do cache local
    /// quaisquer IDs favoritos que ainda não tenham sido carregados via paginação.
    private func mergeMissingFavoriteBreedsFromCache() {
        let existingIDs = Set(breeds.map { $0.id })
        let missingIDs = favoriteIDs.subtracting(existingIDs)
        guard !missingIDs.isEmpty else { return }

        do {
            let cached = try breedsCacheDB.fetchBreedsByIDs(missingIDs)
            guard !cached.isEmpty else { return }

            // Mapear CachedBreed -> CatBreed
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

            // Mesclar sem duplicar
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
