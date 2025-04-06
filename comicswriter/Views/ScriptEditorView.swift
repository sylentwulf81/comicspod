import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// Create a typealias to help with Panel ID types
typealias PanelID = PersistentIdentifier

struct ScriptEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let issue: ComicIssue
    
    @State private var selectedPage: Page?
    @State private var selectedPanel: PanelID? // Keep this for potential future use
    @State private var showingPreviewSheet = false
    @State private var showAddPageIndicator = false
    @State private var showingSidebarOnMobile = false
    @State private var searchText = ""
    
    // Layout preferences
    @State private var showingPageListAsMiniature = true
    @State private var sidebarWidth: CGFloat = 260
    
    // Filtered pages based on search
    private var filteredPages: [Page] {
        if searchText.isEmpty {
            return issue.pages.sorted(by: { $0.pageNumber < $1.pageNumber })
        } else {
            return issue.pages.filter { page in
                // Search in page panel details or dialogue
                let pageNumberMatch = "\(page.pageNumber)".contains(searchText)
                let panelDetailsMatch = page.panels.contains { panel in
                    panel.details.localizedCaseInsensitiveContains(searchText)
                }
                let dialogueMatch = page.panels.contains { panel in
                    panel.characters.contains { character in
                        character.dialogue.localizedCaseInsensitiveContains(searchText) ||
                        character.name.localizedCaseInsensitiveContains(searchText)
                    }
                }
                
                return pageNumberMatch || panelDetailsMatch || dialogueMatch
            }.sorted(by: { $0.pageNumber < $1.pageNumber })
        }
    }
    
    @State private var showingCharacterSheet = false
    @State private var newCharacterName = ""
    @State private var showingDeletePanelAlert = false
    @State private var panelToDelete: Panel? = nil
    @State private var showingDeleteElementAlert = false
    @State private var elementToDelete: Character? = nil
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // SIDEBAR: Pages overview
                Group {
                    if geometry.size.width > 600 || showingSidebarOnMobile {
                        VStack(spacing: 0) {
                            // Sidebar header with search and add buttons
                            HStack {
                                // Toggle between thumbnail and list view
                                Button {
                                    withAnimation {
                                        showingPageListAsMiniature.toggle()
                                    }
                                } label: {
                                    Image(systemName: showingPageListAsMiniature ? "list.bullet" : "square.grid.2x2")
                                        .font(.system(size: 18))
                                        .contentShape(Rectangle()) // Ensure tap area is properly sized
                                        .padding(5) // Make tap target larger
                                }
                                .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle explicitly
                                .padding(.trailing, 4)
                                
                                // Search field
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14))
                                    
                                    TextField("Search pages", text: $searchText)
                                        .font(.system(size: 14))
                                    
                                    if !searchText.isEmpty {
                                        Button {
                                            searchText = ""
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                                .font(.system(size: 14))
                                                .contentShape(Rectangle()) // Ensure tap area is properly sized
                                                .padding(3) // Make tap target larger
                                        }
                                        .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle explicitly
                                    }
                                }
                                .padding(6)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                
                                Spacer()
                                
                                // Add page button
                                Button { 
                                    // Directly add page
                                    addNewPageToEnd() 
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                        .contentShape(Rectangle()) // Ensure tap area is properly sized
                                        .padding(5) // Make tap target larger
                                }
                                .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle explicitly
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                            
                            Divider()
                            
                            // Pages list
                            Group {
                                if showingPageListAsMiniature {
                                    // Grid view with page thumbnails
                                    PageThumbnailsView(
                                        pages: filteredPages,
                                        selectedPage: $selectedPage,
                                        showAddPageIndicator: $showAddPageIndicator,
                                        onAddPage: { addNewPageToEnd() }
                                    )
                                } else {
                                    // List view
                                    ScrollView {
                                        LazyVStack(spacing: 0) {
                                            ForEach(filteredPages) { page in
                                                PageListItemView(
                                                    page: page,
                                                    isSelected: page.persistentModelID == selectedPage?.persistentModelID
                                                )
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    print("Tapped on PageListItemView for page \(page.pageNumber)")
                                                    selectedPage = page
                                                }
                                                .padding(.vertical, 2) // Add more padding for better tap target
                                                
                                                Divider()
                                            }
                                            
                                            // "Add page" button at the end of the list
                                            Button { 
                                                // Directly add page
                                                addNewPageToEnd() 
                                            } label: {
                                                HStack {
                                                    Image(systemName: "plus.circle")
                                                        .foregroundColor(.blue)
                                                    
                                                    Text("Add Page")
                                                        .foregroundColor(.primary)
                                                    
                                                    Spacer()
                                                }
                                                .padding()
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle explicitly
                                        }
                                    }
                                    .clipped(antialiased: false) // Don't clip scroll content
                                }
                            }
                            .background(Color(.systemBackground))
                        }
                        .frame(width: sidebarWidth)
                        .background(Color(.systemBackground))
                        .overlay(
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 1)
                                .padding(.vertical, 0),
                            alignment: .trailing
                        )
                        // Gesture to resize sidebar
                        .overlay(
                            GeometryReader { geo in
                                // Reduce width to avoid interfering with content interactions
                                Color.gray.opacity(0.001) // Nearly invisible but still interactive
                                    .contentShape(Rectangle())
                                    .frame(width: 7)
                                    .position(x: geo.size.width - 3.5, y: geo.size.height / 2)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                let newWidth = sidebarWidth + value.translation.width
                                                if newWidth >= 150 && newWidth <= 400 {
                                                    sidebarWidth = newWidth
                                                }
                                            }
                                    )
                            },
                            alignment: .trailing
                        )
                        .allowsHitTesting(true) // Explicitly allow hit testing
                    }
                }
                
                // MAIN CONTENT: Single page editor
                ZStack {
                    // Background
                    Color(.systemGray6)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Main content toolbar (Keep this top bar)
                        HStack {
                           // ... Mobile sidebar toggle ...
                            
                           // ... Current page title ...
                            
                            Spacer()
                            
                            // Action buttons (Keep Add Page / Preview)
                            HStack(spacing: 16) {
                                Button { 
                                    // Directly add page
                                    addNewPageToEnd() 
                                } label: { Label("Add Page", systemImage: "plus.square") }
                                
                                Button { showingPreviewSheet = true } 
                                label: { Label("Preview", systemImage: "eye") }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .overlay(Divider(), alignment: .bottom)
                        
                        // <<< Re-insert Element Adding Toolbar >>>
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                Button {
                                    if let page = selectedPage { 
                                        let nextPanelNumber = (page.panels.map { $0.panelNumber }.max() ?? 0) + 1
                                        addNewPanel(to: page, panelNumber: nextPanelNumber)
                                    }
                                } label: { 
                                    VStack {
                                        Image(systemName: "rectangle.split.3x1")
                                            .font(.system(size: 16))
                                        Text("Panel")
                                            .font(.caption)
                                    }
                                }
                                .contentShape(Rectangle())
                                .disabled(selectedPage == nil) // Disable if no page selected
                                
                                Button {
                                    if selectedPanel != nil {
                                        newCharacterName = ""
                                        showingCharacterSheet = true
                                    }
                                } label: { 
                                    VStack {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 16))
                                        Text("Character")
                                            .font(.caption)
                                    }
                                }
                                .disabled(selectedPanel == nil)
                                .contentShape(Rectangle())
                                
                                Button {
                                    if let page = selectedPage, let panelID = selectedPanel, 
                                       let panel = page.panels.first(where: { $0.persistentModelID == panelID }) {
                                        let caption = Character(name: "CAPTION", panel: panel)
                                        caption.createdAt = Date() 
                                        modelContext.insert(caption)
                                        panel.characters.append(caption)
                                    }
                                } label: { 
                                    VStack {
                                        Image(systemName: "text.quote")
                                            .font(.system(size: 16))
                                        Text("Caption")
                                            .font(.caption)
                                    }
                                }
                                .disabled(selectedPanel == nil)
                                .contentShape(Rectangle())
                                
                                Button {
                                    if let page = selectedPage, let panelID = selectedPanel,
                                       let panel = page.panels.first(where: { $0.persistentModelID == panelID }) {
                                        let sfx = Character(name: "SFX", panel: panel)
                                        sfx.createdAt = Date()
                                        modelContext.insert(sfx)
                                        panel.characters.append(sfx)
                                    }
                                } label: { 
                                    VStack {
                                        Image(systemName: "waveform")
                                            .font(.system(size: 16))
                                        Text("SFX")
                                            .font(.caption)
                                    }
                                }
                                .disabled(selectedPanel == nil)
                                .contentShape(Rectangle())
                                
                                Divider().frame(height: 30)
                                
                                Button {
                                    duplicateSelectedPanel(in: selectedPage)
                                } label: { 
                                    VStack {
                                        Image(systemName: "plus.square.on.square")
                                            .font(.system(size: 16))
                                        Text("Duplicate")
                                            .font(.caption)
                                    }
                                }
                                .disabled(selectedPanel == nil)
                                .contentShape(Rectangle())
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .allowsHitTesting(true) // Keep this from previous attempt
                        }
                        .background(Color(.systemGray6))
                        .padding(.bottom, 4)
                        // <<< End Re-inserted Toolbar >>>
                        
                        // Main editing area
                        if let selectedPage = selectedPage { 
                            // Ensure this is the ONLY content in this block
                             ScrollView { 
                                 FormattedScriptPageView(
                                     page: selectedPage, 
                                     selectedPanel: $selectedPanel,
                                     onDeletePanel: { panel in
                                         panelToDelete = panel
                                         showingDeletePanelAlert = true
                                     },
                                     onDeleteElement: { character in
                                         elementToDelete = character
                                         showingDeleteElementAlert = true
                                     },
                                     onCommandAddPage: { 
                                         // Call the existing function to add a page
                                         addNewPageToEnd() 
                                     },
                                     onCommandAddPanel: { pageContext in
                                         // Call the existing function to add a panel
                                         let nextPanelNumber = (pageContext.panels.map { $0.panelNumber }.max() ?? 0) + 1
                                         addNewPanel(to: pageContext, panelNumber: nextPanelNumber)
                                     },
                                     onCommandAddCharacter: { name, panelContext in
                                         // Call the existing function to add a character
                                         addCharacter(name: name.capitalized, to: panelContext.page)
                                         // TODO: Optionally shift focus to the new character's dialogue field
                                     }
                                 )
                                     // Apply width constraints if needed, e.g., based on GeometryReader
                                     // .frame(width: preferredWidth) 
                                     .padding(.bottom, 40) 
                                     .frame(maxWidth: .infinity) 
                                     .padding(.vertical, 20) 
                             }
                             .id("EditorForPage_\(selectedPage.id)")
                             
                        } else {
                             // ... existing placeholder view for when no page is selected ...
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(issue.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPreviewSheet) {
            // Keep ScriptPreviewView functionality
            ScriptPreviewView(issue: issue)
        }
        .sheet(isPresented: $showingCharacterSheet) {
            CharacterNameSheet(
                isPresented: $showingCharacterSheet,
                characterName: $newCharacterName,
                onSave: { name in
                    addCharacter(name: name, to: selectedPage)
                },
                existingCharacters: getUniqueCharacterNames(for: selectedPage)
            )
        }
        .alert("Delete Panel?", isPresented: $showingDeletePanelAlert, presenting: panelToDelete) { panelToDelete in
            Button("Delete", role: .destructive) {
                deletePanel(panelToDelete)
            }
            Button("Cancel", role: .cancel) { }
        } message: { panelToDelete in
            Text("Are you sure you want to delete Panel \(panelToDelete.panelNumber)? This cannot be undone.")
        }
        .alert("Delete Element?", isPresented: $showingDeleteElementAlert, presenting: elementToDelete) { elementToDelete in
            Button("Delete", role: .destructive) {
                deleteCharacterElement(elementToDelete)
            }
            Button("Cancel", role: .cancel) { }
        } message: { elementToDelete in
            Text("Are you sure you want to delete this \(elementToDelete.name.lowercased()) element?")
        }
        .onAppear {
            // Select the first page by default, if one exists
            if selectedPage == nil && !issue.pages.isEmpty {
                selectedPage = issue.pages.sorted(by: { $0.pageNumber < $1.pageNumber }).first
            }
        }
    }
    
    private func selectPreviousPage() {
        guard let currentPage = selectedPage else { return }
        
        // Find the page with the number right before the current one
        let sortedPages = issue.pages.sorted(by: { $0.pageNumber < $1.pageNumber })
        if let index = sortedPages.firstIndex(where: { $0.persistentModelID == currentPage.persistentModelID }),
           index > 0 {
            selectedPage = sortedPages[index - 1]
            selectedPanel = nil
        }
    }
    
    private func selectNextPage() {
        guard let currentPage = selectedPage else { return }
        
        // Find the page with the number right after the current one
        let sortedPages = issue.pages.sorted(by: { $0.pageNumber < $1.pageNumber })
        if let index = sortedPages.firstIndex(where: { $0.persistentModelID == currentPage.persistentModelID }),
           index < sortedPages.count - 1 {
            selectedPage = sortedPages[index + 1]
            selectedPanel = nil
        }
    }

    private func addNewPanel(to page: Page?, panelNumber: Int) {
        guard let page = page else { return }
        let newPanel = Panel(panelNumber: panelNumber, page: page)
        modelContext.insert(newPanel)
        page.panels.append(newPanel)
        page.updatedAt = Date()
        selectedPanel = newPanel.persistentModelID 
    }
    
    private func duplicateSelectedPanel(in page: Page?) {
        guard let page = page, 
              let panelID = selectedPanel,
              let panelToDuplicate = page.panels.first(where: { $0.persistentModelID == panelID }) else { return }
              
        let nextPanelNumber = (page.panels.map { $0.panelNumber }.max() ?? 0) + 1
        
        let newPanel = Panel(
            panelNumber: nextPanelNumber,
            details: panelToDuplicate.details,
            page: page
        )
        modelContext.insert(newPanel)
        page.panels.append(newPanel)
        
        for character in panelToDuplicate.characters {
            let newCharacter = Character(
                name: character.name, 
                dialogue: character.dialogue,
                panel: newPanel
            )
            modelContext.insert(newCharacter)
            newPanel.characters.append(newCharacter)
        }
        
        page.updatedAt = Date()
        selectedPanel = newPanel.persistentModelID
    }

    private func addCharacter(name: String, to page: Page?) {
        guard let page = page, 
              !name.isEmpty, let panelID = selectedPanel, 
              let targetPanel = page.panels.first(where: { $0.persistentModelID == panelID }) else { return }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newCharacter = Character(name: trimmedName)
        newCharacter.panel = targetPanel
        newCharacter.createdAt = Date() 
        modelContext.insert(newCharacter)
        targetPanel.characters.append(newCharacter)
    }
    
    private func getUniqueCharacterNames(for page: Page?) -> [String] {
        guard let page = page, let issue = page.issue else { return [] }
        var characterLastUsed: [String: Date] = [:]
        for p in issue.pages { 
            for panel in p.panels {
                for character in panel.characters {
                    if character.name != "CAPTION" && character.name != "SFX" {
                        if let existingDate = characterLastUsed[character.name], existingDate > character.createdAt {
                        } else {
                            characterLastUsed[character.name] = character.createdAt
                        }
                    }
                }
            }
        }
        return characterLastUsed.sorted { $0.value > $1.value }.map { $0.key }
    }

    private func deletePanel(_ panel: Panel) {
        guard let page = panel.page else { return }
        
        // Deselect if this panel was selected
        if selectedPanel == panel.persistentModelID {
            selectedPanel = nil
        }
        
        let deletedPanelNumber = panel.panelNumber
        
        // Delete the panel from context first (handles cascading deletes of children)
        modelContext.delete(panel)
        
        // Remove from page's array (might be redundant if relationship handles it, but safe)
        page.panels.removeAll { $0.id == panel.id }
        
        // Renumber subsequent panels
        for p in page.panels where p.panelNumber > deletedPanelNumber {
            p.panelNumber -= 1
        }
        
        // Sort panels in memory (important if relying on sorted array elsewhere)
        page.panels.sort { $0.panelNumber < $1.panelNumber }
        
        page.updatedAt = Date()
        print("Deleted Panel \(deletedPanelNumber)")
    }

    private func deleteCharacterElement(_ character: Character) {
        guard let panel = character.panel else { return }
        print("Deleting element: \(character.name) - \(character.dialogue.prefix(10))...")
        // Delete from context
        modelContext.delete(character)
        // Remove from panel's array (may be redundant)
        panel.characters.removeAll { $0.id == character.id }
        // No renumbering needed for elements, rely on createdAt sorting
        panel.page?.updatedAt = Date() // Update parent page timestamp
    }

    // --- Add New Helper Function --- 
    private func addNewPageToEnd() {
        let nextPageNumber = (issue.pages.map { $0.pageNumber }.max() ?? 0) + 1
        let newPage = Page(pageNumber: nextPageNumber, issue: issue)
        modelContext.insert(newPage)
        // Ensure the page is added to the issue's relationship
        issue.pages.append(newPage)
        
        // Create an initial panel
        let newPanel = Panel(panelNumber: 1, page: newPage)
        modelContext.insert(newPanel)
        // Ensure the panel is added to the page's relationship
        newPage.panels.append(newPanel)
        
        // Update timestamp
        issue.updatedAt = Date()
        
        // Select the new page and its panel
        selectedPage = newPage
        selectedPanel = newPanel.persistentModelID
        
        // Trigger indicator briefly (optional)
        showAddPageIndicator = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showAddPageIndicator = false
        }
        print("Added Page \(nextPageNumber) directly.")
    }
    // --- End New Helper Function --- 
}

struct ScriptOutlineView: View {
    @Environment(\.modelContext) private var modelContext
    let issue: ComicIssue
    @Binding var selectedPage: Page?
    @Binding var selectedPanel: PanelID?
    
    var body: some View {
        List {
            ForEach(issue.pages.sorted(by: { $0.pageNumber < $1.pageNumber })) { page in
                OutlinePageRow(
                    page: page,
                    isSelected: selectedPage?.persistentModelID == page.persistentModelID,
                    selectedPanel: $selectedPanel,
                    selectedPage: $selectedPage
                )
                // Remove the onTapGesture here since we added it to the HStack inside OutlinePageRow
                .contentShape(Rectangle())
                .padding(.vertical, 4)
            }
            
            Button(action: { 
                // Directly add a new page without confirmation
                let nextPageNumber = (issue.pages.map { $0.pageNumber }.max() ?? 0) + 1
                addNewPage(pageNumber: nextPageNumber)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Add Page")
                        .font(.system(size: 15, weight: .medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .listStyle(SidebarListStyle())
    }
    
    private func addNewPage(pageNumber: Int) {
        let newPage = Page(pageNumber: pageNumber, issue: issue)
        modelContext.insert(newPage)
        issue.pages.append(newPage)
        issue.updatedAt = Date()
        selectedPage = newPage
        
        // Add an initial panel
        let newPanel = Panel(panelNumber: 1, page: newPage)
        modelContext.insert(newPanel)
        newPage.panels.append(newPanel)
        selectedPanel = newPanel.persistentModelID
    }
}

struct OutlinePageRow: View {
    @Environment(\.modelContext) private var modelContext
    let page: Page
    let isSelected: Bool
    @Binding var selectedPanel: PanelID?
    @Binding var selectedPage: Page?
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Page number
            Text("\(page.pageNumber)")
                .font(.system(.headline, design: .monospaced))
                .frame(width: 30)
            
            // Page info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Page \(page.pageNumber)")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(page.panels.count) Panels")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Brief panel count
                if !page.panels.isEmpty {
                    Text(panelSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            isSelected ? Color.blue.opacity(0.1) :
                (isHovering ? Color(.systemGray6) : Color.clear)
        )
        .contentShape(Rectangle()) // Ensure the entire view is tappable
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            print("Tapped on Page \(page.pageNumber) row header")
            if selectedPage?.persistentModelID != page.persistentModelID {
                selectedPage = page
            }
        }
    }
    
    // Create a brief summary of panels
    private var panelSummary: String {
        let characterCounts = page.panels.map { $0.characters.count }
        let totalCharacters = characterCounts.reduce(0, +)
        
        if totalCharacters > 0 {
            let dialogueCount = page.panels.reduce(0) { count, panel in
                count + panel.characters.filter { !$0.dialogue.isEmpty }.count
            }
            
            return "\(totalCharacters) characters, \(dialogueCount) dialogue"
        } else {
            return "No characters"
        }
    }
}

// Page thumbnails view for sidebar
struct PageThumbnailsView: View {
    let pages: [Page]
    @Binding var selectedPage: Page?
    @Binding var showAddPageIndicator: Bool
    var onAddPage: () -> Void
    
    // Layout settings
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 10)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(pages) { page in
                    PageThumbnailItem(
                        page: page,
                        isSelected: page.persistentModelID == selectedPage?.persistentModelID,
                        isHighlighted: showAddPageIndicator && page.persistentModelID == pages.last?.persistentModelID
                    )
                    .contentShape(Rectangle()) // Ensure the entire item is tappable
                    .onTapGesture {
                        print("Tapped on page \(page.pageNumber)")
                        withAnimation {
                            selectedPage = page
                        }
                    }
                    .id("page-\(page.persistentModelID.hashValue)") // Unique stable ID
                }
                
                // Add page button
                Button {
                    onAddPage()
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        
                        Text("Add Page")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(height: 130)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                    )
                    .contentShape(Rectangle()) // Ensure the button is tappable
                }
                .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle explicitly
                .padding(5) // Add padding for better tap target
            }
            .padding(12)
        }
        .clipped(antialiased: false) // Prevent clipping that might interfere with touch
        .allowsHitTesting(true) // Explicitly allow hit testing
    }
}

// Individual page thumbnail
struct PageThumbnailItem: View {
    let page: Page
    let isSelected: Bool
    let isHighlighted: Bool
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Page preview
            ZStack(alignment: .topLeading) {
                // Page background
                Rectangle()
                    .fill(Color(.systemGray6))
                
                // Page content preview - simple representation of panels
                VStack(spacing: 6) {
                    ForEach(page.panels.prefix(3).sorted(by: { $0.panelNumber < $1.panelNumber })) { panel in
                        PanelThumbnailPreview(panel: panel)
                    }
                    
                    if page.panels.count > 3 {
                        Text("+ \(page.panels.count - 3) more")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 2)
                    }
                }
                .padding(6)
                
                // Page number badge
                Text("\(page.pageNumber)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Circle().fill(Color.black.opacity(0.7)))
                    .offset(x: 6, y: 6)
            }
            .aspectRatio(3/4, contentMode: .fit)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.blue : (isHovering ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)),
                            lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isHighlighted ? 1.05 : 1.0)
            .shadow(color: isHighlighted ? Color.blue.opacity(0.4) : Color.clear, radius: isHighlighted ? 5 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
            
            // Page info
            HStack {
                Text("Page \(page.pageNumber)")
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(page.panels.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
            .padding(.horizontal, 2)
        }
        .padding(4)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle()) // Ensure the entire item is tappable
        .onHover { hovering in
            isHovering = hovering
        }
        .buttonStyle(PlainButtonStyle()) // Enable proper button interaction
        .allowsHitTesting(true) // Explicitly allow hit testing
    }
}

// Simple panel preview for thumbnails
struct PanelThumbnailPreview: View {
    let panel: Panel
    
    var body: some View {
        HStack(spacing: 4) {
            // Simple representation of characters
            VStack(alignment: .leading, spacing: 2) {
                ForEach(panel.characters.prefix(2).sorted(by: { $0.createdAt < $1.createdAt })) { character in
                    HStack(spacing: 2) {
                        Circle()
                            .fill(getCharacterColor(name: character.name))
                            .frame(width: 5, height: 5)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                if panel.characters.count > 2 {
                    Text("+\(panel.characters.count - 2)")
                        .font(.system(size: 7))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 30)
        .frame(maxWidth: .infinity)
        .padding(4)
        .background(Color.white.opacity(0.8))
        .cornerRadius(4)
    }
    
    // Get consistent color based on character name
    private func getCharacterColor(name: String) -> Color {
        // Simple hash function for consistent colors
        let hash = abs(name.hashValue)
        
        // Predefined colors for common types
        if name == "CAPTION" {
            return .blue
        } else if name == "SFX" {
            return .orange
        } else {
            // Generate color from hash
            let predefinedColors: [Color] = [.red, .green, .blue, .purple, .orange, .pink]
            return predefinedColors[hash % predefinedColors.count]
        }
    }
}

// List item view for pages
struct PageListItemView: View {
    let page: Page
    let isSelected: Bool
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Page number
            Text("\(page.pageNumber)")
                .font(.system(.headline, design: .monospaced))
                .frame(width: 30)
            
            // Page info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Page \(page.pageNumber)")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(page.panels.count) Panels")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Brief panel count
                if !page.panels.isEmpty {
                    Text(panelSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            isSelected ? Color.blue.opacity(0.1) :
                (isHovering ? Color(.systemGray6) : Color.clear)
        )
        .contentShape(Rectangle()) // Ensure the entire view is tappable
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    // Create a brief summary of panels
    private var panelSummary: String {
        let characterCounts = page.panels.map { $0.characters.count }
        let totalCharacters = characterCounts.reduce(0, +)
        
        if totalCharacters > 0 {
            let dialogueCount = page.panels.reduce(0) { count, panel in
                count + panel.characters.filter { !$0.dialogue.isEmpty }.count
            }
            
            return "\(totalCharacters) characters, \(dialogueCount) dialogue"
        } else {
            return "No characters"
        }
    }
}

// Sheet for adding a new page
/*
struct AddPageSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let issue: ComicIssue
    let onPageAdded: (Page) -> Void
    
    @State private var pageNumber: Int
    
    init(issue: ComicIssue, onPageAdded: @escaping (Page) -> Void) {
        self.issue = issue
        self.onPageAdded = onPageAdded
        
        // Set default page number to the next available number
        let nextNumber = (issue.pages.map { $0.pageNumber }.max() ?? 0) + 1
        self._pageNumber = State(initialValue: nextNumber)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Page Details") {
                    Stepper("Page #\(pageNumber)", value: $pageNumber, in: 1...1000)
                }
                
                Section {
                    Button("Add Page") {
                        addPage()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add New Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addPage()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func addPage() {
        // Check if the requested page number already exists
        if issue.pages.contains(where: { $0.pageNumber == pageNumber }) {
            // If the page number exists, shift all pages with this or higher number
            let pagesToShift = issue.pages.filter { $0.pageNumber >= pageNumber }
            for page in pagesToShift.sorted(by: { $0.pageNumber > $1.pageNumber }) {
                page.pageNumber += 1
            }
        }
        
        // Create the new page
        let newPage = Page(pageNumber: pageNumber, issue: issue)
        modelContext.insert(newPage)
        issue.pages.append(newPage)
        
        // Create an initial panel
        let newPanel = Panel(panelNumber: 1, page: newPage)
        modelContext.insert(newPanel)
        newPage.panels.append(newPanel)
        
        // Update timestamp
        issue.updatedAt = Date()
        
        // Notify parent
        onPageAdded(newPage)
        
        // Dismiss sheet
        dismiss()
    }
}
*/

// PDF page view for rendering in the PDF
struct PagePDFView: View {
    let page: Page
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("PAGE \(page.pageNumber)")
                .font(.system(size: 18, weight: .bold))
                .padding(.bottom, 8)
            
            ForEach(page.panels.sorted(by: { $0.panelNumber < $1.panelNumber })) { panel in
                VStack(alignment: .leading, spacing: 10) {
                    Text("PANEL \(panel.panelNumber)")
                        .font(.system(size: 16, weight: .bold))
                    
                    if !panel.details.isEmpty {
                        Text(panel.details)
                            .font(.body)
                            .padding(.leading, 16)
                            .padding(.bottom, 4)
                    }
                    
                    if !panel.characters.isEmpty {
                        ForEach(panel.characters.sorted(by: { $0.createdAt < $1.createdAt })) { character in
                            VStack(alignment: .leading, spacing: 4) {
                                if character.name == "CAPTION" {
                                    Text("CAPTION:")
                                        .font(.system(size: 14, weight: .semibold))
                                        .padding(.top, 4)
                                    
                                    Text(character.dialogue)
                                        .font(.body)
                                        .italic()
                                        .padding(.leading, 16)
                                } else if character.name == "SFX" {
                                    Text("SFX:")
                                        .font(.system(size: 14, weight: .semibold))
                                        .padding(.top, 4)
                                    
                                    Text(character.dialogue.uppercased())
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.leading, 16)
                                } else {
                                    Text("\(character.name):")
                                        .font(.system(size: 14, weight: .semibold))
                                        .padding(.top, 4)
                                    
                                    Text(character.dialogue)
                                        .font(.body)
                                        .padding(.leading, 16)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
            }
            
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Series.self, ComicIssue.self, Page.self, Panel.self, Character.self, configurations: config)
    
    let previewSeries = Series(title: "Example Series")
    let previewIssue = ComicIssue(title: "First Issue", issueNumber: 1, series: previewSeries)
    let previewPage = Page(pageNumber: 1, issue: previewIssue)
    let previewPanel = Panel(panelNumber: 1, details: "Our hero stands triumphantly on a rooftop.", page: previewPage)
    let previewCharacter = Character(name: "Hero", dialogue: "I have saved the day once again!", panel: previewPanel)
    
    container.mainContext.insert(previewSeries)
    container.mainContext.insert(previewIssue)
    container.mainContext.insert(previewPage)
    container.mainContext.insert(previewPanel)
    container.mainContext.insert(previewCharacter)
    
    previewSeries.issues.append(previewIssue)
    previewIssue.pages.append(previewPage)
    previewPage.panels.append(previewPanel)
    previewPanel.characters.append(previewCharacter)
    
    return NavigationStack {
        ScriptEditorView(issue: previewIssue)
    }
    .modelContainer(container)
}

// Add the AddPanelSheet that was referenced but not defined
struct AddPanelSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let page: Page
    @Binding var selectedPanelID: PanelID?
    
    @State private var panelNumber: Int
    
    init(page: Page, selectedPanelID: Binding<PanelID?>) {
        self.page = page
        self._selectedPanelID = selectedPanelID
        
        // Set default panel number to the next available number
        let nextNumber = (page.panels.map { $0.panelNumber }.max() ?? 0) + 1
        self._panelNumber = State(initialValue: nextNumber)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Panel Details") {
                    Stepper("Panel #\(panelNumber)", value: $panelNumber, in: 1...100)
                }
                
                Section {
                    Button("Add Panel") {
                        addPanel()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add New Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addPanel()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func addPanel() {
        // Check if the requested panel number already exists
        if page.panels.contains(where: { $0.panelNumber == panelNumber }) {
            // If the panel number exists, shift all panels with this or higher number
            let panelsToShift = page.panels.filter { $0.panelNumber >= panelNumber }
            for panel in panelsToShift.sorted(by: { $0.panelNumber > $1.panelNumber }) {
                panel.panelNumber += 1
            }
        }
        
        // Create the new panel
        let newPanel = Panel(panelNumber: panelNumber, page: page)
        modelContext.insert(newPanel)
        page.panels.append(newPanel)
        
        // Update timestamp
        page.updatedAt = Date()
        
        // Select the new panel
        selectedPanelID = newPanel.persistentModelID
        
        // Dismiss sheet
        dismiss()
    }
}

// MARK: - New Script Editor View (Traditional Format)

/* 
struct FormattedScriptPageView: View {
    // ... entire struct definition ...
}
*/

// MARK: - Helper TextEditor View (Reusable)

/*
struct ScriptTextEditor: View {
    // ... entire struct definition ...
}
*/

// --- Ensure CharacterNameSheet struct definition exists --- 
struct CharacterNameSheet: View {
    @Binding var isPresented: Bool
    @Binding var characterName: String
    var onSave: (String) -> Void
    var existingCharacters: [String] = [] // New parameter for existing character names
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Character Name") {
                    TextField("Name", text: $characterName)
                        .autocapitalization(.words)
                }
                
                // Only show this section if there are existing characters
                if !existingCharacters.isEmpty {
                    Section("Existing Characters") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(existingCharacters, id: \.self) { name in
                                    Button(action: {
                                        characterName = name
                                    }) {
                                        Text(name)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color.blue.opacity(0.1))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section {
                    Button("Add Character") {
                        if !characterName.isEmpty {
                            onSave(characterName)
                            isPresented = false
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(characterName.isEmpty)
                }
            }
            .navigationTitle("New Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// --- Ensure CharacterDialogueEditor struct is commented out or removed --- 
/*
struct CharacterDialogueEditor: View { ... }
*/

// --- Ensure ScriptPreviewView struct definition exists --- 
struct ScriptPreviewView: View {
    let issue: ComicIssue 
    
    var body: some View {
        Text("Script Preview Placeholder") 
            .navigationTitle("Preview") // Add a title for context
    }
}

// ... Other View Structs ...
