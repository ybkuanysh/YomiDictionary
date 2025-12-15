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
    var isInitImport: Bool = false
    var dictionaries: [YomiDictionary] = []
    var importProgress: Double? = nil {
        didSet { isInitImport = false }
    }
    var importControlsDisabled: Bool {
        importProgress != nil || isInitImport
    }
    
    var isAlertPresented: Bool = false
    
    init() {
    }
    func didAppear() {
        loadDictionaryList()
    }
    
    func loadDictionaryList() {
        Task {
            let dictionaryManager = await DictionaryManager()
            let fetchedDictionaries = try? await dictionaryManager.fetchDictionaries()
            dictionaries = fetchedDictionaries ?? []
        }
    }
    
    func onDictDelete(_ indexSet: IndexSet) -> Void {
        Task {
            for index in indexSet {
                let dictionary = dictionaries[index]
                print("Trying to delete: \(dictionary.title)")
                let dictionaryManager = await DictionaryManager()
                try? await dictionaryManager.deleteDictionary(dictionary)
                print("Successfully deleted: \(dictionary.title)")
            }
        }
    }
    
    func importDictionary(result: Result<URL, Error>) -> Void {
        if case .failure(let failure) = result {
            print("Failed to import dictionary: \(failure)")
            return
        }
        
        guard case .success(let fileUrl) = result else { return }
        
        isInitImport = true
        
        Task {
            do {
                let dictionaryManager = await DictionaryManager()
                try await dictionaryManager.saveDictionary(fileUrl) { [weak self] progressPercent in
                    withAnimation {
                        self?.importProgress = progressPercent
                    }
                } completion: { [weak self] in
                    withAnimation {
                        self?.importProgress = nil
                        self?.loadDictionaryList()
                    }
                }
            } catch {
                isInitImport = false
                importProgress = nil
                isAlertPresented = true
            }
        }

    }
}
