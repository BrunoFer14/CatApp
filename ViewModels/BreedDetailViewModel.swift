import Foundation
import Combine


@MainActor
class BreedDetailViewModel: ObservableObject {
    @Published var breed: CatBreed?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Galeria de imagens adicionais
    @Published var galleryImages: [BreedGalleryImage] = []
    @Published var isLoadingGallery = false
    @Published var galleryError: String?

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

    func loadGalleryImages(breedId: String, limit: Int = 10) {
        isLoadingGallery = true
        galleryError = nil
        repository?.fetchBreedImages(by: breedId, limit: limit)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoadingGallery = false
                if case let .failure(error) = completion {
                    self?.galleryError = "Erro: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] images in
                self?.galleryImages = images
            })
            .store(in: &cancellables)
    }
}
