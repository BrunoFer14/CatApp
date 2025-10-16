import SwiftUI

struct BreedSquareTile: View {
    let breed: CatBreed
    let isFavorite: Bool
    let favoriteAction: () -> Void
    let cardBackground: Color
    let shadowColor: Color

    // Tile layout constants
    private let cornerRadius: CGFloat = UILayout.cardCornerRadius
    private let imageCornerRadius: CGFloat = UILayout.imageCornerRadius
    private let imageHeight: CGFloat = UIDimensions.tileImageHeight

    var body: some View {
        VStack(alignment: .leading, spacing: UILayout.tileContentSpacing) {
            ZStack(alignment: .topTrailing) {
                // Image (uses URL from breed model)
                CatImageView(
                    urlString: breed.displayImageUrl ?? breed.referenceImageUrl,
                    height: imageHeight,
                    cornerRadius: imageCornerRadius,
                    contentMode: .fill
                )

                // Favorite button floating over the image
                Button(action: favoriteAction) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                        .padding(UILayout.iconButtonPadding)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(UILayout.circleButtonFillOpacity))
                                .shadow(
                                    color: Color.black.opacity(UILayout.circleButtonShadowOpacity),
                                    radius: UILayout.circleButtonShadowRadius,
                                    x: UILayout.circleButtonShadowOffsetX,
                                    y: UILayout.circleButtonShadowOffsetY
                                )
                        )
                        .padding(UILayout.iconButtonPadding)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavorite ? "Remove from Favorites" : "Add to Favorites")
            }

            // Title
            Text(breed.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(UILayout.titleLineLimit)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Optional origin as subtitle
            if let origin = breed.origin, !origin.isEmpty {
                Text(origin)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(UILayout.subtitleLineLimit)
            }

            Spacer(minLength: 0)
        }
        .padding(UILayout.cardContentPadding)
        .frame(maxWidth: .infinity)
        .frame(height: UIDimensions.breedCardHeight) // matches HomeListView placeholder height
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(
            color: shadowColor,
            radius: UILayout.cardShadowRadius,
            x: UILayout.cardShadowOffsetX,
            y: UILayout.cardShadowOffsetY
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    let sample = CatBreed(
        id: "abys",
        name: "Abyssinian",
        origin: "Egypt",
        description: "Active, Energetic, Independent, Intelligent, Gentle",
        temperament: "Active, Energetic",
        lifeSpan: "14 - 15",
        image: BreedImage(url: "https://cdn2.thecatapi.com/images/0XYvRd7oD.jpg"),
        referenceImageId: "0XYvRd7oD"
    )

    return BreedSquareTile(
        breed: sample,
        isFavorite: true,
        favoriteAction: {},
        cardBackground: Color.gray.opacity(UILayout.previewCardBackgroundOpacity),
        shadowColor: Color.black.opacity(UILayout.previewShadowOpacity)
    )
    .padding()
}
