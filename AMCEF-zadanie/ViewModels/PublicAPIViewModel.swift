//
//  PublicAPIViewModel.swift
//  AMCEF-zadanie
//
//  Created by Marek Meriač on 15/04/2024.
//

import SwiftUI
import Combine
import CoreData

class PublicAPIViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var categories: [String] = []
    @Published var entries: [Entry] = [] // List entries
    
    // Používa len dashboard, vždy sa všetky zobrazujú podľa kategorií
    @Published var allEntries: [Entry] = []
    
    private var cancellables: Set<AnyCancellable> = []
    private var apiService: APIService
    private var context: NSManagedObjectContext
    
    // Filter
    @Published var apiQuery: String = ""
    @Published var descriptionQuery: String = ""
    @Published var selectedCategory: String = "All"
    
    var isFilterActive: Bool {
        return !apiQuery.isEmpty || !descriptionQuery.isEmpty || selectedCategory != "All"
    }
    
    // Možnosť nahradenia apiService a context pre mock testy
    init(apiService: APIService = APIService(), context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        print("Initializing PublicAPIViewModel")
        self.apiService = apiService
        self.context = context
        loadExistingEntries()
        loadInitialData()
    }
    
    // Fetch entries
    func loadAPIEntries() {
        isLoading = true
        print("Loading API entries with filters: API=\(apiQuery), Description=\(descriptionQuery), Category=\(selectedCategory)")
        
        apiService.fetchAPIList(apiQuery: apiQuery, descriptionQuery: descriptionQuery, categoryQuery: selectedCategory)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.isLoading = false
                        print("Successfully loaded API entries.")
                    case .failure(let error):
                        print("Failed to load API entries: \(error.localizedDescription)")
                        self?.isLoading = false
                    }
                },
                receiveValue: { [weak self] apiEntries in
                    print("Received \(apiEntries.count) API entries, filtering and saving..")
                    
                    // Refresh kategorií pri nepodarenom prvotnom potiahnutí
                    if (self?.categories.count)! < 1 {
                        self?.loadAPICategories()
                    }
                    
                    // Zmazanie všetkých entries z core data. Najjednoduchšie riešenie, update je lepšia možnosť..
                    self?.deleteExistingEntries {
                        let filteredEntries = self?.filterEntries(apiEntries, apiQuery: self?.apiQuery, descriptionQuery: self?.descriptionQuery) ?? []
                        self?.saveAPIEntriesToCoreData(filteredEntries)
                        
                        // Ak je filter, zobrazenie všetkých entries. Ak nie, zobrazenie max 40 entries
                        // Tým že sa má do core data ukladať max 40 entries, takto to viem obmedzovať, koľko, kedy zobraziť
                        if self?.isFilterActive == true {
                            self?.entries = self?.convertEntries(filteredEntries) ?? []
                        } else {
                            self?.loadExistingEntries()
                            
                            // Pre dashboard
                            self?.allEntries = self?.convertEntries(apiEntries) ?? []
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Fitrovanie podľa apiQuery a descriptionQuery aspoň takto v appke, kedže nemám REST API na filter týchto parametrov
    private func filterEntries(_ entries: [APIEntry], apiQuery: String?, descriptionQuery: String?) -> [APIEntry] {
        var filtered = entries
        if let query = apiQuery, !query.isEmpty {
            filtered = filtered.filter { $0.API.localizedCaseInsensitiveContains(query) }
        }
        if let query = descriptionQuery, !query.isEmpty {
            filtered = filtered.filter { $0.Description.localizedCaseInsensitiveContains(query) }
        }
        print("Filtered entries count: \(filtered.count)")
        return filtered
    }
    
    // Fetch categories
    func loadAPICategories() {
        apiService.fetchAPICategories()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to load categories: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] loadedCategories in
                    self?.categories = loadedCategories
                    print("Loaded \(loadedCategories.count) categories.")
                }
            )
            .store(in: &cancellables)
    }
    
    // Počiatočné potiahnutie všetkých potrebných dát
    func loadInitialData() {
        isLoading = true
        
        let apiEntriesPublisher = apiService.fetchAPIList(apiQuery: "", descriptionQuery: "", categoryQuery: "All")
        let categoriesPublisher = apiService.fetchAPICategories()
        
        Publishers.Zip(apiEntriesPublisher, categoriesPublisher)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("Error: \(error)")
                }
            }, receiveValue: { [weak self] (apiEntries, categories) in
                // Pre dashboard
                self?.allEntries = self?.convertEntries(apiEntries) ?? []
                
                // Pre list
                self?.deleteExistingEntries {
                    self?.saveAPIEntriesToCoreData(apiEntries)
                    self?.loadExistingEntries()
                }
                
                self?.categories = categories
            })
            .store(in: &cancellables)
    }
    
    func resetFilters() {
        print("Reseting filters.")
        apiQuery = ""
        descriptionQuery = ""
        selectedCategory = "All"
        loadAPIEntries()
    }
    
    // Uloženie entries do core data, max 40
    func saveAPIEntriesToCoreData(_ entries: [APIEntry]) {
        let limitedEntries = entries.prefix(40)
        print("Saving up to \(limitedEntries.count) entries to CoreData.")
        
        for entry in limitedEntries {
            let newEntry = Entry(context: context)
            newEntry.id = UUID()
            newEntry.name = entry.API
            newEntry.desc = entry.Description
            newEntry.auth = entry.Auth
            newEntry.https = entry.HTTPS
            newEntry.cors = entry.Cors
            newEntry.link = entry.Link
            newEntry.category = entry.Category
        }
        
        saveContext()
    }
    
    // Convert bez ukladania do core data - použité kvôli maximálnemu uloženiu 40 entries a pre dashboard. Takto zobrazujem všetky
    private func convertEntries(_ entries: [APIEntry]) -> [Entry] {
        print("Converting up to \(entries.count) entries to show.")
        var newEntries: [Entry] = []
        guard let entity = NSEntityDescription.entity(forEntityName: "Entry", in: context) else {
            fatalError("Error: No entity description found for Entry")
        }
        for entry in entries {
            let newEntry = Entry(entity: entity, insertInto: nil)
            newEntry.id = UUID()
            newEntry.name = entry.API
            newEntry.desc = entry.Description
            newEntry.auth = entry.Auth
            newEntry.https = entry.HTTPS
            newEntry.cors = entry.Cors
            newEntry.link = entry.Link
            newEntry.category = entry.Category
            newEntries.append(newEntry)
        }
        
        return newEntries
    }
    
    // Zmazanie všetkých entries z core data
    func deleteExistingEntries(completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Entry.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(batchDeleteRequest)
            try context.save()
            print("Existing entries deleted.")
            completion()
        } catch let error as NSError {
            print("Error deleting existing entries: \(error), \(error.userInfo)")
        }
    }
    
    // Načítanie všetkých entries z core data
    func loadExistingEntries() {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.name, ascending: true)]
        do {
            entries = try context.fetch(request)
            print("Loaded \(entries.count) entries from CoreData.")
        } catch {
            print("Error fetching items from CoreData: \(error)")
        }
    }
    
    
    private func saveContext() {
        do {
            try context.save()
            print("CoreData context saved successfully.")
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
}

