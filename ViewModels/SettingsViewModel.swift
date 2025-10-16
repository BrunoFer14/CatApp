import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    // Dependência que conhece a cache e o estado global da lista
    private let catViewModel: CatBreedsViewModel

    // Estado de UI específico do ecrã de Settings
    @Published var showConfirmClear = false
    @Published var clearedToast = false

    init(catViewModel: CatBreedsViewModel) {
        self.catViewModel = catViewModel
    }

    func clearCache() {
        catViewModel.clearCache()
        clearedToast = true
    }
}
