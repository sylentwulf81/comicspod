//
//  comicswriterApp.swift
//  comicswriter
//
//  Created by Damien Lavizzo on 3/15/25.
//

import SwiftUI
import SwiftData

@main
struct comicswriterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Series.self,
            Issue.self,
            Page.self,
            Panel.self,
            Character.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            SeriesListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
