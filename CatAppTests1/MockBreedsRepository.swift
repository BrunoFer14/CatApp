import Foundation
import Combine
@testable import CatApp

class MockBreedsRepository: BreedsRepositoryProtocol {
    // Permite configurar resultados por página
    var mockBreedsByPage: [Int: [CatBreed]] = [:]

    // Atalho legado para compatibilidade com testes existentes
    var mockBreeds: [CatBreed] {
        get { mockBreedsByPage[0] ?? [] }
        set { mockBreedsByPage[0] = newValue }
    }

    func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], Error> {
        if let error {
            return Fail(error: error).eraseToAnyPublisher()
        }
        let result = mockBreedsByPage[page] ?? []
        return Just(result)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
