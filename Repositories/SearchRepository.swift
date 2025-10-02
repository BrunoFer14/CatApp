import Foundation
import Combine

/// Protocolo para pesquisa de raças
protocol SearchRepositoryProtocol {
    func searchBreeds(query: String) -> AnyPublisher<[CatBreed], Error>
}

/// Implementação que usa o NetworkService
class SearchRepository: SearchRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    func searchBreeds(query: String) -> AnyPublisher<[CatBreed], Error> {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.thecatapi.com/v1/breeds/search?q=\(encoded)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return networkService.fetch([CatBreed].self, from: url)
    }
}


