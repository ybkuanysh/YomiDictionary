//
//  ContextManager.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import Foundation
import SwiftData

public final actor ContainerManager {
    public private(set) static var shared = ContainerManager()
    public private(set) var container: ModelContainer!
    
    private init() {
        do {
            container = try ModelContainer(for: SDYomiWord.self)
        } catch {
            fatalError("Error initializing Core Data stack: \(error.localizedDescription)")
        }
    }
}
