//
//  APIServiceTests.swift
//  AMCEF-zadanieTests
//
//  Created by Marek Meriač on 24/04/2024.
//

import XCTest
import Combine
@testable import AMCEF_zadanie

class APIServiceTests: XCTestCase {
    var apiService: APIService!
    var mockSession: MockURLSession!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        apiService = APIService(session: mockSession)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        apiService = nil
        mockSession = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testFetchAPIListSuccess() {
        let jsonString = """
            [{
                "API": "AdoptAPet",
                "Auth": "apiKey",
                "CORS": "Yes",
                "Category": "Animals",
                "Description": "Resource to help get pets adopted",
                "HTTPS": true,
                "Link": "https://www.adoptapet.com/public/apis/pet_list.html"
            }]
            """
        mockSession.nextData = jsonString.data(using: .utf8)
        
        let expectation = XCTestExpectation(description: "Fetch API list completes")
        apiService.fetchAPIList(apiQuery: "", descriptionQuery: "", categoryQuery: "All")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("API call failed with error: \(error)")
                }
            }, receiveValue: { apiEntries in
                XCTAssertEqual(apiEntries.count, 1)
                XCTAssertEqual(apiEntries.first?.API, "AdoptAPet")
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchAPIListNetworkFailure() {
        let expectedError = URLError(.cannotLoadFromNetwork)
        mockSession.nextError = expectedError
        
        let expectation = XCTestExpectation(description: "Fetch API list handles network error")
        apiService.fetchAPIList(apiQuery: "", descriptionQuery: "", categoryQuery: "All")
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Expected failure, but got success")
                case .failure(let error):
                    if let urlError = error as? URLError {
                        XCTAssertEqual(urlError.code, expectedError.code, "Expected network not connected error")
                    } else {
                        XCTFail("Error should be a URLError")
                    }
                    expectation.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("Expected no return value on network error")
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchAPICategoriesSuccess() {
        let jsonString = """
        {
            "categories": ["Animals", "Anime", "Anti-Malware", "Art & Design"]
        }
        """
        mockSession.nextData = jsonString.data(using: .utf8)
        
        let expectation = XCTestExpectation(description: "Fetch categories completes")
        apiService.fetchAPICategories()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("API call failed with error: \(error)")
                }
            }, receiveValue: { categories in
                XCTAssertEqual(categories.count, 4)
                XCTAssertTrue(categories.contains("Animals"))
                XCTAssertTrue(categories.contains("Anime"))
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}

class MockURLSession: URLSessionProtocol {
    var nextData: Data?
    var nextError: Error?
    
    func customDataTaskPublisher(for url: URL) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        if let _ = nextError {
            return Fail(error: URLError(.cannotLoadFromNetwork))
                .eraseToAnyPublisher()
        }
        return Just((nextData ?? Data(), response as URLResponse))
            .setFailureType(to: URLError.self)
            .eraseToAnyPublisher()
    }
}
