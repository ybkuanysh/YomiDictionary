//
//  YomiDictionaryApp.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import SwiftUI

@main
struct YomiDictionaryApp: App {
    var body: some Scene {
        WindowGroup {
            MainContainerView()
                .onAppear {
                    Task {
                        do {
                            try await DictionaryManager().startDictionaryManager()
                        } catch { fatalError("Error at dictionary manager start: \(error)") }
                    }
                }
        }
    }
}
