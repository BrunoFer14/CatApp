import Foundation
import Combine

/// ViewModel para a pesquisa remota de raças.
/// Mantém estado de query, resultados, loading e erro.
@MainActor
class BreedSearchViewModel: ObservableObject {
    // Resultados que a UI vai mostrar
    @Published var results: [CatBreed] = []
    // Texto que o utilizador escreve no campo de pesquisa
    @Published var query: String = ""
    // Indicador de carregamento (para mostrar um spinner na UI)
    @Published var isLoading: Bool = false
    // Mensagem de erro (se algo correr mal)
    @Published var errorMessage: String?

    // Guarda subscrições do Combine para não se perderem
    private var cancellables = Set<AnyCancellable>()
    // Repositório que sabe falar com a API de pesquisa
    private let repository: SearchRepositoryProtocol

    // Permite injetar um repositório (útil para testes); por defeito usa SearchRepository real
    init(repository: SearchRepositoryProtocol = SearchRepository()) {
        self.repository = repository
    }

    // Faz a pesquisa na API
    func search() {
        // If the query is empty, clear results and do not make a request
        guard !query.isEmpty else {
            results = []
            return
        }

        isLoading = true
        errorMessage = nil

        // Ask the repository to search; receive on main thread to update UI
        repository.searchBreeds(query: query)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                // When completed (success or failure), turn off loading
                self?.isLoading = false
                // If it failed, save the message for the UI to show
                if case let .failure(error) = completion {
                    self?.errorMessage = "Error: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] breeds in
                // On success, update results
                self?.results = breeds
            })
            .store(in: &cancellables)
    }
}
