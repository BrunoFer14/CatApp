import Foundation
import Combine

/// Protocolo de repositório para buscar raças
protocol BreedsRepositoryProtocol {
    func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], Error>
}

/// Implementação usando o NetworkService
class BreedsRepository: BreedsRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], Error> {
        guard let url = URL(string: "https://api.thecatapi.com/v1/breeds?limit=\(limit)&page=\(page)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return networkService.fetch([CatBreed].self, from: url)
    }
}
