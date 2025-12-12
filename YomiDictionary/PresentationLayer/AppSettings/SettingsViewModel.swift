//
//  SettingsViewModel.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import SwiftUI

@Observable
final class SettingsViewModel {
    var isFilePickerPresented: Bool = false
    var dictionaries: [YomiDictionary] = []
    var importProgress: Double? = nil
    
    let dictionaryManager: DictionaryManager
    
    init() {
        dictionaryManager = .init()
    }
    
    func updateDictionaryList() async {
        dictionaries = await dictionaryManager.getDictionaries()
    }
    
    func importDictionary(result: Result<URL, Error>) -> Void {
        if case .failure(let failure) = result {
            print("Failed to import dictionary: \(failure)")
            return
        }
        
        guard case .success(let fileUrl) = result else { return }
        
        guard fileUrl.startAccessingSecurityScopedResource() else {
            fatalError("Failed to access dictionary file")
        }
        defer { fileUrl.stopAccessingSecurityScopedResource() }
        
        let savingProgress: AsyncThrowingStream<DictionaryProgress, Error>?
        do { savingProgress = try dictionaryManager.saveDictionary(from: fileUrl) }
        catch { fatalError("Failed to save dictionary: \(error)") }
        
        guard let savingProgress else { fatalError("Failed to save dictionary") }
        
        Task {
            for try await status in savingProgress {
                importProgress = await status.percentage
            }
            importProgress = nil
            await updateDictionaryList()
        }
        
//        var dictionaryProcessing: DictionarySavingData
//        do { dictionaryProcessing = try dictionaryManager.saveDictionary(from: fileUrl) }
//        catch { fatalError("Failed to save dictionary: \(error)") }
//        print("Count of JSON Items: \(dictionaryProcessing.itemsCount)")
//        Task {
//            for try await data in dictionaryProcessing.asyncThrowingStream {
//                print("Saved \(data.wordsSaved) words")
//            }
//        }
    }
}
