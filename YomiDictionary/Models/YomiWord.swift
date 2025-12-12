//
//  Word.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import Foundation
import SwiftData

/// Non-Sendable SwiftData Model. Only for store data. Use YomiWord in case of transfer data.
@Model
public class SDYomiWord: Identifiable, Hashable {
    @Attribute(.unique)
    public var id: UUID = UUID()
    public var wordOriginal: String
    public var reading: String
    public var definitions: [String]
    public var dictionary: SDYomiDictionary?

    public init(
        wordOriginal: String,
        reading: String,
        definitions: [String],
        dictionary: SDYomiDictionary? = nil
    ) {
        self.wordOriginal = wordOriginal
        self.reading = reading
        self.definitions = definitions
        self.dictionary = dictionary
    }
    
    public init(
        _ entry: DictionaryEntry,
        dictionary: SDYomiDictionary? = nil
    ) {
        self.wordOriginal = entry.kanji
        self.reading = entry.reading
        self.definitions = entry.definitions
        self.dictionary = dictionary
    }
}

/// Sendable data model.
public struct YomiWord: Identifiable, Hashable {
    public var id: UUID
    public var wordOriginal: String
    public var reading: String
    public var definitions: [String]
    public var dictionary: SDYomiDictionary?

    public init(
        id: UUID,
        wordOriginal: String,
        reading: String,
        definitions: [String],
        dictionary: SDYomiDictionary? = nil
    ) {
        self.id = id
        self.wordOriginal = wordOriginal
        self.reading = reading
        self.definitions = definitions
        self.dictionary = dictionary
    }
}

