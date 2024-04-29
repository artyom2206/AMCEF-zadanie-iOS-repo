//
//  FilterView.swift
//  AMCEF-zadanie
//
//  Created by Marek Meriač on 15/04/2024.
//

import SwiftUI

struct FilterView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: PublicAPIViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Name")) {
                    TextField("Enter API name", text: $viewModel.apiQuery)
                }
                
                Section(header: Text("Description")) {
                    TextField("Enter description", text: $viewModel.descriptionQuery)
                }
                
                Section(header: Text("Category")) {
                    Picker("Select a Category", selection: $viewModel.selectedCategory) {
                        Text("All").tag("All")
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .navigationBarTitle("Filter Options", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Reset") {
                    viewModel.resetFilters()
                }
            )
        }
        .overlay(
            Button(action: {
                viewModel.loadAPIEntries()
                isPresented = false
            }) {
                Text("Filter")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
                .padding()
            , alignment: .bottom
        )
    }
}

