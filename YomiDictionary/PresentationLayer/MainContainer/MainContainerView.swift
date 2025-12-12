//
//  ContentView.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import SwiftUI

struct MainContainerView: View {
    var body: some View {
        TabView {
            Tab("Dictionary", systemImage: "character.book.closed.ja") {
                SimpleDictView()
            }
            Tab("Settings", systemImage: "gearshape") {
                AppSettingsView()
            }
        }
    }
}

#Preview {
    MainContainerView()
}
