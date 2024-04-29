//
//  Entries.swift
//  AMCEF-zadanie
//
//  Created by Marek Meriač on 15/04/2024.
//

import Foundation


struct APIEntry: Codable, Identifiable {
    var id = UUID()
    let API: String
    let Description: String
    let Auth: String?
    let HTTPS: Bool
    let Cors: String?
    let Link: String
    let Category: String
    
    enum CodingKeys: String, CodingKey {
        case API, Description, Auth, HTTPS, Cors, Link, Category
    }
    
    init(API: String, Description: String, Auth: String?, HTTPS: Bool, Cors: String?, Link: String, Category: String) {
        self.API = API
        self.Description = Description
        self.Auth = Auth
        self.HTTPS = HTTPS
        self.Cors = Cors
        self.Link = Link
        self.Category = Category
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        API = try container.decode(String.self, forKey: .API)
        Description = try container.decode(String.self, forKey: .Description)
        Auth = try container.decodeIfPresent(String.self, forKey: .Auth)
        HTTPS = try container.decode(Bool.self, forKey: .HTTPS)
        Cors = try container.decodeIfPresent(String.self, forKey: .Cors)
        Link = try container.decode(String.self, forKey: .Link)
        Category = try container.decode(String.self, forKey: .Category)
    }
}

struct CategoriesResponse: Codable {
    let categories: [String]
}
