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
                        }
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
                    }
                }
                .listStyle(.insetGrouped)
            }
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
