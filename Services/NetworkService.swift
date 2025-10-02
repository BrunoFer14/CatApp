import Foundation
import Combine

//protocolo que define como o serviço de rede deve comportar-se
protocol NetworkServiceProtocol {
    func fetch<T: Decodable>(_ type: T.Type, from url: URL) -> AnyPublisher<T, Error>
}

class NetworkService: NetworkServiceProtocol {
    func fetch<T: Decodable>(_ type: T.Type, from url: URL) -> AnyPublisher<T, Error> {
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
