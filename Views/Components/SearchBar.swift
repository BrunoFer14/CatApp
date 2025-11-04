import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Componente reutilizável de barra de pesquisa.
/// Usa um binding de texto para ligar ao ViewModel.
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."

    // Cor de fundo compatível com múltiplas plataformas
    private var backgroundColor: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGray6)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.gray.opacity(UILayout.searchBarFallbackBackgroundOpacity)
        #endif
    }

    var body: some View {
        HStack {
            Image(systemName: UIStrings.Icons.magnifyingglass)

            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: UIStrings.Icons.xmarkCircleFill)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(UILayout.buttonPadding)
        .background(backgroundColor)
        .cornerRadius(UILayout.defaultCornerRadius)
        .padding(.horizontal, UILayout.listPadding)
    }
}
