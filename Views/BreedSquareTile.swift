import SwiftUI

struct BreedSquareTile: View {
    let breed: CatBreed
    let isFavorite: Bool
    let favoriteAction: () -> Void
    let cardBackground: Color
    let shadowColor: Color

    // Tile layout constants
    private let cornerRadius: CGFloat = 14
    private let imageCornerRadius: CGFloat = 12
    private let imageHeight: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                        )
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavorite ? "Remove from Favorites" : "Add to Favorites")
            }

            // Title
            Text(breed.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Optional origin as subtitle
            if let origin = breed.origin, !origin.isEmpty {
                Text(origin)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .frame(height: 180) // matches HomeListView placeholder height
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: shadowColor, radius: 6, x: 0, y: 2)
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
        life_span: "14 - 15",
        image: BreedImage(url: "https://cdn2.thecatapi.com/images/0XYvRd7oD.jpg"),
        referenceImageId: "0XYvRd7oD"
    )

    return BreedSquareTile(
        breed: sample,
        isFavorite: true,
        favoriteAction: {},
        cardBackground: Color.gray.opacity(0.15),
        shadowColor: Color.black.opacity(0.08)
    )
    .padding()
}
