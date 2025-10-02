import Foundation
import Combine

/// ViewModel para a pesquisa remota de raças.
/// Mantém estado de query, resultados, loading e erro.
@MainActor
class BreedSearchViewModel: ObservableObject {
    @Published var results: [CatBreed] = []
    @Published var query: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let repository: SearchRepositoryProtocol

    init(repository: SearchRepositoryProtocol = SearchRepository()) {
        self.repository = repository
    }

    func search() {
        guard !query.isEmpty else {
            results = []
            return
        }

        isLoading = true
        errorMessage = nil

        repository.searchBreeds(query: query)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = "Erro: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] breeds in
                self?.results = breeds
            })
            .store(in: &cancellables)
    }
}
