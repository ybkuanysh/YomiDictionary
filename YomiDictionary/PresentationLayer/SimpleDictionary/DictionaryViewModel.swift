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
//    let dataSource: YomiDictionariesDataSource
    
    var dictionaryRecords: [SDYomiWord] = []
    var searchText: String = ""
    var searchResults: [SDYomiWord] {
        if searchText.isEmpty {
            return dictionaryRecords
        } else {
            return dictionaryRecords.filter {
                $0.reading.contains(searchText)
                || $0.wordOriginal.contains(searchText)
                || $0.definitions.contains(where: { definition in
                    definition.localizedCaseInsensitiveContains(searchText.lowercased())
                })
            }
        }
    }
    
    init() {
//        let context = ModelContext(ContainerManager.shared.container)
//        dataSource = YomiDictionariesDataSource(context: context)
    }

    func parseDictionary() {
//        do {
//            dictionaryRecords = try dataSource.fetchWords()
//            print("Successfully fetched \(dictionaryRecords.count) words.")
//        } catch {
//            fatalError(error.localizedDescription)
//        }
    }
}
