//
//  SimpleDictView.swift
//  YomiDictionary
//
//  Created by Kuanysh Yabekov on 08.12.2025.
//

import SwiftUI

struct SimpleDictView: View {
    @State private var viewModel = DictionaryViewModel()
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.searchResults.isEmpty {
                    VStack {
                        Image(systemName: "questionmark.folder.fill.ar")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                        Text("No data")
                            .font(Font.largeTitle.bold())
                    }
                    .foregroundStyle(Color(.systemGray3))
                } else {
                    List(viewModel.searchResults) { item in
                        HStack {
                            VStack {
                                Text(item.wordOriginal)
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                                Text(item.reading)
                                    .foregroundStyle(.secondary)
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                            }
                            Spacer()
                            Text(item.definitions.first ?? "")
                                .lineLimit(1)
                                .frame(maxWidth: 200, alignment: .trailing)
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText)
            .onAppear {
                viewModel.parseDictionary()
            }
            .navigationTitle("Dictionary")
        }
    }
}

#Preview {
    SimpleDictView()
}
