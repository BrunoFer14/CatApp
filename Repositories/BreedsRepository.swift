import Foundation
import Combine

/// Repositório que chama a API para obter raças paginadas.
protocol BreedsRepositoryProtocol {
    func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], Error>
}

/// Implementação usando um NetworkService genérico (URLSession + Combine).
class BreedsRepository: BreedsRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], Error> {
        // Endpoint com paginação
        guard let url = URL(string: "https://api.thecatapi.com/v1/breeds?limit=\(limit)&page=\(page)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        // Pede ao serviço de rede para fazer o request e decodificar automaticamente
        return networkService.fetch([CatBreed].self, from: url)
    }
}
