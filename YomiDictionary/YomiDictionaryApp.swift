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
                    do {
                        let fileManager = FileManager.default
                        let cacheDirectoryURL = try fileManager.url(
                            for: .cachesDirectory,
                            in: .userDomainMask,
                            appropriateFor: nil,
                            create: false
                        )
                        let fileURLs = try fileManager.contentsOfDirectory(
                            at: cacheDirectoryURL,
                            includingPropertiesForKeys: nil
                        )
                        if fileURLs.isEmpty {
                            print("No items to remove from cache")
                            return
                        }
                        try fileURLs.forEach(fileManager.removeItem(at:))
                        print(
                            "Successfully removed \(fileURLs.count) items from cache"
                        )
                    } catch {
                        fatalError(
                            "Failed to remove items from cache: \(error)"
                        )
                    }
                }
        }
    }
}
