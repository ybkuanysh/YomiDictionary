//
//  DictionaryManager.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import Foundation
import SwiftData
import JsonStream
import ZIPFoundation


public final actor DictionaryManager {
    private var dataStore: YomiDictionariesDataSource!

    init() async {
        dataStore = .init(container: await ContainerManager.shared.container)
    }
    
}

// MARK: - Save Dictionary Words to Database

extension DictionaryManager {
    public func fetchDictionaries() async -> [YomiDictionary] {
        let dictionaries = try? await dataStore.fetchData(predicate: #Predicate<SDYomiDictionary> {_ in true})
        return dictionaries?.map(YomiDictionary.init) ?? []
    }

    public func saveDictionary(_ fileUrl: URL,
                               progress: @MainActor @escaping (Double) -> Void,
                               completion: @MainActor @escaping () async -> Void) async throws -> Void {
        
            guard fileUrl.startAccessingSecurityScopedResource() else {
                throw DictionaryErrors.basicError
            }
            defer { fileUrl.stopAccessingSecurityScopedResource() }

            let dictionaryURL = try await DictionaryManager.extractToCache(zipURL: fileUrl)
            
            let savingProgress = try dictionaryAsyncStream(from: dictionaryURL)
            
            var lastResult: Double = 0
            for try await status in savingProgress {
                let status = await status.percentage
                if status == lastResult { continue }
                lastResult = status
                await progress(status)
            }
            await completion()
    }
    
    
    

}


// MARK: - Helpers

extension DictionaryManager {
    
    private func dictionaryAsyncStream(from dictionaryFolder: URL) throws -> AsyncThrowingStream
                                                                             <DictionaryProgress, Error> {
                                                                                 
        return AsyncThrowingStream<DictionaryProgress, Error> { continuation in
            Task.detached { [self] in
                
                // Extracting dictionary zip file to cache
                let fileManager = FileManager()
                
                var files = try fileManager.contentsOfDirectory(at: dictionaryFolder,
                                                                        includingPropertiesForKeys: nil)
                // Getting index.json id in files
                let indexFileIdx = files.firstIndex { $0.lastPathComponent.contains("index.json") }
                guard let indexFileIdx else { throw DictionaryErrors.basicError }
                
                // Processing index.json
                let currentDictionary = try await processDictionaryMeta(files[indexFileIdx])
                files.remove(at: indexFileIdx)

                let countOfWords = try await countWords(in: files)
                
                // Saving count of words in database to dictionary
                try await updateDictionary(currentDictionary.id, with: countOfWords)

                let progress = DictionaryProgress(allWordsCount: countOfWords)
                
                try await withThrowingTaskGroup(of: Void.self) { group in
                    files.forEach { url in
                        group.addTask(priority: .low) { [self] in
                            try await saveDictionaryPart(from: url, in: currentDictionary) {
                                let result = await progress.incrementSavedWords($0)
                                continuation.yield(result)
                            }
                        }
                    }
                    
                    for try await _ in group {}
                    continuation.finish()
                }
            }
        }
    }

    private func saveDictionaryPart(from file: URL,
                                    in dictionary: SDYomiDictionary?,
                                    handler: (Int) async -> Void) async throws {
        var counter: Int = 0

        var arrayDepth: Int = 0
        var isDefinitionArray: Bool { arrayDepth == 3 }
        var isWordArray: Bool { arrayDepth == 2 }
        var isMainArray: Bool { arrayDepth == 1 }

        var originalWord: String? = nil
        var reading: String? = nil
        var definitions: [String] = []
        func resetData() {
            originalWord = nil
            reading = nil
            definitions = []
        }
        let jis = try JsonInputStream(filePath: file.path)

        while let token = try jis.read() {
            switch token {
            case .startArray: arrayDepth += 1
            case .endArray: arrayDepth -= 1
            case .string(let key, let value):
                if case .index(let id) = key {
                    if isDefinitionArray {
                        definitions.append(value)
                    } else {
                        switch id {
                        case 0: originalWord = value
                        case 1: reading = value
                        default: continue
                        }
                    }
                }
            default: continue
            }

            if isMainArray, let originalWord, let reading, !definitions.isEmpty
            {
                let word = SDYomiWord(
                    wordOriginal: originalWord,
                    reading: reading,
                    definitions: definitions,
                    dictionary: dictionary
                )
                await dataStore.insert(word)
                await handler(1)
                counter += 1
                resetData()
            }
            if counter % 100 == 0 {
                try await dataStore.save()
                counter = 0
            }
        }
        try await dataStore.save()
    }

    private func updateDictionary(_ id: UUID, with count: Int) async throws {
        let dictionaries = try await dataStore.fetchData(
            predicate: #Predicate<SDYomiDictionary> { $0.id == id }
        )
        if let dictionary = dictionaries.first {
            dictionary.wordsCount = count
            await dataStore.insert(dictionary)
            try await dataStore.save()
            return
        } else { fatalError("Dictionary with id: \(id) not found") }
    }

    private func countWords(in file: URL) throws -> Int {
        let jis = try JsonInputStream(filePath: file.path)
        var counter: Int = 0

        var arrayDepth: Int = 0
        var isMainArray: Bool { arrayDepth == 1 }

        while let token = try jis.read() {
            switch token {
            case .startArray: arrayDepth += 1
            case .endArray:
                arrayDepth -= 1
                if isMainArray { counter += 1 }
            default: continue
            }
        }
        return counter
    }

    private func countWords(in files: [URL]) async throws -> Int {
        let total = try await withThrowingTaskGroup(of: Int.self) { group in
            files.forEach { url in
                group.addTask { [self] in try await countWords(in: url) }
            }
            
            var totalCount: Int = 0
            
            for try await data in group {
                totalCount += data
            }
            return totalCount
        }
        return total
    }

    /// Extract zip archive and return folder URL
    @MainActor
    private static func extractToCache(zipURL: URL) throws -> URL {
        let fileManager = FileManager()
        var destinationURL = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )

        let fileName = zipURL.lastPathComponent + UUID().uuidString
        destinationURL.appendPathComponent(fileName)
        try fileManager.createDirectory(
            at: destinationURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try fileManager.unzipItem(at: zipURL, to: destinationURL)
        
        return destinationURL
    }

    /// Decode dictionary metadata from index.json and save in database
    private func processDictionaryMeta(_ indexURL: URL) async throws -> SDYomiDictionary {
        let data = try Data(contentsOf: indexURL)
        let metaData = try JSONDecoder().decode(LoadedDictionary.self, from: data)
        let dictionary = SDYomiDictionary(title: metaData.name,
                                          revision: metaData.revision,
                                          dictDescription: metaData.description,
                                          wordsCount: 0)
        print("Found dictionary: \(dictionary.title)")
        await dataStore.insert(dictionary)
        try await dataStore.save()
        return dictionary
    }
}
