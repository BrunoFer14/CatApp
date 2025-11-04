import Foundation

enum UIStrings {

    enum Common {
        static let loadingBreeds = "Loading breeds…"
        static let errorTitle = "Error"
        static let years = "years"
        static let favorites = "Favorites"
        static let searchBreeds = "Search Breeds"
        static let searchPrompt = "Search breeds..."
        static let catBreedsTitle = "Cat Breeds"
        static let noFavoritesYet = "No favorites yet 🐾"
        static let averageLifeSpanOfFavoritesPrefix = "Average life span of favorites:"
        
        // Error messages
        static let pageLoadFailure = "Falha ao carregar página"
        static let favoriteUpdateFailure = "Falha ao atualizar favorito."
    }

    enum Detail {
        static let originPrefix = "🌍 Origin:"
        static let temperamentPrefix = "😺 Temperament:"
        static let lifeSpanPrefix = "⏳ Life span:"
        static let addToFavorites = "Add to Favorites"
        static let removeFromFavorites = "Remove from Favorites"
        static let notFoundError = "Erro: Raça não encontrada."
    }

    enum Favorites {
        static let title = "Favorites"
    }

    enum Home {
        static let title = "Cat Breeds"
    }

    enum Search {
        static let title = "Search Breeds"
        // prompt compartilhado está em Common.searchPrompt
    }

    enum Icons {
        static let heart = "heart"
        static let heartFill = "heart.fill"
        static let chevronLeft = "chevron.left"
        static let chevronRight = "chevron.right"
        static let closeCircleFill = "xmark.circle.fill"
        
        // Tab bar icons
        static let house = "house"
        static let magnifyingglass = "magnifyingglass"
        
        // SearchBar icons
        static let xmarkCircleFill = "xmark.circle.fill"
        
        // Placeholder icons
        static let photo = "photo"
    }
}
