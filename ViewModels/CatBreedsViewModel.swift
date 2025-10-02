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
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let context: ModelContext

    private let limit = 20

    init(
        context: ModelContext,
        repository: BreedsRepositoryProtocol = BreedsRepository(),
        favoritesRepository: FavoritesRepositoryProtocol? = nil
    ) {
        self.repository = repository
        self.favoritesRepository = favoritesRepository ?? FavoritesRepository(context: context)
        self.context = context

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
                    self.breeds.append(contentsOf: newBreeds)
                }

                self.currentPage = page
                self.saveToCache(newBreeds)
            })
            .store(in: &cancellables)
    }

    // MARK: - Cache
    private func saveToCache(_ breeds: [CatBreed]) {
        do {
            for breed in breeds {
                // Upsert: atualiza se existir, senão insere
                let predicate = #Predicate<CachedBreed> { $0.id == breed.id }
                var descriptor = FetchDescriptor<CachedBreed>(predicate: predicate)
                descriptor.fetchLimit = 1

                if let existing = try context.fetch(descriptor).first {
                    existing.name = breed.name
                    existing.origin = breed.origin
                    existing.temperament = breed.temperament
                    existing.life_span = breed.life_span
                    existing.breedDescription = breed.description
                    existing.imageUrl = breed.image?.url ?? breed.referenceImageUrl
                } else {
                    let cached = CachedBreed(
                        id: breed.id,
                        name: breed.name,
                        origin: breed.origin,
                        temperament: breed.temperament,
                        life_span: breed.life_span,
                        breedDescription: breed.description,
                        imageUrl: breed.image?.url ?? breed.referenceImageUrl
                    )
                    context.insert(cached)
                }
            }

            try context.save()
        } catch {
            print("❌ Erro ao guardar cache: \(error)")
        }
    }

    private func loadFromCache() {
        do {
            let cachedBreeds = try context.fetch(FetchDescriptor<CachedBreed>())
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
