import SwiftUI

struct CatImageView: View {
    let urlString: String?
    let width: CGFloat?
    let height: CGFloat?
    let cornerRadius: CGFloat

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
        if let urlString = urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
        } else {
            Image(systemName: "photo")
                .resizable()
                .frame(width: width, height: height)
                .foregroundColor(.gray)
                .cornerRadius(cornerRadius)
        }
    }
}
