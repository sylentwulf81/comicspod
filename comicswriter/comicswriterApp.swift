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
        do {
            // Define the model schema with versioning
            let schema = Schema([
                Series.self,
                ComicIssue.self,
                Page.self,
                Panel.self,
                Character.self
            ])
            
            // Create a configuration with migration options
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            return try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            // Handle model container creation error
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
