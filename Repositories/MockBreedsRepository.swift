import Foundation
import Combine
@testable import CatApp

class MockBreedsRepository: BreedsRepositoryProtocol {
    var mockBreeds: [CatBreed] = []

    func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], Error> {
        return Just(mockBreeds)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
