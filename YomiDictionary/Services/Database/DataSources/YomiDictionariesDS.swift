//
//  YomiDictionariesDS.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import Foundation
import SwiftData

public actor YomiDictionariesDataSource: ModelActor {
    public let modelContainer: ModelContainer
    public let modelExecutor: any ModelExecutor
    private var context: ModelContext { modelExecutor.modelContext }

    public init(container: ModelContainer) {
        self.modelContainer = container
        let context = ModelContext(container)
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }
}

extension YomiDictionariesDataSource {
    public func fetchData<T: PersistentModel>(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) throws -> [T] {
        let fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        let list: [T] = try context.fetch(fetchDescriptor)
        return list
    }
    
    public func fetchCount<T: PersistentModel>(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) throws -> Int {
        let fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        let count = try context.fetchCount(fetchDescriptor)
        return count
    }
    
    public func insert<T: PersistentModel>(_ model: T) {
        let context = model.modelContext ?? context
        context.insert(model)
    }
    
    public func save() throws {
        try context.save()
    }
    
    public func remove<T: PersistentModel>(predicate: Predicate<T>? = nil) throws {
        try context.delete(model: T.self, where: predicate)
    }
    
    public func saveAndInsertIfNeeded<T: PersistentModel>(
        _ model: T,
        predicate: Predicate<T>
    ) throws {
        let descriptor = FetchDescriptor<T>(predicate: predicate)
        let context = model.modelContext ?? context
        let savedCount = try context.fetchCount(descriptor)

        if savedCount == 0 {
            context.insert(model)
        }
        try context.save()
    }
}
