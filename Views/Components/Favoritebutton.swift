import SwiftUI

/// Botão de coração simples para favoritos.
/// Recebe o estado atual (isFavorite) e uma ação a executar ao tocar.
struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void
    
    @State private var isAnimating = false

    var body: some View {
        Button(action: {
            // Trigger animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                isAnimating.toggle()
            }
            // Reset animation state after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAnimating = false
            }
            // Execute the actual favorite toggle
            action()
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundColor(.red)
                .imageScale(.large)
                .scaleEffect(isAnimating ? 1.3 : 1.0) // Bounce effect
                .rotation3DEffect(
                    .degrees(isAnimating ? 360 : 0), // Rotation effect
                    axis: (x: 0, y: 1, z: 0)
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isFavorite) // Smooth transition between states
        }
        .buttonStyle(PlainButtonStyle())
    }
}
