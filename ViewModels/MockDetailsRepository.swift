import Foundation
import Combine

final class MockDetailsRepository: DetailsRepositoryProtocol {
    var breedsById: [String: CatBreed] = [:]
    var imagesByBreedId: [String: [BreedGalleryImage]] = [:]
    var error: Error?

    // Testing helpers
    private(set) var fetchBreedDetailCallCount: Int = 0
    private(set) var fetchBreedImagesCallCount: Int = 0

    func resetCounters() {
        fetchBreedDetailCallCount = 0
        fetchBreedImagesCallCount = 0
    }

    func fetchBreedDetail(by id: String) -> AnyPublisher<CatBreed?, Error> {
        fetchBreedDetailCallCount += 1

        if let error {
            return Fail(error: error).eraseToAnyPublisher()
        }
        let breed = breedsById[id]
        return Just(breed)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func fetchBreedImages(by id: String, limit: Int) -> AnyPublisher<[BreedGalleryImage], Error> {
        fetchBreedImagesCallCount += 1

        if let error {
            return Fail(error: error).eraseToAnyPublisher()
        }
        let images = imagesByBreedId[id] ?? []
        let limited = images.prefix(limit)
        return Just(Array(limited))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
