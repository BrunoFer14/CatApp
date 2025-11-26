import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// View that loads and displays an image by URL, with cache (memory + disk).
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

    // Expose the loaded image to the outside (optional)
    private var loadedImageBinding: Binding<Image?>?

    @State private var image: Image?
    @State private var isLoading = false

    init(
        urlString: String?,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        cornerRadius: CGFloat = UILayout.defaultCornerRadius,
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
                ProgressView.standardCircular
            } else {
                Image(systemName: UIStrings.Icons.photo)
                    .resizable()
                    .aspectRatio(contentMode: contentMode == .fill ? .fill : .fit)
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .if(contentMode == .fill) { view in
                        view.clipped()
                    }
                    .onAppear {
                        // placeholder => clear binding
                        loadedImageBinding?.wrappedValue = nil
                    }
            }
        }
        .frame(width: width, height: height)
        .cornerRadius(cornerRadius)
        .task(id: urlString) {
            // When the URL changes, try to load the image
            await loadImage()
        }
    }

    @MainActor
    private func setImage(from data: Data) {
        // Convert Data → Image (compatible with UIKit/AppKit)
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

    @MainActor
    private func loadImage() async {
        guard let urlString, let url = URL(string: urlString) else { return }
        if image != nil { return } // avoid reloading
        isLoading = true
        defer { isLoading = false }

        do {
            // Use ImageCache (actor) to obtain data (with memory+disk cache)
            let data = try await ImageCache.shared.imageData(for: url)
            setImage(from: data)
        } catch {
            // Keep placeholder on failure
            // Clear binding if we couldn't load
            loadedImageBinding?.wrappedValue = nil
        }
    }
}

// Small helper to apply modifiers conditionally
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

// MARK: - Reusable Progress Views
extension ProgressView where CurrentValueLabel == EmptyView, Label == EmptyView {
    /// Standard circular progress view with consistent styling
    static var standardCircular: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .padding()
    }
}

extension ProgressView where CurrentValueLabel == EmptyView, Label == Text {
    /// Standard circular progress view with text and consistent styling
    static func standardCircular(_ title: String) -> some View {
        ProgressView(title)
            .progressViewStyle(.circular)
            .padding()
    }
}

