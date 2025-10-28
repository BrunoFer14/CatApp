import Foundation
import Combine

/// Repository that calls the API to obtain paginated breeds.
protocol BreedsRepositoryProtocol {
    func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], Error>
}

/// Implementation using a generic NetworkService (URLSession + Combine).
class BreedsRepository: BreedsRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    // Now reads the API key from Info.plist via the helper 'secrets.catApiKey'.
    init(networkService: NetworkServiceProtocol = NetworkService(apiKey: secrets.catApiKey)) {
        self.networkService = networkService
    }

    func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], Error> {
        // Build via Endpoint -> URLRequest
        guard let request = Endpoint.breeds(page: page, limit: limit).request() else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return networkService.fetch([CatBreed].self, from: request)
    }
}

