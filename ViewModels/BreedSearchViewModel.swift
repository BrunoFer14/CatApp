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
        // Se a query estiver vazia, limpa resultados e não faz pedido
        guard !query.isEmpty else {
            results = []
            return
        }

        isLoading = true
        errorMessage = nil

        // Pede ao repositório para pesquisar; recebe no main thread para atualizar UI
        repository.searchBreeds(query: query)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                // Quando acaba (com sucesso ou erro), desliga o loading
                self?.isLoading = false
                // Se deu erro, guarda a mensagem para a UI mostrar
                if case let .failure(error) = completion {
                    self?.errorMessage = "Erro: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] breeds in
                // Se correu bem, atualiza os resultados
                self?.results = breeds
            })
            .store(in: &cancellables)
    }
}
