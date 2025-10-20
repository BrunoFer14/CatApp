import Foundation
import Combine

/// ViewModel para a pesquisa remota de raças.
/// Mantém estado de query, resultados, loading e erro.
@MainActor
class BreedSearchViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case content([CatBreed])
        case error(String)
    }

    // Estado principal (enum), e propriedades derivadas para compatibilidade com a UI atual
    @Published var state: State = .idle {
        didSet { apply(state) }
    }

    // Resultados que a UI vai mostrar (derivado de state)
    @Published var results: [CatBreed] = []
    // Texto que o utilizador escreve no campo de pesquisa
    @Published var query: String = ""
    // Indicador de carregamento (para mostrar um spinner na UI) — derivado de state
    @Published var isLoading: Bool = false
    // Mensagem de erro (se algo correr mal) — derivada de state
    @Published var errorMessage: String?

    // Guarda subscrições do Combine para não se perderem
    private var cancellables = Set<AnyCancellable>()
    // Repositório que sabe falar com a API de pesquisa
    private let repository: SearchRepositoryProtocol

    // Permite injetar um repositório (útil para testes); por defeito usa SearchRepository real
    init(repository: SearchRepositoryProtocol = SearchRepository()) {
        self.repository = repository
        // Ensure derived properties match initial state
        apply(state)
    }

    // Faz a pesquisa na API
    func search() {
        // Se a query estiver vazia, limpa e volta a idle
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }

        state = .loading

        repository.searchBreeds(query: trimmed)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case let .failure(error) = completion {
                        self.state = .error("Error: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] breeds in
                    guard let self else { return }
                    self.state = .content(breeds)
                }
            )
            .store(in: &cancellables)
    }

    // Mantém results/isLoading/errorMessage sincronizados com o enum state
    private func apply(_ state: State) {
        switch state {
        case .idle:
            results = []
            isLoading = false
            errorMessage = nil
        case .loading:
            isLoading = true
            errorMessage = nil
            // keep current results (optional: clear if desired)
        case .content(let breeds):
            results = breeds
            isLoading = false
            errorMessage = nil
        case .error(let message):
            isLoading = false
            errorMessage = message
            // keep current results (optional: clear if desired)
        }
    }
}
