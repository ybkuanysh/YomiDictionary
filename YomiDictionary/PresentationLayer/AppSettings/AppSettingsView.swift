//
//  AppSettingsView.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct AppSettingsView: View {
    @State var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    HStack {
                        Text("Dictionaries")
                        Spacer()
                        Button("Import") {
                            viewModel.isFilePickerPresented = true
                        }
                    }
                    if viewModel.importProgress != nil {
                        HStack {
                            ProgressView(value: viewModel.importProgress)
                        }
                    }
                    ForEach(viewModel.dictionaries) { item in
                        HStack {
                            Text(item.title)
                            Spacer()
                            VStack {
                                Text(item.revision ?? "No revision")
                                Text("\(item.wordsCount)")
                            }
                        }
                    }
                }
            }
            .task { await viewModel.updateDictionaryList() }
            .navigationBarTitle("Settings")
            .fileImporter(
                isPresented: $viewModel.isFilePickerPresented,
                allowedContentTypes: [.item],
                onCompletion: viewModel.importDictionary
            )
        }
    }
}

#Preview {
    AppSettingsView()
}
