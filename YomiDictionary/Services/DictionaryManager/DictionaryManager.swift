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
    
    /// Run this func at application start to clear caches and remove empty dictionaries
    public func startDictionaryManager() async throws {
        try await DictionaryManager.clearCache()
        try await removeEmptyDictionaries()
    }
    
    /// Fetch all dictionaries. Empty dictionaries will be ignored and removed at application restart.
    public func fetchDictionaries() async throws -> [YomiDictionary] {
        let fetchedDictionaries = try await dataStore.fetchData(predicate: #Predicate<SDYomiDictionary> {_ in true})
        return fetchedDictionaries.compactMap(YomiDictionary.init).filter { $0.wordsCount > 0 }
    }
    
    /// Save dictionary by URL
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
    
    /// Delete dictionary and all connected words
    public func deleteDictionary(_ dictionary: YomiDictionary) async throws {
        let _ = try await removeWords(ofDictionaryWithId: dictionary.id)
        let dictId = dictionary.id
        let dictToRemovePredicate = #Predicate<SDYomiDictionary> { $0.id == dictId  }
        try await dataStore.remove(predicate: dictToRemovePredicate)
    }
    
    
    /// Fetch all words which contains provided part
    public func fetchWords(contains word: String) async throws -> [YomiWord] {
        let predicate = #Predicate<SDYomiWord> { $0.reading.contains(word) || $0.wordOriginal.contains(word) }
        let fetchedWords = try await dataStore.fetchData(predicate: predicate)
        return fetchedWords.compactMap(YomiWord.init)
    }
}


// MARK: - Helpers

extension DictionaryManager {
    
    private func removeWords(ofDictionaryWithId dictId: UUID) async throws -> Int {
        let wordsOfDictPredicate = #Predicate<SDYomiWord> { $0.dictionary.id == dictId }
        let wordsRemovedTotal = try await dataStore.fetchCount(predicate: wordsOfDictPredicate)
        try await dataStore.remove(predicate: wordsOfDictPredicate)
        return wordsRemovedTotal
    }
    
    private func removeEmptyDictionaries() async throws {
        let allWordsPredicate = #Predicate<SDYomiWord> { _ in true }
        let allWordsCount = try await dataStore.fetchCount(predicate: allWordsPredicate)
        print("All words count: \(allWordsCount)")
        
        // Find dictionaries that are empty
        let emptyDictsPredicate = #Predicate<SDYomiDictionary> { $0.wordsCount == 0 }
        let emptyDictionaries = try await dataStore.fetchData(predicate: emptyDictsPredicate)
        print("Found empty dictionaries: \(emptyDictionaries.map {$0.title})")
        
        for dict in emptyDictionaries {
            let wordsRemovedTotal = try await removeWords(ofDictionaryWithId: dict.id)
            print("Removed \(wordsRemovedTotal) words from \(dict.title) dictionary")
        }
        
        // Remove the empty dictionaries themselves
        try await dataStore.remove(predicate: emptyDictsPredicate)
        print("Removed \(emptyDictionaries.count) empty dictionaries")
    }

    private func dictionaryAsyncStream(from dictionaryFolder: URL) throws -> AsyncThrowingStream
                                                                             <DictionaryProgress, Error> {
                                                                                 
        return AsyncThrowingStream<DictionaryProgress, Error> { continuation in
            Task.detached { [self] in
                do {
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
                        
                        // Saving count of words in database to dictionary
                        try await updateDictionary(currentDictionary.id, with: progress.wordsSaved)
                        
                        continuation.finish()
                    }
                } catch { continuation.finish(throwing: error) }
            }
        }
    }
    private func checkIsDictionaryAlreadyImported(_ dictionary: SDYomiDictionary) async throws {
        let rev = dictionary.revision
        let title = dictionary.title
        let predicate = #Predicate<SDYomiDictionary> { $0.title == title && $0.revision == rev }
        let dictionaries = try await dataStore.fetchData(predicate: predicate)
        if !dictionaries.isEmpty { throw DictionaryErrors.dictionaryAlreadyImported }
    }

    private func saveDictionaryPart(from file: URL,
                                    in dictionary: SDYomiDictionary,
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
    
    @MainActor
    private static func clearCache() throws {
        let fileManager = FileManager.default
        let cacheDirectoryURL = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let fileURLs = try fileManager.contentsOfDirectory(
            at: cacheDirectoryURL,
            includingPropertiesForKeys: nil
        )
        if fileURLs.isEmpty {
            print("No items to remove from cache")
            return
        }
        try fileURLs.forEach(fileManager.removeItem(at:))
        print(
            "Successfully removed \(fileURLs.count) items from cache"
        )
    }

    /// Decode dictionary metadata from index.json and save in database
    private func processDictionaryMeta(_ indexURL: URL) async throws -> SDYomiDictionary {
        let data = try Data(contentsOf: indexURL)
        let metaData = try JSONDecoder().decode(LoadedDictionary.self, from: data)
        let dictionary = SDYomiDictionary(title: metaData.name,
                                          revision: metaData.revision,
                                          dictDescription: metaData.description,
                                          wordsCount: 0)
        
        try await checkIsDictionaryAlreadyImported(dictionary)
        
        print("Found dictionary: \(dictionary.title)")
        await dataStore.insert(dictionary)
        try await dataStore.save()
        return dictionary
    }
}

