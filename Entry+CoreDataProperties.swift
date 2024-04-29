//
//  Entry+CoreDataProperties.swift
//  AMCEF-zadanie
//
//  Created by Marek Meriač on 28/04/2024.
//
//

import Foundation
import CoreData


extension Entry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entry> {
        return NSFetchRequest<Entry>(entityName: "Entry")
    }

    @NSManaged public var auth: String?
    @NSManaged public var category: String?
    @NSManaged public var cors: String?
    @NSManaged public var desc: String?
    @NSManaged public var https: Bool
    @NSManaged public var id: UUID?
    @NSManaged public var link: String?
    @NSManaged public var name: String?

}

extension Entry : Identifiable {

}
