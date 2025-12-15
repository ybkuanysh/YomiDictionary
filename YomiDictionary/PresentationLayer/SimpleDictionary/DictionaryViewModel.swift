//
//  DictionaryViewModel.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import SwiftUI
import SwiftData

@Observable
final class DictionaryViewModel {
    var isSettingsPresented: Bool = false
    var searchText: String = ""
    var wordsList: [YomiWord] {
        if fetchedWords.isEmpty {
            []
        } else {
            fetchedWords
        }
    }

    var fetchedWords: [YomiWord] = []
    
    init() {
    }

    func searchChanged(oldValue: String, newValue: String) {
        Task {
            let manager = await DictionaryManager()
            fetchedWords = (try? await manager.fetchWords(contains: newValue)) ?? []
        }
    }
}
