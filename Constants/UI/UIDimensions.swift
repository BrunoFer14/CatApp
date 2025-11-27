import CoreGraphics

enum UIDimensions {
    // Heights and sizes
    static let breedCardHeight: CGFloat = 180
    static let breedCardWidth: CGFloat = 175   // Increased width for better proportions
    static let tileImageHeight: CGFloat = 120
    static let tileTextAreaHeight: CGFloat = 44  // Fixed height for text section

    // Detail screen image heights
    static let detailImageHeightPrimary: CGFloat = 260
    static let detailImageHeightFallback: CGFloat = 200

    // Favorites
    static let favoriteThumbnailSize: CGFloat = 40

    // Home grid
    static let homeGridColumnCount: Int = 2

    // Search
    static let searchThumbnailSize: CGFloat = 60
    static let searchGalleryLimit: Int = 10

    // Placeholder
    static let placeholderItemsCount: Int = 6
}
