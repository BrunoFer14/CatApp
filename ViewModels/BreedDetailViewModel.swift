import Foundation
import Combine

struct ImageItem: Identifiable, Equatable {
    let id: String
    let url: String
}

@MainActor
class BreedDetailViewModel: ObservableObject {
    @Published var breed: CatBreed?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Galeria de imagens adicionais
    @Published var galleryImages: [BreedGalleryImage] = []
    @Published var isLoadingGallery = false
    @Published var galleryError: String?

    // UI-driven state moved from the View
    @Published var imageItems: [ImageItem] = []
    @Published var selectedIndex: Int = 0

    // Fullscreen state
    @Published var isPresentingFullscreen: Bool = false
    @Published var fullscreenURL: String?

    private let repository: DetailsRepositoryProtocol?
    private var cancellables = Set<AnyCancellable>()

    /// Se já tens a raça completa, passas aqui e não faz request
    init(breed: CatBreed? = nil, repository: DetailsRepositoryProtocol? = DetailsRepository()) {
        self.breed = breed
        self.repository = repository
    }

    // MARK: - Public API for the View

    func prepare(for initialBreed: CatBreed) {
        // Set initial breed if not present
        if breed == nil {
            breed = initialBreed
        }
        // Build images with whatever we have now (main image only)
        rebuildImageItems()

        // Load details if needed (only when breed is not fully loaded)
        loadBreedDetail(id: initialBreed.id)

        // Load gallery; when it arrives, rebuild image list
        loadGalleryImages(breedId: initialBreed.id, limit: 10)
    }

    func goPrev() {
        selectedIndex = max(0, selectedIndex - 1)
    }

    func goNext() {
        selectedIndex = min(imageItems.count - 1, selectedIndex + 1)
    }

    func select(index: Int) {
        guard imageItems.indices.contains(index) else { return }
        selectedIndex = index
    }

    func presentFullscreenForSelected() {
        guard imageItems.indices.contains(selectedIndex) else { return }
        fullscreenURL = imageItems[selectedIndex].url
        isPresentingFullscreen = true
    }

    func dismissFullscreen() {
        isPresentingFullscreen = false
        fullscreenURL = nil
    }

    // MARK: - Private helpers

    private func rebuildImageItems() {
        var urls: [String] = []

        // main image (from breed)
        if let main = breed?.image?.url ?? breed?.referenceImageUrl {
            urls.append(main)
        }

        // gallery urls
        let gallery = galleryImages.map { $0.url }

        // deduplicate while preserving order (main first)
        var seen = Set<String>()
        var result: [ImageItem] = []
        for url in urls + gallery {
            if !seen.contains(url) {
                seen.insert(url)
                result.append(ImageItem(id: url, url: url))
            }
        }

        // update items and keep selection safe
        imageItems = result
        if selectedIndex >= imageItems.count {
            selectedIndex = max(0, imageItems.count - 1)
        }
    }

    // MARK: - Data loading

    func loadBreedDetail(id: String) {
        // Só faz request se ainda não houver a raça completa
        guard breed == nil else { return }

        isLoading = true
        errorMessage = nil

        repository?.fetchBreedDetail(by: id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                if case let .failure(error) = completion {
                    self.errorMessage = "Erro: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] fetchedBreed in
                guard let self else { return }
                self.breed = fetchedBreed
                // If the main image changed, rebuild items
                self.rebuildImageItems()
            })
            .store(in: &cancellables)
    }

    func loadGalleryImages(breedId: String, limit: Int = 10) {
        isLoadingGallery = true
        galleryError = nil
        repository?.fetchBreedImages(by: breedId, limit: limit)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.isLoadingGallery = false
                if case let .failure(error) = completion {
                    self.galleryError = "Erro: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] images in
                guard let self else { return }
                self.galleryImages = images
                // Whenever gallery updates, keep selectedIndex at 0 (main image)
                self.selectedIndex = 0
                self.rebuildImageItems()
            })
            .store(in: &cancellables)
    }
}
