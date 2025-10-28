import Foundation
import Combine

struct ImageItem: Identifiable, Equatable {
    let id: String
    let url: String
}

@MainActor
class BreedDetailViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case content(CatBreed)
        case error(String)
    }

    @Published var state: State

    // Expose loading as a published property so tests (and UI) can subscribe to $isLoading
    @Published var isLoading: Bool = false

    // Galeria de imagens adicionais (mantida separada, pois carrega independentemente)
    @Published var galleryImages: [BreedGalleryImage] = []
    @Published var isLoadingGallery = false
    @Published var galleryError: String?

    // UI-driven state moved from the View
    @Published var imageItems: [ImageItem] = []
    @Published var selectedIndex: Int = UIConfig.Pagination.initialPageIndex

    // Fullscreen state
    @Published var isPresentingFullscreen: Bool = false
    @Published var fullscreenURL: String?

    private let repository: DetailsRepositoryProtocol?
    private var cancellables = Set<AnyCancellable>()

    /// Se já tens a raça completa, passas aqui e não faz request
    init(breed: CatBreed? = nil, repository: DetailsRepositoryProtocol? = DetailsRepository()) {
        if let breed {
            self.state = .content(breed)
        } else {
            self.state = .idle
        }
        self.repository = repository
    }

    // Computed accessors for convenience
    var breed: CatBreed? {
        if case let .content(b) = state { return b }
        return nil
    }

    var errorMessage: String? {
        if case let .error(msg) = state { return msg }
        return nil
    }

    // MARK: - Public API for the View

    func prepare(for initialBreed: CatBreed) {
        // If we don't have content yet, set it
        if case .idle = state {
            state = .content(initialBreed)
        }

        // Build images with whatever we have now (main image only)
        rebuildImageItems()

        // Load details if needed (only when we don't have a fully loaded breed)
        loadBreedDetail(id: initialBreed.id)

        // Load gallery; when it arrives, rebuild image list
        loadGalleryImages(breedId: initialBreed.id, limit: APIConstants.defaultGalleryLimit)
    }

    func goPrev() {
        selectedIndex = max(UIConfig.Pagination.initialPageIndex, selectedIndex - 1)
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

    // MARK: - Data loading

    func loadBreedDetail(id: String) {
        // Só faz request se ainda não houver a raça completa
        if case .content = state {
            return
        }

        state = .loading
        isLoading = true

        var receivedNonNilValue = false

        repository?.fetchBreedDetail(by: id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                switch completion {
                case .failure(let error):
                    self.state = .error("Erro: \(error.localizedDescription)")
                case .finished:
                    // If no non-nil value was received, treat as not found
                    if !receivedNonNilValue {
                        self.state = .error("Erro: Raça não encontrada.")
                    }
                }
            }, receiveValue: { [weak self] fetchedBreed in
                guard let self else { return }
                if let fetchedBreed {
                    receivedNonNilValue = true
                    self.state = .content(fetchedBreed)
                    // If the main image changed, rebuild items
                    self.rebuildImageItems()
                } else {
                    // Keep flag false; completion will set the not-found error
                }
            })
            .store(in: &cancellables)
    }

    func loadGalleryImages(breedId: String, limit: Int = APIConstants.defaultGalleryLimit) {
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
                // Whenever gallery updates, keep selectedIndex at initial page (main image)
                self.selectedIndex = UIConfig.Pagination.initialPageIndex
                self.rebuildImageItems()
            })
            .store(in: &cancellables)
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
            selectedIndex = max(UIConfig.Pagination.initialPageIndex, imageItems.count - 1)
        }
    }
}
