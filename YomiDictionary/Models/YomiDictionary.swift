//
//  YomiDictionary.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import Foundation
import SwiftData

@Model
public class SDYomiDictionary: Identifiable, Hashable {
    @Attribute(.unique)
    public var id: UUID = UUID()
    public var title: String
    public var revision: String?
    public var dictDescription: String?
    public var wordsCount: Int
    
    public init(
        title: String,
        revision: String? = nil,
        dictDescription: String? = nil,
        wordsCount: Int = 0
    ) {
        self.title = title
        self.revision = revision
        self.dictDescription = dictDescription
        self.wordsCount = wordsCount
    }
    
    public init(_ entry: LoadedDictionary) {
        self.title = entry.name
        self.revision = entry.revision
        self.dictDescription = entry.description
        self.wordsCount = 0
    }
}

public struct YomiDictionary: Identifiable {
    public var id: UUID = UUID()
    public var title: String
    public var revision: String?
    public var dictDescription: String?
    public var wordsCount: Int

    public init(
        id: UUID,
        title: String,
        revision: String? = nil,
        dictDescription: String? = nil,
        wordsCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.revision = revision
        self.dictDescription = dictDescription
        self.wordsCount = wordsCount
    }
    
    public init(_ dictionary: SDYomiDictionary) {
        self.id = dictionary.id
        self.title = dictionary.title
        self.revision = dictionary.revision
        self.dictDescription = dictionary.dictDescription
        self.wordsCount = dictionary.wordsCount
    }
}
