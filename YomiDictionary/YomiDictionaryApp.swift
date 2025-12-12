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
                .onAppear { try? ZipExtractor.shared.clearCache() }
        }
    }
}
