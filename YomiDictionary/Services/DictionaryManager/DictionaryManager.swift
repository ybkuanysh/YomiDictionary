//
//  DictionaryManager.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import Foundation
import SwiftData
import JsonStream

public actor DictionaryProgress {
    public private(set) var wordsSaved: Int
    public let allWordsCount: Int
    public var percentage: Double {
        Double(wordsSaved) / Double(allWordsCount)
    }
    
    public init(wordsSaved: Int = 0, allWordsCount: Int = 0) {
        self.wordsSaved = wordsSaved
        self.allWordsCount = allWordsCount
    }
    public func incrementSavedWords(_ count: Int) -> Self {
        wordsSaved += count
        return self
    }
}

public final class DictionaryManager {
    
    private let dataStore: YomiDictionariesDataSource
    
    init() {
        dataStore = .init(container: .YomiWord())
    }
    
    public func getDictionaries() async -> [YomiDictionary] {
        let dictionaries = try? await dataStore.fetchData(predicate: #Predicate<SDYomiDictionary> {_ in true})
        return dictionaries?.map(YomiDictionary.init) ?? []
    }
}

// MARK: - Save Dictionary Words to Database

extension DictionaryManager {
    
    public func saveDictionary(from zipURL: URL) throws -> AsyncThrowingStream<DictionaryProgress, Error> {

        // Extracting dictionary zip file to cache
        let dictionaryFolder = try ZipExtractor.shared.extractToCache(zipURL: zipURL)
        
        return AsyncThrowingStream<DictionaryProgress, Error> { continuation in
            Task.detached { [self] in
                var files = try FileManager.default.contentsOfDirectory(at: dictionaryFolder,
                                                                        includingPropertiesForKeys: nil)
                // Getting index.json id in files
                let indexFileIdx = files.firstIndex { $0.lastPathComponent.contains("index.json") }
                guard let indexFileIdx else { fatalError("Index file not found in the dictionary folder") }
                
                print("Index idx found")
                
                // Processing index.json
                let currentDictionary = try await processDictionaryMeta(files[indexFileIdx])
                files.remove(at: indexFileIdx)

                let countOfWords = try await countWords(in: files)
                
                // Saving count of words in database to dictionary
                try await updateDictionary(currentDictionary.id, with: countOfWords)

                let progress = DictionaryProgress(allWordsCount: countOfWords)
                
                try await withThrowingTaskGroup(of: Void.self) { group in
                    files.forEach { url in
                        group.addTask { [self] in
                            try await saveDictionaryPartStream(from: url, in: currentDictionary) {
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

    private func saveDictionaryPartStream(
        from file: URL,
        in dictionary: SDYomiDictionary?,
        handler:  (Int) async -> Void
    ) async throws {
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
                counter += 1
                resetData()
            }
            if counter % 100 == 0 {
                try await dataStore.save()
                await handler(counter)
                counter = 0
            }
        }
        try await dataStore.save()
        await handler(counter)
    }
}


// MARK: - Helpers

extension DictionaryManager {
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
