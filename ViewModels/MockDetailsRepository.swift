import Foundation
import Combine
@testable import CatApp

final class MockDetailsRepository: DetailsRepositoryProtocol {
    var breedsById: [String: CatBreed] = [:]
    var error: Error?

    func fetchBreedDetail(by id: String) -> AnyPublisher<CatBreed?, Error> {
        if let error {
            return Fail(error: error).eraseToAnyPublisher()
        }
        let breed = breedsById[id]
        return Just(breed)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
