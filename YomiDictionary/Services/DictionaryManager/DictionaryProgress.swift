//
//  DictionaryProgress.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 14.12.2025.
//

import Foundation

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
