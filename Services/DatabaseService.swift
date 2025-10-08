import SwiftData

/// Abstração por cima do SwiftData para facilitar testes e reutilização.
@MainActor
protocol DatabaseServiceProtocol {
    var context: ModelContext { get }

    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T]
    func insert<T: PersistentModel>(_ model: T) throws
    func delete<T: PersistentModel>(_ model: T) throws
    func deleteAll<T: PersistentModel>(_ modelType: T.Type) throws
    func saveIfNeeded() throws
}

/// Implementação concreta usando SwiftData.
@MainActor
final class SwiftDataDatabaseService: DatabaseServiceProtocol {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        try context.fetch(descriptor)
    }

    func insert<T: PersistentModel>(_ model: T) throws {
        context.insert(model)
        try saveIfNeeded()
    }

    func delete<T: PersistentModel>(_ model: T) throws {
        context.delete(model)
        try saveIfNeeded()
    }

    func deleteAll<T: PersistentModel>(_ modelType: T.Type) throws {
        // Busca tudo e apaga, depois guarda
        let all = try context.fetch(FetchDescriptor<T>())
        for m in all { context.delete(m) }
        try saveIfNeeded()
    }

    func saveIfNeeded() throws {
        // Só faz save se houver alterações pendentes
        if context.hasChanges {
            try context.save()
        }
    }
}
