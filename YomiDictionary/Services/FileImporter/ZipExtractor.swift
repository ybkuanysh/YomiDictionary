//
//  ExtractZip.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import Foundation
import ZIPFoundation

final class ZipExtractor {

    public static let shared = ZipExtractor()

    private let fileManager: FileManager!

    private init() {
        self.fileManager = FileManager()
    }
    
    public func clearCache() throws {
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
        print("Successfully removed \(fileURLs.count) items from cache")
    }

    public func extractToCache(zipURL: URL) throws -> URL {
        var destinationURL = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )

        let fileName = zipURL.lastPathComponent + UUID().uuidString
        destinationURL.appendPathComponent(fileName)
        try fileManager.createDirectory(
            at: destinationURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try fileManager.unzipItem(at: zipURL, to: destinationURL)
        return destinationURL
    }
}
