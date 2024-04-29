//
//  APIService.swift
//  AMCEF-zadanie
//
//  Created by Marek Meriač on 15/04/2024.
//

import Foundation
import Combine

class APIService {
    var session: URLSessionProtocol
    
    // Možnosť nahradenia URLSession pre mock testy
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    func fetchAPIList(apiQuery: String?, descriptionQuery: String?, categoryQuery: String?) -> AnyPublisher<[APIEntry], Error> {
        //        let baseURL = URL(string: "https://api.publicapis.org/entries")!
        let baseURL = URL(string: "https://json-rest-api-79fe3-default-rtdb.europe-west1.firebasedatabase.app/entries.json")!
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        var queryItems = [URLQueryItem]()
        
        // Ak by bolo filtrovanie cez rest api
        /*if apiQuery != nil && !apiQuery!.isEmpty {
         if let encodedAPI = apiQuery!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
         queryItems.append(URLQueryItem(name: "api", value: encodedAPI))
         }
         }
         if descriptionQuery != nil && !descriptionQuery!.isEmpty {
         if let encodedDescription = descriptionQuery!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
         queryItems.append(URLQueryItem(name: "description", value: encodedDescription))
         }
         }
         if categoryQuery != nil && !categoryQuery!.isEmpty && categoryQuery != "All" {
         if let encodedCategory = categoryQuery!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
         queryItems.append(URLQueryItem(name: "category", value: encodedCategory))
         }
         }*/
        
        // Server-side sortovanie a filtrovanie podľa kategórie vo firebase
        if let categoryQuery = categoryQuery, !categoryQuery.isEmpty && categoryQuery != "All" {
            let encodedCategoryKey = "\"Category\""
            queryItems.append(URLQueryItem(name: "orderBy", value: encodedCategoryKey))
            queryItems.append(URLQueryItem(name: "equalTo", value: "\"\(categoryQuery)\""))
        }
        
        components?.queryItems = queryItems
        let finalURL = components?.url ?? baseURL
        
        print("Request to url: \(finalURL)")
        
        return session.customDataTaskPublisher(for: finalURL)
            .map(\.data)
            .tryMap { data in
                let entries = try JSONDecoder().decodeAPIEntries(from: data)
                return entries.sorted { $0.API.localizedCaseInsensitiveCompare($1.API) == .orderedAscending }
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func fetchAPICategories() -> AnyPublisher<[String], Error> {
        //        let url = URL(string: "https://api.publicapis.org/categories")!
        let url = URL(string: "https://json-rest-api-79fe3-default-rtdb.europe-west1.firebasedatabase.app/categories.json")!
        
        return session.customDataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: CategoriesResponse.self, decoder: JSONDecoder())
            .map { $0.categories }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

extension JSONDecoder {
    func decodeAPIEntries(from data: Data) throws -> [APIEntry] {
        do {
            let entries = try self.decode([APIEntry].self, from: data)
            return entries
        } catch {
            let dictionary = try self.decode([String: APIEntry].self, from: data)
            return Array(dictionary.values)
        }
    }
}

// Kvôli mock testom
protocol URLSessionProtocol {
    func customDataTaskPublisher(for url: URL) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
}

extension URLSession: URLSessionProtocol {
    func customDataTaskPublisher(for url: URL) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        return self.dataTaskPublisher(for: url)
            .mapError { $0 as URLError }
            .eraseToAnyPublisher()
    }
}
