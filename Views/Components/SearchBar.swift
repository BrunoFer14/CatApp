import SwiftUI

/// Componente reutilizável de barra de pesquisa.
/// Usa um binding de texto para ligar ao ViewModel.
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Pesquisar..."

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")

            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
