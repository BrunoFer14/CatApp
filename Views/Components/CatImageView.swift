import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Vista que carrega e mostra uma imagem por URL, com cache (memória + disco).
struct CatImageView: View {
    enum ContentMode {
        case fit
        case fill
    }

    let urlString: String?
    let width: CGFloat?
    let height: CGFloat?
    let cornerRadius: CGFloat
    let contentMode: ContentMode

    // Expor a imagem carregada para o exterior (opcional)
    private var loadedImageBinding: Binding<Image?>?

    @State private var image: Image?
    @State private var isLoading = false

    init(
        urlString: String?,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        cornerRadius: CGFloat = 8,
        contentMode: ContentMode = .fit,
        loadedImage: Binding<Image?>? = nil
    ) {
        self.urlString = urlString
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.contentMode = contentMode
        self.loadedImageBinding = loadedImage
    }

    var body: some View {
        ZStack {
            if let image {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode == .fill ? .fill : .fit)
                    .if(contentMode == .fill) { view in
                        view.clipped()
                    }
            } else if isLoading {
                ProgressView()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: contentMode == .fill ? .fill : .fit)
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .if(contentMode == .fill) { view in
                        view.clipped()
                    }
                    .onAppear {
                        // placeholder => limpar binding
                        loadedImageBinding?.wrappedValue = nil
                    }
            }
        }
        .frame(width: width, height: height)
        .cornerRadius(cornerRadius)
        .task(id: urlString) {
            // Quando a URL muda, tenta carregar a imagem
            await loadImage()
        }
    }

    @MainActor
    private func setImage(from data: Data) {
        // Converte Data → Image (compatível com UIKit/AppKit)
        #if canImport(UIKit)
        if let uiImage = UIImage(data: data) {
            let swiftUIImage = Image(uiImage: uiImage)
            image = swiftUIImage
            loadedImageBinding?.wrappedValue = swiftUIImage
        }
        #elseif canImport(AppKit)
        if let nsImage = NSImage(data: data) {
            let swiftUIImage = Image(nsImage: nsImage)
            image = swiftUIImage
            loadedImageBinding?.wrappedValue = swiftUIImage
        }
        #endif
    }

    private func loadImage() async {
        guard let urlString, let url = URL(string: urlString) else { return }
        if image != nil { return } // evita recarregar
        isLoading = true
        defer { isLoading = false }

        do {
            // Usa o ImageCache (actor) para obter dados (com cache memória+disco)
            let data = try await ImageCache.shared.imageData(for: url)
            await setImage(from: data)
        } catch {
            // Mantém placeholder se falhar
            // Limpa binding se não conseguimos carregar
            loadedImageBinding?.wrappedValue = nil
        }
    }
}

// Pequeno helper para aplicar modificadores condicionalmente
private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
