//
//  PublicAPIViewModelTests.swift
//  AMCEF-zadanieTests
//
//  Created by Marek Meriač on 24/04/2024.
//

import XCTest
import Combine
import CoreData
@testable import AMCEF_zadanie

class PublicAPIViewModelTests: XCTestCase {
    var viewModel: PublicAPIViewModel!
    var mockAPIService: MockAPIService!
    var cancellables: Set<AnyCancellable>!
    var container: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
        container = NSPersistentContainer.inMemoryContainer()
        viewModel = PublicAPIViewModel(apiService: mockAPIService, context: container.viewContext)
        cancellables = []
    }
    
    override func tearDown() {
        super.tearDown()
        container.viewContext.reset()
        container.persistentStoreCoordinator.performAndWait {
            for store in container.persistentStoreCoordinator.persistentStores {
                do {
                    try container.persistentStoreCoordinator.remove(store)
                } catch {
                    print("Error removing persistent store: \(error)")
                }
            }
        }
        viewModel = nil
        mockAPIService = nil
        container = nil
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    func testAllData_Success() {
        mockAPIService.mockEntries = [APIEntry(API: "AniAPI", Description: "Anime discovery, streaming & syncing with trackers", Auth: "OAuth", HTTPS: true, Cors: "Yes", Link: "https://aniapi.com/docs/", Category: "Anime")]
        mockAPIService.mockCategories = ["Anime"]
        
        let expectationEntries = XCTestExpectation(description: "Initial entries loaded")
        let expectationCategories = XCTestExpectation(description: "Initial categories loaded")
        
        viewModel.$allEntries
            .dropFirst()
            .sink { entries in
                XCTAssertEqual(entries.count, 1)
                XCTAssertEqual(entries.first?.name, "AniAPI")
                expectationEntries.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.$categories
            .dropFirst()
            .sink { categories in
                XCTAssertEqual(categories, ["Anime"])
                expectationCategories.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.loadAPIEntries()
        viewModel.loadAPICategories()
        
        wait(for: [expectationEntries, expectationCategories], timeout: 5.0)
    }
    
    func testLoadAPIEntries_WithFilters() {
        mockAPIService.mockEntries = [
            APIEntry(API: "Filtered API", Description: "Matches filter", Auth: "API Key", HTTPS: true, Cors: "Yes", Link: "https://filtered.com", Category: "Filtered"),
            APIEntry(API: "AdoptAPet", Description: "Resource to help get pets adopted", Auth: "apiKey", HTTPS: true, Cors: "Yes", Link: "https://www.adoptapet.com/public/apis/pet_list.html", Category: "Animals")
        ]
        
        let expectation = XCTestExpectation(description: "Filtered entries loaded")
        viewModel.apiQuery = "Filtered"
        viewModel.selectedCategory = "Filtered"
        
        viewModel.$entries
            .dropFirst()
            .sink { entries in
                XCTAssertEqual(entries.count, 1)
                XCTAssertEqual(entries.first?.name, "Filtered API")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.loadAPIEntries()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadAPIEntries_Error() {
        mockAPIService.shouldReturnError = true
        
        let expectation = XCTestExpectation(description: "Handle API loading error")
        
        viewModel.$entries
            .dropFirst()
            .sink { entries in
                XCTAssertTrue(entries.isEmpty)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.loadAPIEntries()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCoreDataOperations() {
        let mockEntries = [
            APIEntry(API: "AdoptAPet", Description: "Resource to help get pets adopted", Auth: "apiKey", HTTPS: true, Cors: "Yes", Link: "https://www.adoptapet.com/public/apis/pet_list.html", Category: "Animals"),
            APIEntry(API: "AniAPI", Description: "Anime discovery, streaming & syncing with trackers", Auth: "OAuth", HTTPS: true, Cors: "Yes", Link: "https://aniapi.com/docs/", Category: "Anime")
        ]
        
        viewModel.saveAPIEntriesToCoreData(mockEntries)
        viewModel.loadExistingEntries()
        
        XCTAssertEqual(viewModel.entries.count, mockEntries.count, "Number of saved entries should match the loaded entries")
        
        if let firstEntry = viewModel.entries.first {
            XCTAssertEqual(firstEntry.name, mockEntries.first?.API, "The first entry's API should match")
            XCTAssertEqual(firstEntry.desc, mockEntries.first?.Description, "The first entry's Description should match")
        }
        
        let deleteExpectation = XCTestExpectation(description: "Delete operation complete")
        viewModel.deleteExistingEntries {
            self.viewModel.loadExistingEntries()
            XCTAssertEqual(self.viewModel.entries.count, 0, "Entries should be deleted")
            deleteExpectation.fulfill()
        }
        
        wait(for: [deleteExpectation], timeout: 5.0)
    }
}

class MockAPIService: APIService {
    var mockEntries: [APIEntry] = []
    var mockCategories: [String] = []
    var shouldReturnError: Bool = false
    
    override func fetchAPIList(apiQuery: String?, descriptionQuery: String?, categoryQuery: String?) -> AnyPublisher<[APIEntry], Error> {
        if shouldReturnError {
            return Fail(error: NSError(domain: "", code: -1, userInfo: nil))
                .eraseToAnyPublisher()
        }
        return Just(mockEntries)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    override func fetchAPICategories() -> AnyPublisher<[String], Error> {
        if shouldReturnError {
            return Fail(error: NSError(domain: "", code: -1, userInfo: nil))
                .eraseToAnyPublisher()
        }
        return Just(mockCategories)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

extension NSPersistentContainer {
    static func inMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "AMCEF_zadanie")
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }
}




