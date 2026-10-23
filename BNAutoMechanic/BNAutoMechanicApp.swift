//
//  BNAutoMechanicApp.swift
//  BNAutoMechanic
//
//  Created by TeaLover on 22/10/2026.
//

import SwiftUI
import CoreData

@main
struct BNAutoMechanicApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
