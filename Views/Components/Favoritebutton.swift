import SwiftUI

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundColor(.red)
                .imageScale(.large)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


