//
//  bloodpressureApp.swift
//  bloodpressure
//
//  Created by Bilaal Ishtiaq on 14/12/2025.
//

import SwiftUI
import SwiftData

@main
struct bloodpressureApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BPLog.self,
        ])
        
        // Explicitly name the store for reliable CloudKit mirroring
        let modelConfiguration = ModelConfiguration("bloodpressure", schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
