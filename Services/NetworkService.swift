import Foundation
import Combine

/// Protocolo para um serviço de rede genérico.
protocol NetworkServiceProtocol {
    func fetch<T: Decodable>(_ type: T.Type, from url: URL) -> AnyPublisher<T, Error>
}

/// Implementação baseada em URLSession + Combine.
class NetworkService: NetworkServiceProtocol {
    func fetch<T: Decodable>(_ type: T.Type, from url: URL) -> AnyPublisher<T, Error> {
        // dataTaskPublisher → transforma em Data → decodifica para o tipo pedido
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
