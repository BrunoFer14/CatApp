import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct CatImageView: View {
    let urlString: String?
    let width: CGFloat?
    let height: CGFloat?
    let cornerRadius: CGFloat

    @State private var image: Image?
    @State private var isLoading = false

    init(
        urlString: String?,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        cornerRadius: CGFloat = 8
    ) {
        self.urlString = urlString
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        ZStack {
            if let image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
            }
        }
        .frame(width: width, height: height)
        .cornerRadius(cornerRadius)
        .task(id: urlString) {
            await loadImage()
        }
    }

    @MainActor
    private func setImage(from data: Data) {
        #if canImport(UIKit)
        if let uiImage = UIImage(data: data) {
            image = Image(uiImage: uiImage)
        }
        #elseif canImport(AppKit)
        if let nsImage = NSImage(data: data) {
            image = Image(nsImage: nsImage)
        }
        #endif
    }

    private func loadImage() async {
        guard let urlString, let url = URL(string: urlString) else { return }
        if image != nil { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await ImageCache.shared.imageData(for: url)
            await setImage(from: data)
        } catch {
            // Mantém placeholder se falhar
        }
    }
}
