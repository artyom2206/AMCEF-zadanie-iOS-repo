//
//  ContentView.swift
//  AMCEF-zadanie
//
//  Created by Marek Meriač on 15/04/2024.
//

import SwiftUI
import CoreData
import WebKit

struct APIEntryRow: View {
    var apiEntry: Entry
    var onCategorySelected: (String) -> Void
    @State private var isTapped = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(apiEntry.name!)
                    .font(.headline)
                    .foregroundColor(.blue)
                Text(apiEntry.desc!)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Text("Category:")
                        .font(.caption)
                    Text(apiEntry.category ?? "")
                        .font(.caption)
                        .underline(isTapped)
                        .foregroundColor(.blue)
                        .onTapGesture {
                            self.isTapped = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                self.isTapped = false
                                self.onCategorySelected(apiEntry.category ?? "")
                            }
                        }
                }
                if apiEntry.https {
                    Text("HTTPS")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            if apiEntry.auth != "" && apiEntry.auth != "No" {
                Image(systemName: "lock.shield")
            }
        }
    }
}

struct APIEntryCard: View {
    var entry: Entry
    var showCategory: Bool
    var fullWidth: Bool = false
    var descMaxLines: Int = 0
    
    @Environment(\.colorScheme) var colorScheme
    
    var onCategorySelected: ((String) -> Void)? = nil
    @State private var isTapped = false
    
    var body: some View {
        NavigationLink(destination: WebView(viewModel: WebViewViewModel(), urlString: entry.link ?? "")) {
            
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.name!)
                    .font(.headline)
                    .foregroundColor(.blue)
                
                if descMaxLines > 0 {
                    Text(entry.desc!)
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                        .lineLimit(2)
                } else {
                    Text(entry.desc!)
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                }
                
                
                if showCategory {
                    HStack {
                        Text("Category:")
                            .font(.caption)
                            .foregroundColor(Color.primary)
                        
                        Text(entry.category ?? "")
                            .font(.caption)
                            .underline(isTapped)
                            .foregroundColor(.blue)
                            .onTapGesture {
                                self.isTapped = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    self.isTapped = false
                                    self.onCategorySelected!(entry.category ?? "")
                                }
                            }
                    }
                }
                
                HStack {
                    TagView(text: entry.https ? "HTTPS" : "HTTP", color: entry.https ? .green : .orange)
                    
                    if let auth = entry.auth, entry.auth != "No", !auth.isEmpty {
                        TagView(text: auth, color: .green, icon: "lock.shield")
                    }
                }
            }
            //        .frame(width: fullWidth ? .infinity : nil, height: 150)
            .frame(minWidth: 150, maxWidth: fullWidth ? .infinity : 200)
            //            .frame(minWidth: 200, maxWidth: fullWidth ? .infinity : nil, idealWidth: fullWidth ? .infinity : 200, height: 180)
            
            .padding()
            .background(backgroundForColorScheme(colorScheme))
            .cornerRadius(10)
            .shadow(radius: 3)
        }
    }
    
    private func backgroundForColorScheme(_ scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color(.systemGray6) // Tmavý režim
        default:
            return Color(.white) // Svetlý režim
        }
    }
}

struct TagView: View {
    var text: String
    var color: Color
    var icon: String?
    
    var body: some View {
        HStack(spacing: 5) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
            }
            Text(text)
                .font(.caption)
                .bold()
                .foregroundColor(color)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(color, lineWidth: 1)
        )
    }
}

struct ContentView: View {
    @StateObject var viewModel = PublicAPIViewModel()
    @State private var showFilter = false
    @State private var searchText = ""
    @State private var selectedTab = 0
    
    
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            dashboardView
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }
                .tag(0)
            
            listContentView
                .tabItem {
                    Label("List", systemImage: "list.dash")
                }
                .tag(1)
            
        }
    }
    
    var dashboardView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let featuredEntry = viewModel.allEntries.randomElement() {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Random API")
                                .font(.title)
                            
                            APIEntryCard(entry: featuredEntry, showCategory: true, fullWidth: true, onCategorySelected: { category in
                                viewModel.selectedCategory = category
                                viewModel.loadAPIEntries()
                                selectedTab = 1
                            })
                            .blur(radius: viewModel.isLoading ? 3 : 0)
                        }.padding(.bottom, 5)
                    }
                    
                    ForEach(viewModel.categories, id: \.self) { category in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(category)
                                .font(.title)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 10) {
                                    ForEach(viewModel.allEntries.filter { $0.category == category }, id: \.self) { entry in
                                        APIEntryCard(entry: entry, showCategory: false, descMaxLines: 2)
                                            .blur(radius: viewModel.isLoading ? 3 : 0)
                                    }
                                }.padding(5)
                            }
                        }
                    }
                    if viewModel.allEntries.isEmpty && !viewModel.isLoading {
                        Text("No results")
                            .font(.title)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("All public APIs (\(viewModel.allEntries.count))")
            .refreshable {
                viewModel.loadAPIEntries()
            }
        }
    }
    
    var listContentView: some View {
        NavigationView {
            List {
                ForEach(filteredEntries, id: \.self) { entry in
                    NavigationLink(destination: WebView(viewModel: WebViewViewModel(), urlString: entry.link ?? "")) {
                        APIEntryRow(apiEntry: entry, onCategorySelected: { category in
                            viewModel.selectedCategory = category
                            viewModel.loadAPIEntries()
                        })
                        .blur(radius: viewModel.isLoading ? 3 : 0)
                    }
                }
                if viewModel.entries.isEmpty && !viewModel.isLoading {
                    Text("No results")
                        .font(.title)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .refreshable {
                viewModel.loadAPIEntries()
            }
            .searchable(text: $searchText)
            .navigationTitle("Public APIs (\(viewModel.entries.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
        }.sheet(isPresented: $showFilter) {
            FilterView(isPresented: $showFilter, viewModel: viewModel)
        }
    }
    
    
    var filteredEntries: [Entry] {
        if searchText.isEmpty {
            return viewModel.entries
        } else {
            return viewModel.entries.filter { $0.name?.localizedCaseInsensitiveContains(searchText) ?? false }
        }
    }
    
    var filterButton: some View {
        Button(action: {
            showFilter.toggle()
        }) {
            HStack {
                Text("Filter")
                if viewModel.isFilterActive {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 5, y: -7)
                }
            }
        }
    }
}



//#Preview {
//    ContentView()
//}
