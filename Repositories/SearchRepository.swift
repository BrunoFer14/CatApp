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
        // Codifica a query e constrói o URL
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.thecatapi.com/v1/breeds/search?q=\(encoded)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        // Faz o pedido e decodifica para [CatBreed]
        return networkService.fetch([CatBreed].self, from: url)
    }
}

