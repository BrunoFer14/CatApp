import Foundation
import Combine
@testable import CatApp

/// Mock de NetworkServiceProtocol para testes de repositórios.
/// Você pode configurar o próximo resultado por tipo esperado ou por URL.
final class MockNetworkService: NetworkServiceProtocol {
    struct Key: Hashable {
        let url: URL
        let typeName: String
    }

    // Map de (URL, Tipo) -> Data ou Erro
    var results: [Key: Result<Data, Error>] = [:]

    // Atalho: define resposta para um tipo codificável e URL.
    func setJSONResponse<T: Encodable>(_ object: T, for url: URL, encoder: JSONEncoder = JSONEncoder()) throws {
        let data = try encoder.encode(AnyEncodable(object))
        let key = Key(url: url, typeName: String(describing: T.self))
        results[key] = .success(data)
    }

    func setError<T: Decodable>(_ error: Error, for type: T.Type, url: URL) {
        let key = Key(url: url, typeName: String(describing: T.self))
        results[key] = .failure(error)
    }

    func fetch<T>(_ type: T.Type, from url: URL) -> AnyPublisher<T, Error> where T : Decodable {
        let key = Key(url: url, typeName: String(describing: T.self))
        guard let result = results[key] else {
            return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
        }
        switch result {
        case .success(let data):
            return Just(data)
                .decode(type: T.self, decoder: JSONDecoder())
                .mapError { $0 }
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}

/// Wrapper para permitir codificar qualquer Encodable como Data com JSONEncoder.
private struct AnyEncodable: Encodable {
    let value: any Encodable
    init(_ value: any Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}
