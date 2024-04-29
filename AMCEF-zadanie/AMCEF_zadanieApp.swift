//
//  AMCEF_zadanieApp.swift
//  AMCEF-zadanie
//
//  Created by Marek Meriač on 15/04/2024.
//

import SwiftUI

@main
struct AMCEF_zadanieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
