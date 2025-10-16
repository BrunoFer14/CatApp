import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Cache de imagens em memória + disco, seguro com actor.
/// Usa hash do URL como nome de ficheiro para persistir no disco.
actor ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, NSData>()
    private let fm = FileManager.default
    private let directoryURL: URL

    init() {
        // Limite aproximado de 50 MB em memória
        memoryCache.totalCostLimit = ImageCacheConstants.memoryLimitBytes
        // Pasta de cache no disco
        let base = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        directoryURL = base.appendingPathComponent(ImageCacheConstants.directoryName, isDirectory: true)
        try? fm.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    /// Obtém dados da imagem (memória → disco → rede).
    func imageData(for url: URL) async throws -> Data {
        // Respeita cancelamento cedo
        if Task.isCancelled { throw CancellationError() }

        let key = url.absoluteString as NSString

        // 1) Tenta memória
        if let cached = memoryCache.object(forKey: key) {
            return cached as Data
        }

        // 2) Tenta disco
        let fileURL = fileURL(for: url)
        if let data = try? Data(contentsOf: fileURL) {
            memoryCache.setObject(data as NSData, forKey: key, cost: data.count)
            return data
        }

        // 3) Faz download e guarda
        if Task.isCancelled { throw CancellationError() }
        let (data, _) = try await URLSession.shared.data(from: url)
        if Task.isCancelled { throw CancellationError() }

        memoryCache.setObject(data as NSData, forKey: key, cost: data.count)
        try? data.write(to: fileURL, options: .atomic)
        return data
    }

    /// Pré-carrega várias imagens em paralelo.
    func prefetch(urls: [URL]) async {
        guard !urls.isEmpty else { return }
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    // Ignora erros e respeita cancelamento
                    if Task.isCancelled { return }
                    _ = try? await self.imageData(for: url)
                }
            }
        }
    }

    // MARK: - Helpers

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

