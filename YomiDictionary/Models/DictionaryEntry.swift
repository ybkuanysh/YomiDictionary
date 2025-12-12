//
//  DictionaryItem.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import Foundation

nonisolated public struct LoadedDictionary: Hashable, Identifiable, Decodable {
    public var id: UUID
    public var name: String
    public var revision: String?
    public var description: String?
    
    public init(name: String, revision: String = "1.0") {
        self.id = UUID()
        self.name = name
        self.revision = revision
    }
    
    enum CodingKeys: CodingKey {
        case title
        case revision
        case description
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .title)
        self.revision = try container.decodeIfPresent(String.self, forKey: .revision)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
    }
}

public struct DictionaryEntry: Hashable, Identifiable, Decodable {
    public let id = UUID()
    public var kanji: String
    public var reading: String
    public var definitions: [String]
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        self.kanji = try container.decode(String.self)
        self.reading = try container.decode(String.self)
        
        _ = try container.decode(String.self)
        _ = try container.decode(String.self)
        _ = try container.decode(Int.self)
        
        self.definitions = try container.decode([String].self)
        
        _ = try container.decode(Int.self)
        _ = try container.decode(String.self)
    }
}
