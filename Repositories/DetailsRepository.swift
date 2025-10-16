import Foundation
import Combine

/// Repository to fetch details of a breed by ID.
protocol DetailsRepositoryProtocol {
    func fetchBreedDetail(by id: String) -> AnyPublisher<CatBreed?, Error>
    func fetchBreedImages(by id: String, limit: Int) -> AnyPublisher<[BreedGalleryImage], Error>
}

/// Simple implementation: fetches all breeds and filters locally by ID.
class DetailsRepository: DetailsRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService(apiKey: secrets.catApiKey)) {
        self.networkService = networkService
    }

    func fetchBreedDetail(by id: String) -> AnyPublisher<CatBreed?, Error> {
        // The API does not provide an endpoint by ID here, so we fetch all and filter
        guard let request = Endpoint.breeds(page: nil, limit: nil).request() else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return networkService.fetch([CatBreed].self, from: request)
            .map { breeds in
                breeds.first(where: { $0.id == id })
            }
            .eraseToAnyPublisher()
    }

    func fetchBreedImages(by id: String, limit: Int) -> AnyPublisher<[BreedGalleryImage], Error> {
        // Official endpoint: /v1/images/search?breed_ids={id}&limit={limit}
        guard let request = Endpoint.breedImages(breedId: id, limit: limit).request() else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return networkService.fetch([BreedGalleryImage].self, from: request)
    }
}

