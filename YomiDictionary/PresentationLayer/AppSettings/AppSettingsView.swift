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
                    Section {
                        HStack {
                            Text("Import dictionary")
                            Spacer()
                            Button("Select") {
                                viewModel.isFilePickerPresented = true
                            }
                            if viewModel.isInitImport { ProgressView() }
                        }
                        .disabled(viewModel.importControlsDisabled)
                        if viewModel.importProgress != nil {
                            VStack(alignment: .leading) {
                                Text("Importing...")
                                ProgressView(value: viewModel.importProgress)
                            }
                        }
                    }
                    Section {
                        ForEach(viewModel.dictionaries) { item in
                            HStack {
                                Text(item.title)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(item.revision ?? "No revision")
                                    Text("\(item.wordsCount)")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.caption)
                            }
                        }
                        .onDelete(perform: viewModel.onDictDelete)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .alert(
                "Import error",
                isPresented: $viewModel.isAlertPresented,
                actions: { Button("OK") {} },
                message: { Text("Dictionary already exists. Please, try to import another one.") }
            )
            //            .alert(
//                isPresented: $viewModel.isAlertPresented,
//                error: viewModel.localizedError,
//                actions: { _ in Text("OK") },
//                message: { error in Text(error.localizedDescription) }
//            )
            .onAppear { viewModel.didAppear() }
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
