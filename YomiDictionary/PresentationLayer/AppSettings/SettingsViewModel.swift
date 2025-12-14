//
//  SettingsViewModel.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import SwiftUI
import ZIPFoundation

@Observable
final class SettingsViewModel {
    var isFilePickerPresented: Bool = false
    var dictionaries: [YomiDictionary] = []
    var importProgress: Double? = nil
    
    init() {
    }
    func didAppear() {
        loadDictionaryList()
    }
    
    func loadDictionaryList() {
        Task {
            let dictionaryManager = await DictionaryManager()
            dictionaries = await dictionaryManager.fetchDictionaries()
        }
    }
    
    func importDictionary(result: Result<URL, Error>) -> Void {
        if case .failure(let failure) = result {
            print("Failed to import dictionary: \(failure)")
            return
        }
        
        guard case .success(let fileUrl) = result else { return }
        
        Task {
            let dictionaryManager = await DictionaryManager()
            try await dictionaryManager.saveDictionary(fileUrl) { [weak self] progressPercent in
                self?.importProgress = progressPercent
            } completion: { [weak self] in
                self?.importProgress = nil
                self?.loadDictionaryList()
            }
        }

    }
}
