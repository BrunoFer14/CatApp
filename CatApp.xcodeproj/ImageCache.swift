import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

actor ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, NSData>()
    private let fm = FileManager.default
    private let directoryURL: URL

    init() {
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // ~50 MB
        let base = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        directoryURL = base.appendingPathComponent("ImageCache", isDirectory: true)
        try? fm.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    func imageData(for url: URL) async throws -> Data {
        let key = url.absoluteString as NSString

        if let cached = memoryCache.object(forKey: key) {
            return cached as Data
        }

        let fileURL = fileURL(for: url)
        if let data = try? Data(contentsOf: fileURL) {
            memoryCache.setObject(data as NSData, forKey: key, cost: data.count)
            return data
        }

        // Download e persiste
        let (data, _) = try await URLSession.shared.data(from: url)
        memoryCache.setObject(data as NSData, forKey: key, cost: data.count)
        try? data.write(to: fileURL, options: .atomic)
        return data
    }

    func prefetch(urls: [URL]) async {
        guard !urls.isEmpty else { return }
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    _ = try? await self.imageData(for: url)
                }
            }
        }
    }

    private func fileURL(for url: URL) -> URL {
        directoryURL.appendingPathComponent(hash(url.absoluteString))
    }

    private func hash(_ string: String) -> String {
        #if canImport(CryptoKit)
        let data = Data(string.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
        #else
        // Fallback simples caso CryptoKit não esteja disponível
        return String(string.hashValue)
        #endif
    }
}
