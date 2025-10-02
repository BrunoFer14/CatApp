import Foundation
import Combine


@MainActor
class BreedDetailViewModel: ObservableObject {
    @Published var breed: CatBreed?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: DetailsRepositoryProtocol?
    private var cancellables = Set<AnyCancellable>()

    /// Se já tens a raça completa, passas aqui e não faz request
    init(breed: CatBreed? = nil, repository: DetailsRepositoryProtocol? = DetailsRepository()) {
        self.breed = breed
        self.repository = repository
    }

    func loadBreedDetail(id: String) {
        // Só faz request se ainda não houver a raça completa
        guard breed == nil else { return }

        isLoading = true
        errorMessage = nil

        repository?.fetchBreedDetail(by: id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = "Erro: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] breed in
                self?.breed = breed
            })
            .store(in: &cancellables)
    }
}
