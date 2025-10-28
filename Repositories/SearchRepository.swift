import Foundation
import Combine

/// Repositório para pesquisa remota por nome de raça.
protocol SearchRepositoryProtocol {
    func searchBreeds(query: String) -> AnyPublisher<[CatBreed], Error>
}

/// Implementação que usa o NetworkService para chamar a API de search.
class SearchRepository: SearchRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService(apiKey: secrets.catApiKey)) {
        self.networkService = networkService
    }

    func searchBreeds(query: String) -> AnyPublisher<[CatBreed], Error> {
        guard let request = Endpoint.breedSearch(query: query).request() else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return networkService.fetch([CatBreed].self, from: request)
    }
}

