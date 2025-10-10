import Foundation
import Combine

/// Repositório para obter detalhes de uma raça por ID.
protocol DetailsRepositoryProtocol {
    func fetchBreedDetail(by id: String) -> AnyPublisher<CatBreed?, Error>
    func fetchBreedImages(by id: String, limit: Int) -> AnyPublisher<[BreedGalleryImage], Error>
}

/// Implementação simples: busca todas as raças e filtra localmente pelo ID.
class DetailsRepository: DetailsRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService(apiKey: secrets.catApiKey)) {
        self.networkService = networkService
    }

    func fetchBreedDetail(by id: String) -> AnyPublisher<CatBreed?, Error> {
        // API não tem endpoint por ID aqui, por isso busca todas e filtra
        guard let url = URL(string: "https://api.thecatapi.com/v1/breeds") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return networkService.fetch([CatBreed].self, from: url)
            .map { breeds in
                breeds.first(where: { $0.id == id })
            }
            .eraseToAnyPublisher()
    }

    func fetchBreedImages(by id: String, limit: Int) -> AnyPublisher<[BreedGalleryImage], Error> {
        // Endpoint oficial: /v1/images/search?breed_ids={id}&limit={limit}
        guard let url = URL(string: "https://api.thecatapi.com/v1/images/search?breed_ids=\(id)&limit=\(limit)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return networkService.fetch([BreedGalleryImage].self, from: url)
    }
}
