//
//  DictionaryErrors.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 14.12.2025.
//

import Foundation

enum DictionaryErrors: LocalizedError {
    case basicError
}

extension DictionaryErrors {
    var errorDescription: String? {
        switch self {
        case .basicError:
            return "Something went wrong."
        }
    }
}
