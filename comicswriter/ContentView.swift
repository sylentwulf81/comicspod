//
//  ContentView.swift
//  comicswriter
//
//  Created by Damien Lavizzo on 3/15/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        SeriesListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Series.self, Issue.self, Page.self, Panel.self, Character.self], inMemory: true)
}
