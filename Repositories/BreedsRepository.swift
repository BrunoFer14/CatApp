import Foundation
import Combine

/// Repositório que chama a API para obter raças paginadas.
protocol BreedsRepositoryProtocol {
    func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], Error>
}

/// Implementação usando um NetworkService genérico (URLSession + Combine).
class BreedsRepository: BreedsRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    // Por agora, injetamos a API key diretamente no código conforme pedido.
    // No futuro, trocar para Info.plist/.xcconfig/Keychain.
    init(networkService: NetworkServiceProtocol = NetworkService(apiKey: "live_jM7hf3la9E8N4JaZgTk88Rd9zqXxhS2Xm9w3yAi5eLNuevXmE1Xq564UyqFOMsoi")) {
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

