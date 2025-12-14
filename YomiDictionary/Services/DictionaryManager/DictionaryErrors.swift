//
//  DictionaryErrors.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 14.12.2025.
//

import Foundation

enum DictionaryErrors: LocalizedError {
    case basicError
    case dictionaryAlreadyImported
}

extension DictionaryErrors {
    var errorDescription: String? {
        switch self {
        case .basicError: "Something went wrong."
        case .dictionaryAlreadyImported: "This dictionary is already imported."
        }
    }
}
