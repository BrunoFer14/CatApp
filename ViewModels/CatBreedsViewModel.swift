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
        breedsCacheDB: BreedsCacheDatabaseServiceProtocol? = nil
    ) {
        self.repository = repository
        self.detailsRepository = detailsRepository

        let baseDB = SwiftDataDatabaseService(context: context)
        self.favoritesRepository = favoritesRepository ?? FavoritesRepository(db: baseDB)
        self.breedsCacheDB = breedsCacheDB ?? BreedsCacheDatabaseService(db: baseDB)

        // Carrega do cache primeiro (mostra algo mesmo offline)
        loadFromCache()
        fetchFavorites()
        fetchPage(page: 0)
    }

    // MARK: - Paginação
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
                self.saveToCache(newBreeds, page: page)

                let urls = newBreeds
                    .compactMap { $0.image?.url ?? $0.referenceImageUrl }
                    .compactMap(URL.init(string:))
                if !urls.isEmpty {
                    Task {
                        await ImageCache.shared.prefetch(urls: urls)
                    }
                }
            })
            .store(in: &cancellables)
    }

    // MARK: - Cache (via serviço)
    private func saveToCache(_ breeds: [CatBreed], page: Int) {
        do {
            try breedsCacheDB.upsertBreeds(breeds, page: page, limit: limit)
        } catch {
            print("❌ Erro ao guardar cache: \(error)")
        }
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
        } catch {
            print("❌ Erro ao carregar cache: \(error)")
        }
    }

    // MARK: - Favoritos
    func fetchFavorites() {
        do {
            let favorites = try favoritesRepository.fetchFavorites()
            favoriteIDs = Set(favorites.map { $0.breedId })

            // IDs de favoritos que ainda não estão em breeds
            let currentIDs = Set(breeds.map { $0.id })
            let missingIDs = favoriteIDs.subtracting(currentIDs)

            // 1) Completa a partir do cache
            var appendedIDs = Set<String>()
            if !missingIDs.isEmpty {
                let cachedMissing = try breedsCacheDB.fetchBreedsByIDs(missingIDs)
                let mappedMissing: [CatBreed] = cachedMissing.map {
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

                let existingIDs = Set(breeds.map { $0.id })
                let toAppend = mappedMissing.filter { !existingIDs.contains($0.id) }
                if !toAppend.isEmpty {
                    breeds.append(contentsOf: toAppend)
                    appendedIDs.formUnion(toAppend.map { $0.id })
                }
            }

            // 2) Para o que ainda faltar, fallback à rede por ID
            let stillMissing = missingIDs.subtracting(appendedIDs)
            guard !stillMissing.isEmpty else { return }

            let publishers = stillMissing.map { id in
                detailsRepository.fetchBreedDetail(by: id)
                    .replaceError(with: nil)
            }

            Publishers.MergeMany(publishers)
                .compactMap { $0 }
                .collect()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] fetched in
                    guard let self else { return }
                    let existingIDs = Set(self.breeds.map { $0.id })
                    let toAppend = fetched.filter { !existingIDs.contains($0.id) }
                    if !toAppend.isEmpty {
                        self.breeds.append(contentsOf: toAppend)
                        // Guarda estes no cache para futuras execuções
                        self.saveToCache(toAppend, page: self.currentPage)
                    }
                }
                .store(in: &cancellables)

        } catch {
            print("❌ Erro ao buscar favoritos: \(error)")
        }
    }

    func toggleFavorite(for breed: CatBreed) {
        if isFavorite(breed) {
            do {
                try favoritesRepository.removeFavorite(id: breed.id)
                fetchFavorites()
            } catch {
                print("❌ Erro ao remover favorito: \(error)")
            }
        } else {
            do {
                try favoritesRepository.addFavorite(id: breed.id)
                fetchFavorites()
            } catch {
                print("❌ Erro ao adicionar favorito: \(error)")
            }
        }
    }

    func isFavorite(_ breed: CatBreed) -> Bool {
        favoritesRepository.isFavorite(id: breed.id)
    }

    // MARK: - Média de vida dos favoritos
    func averageLifeSpanForFavorites() -> Double? {
        let favoriteBreeds = breeds.filter { favoriteIDs.contains($0.id) }

        let spans: [Double] = favoriteBreeds.compactMap { breed in
            guard let spanString = breed.life_span else { return nil }
            let numbers = spanString
                .components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Double($0) }
            guard !numbers.isEmpty else { return nil }
            return numbers.reduce(0, +) / Double(numbers.count)
        }

        guard !spans.isEmpty else { return nil }
        return spans.reduce(0, +) / Double(spans.count)
    }
}
