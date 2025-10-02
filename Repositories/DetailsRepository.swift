import Foundation
import Combine

/// Protocolo para obter detalhes de uma raça
protocol DetailsRepositoryProtocol {
    func fetchBreedDetail(by id: String) -> AnyPublisher<CatBreed?, Error>
}

/// Implementação que reusa a mesma API `/breeds`
class DetailsRepository: DetailsRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    func fetchBreedDetail(by id: String) -> AnyPublisher<CatBreed?, Error> {
        guard let url = URL(string: "https://api.thecatapi.com/v1/breeds") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        // Faz fetch de todas as raças e filtra pelo id
        return networkService.fetch([CatBreed].self, from: url)
            .map { breeds in
                breeds.first(where: { $0.id == id })
            }
            .eraseToAnyPublisher()
    }
}
