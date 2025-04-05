import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ScriptEditorView: View {
    @Environment(\.modelContext) private var modelContext
    let issue: ComicIssue
    @State private var selectedPage: Page?
    @State private var selectedPanel: Panel?
    @State private var showingScriptPreview = false
    @State private var showingSettingsSheet = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Left sidebar - Page outline
            ScriptOutlineView(
                issue: issue,
                selectedPage: $selectedPage,
                selectedPanel: $selectedPanel
            )
            .frame(width: 220)
            .background(Color(.systemGray6))
            
            // Main editing area
            if let selectedPage = selectedPage {
                PageEditorView(page: selectedPage, selectedPanel: $selectedPanel)
            } else {
                Text("Select a page to edit or create a new one")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
        }
        .navigationTitle("\(issue.title) - Issue #\(issue.issueNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingSettingsSheet = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingScriptPreview = true
                } label: {
                    Label("Preview", systemImage: "doc.text.magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $showingScriptPreview) {
            ScriptPreviewView(issue: issue)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView(issue: issue)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            // Select the first page by default if available
            if let firstPage = issue.pages.first {
                selectedPage = firstPage
                selectedPanel = firstPage.panels.first
            }
        }
    }
}

struct ScriptOutlineView: View {
    @Environment(\.modelContext) private var modelContext
    let issue: ComicIssue
    @Binding var selectedPage: Page?
    @Binding var selectedPanel: Panel?
    
    var body: some View {
        List {
            ForEach(issue.pages.sorted(by: { $0.pageNumber < $1.pageNumber })) { page in
                OutlinePageRow(
                    page: page,
                    isSelected: selectedPage?.id == page.id,
                    selectedPanel: $selectedPanel,
                    selectedPage: $selectedPage
                )
                .onTapGesture {
                    selectedPage = page
                }
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
        selectedPanel = newPanel
    }
}

struct OutlinePageRow: View {
    @Environment(\.modelContext) private var modelContext
    let page: Page
    let isSelected: Bool
    @Binding var selectedPanel: Panel?
    @Binding var selectedPage: Page?
    @State private var isExpanded = true
    @State private var showingDeletePageConfirmation = false
    @State private var panelToDelete: Panel? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isExpanded.toggle()
                    }
                
                Text("Page \(page.pageNumber)")
                    .font(.system(size: 15))
                    .fontWeight(isSelected ? .bold : .medium)
                
                Spacer()
                
                Menu {
                    Button("Add Panel") {
                        let nextPanelNumber = (page.panels.map { $0.panelNumber }.max() ?? 0) + 1
                        addNewPanel(panelNumber: nextPanelNumber)
                    }
                    
                    Divider()
                    
                    Button("Delete Page", role: .destructive) {
                        showingDeletePageConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(page.panels.sorted(by: { $0.panelNumber < $1.panelNumber })) { panel in
                        HStack {
                            Text("Panel \(panel.panelNumber)")
                                .font(.system(size: 14))
                                .padding(.leading, 24)
                                .padding(.vertical, 6)
                                .foregroundColor(selectedPanel?.id == panel.id ? .blue : .primary)
                            
                            Spacer()
                            
                            Button {
                                // Set the panel to delete and show confirmation
                                panelToDelete = panel
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .frame(width: 24, height: 24)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 4)
                        .background(selectedPanel?.id == panel.id ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // First ensure the page is selected
                            if page.id != selectedPage?.id {
                                selectedPage = page
                            }
                            // Then select the panel with a slight delay to ensure page selection completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                selectedPanel = panel
                            }
                            
                            // Add haptic feedback for confirmation
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    }
                    
                    Button {
                        let nextPanelNumber = (page.panels.map { $0.panelNumber }.max() ?? 0) + 1
                        addNewPanel(panelNumber: nextPanelNumber)
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                            Text("Add Panel")
                                .font(.system(size: 14))
                        }
                        .padding(.leading, 24)
                        .padding(.vertical, 6)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.vertical, 2)
        // Add alert for panel deletion
        .alert("Delete Panel", isPresented: Binding(
            get: { panelToDelete != nil },
            set: { if !$0 { panelToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let panel = panelToDelete {
                    deletePanel(panel)
                }
                panelToDelete = nil
            }
            
            Button("Cancel", role: .cancel) {
                panelToDelete = nil
            }
        } message: {
            if let panel = panelToDelete {
                Text("Are you sure you want to delete Panel \(panel.panelNumber)? This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete this panel? This action cannot be undone.")
            }
        }
        // Add alert for page deletion
        .alert("Delete Page", isPresented: $showingDeletePageConfirmation) {
            Button("Delete", role: .destructive) {
                deletePage()
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete Page \(page.pageNumber) and all its panels? This action cannot be undone.")
        }
    }
    
    private func addNewPanel(panelNumber: Int) {
        let newPanel = Panel(panelNumber: panelNumber, page: page)
        modelContext.insert(newPanel)
        page.panels.append(newPanel)
        page.updatedAt = Date()
        selectedPanel = newPanel
    }
    
    private func deletePanel(_ panel: Panel) {
        page.panels.removeAll(where: { $0.id == panel.id })
        modelContext.delete(panel)
        
        // Renumber remaining panels
        let sortedPanels = page.panels.sorted(by: { $0.panelNumber < $1.panelNumber })
        for (index, p) in sortedPanels.enumerated() {
            p.panelNumber = index + 1
        }
        
        // Select another panel if the deleted one was selected
        if selectedPanel?.id == panel.id {
            selectedPanel = page.panels.first
        }
    }
    
    private func deletePage() {
        if let issue = page.issue {
            issue.pages.removeAll(where: { $0.id == page.id })
            modelContext.delete(page)
            
            // Renumber remaining pages
            let sortedPages = issue.pages.sorted(by: { $0.pageNumber < $1.pageNumber })
            for (index, page) in sortedPages.enumerated() {
                page.pageNumber = index + 1
            }
            
            // Select another page if the deleted one was the selected one
            if selectedPanel?.page?.id == page.id {
                selectedPanel = nil
            }
        }
    }
}

struct PageEditorView: View {
    @Environment(\.modelContext) private var modelContext
    let page: Page
    @Binding var selectedPanel: Panel?
    @State private var showingCharacterSheet = false
    @State private var newCharacterName = ""
    @Namespace private var panelSpace  // Add namespace for scroll position
    
    var body: some View {
        VStack(spacing: 0) {
            // Page header with toolbar
            PageHeaderView(page: page, selectedPanel: $selectedPanel, showCharacterSheet: $showingCharacterSheet, newCharacterName: $newCharacterName)
            
            // Panel editors
            PanelListView(page: page, selectedPanel: $selectedPanel)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingCharacterSheet) {
            CharacterNameSheet(
                isPresented: $showingCharacterSheet,
                characterName: $newCharacterName,
                onSave: { name in
                    addCharacter(name: name)
                },
                existingCharacters: getUniqueCharacterNames()
            )
        }
    }
    
    private func addCharacter(name: String) {
        guard !name.isEmpty, let targetPanel = selectedPanel else { return }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create a character with the exact name provided without adding a suffix
        let newCharacter = Character(name: trimmedName)
        newCharacter.panel = targetPanel
        newCharacter.createdAt = Date() // Ensure createdAt is set for proper sorting
        modelContext.insert(newCharacter)
        targetPanel.characters.append(newCharacter)
    }
    
    private func getUniqueCharacterNames() -> [String] {
        guard let issue = page.issue else { return [] }
        
        // Map to collect character names with their latest creation timestamp
        var characterLastUsed: [String: Date] = [:]
        
        // Collect character names and their latest timestamp from all pages and panels
        for page in issue.pages {
            for panel in page.panels {
                for character in panel.characters {
                    // Don't include special "characters" like CAPTION and SFX
                    if character.name != "CAPTION" && character.name != "SFX" {
                        // Keep track of the most recent usage of this character name
                        if let existingDate = characterLastUsed[character.name], existingDate > character.createdAt {
                            // Already have a more recent usage, skip
                        } else {
                            characterLastUsed[character.name] = character.createdAt
                        }
                    }
                }
            }
        }
        
        // Sort by most recently used first
        return characterLastUsed.sorted { $0.value > $1.value }.map { $0.key }
    }
}

// New component for the page header and toolbar
struct PageHeaderView: View {
    @Environment(\.modelContext) private var modelContext
    let page: Page
    @Binding var selectedPanel: Panel?
    @Binding var showCharacterSheet: Bool
    @Binding var newCharacterName: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Page \(page.pageNumber)")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Editor Toolbar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    Button {
                        // Add panel immediately without confirmation
                        let nextPanelNumber = (page.panels.map { $0.panelNumber }.max() ?? 0) + 1
                        addNewPanel(panelNumber: nextPanelNumber)
                    } label: {
                        VStack {
                            Image(systemName: "rectangle.split.3x1")
                                .font(.system(size: 16))
                            Text("Panel")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        // Show character name input sheet
                        if selectedPanel != nil {
                            newCharacterName = ""
                            showCharacterSheet = true
                        }
                    } label: {
                        VStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                            Text("Character")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPanel == nil)
                    
                    Button {
                        // Add caption immediately without confirmation
                        if let panel = selectedPanel {
                            let caption = Character(name: "CAPTION", panel: panel)
                            caption.createdAt = Date() // Ensure createdAt is set for proper sorting
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
                    .buttonStyle(.plain)
                    .disabled(selectedPanel == nil)
                    
                    Button {
                        // Add SFX immediately without confirmation
                        if let panel = selectedPanel {
                            let sfx = Character(name: "SFX", panel: panel)
                            sfx.createdAt = Date() // Ensure createdAt is set for proper sorting
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
                    .buttonStyle(.plain)
                    .disabled(selectedPanel == nil)
                    
                    Divider()
                        .frame(height: 30)
                    
                    Button {
                        duplicateSelectedPanel()
                    } label: {
                        VStack {
                            Image(systemName: "plus.square.on.square")
                                .font(.system(size: 16))
                            Text("Duplicate")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPanel == nil)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGray6))
            .padding(.bottom, 4)
        }
        .background(Color(.systemGray5))
    }
    
    private func addNewPanel(panelNumber: Int) {
        let newPanel = Panel(panelNumber: panelNumber, page: page)
        modelContext.insert(newPanel)
        page.panels.append(newPanel)
        page.updatedAt = Date()
        selectedPanel = newPanel
    }
    
    private func duplicateSelectedPanel() {
        guard let panelToDuplicate = selectedPanel else { return }
        let nextPanelNumber = (page.panels.map { $0.panelNumber }.max() ?? 0) + 1
        
        // Create a new panel with the same details
        let newPanel = Panel(
            panelNumber: nextPanelNumber,
            details: panelToDuplicate.details,
            page: page
        )
        modelContext.insert(newPanel)
        page.panels.append(newPanel)
        
        // Duplicate all characters and their dialogues
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
        selectedPanel = newPanel
    }
}

// New component for the panel list
struct PanelListView: View {
    @Environment(\.modelContext) private var modelContext
    let page: Page
    @Binding var selectedPanel: Panel?
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Use a more straightforward ForEach with a separate view component
                    ForEach(page.panels.sorted(by: { $0.panelNumber < $1.panelNumber })) { panel in
                        PanelEditorWrapper(panel: panel, isSelected: selectedPanel?.id == panel.id)
                            .id(panel.id)  // Use ID for scrolling
                            .onTapGesture {
                                selectedPanel = panel
                            }
                    }
                    
                    // Add panel button
                    AddPanelButton(page: page, selectedPanel: $selectedPanel)
                }
                .padding(.vertical)
            }
            .onChange(of: selectedPanel) { _, newPanel in
                if let panelID = newPanel?.id {
                    // Scroll to the selected panel with animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scrollProxy.scrollTo(panelID, anchor: .top)
                    }
                }
            }
        }
    }
}

// Wrapper view to simplify the PanelEditorView integration
struct PanelEditorWrapper: View {
    let panel: Panel
    let isSelected: Bool
    
    var body: some View {
        PanelEditorView(panel: panel, isSelected: isSelected)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.07) : Color(.systemBackground))
                    .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.05), 
                           radius: isSelected ? 4 : 2, 
                           x: 0, 
                           y: isSelected ? 2 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue.opacity(0.6) : Color.gray.opacity(0.2), 
                          lineWidth: isSelected ? 1.5 : 1)
            )
            .padding(.horizontal)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// Button to add a new panel
struct AddPanelButton: View {
    @Environment(\.modelContext) private var modelContext
    let page: Page
    @Binding var selectedPanel: Panel?
    
    var body: some View {
        Button {
            let nextPanelNumber = (page.panels.map { $0.panelNumber }.max() ?? 0) + 1
            addNewPanel(panelNumber: nextPanelNumber)
        } label: {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.split.3x1.fill")
                        .font(.system(size: 24))
                    Text("Add Panel")
                        .font(.headline)
                }
                .foregroundColor(.blue)
                .padding(.vertical, 30)
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
            )
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
    
    private func addNewPanel(panelNumber: Int) {
        let newPanel = Panel(panelNumber: panelNumber, page: page)
        modelContext.insert(newPanel)
        page.panels.append(newPanel)
        page.updatedAt = Date()
        selectedPanel = newPanel
    }
}

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

struct PanelEditorView: View {
    @Environment(\.modelContext) private var modelContext
    let panel: Panel
    let isSelected: Bool
    @State private var panelDetails: String
    @State private var showingDeleteConfirmation = false
    @State private var showingCharacterSheet = false
    @State private var newCharacterName = ""
    @State private var panelDetailsHeight: CGFloat = 80
    @State private var isDetailsExpanded: Bool = true
    
    init(panel: Panel, isSelected: Bool) {
        self.panel = panel
        self.isSelected = isSelected
        self._panelDetails = State(initialValue: panel.details)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Panel header with context menu
            HStack {
                Text("Panel \(panel.panelNumber)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Menu {
                    Button {
                        // Show character sheet
                        newCharacterName = ""
                        showingCharacterSheet = true
                    } label: {
                        Label("Add Character", systemImage: "person.badge.plus")
                    }
                    
                    Button {
                        // Add caption immediately
                        let caption = Character(name: "CAPTION", panel: panel)
                        caption.createdAt = Date() // Ensure createdAt is set for proper sorting
                        modelContext.insert(caption)
                        panel.characters.append(caption)
                    } label: {
                        Label("Add Caption", systemImage: "text.quote")
                    }
                    
                    Button {
                        // Add SFX immediately
                        let sfx = Character(name: "SFX", panel: panel)
                        sfx.createdAt = Date() // Ensure createdAt is set for proper sorting
                        modelContext.insert(sfx)
                        panel.characters.append(sfx)
                    } label: {
                        Label("Add Sound Effect", systemImage: "waveform")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Panel", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                }
            }
            
            // Panel description with improved styling
            HStack {
                Text("Description")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isDetailsExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isDetailsExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            if isDetailsExpanded {
                // Adaptive text editor that grows with content
                ZStack(alignment: .topLeading) {
                    // Invisible text view that determines the size
                    Text(panelDetails.isEmpty ? " " : panelDetails)
                        .font(.body)
                        .padding(8)
                        .padding(.bottom, 6) // Extra padding to ensure scrolling works well
                        .opacity(0)
                        .background(GeometryReader { geometry in
                            Color.clear.preference(
                                key: ViewHeightKey.self,
                                value: geometry.size.height
                            )
                        })
                    
                    TextEditor(text: $panelDetails)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        .frame(minHeight: 80, maxHeight: max(80, panelDetailsHeight)) // Use calculated height with minimum
                        .onChange(of: panelDetails) { _, newValue in
                            panel.details = newValue
                        }
                }
                .onPreferenceChange(ViewHeightKey.self) { height in
                    // Set the height plus a bit extra for comfortable editing
                    self.panelDetailsHeight = min(200, height + 20)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Visual divider
            if !panel.characters.isEmpty {
                Divider()
                    .padding(.vertical, 4)
            }
            
            // Character dialogues with improved styling and arrow-based reordering
            ForEach(panel.characters.sorted(by: { $0.createdAt < $1.createdAt })) { character in
                HStack(spacing: 0) {
                    // Main character content - taking up most but not all of the width
                    CharacterDialogueView(character: character)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(.systemBackground))
                                )
                        )
                        .frame(maxWidth: .infinity)
                    
                    // Only show reordering buttons when there's more than one character
                    if panel.characters.count > 1 {
                        // Dedicated area for up/down navigation
                        VStack(spacing: 0) {
                            // Up arrow - visible only if not first item
                            let sortedCharacters = panel.characters.sorted(by: { $0.createdAt < $1.createdAt })
                            let index = sortedCharacters.firstIndex(where: { $0 === character })
                            let isFirst = index == 0
                            let isLast = index == sortedCharacters.count - 1
                            
                            Button {
                                if let index = index, index > 0 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        moveCharacter(fromIndex: index, toIndex: index - 1)
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 15, weight: .bold))
                                    .frame(width: 44, height: 30)
                                    .foregroundColor(isFirst ? .gray.opacity(0.3) : .blue)
                                    .background(isFirst ? Color.clear : Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .disabled(isFirst)
                            
                            Divider()
                                .frame(width: 30)
                                .padding(.vertical, 2)
                            
                            // Down arrow - visible only if not last item
                            Button {
                                if let index = index, index < sortedCharacters.count - 1 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        moveCharacter(fromIndex: index, toIndex: index + 1)
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 15, weight: .bold))
                                    .frame(width: 44, height: 30)
                                    .foregroundColor(isLast ? .gray.opacity(0.3) : .blue)
                                    .background(isLast ? Color.clear : Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .disabled(isLast)
                        }
                        .frame(width: 44)
                        .background(Color(.systemBackground))
                        .padding(.leading, 8)
                    }
                }
                .padding(.vertical, 2)
            }
            
            // Quick add character button now shows sheet
            Button {
                newCharacterName = ""
                showingCharacterSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.caption)
                    Text("Add Character")
                        .font(.caption)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .alert("Delete Panel", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let page = panel.page {
                    page.panels.removeAll(where: { $0.id == panel.id })
                    modelContext.delete(panel)
                    
                    // Renumber remaining panels
                    let sortedPanels = page.panels.sorted(by: { $0.panelNumber < $1.panelNumber })
                    for (index, p) in sortedPanels.enumerated() {
                        p.panelNumber = index + 1
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this panel? This action cannot be undone.")
        }
        .sheet(isPresented: $showingCharacterSheet) {
            CharacterNameSheet(
                isPresented: $showingCharacterSheet,
                characterName: $newCharacterName,
                onSave: { name in
                    addCharacterToPanel(name: name)
                },
                existingCharacters: getUniqueCharacterNames()
            )
        }
    }
    
    private func addCharacterToPanel(name: String) {
        guard !name.isEmpty else { return }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create a character with the exact name provided without adding a suffix
        let newCharacter = Character(name: trimmedName)
        newCharacter.panel = panel
        newCharacter.createdAt = Date() // Ensure createdAt is set for proper sorting
        modelContext.insert(newCharacter)
        panel.characters.append(newCharacter)
    }
    
    private func getUniqueCharacterNames() -> [String] {
        guard let page = panel.page, let issue = page.issue else { return [] }
        
        // Map to collect character names with their latest creation timestamp
        var characterLastUsed: [String: Date] = [:]
        
        // Collect character names and their latest timestamp from all pages and panels
        for page in issue.pages {
            for panel in page.panels {
                for character in panel.characters {
                    // Don't include special "characters" like CAPTION and SFX
                    if character.name != "CAPTION" && character.name != "SFX" {
                        // Keep track of the most recent usage of this character name
                        if let existingDate = characterLastUsed[character.name], existingDate > character.createdAt {
                            // Already have a more recent usage, skip
                        } else {
                            characterLastUsed[character.name] = character.createdAt
                        }
                    }
                }
            }
        }
        
        // Sort by most recently used first
        return characterLastUsed.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    private func moveCharacter(fromIndex: Int, toIndex: Int) {
        let sortedCharacters = panel.characters.sorted(by: { $0.createdAt < $1.createdAt })
        
        // Ensure indices are valid
        guard fromIndex >= 0 && fromIndex < sortedCharacters.count,
              toIndex >= 0 && toIndex < sortedCharacters.count else {
            return
        }
        
        // Update the timestamps to match the new order
        let now = Date()
        
        // Create a mutable copy of the sorted array
        var characters = sortedCharacters
        
        // Remove the character from its current position
        let character = characters.remove(at: fromIndex)
        
        // Insert it at the new position
        characters.insert(character, at: toIndex)
        
        // Update timestamps to maintain the new order
        for (index, character) in characters.enumerated() {
            // Add 0.1 seconds between each character to maintain order
            character.createdAt = now.addingTimeInterval(TimeInterval(index) * 0.1)
        }
        
        // Enhance haptic feedback - use selection feedback
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred(intensity: 0.7)
    }
}

struct CharacterDialogueView: View {
    @Environment(\.modelContext) private var modelContext
    let character: Character
    @State private var characterDialogue: String
    @State private var isExpanded = true
    @State private var showingDeleteConfirmation = false
    @State private var modifier: String = ""
    @State private var dialogueHeight: CGFloat = 60 // Store text height
    
    // Common character dialogue modifiers based on Blambot guidelines
    private let commonModifiers = [
        "OFF", "WHISPER", "BURST", "WEAK", "SINGING", "THOUGHTS"
    ]
    
    init(character: Character) {
        self.character = character
        self._characterDialogue = State(initialValue: character.dialogue)
        
        // Extract any existing modifier from the character name
        if let openParen = character.name.lastIndex(of: "("),
           let closeParen = character.name.lastIndex(of: ")"),
           openParen < closeParen {
            let modifierStart = character.name.index(after: openParen)
            let modifierEnd = closeParen
            let extractedModifier = String(character.name[modifierStart..<modifierEnd])
            self._modifier = State(initialValue: extractedModifier)
        }
    }
    
    // Computed property to get base name without modifier
    private var baseName: String {
        if let openParen = character.name.lastIndex(of: "(") {
            return String(character.name[..<openParen]).trimmingCharacters(in: .whitespaces)
        } else {
            return character.name
        }
    }
    
    // Computed property to check if character is a special type
    private var isSpecialCharacter: Bool {
        return character.name == "CAPTION" || character.name == "SFX"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Character name header with controls
            HStack {
                // Use appropriate icon based on character type
                Image(systemName: character.name == "CAPTION" ? "text.quote" : 
                       character.name == "SFX" ? "waveform" : "person.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                    .padding(.trailing, 4)
                
                // For regular characters, show the name and any modifiers
                if !isSpecialCharacter {
                    Text(baseName.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Show modifier if present
                    if !modifier.isEmpty {
                        Text("(\(modifier))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 2)
                    }
                } else {
                    // For CAPTION and SFX, just show the name
                    Text(character.name.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Modifier dropdown for regular characters
                if !isSpecialCharacter {
                    Menu {
                        Button("No Modifier") {
                            updateCharacterName(withModifier: nil)
                        }
                        
                        Divider()
                        
                        ForEach(commonModifiers, id: \.self) { mod in
                            Button(mod) {
                                updateCharacterName(withModifier: mod)
                            }
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "tag")
                                .font(.caption)
                            
                            if !modifier.isEmpty {
                                Text(modifier)
                                    .font(.caption2)
                            }
                        }
                        .padding(4)
                    }
                    .buttonStyle(.borderless)
                }
                
                Button {
                    isExpanded.toggle()
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .padding(4)
                }
                .buttonStyle(.plain)
                
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)
            
            // Dialogue text
            if isExpanded {
                ZStack(alignment: .topLeading) {
                    // Invisible text view that determines the size
                    Text(characterDialogue.isEmpty ? " " : characterDialogue)
                        .font(.body)
                        .padding(8)
                        .padding(.bottom, 6)
                        .opacity(0)
                        .background(GeometryReader { geometry in
                            Color.clear.preference(
                                key: ViewHeightKey.self,
                                value: geometry.size.height
                            )
                        })
                    
                    TextEditor(text: $characterDialogue)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        .frame(minHeight: 60, maxHeight: max(60, dialogueHeight))
                        .onChange(of: characterDialogue) { _, newValue in
                            character.dialogue = newValue
                        }
                }
                .onPreferenceChange(ViewHeightKey.self) { height in
                    // Set the height plus a bit extra for comfortable editing
                    self.dialogueHeight = min(180, height + 20)
                }
                .padding(.horizontal, 6)
            }
        }
        .alert("Delete \(character.name)", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let panel = character.panel {
                    panel.characters.removeAll(where: { $0 === character })
                    modelContext.delete(character)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this character? This action cannot be undone.")
        }
    }
    
    private func updateCharacterName(withModifier newModifier: String?) {
        let baseNameToUse = baseName
        
        // Set the new name (with or without modifier)
        if let newModifier = newModifier, !newModifier.isEmpty {
            character.name = "\(baseNameToUse) (\(newModifier))"
            modifier = newModifier
        } else {
            character.name = baseNameToUse
            modifier = ""
        }
    }
}

// New view for formatted script preview
struct ScriptPreviewView: View {
    let issue: ComicIssue
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .standard
    @State private var isExporting = false
    @State private var pdfURL: URL?
    @State private var writerName: String = UserDefaults.standard.string(forKey: "writerName") ?? ""
    @State private var showingSettingsSheet = false
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case standard = "Standard"
        case compact = "Compact"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Industry standard title block per Blambot guidelines
                    VStack(alignment: .center, spacing: 12) {
                        Text(issue.title.uppercased())
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        Text("ISSUE #\(issue.issueNumber)")
                            .font(.system(size: 20, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 4)
                        
                        if !writerName.isEmpty {
                            Text("Written by: \(writerName)")
                                .font(.system(size: 16, weight: .medium))
                                .padding(.top, 2)
                        }
                        
                        if !issue.synopsis.isEmpty {
                            Text(issue.synopsis)
                                .font(.body)
                                .italic()
                                .padding(.top, 12)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.bottom, 30)
                    
                    // Pages and panels
                    ForEach(issue.pages.sorted(by: { $0.pageNumber < $1.pageNumber })) { page in
                        FormattedPageView(page: page, format: exportFormat)
                            .padding(.bottom, 50) // Add space for page breaks in PDF
                    }
                }
                .padding()
                .frame(maxWidth: 650)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Script Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingSettingsSheet = true
                        } label: {
                            Label("Writer Information", systemImage: "person")
                        }
                        
                        Divider()
                        
                        Picker("Format", selection: $exportFormat) {
                            ForEach(ExportFormat.allCases) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        
                        Button {
                            // Save writer name if provided
                            if !writerName.isEmpty {
                                UserDefaults.standard.set(writerName, forKey: "writerName")
                            }
                            generatePDFAndShare()
                        } label: {
                            Label("Share PDF", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Label("Options", systemImage: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                NavigationStack {
                    Form {
                        Section("Writer Information") {
                            TextField("Writer name", text: $writerName)
                                .autocapitalization(.words)
                        }
                    }
                    .navigationTitle("Script Information")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                if !writerName.isEmpty {
                                    UserDefaults.standard.set(writerName, forKey: "writerName")
                                }
                                showingSettingsSheet = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $isExporting) {
                if let pdfURL = pdfURL {
                    ActivityViewController(activityItems: [pdfURL])
                }
            }
            .onAppear {
                // Try to load saved writer name
                self.writerName = UserDefaults.standard.string(forKey: "writerName") ?? ""
            }
        }
    }
    
    private func generatePDFAndShare() {
        // Create page-by-page PDF content to ensure proper page breaks
        var views: [AnyView] = []
        
        // Add title page
        let titlePage = VStack(alignment: .center, spacing: 16) {
            Text(issue.title.uppercased())
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.top, 100)
            
            Text("ISSUE #\(issue.issueNumber)")
                .font(.system(size: 22, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            
            if !writerName.isEmpty {
                Text("Written by:")
                    .font(.system(size: 18, weight: .medium))
                    .padding(.top, 20)
                
                Text(writerName)
                    .font(.system(size: 18, weight: .bold))
            }
            
            if !issue.synopsis.isEmpty {
                Text("Synopsis:")
                    .font(.system(size: 16, weight: .medium))
                    .padding(.top, 40)
                
                Text(issue.synopsis)
                    .font(.body)
                    .italic()
                    .padding(.top, 4)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Text("CONFIDENTIAL")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color.white)
        
        views.append(AnyView(titlePage))
        
        // Add each page as a separate PDF page with proper numbering
        for page in issue.pages.sorted(by: { $0.pageNumber < $1.pageNumber }) {
            let pageView = VStack(alignment: .leading, spacing: 20) {
                FormattedPageView(page: page, format: exportFormat)
                
                Spacer()
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white)
            
            views.append(AnyView(pageView))
        }
        
        // Create a PDF from multiple pages
        let pdfData = generateMultiPagePDF(views: views)
        
        // Create a temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "\(issue.title) - Issue \(issue.issueNumber).pdf"
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
        let url = tempDir.appendingPathComponent(filename)
        
        // Write to temp file
        do {
            try pdfData.write(to: url)
            self.pdfURL = url
            self.isExporting = true
        } catch {
            print("Failed to create PDF: \(error.localizedDescription)")
        }
    }
    
    // Helper to generate multi-page PDF
    private func generateMultiPagePDF(views: [AnyView]) -> Data {
        let pageWidth: CGFloat = 612  // 8.5 inches at 72 dpi
        let pageHeight: CGFloat = 792 // 11 inches at 72 dpi
        
        let pdfMetaData = [
            kCGPDFContextCreator: "ComicsWriter",
            kCGPDFContextAuthor: writerName,
            kCGPDFContextTitle: "\(issue.title) - Issue #\(issue.issueNumber)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
                                            format: format)
        
        let data = renderer.pdfData { context in
            for (pageIndex, view) in views.enumerated() {
                context.beginPage()
                
                // Convert SwiftUI view to UIImage
                let hostingController = UIHostingController(rootView: view
                    .frame(width: pageWidth, height: pageHeight)
                )
                
                hostingController.view.bounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
                hostingController.view.backgroundColor = .white
                
                let frameSize = hostingController.view.frame.size
                let contentSize = hostingController.view.intrinsicContentSize
                let viewScale = min(pageWidth/frameSize.width, pageHeight/frameSize.height)
                
                hostingController.view.transform = CGAffineTransform(scaleX: viewScale, y: viewScale)
                
                // Render the view to the PDF context
                let rect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
                hostingController.view.drawHierarchy(in: rect, afterScreenUpdates: true)
                
                // Add page number at the bottom
                let pageNumberFont = UIFont.systemFont(ofSize: 10)
                let pageNumberAttributes: [NSAttributedString.Key: Any] = [
                    .font: pageNumberFont,
                    .foregroundColor: UIColor.gray
                ]
                
                // Don't show page number on the title page
                if pageIndex > 0 {
                    let pageNumberText = "\(pageIndex)" // 1-indexed page numbers
                    let pageNumberSize = pageNumberText.size(withAttributes: pageNumberAttributes)
                    let pageNumberX = (pageWidth - pageNumberSize.width) / 2
                    let pageNumberY = pageHeight - 36 // Bottom margin
                    
                    pageNumberText.draw(at: CGPoint(x: pageNumberX, y: pageNumberY), withAttributes: pageNumberAttributes)
                }
            }
        }
        
        return data
    }
}

// Custom activity view controller wrapper
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct FormattedPageView: View {
    let page: Page
    let format: ScriptPreviewView.ExportFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Page header - Make it bigger and bolder per Blambot guidelines
            Text("PAGE \(page.pageNumber)")
                .font(.system(size: 18, weight: .bold))
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Panels
            ForEach(page.panels.sorted(by: { $0.panelNumber < $1.panelNumber })) { panel in
                FormattedPanelView(panel: panel, format: format)
            }
            
            Divider()
                .padding(.vertical, 8)
        }
    }
}

struct FormattedPanelView: View {
    let panel: Panel
    let format: ScriptPreviewView.ExportFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Panel header - Bold and clear per Blambot guidelines
            Text("PANEL \(panel.panelNumber)")
                .font(.system(size: 16, weight: .bold))
                .padding(.bottom, 4)
            
            // Panel description
            if !panel.details.isEmpty {
                Text(panel.details)
                    .font(.body)
                    .padding(.leading, format == .compact ? 8 : 16)
                    .padding(.bottom, 8)
            }
            
            // Character dialogues - Numbered per Blambot guidelines
            ForEach(Array(panel.characters.sorted(by: { $0.createdAt < $1.createdAt }).enumerated()), id: \.element.id) { index, character in
                FormattedCharacterView(character: character, index: index + 1, format: format)
            }
            
            Spacer()
                .frame(height: 12)
        }
        .padding(.leading, format == .compact ? 8 : 16)
        .padding(.bottom, 12)
    }
}

struct FormattedCharacterView: View {
    let character: Character
    let index: Int
    let format: ScriptPreviewView.ExportFormat
    
    // Parse any modifiers in character names like "CHARACTER (WHISPER)"
    private var characterNameAndModifier: (name: String, modifier: String?) {
        let fullName = character.name
        
        // Check if there's a modifier in parentheses
        if let openParenIndex = fullName.lastIndex(of: "("),
           let closeParenIndex = fullName.lastIndex(of: ")"),
           openParenIndex < closeParenIndex {
            
            let baseName = fullName[..<openParenIndex].trimmingCharacters(in: .whitespaces)
            let modifierRange = fullName.index(after: openParenIndex)..<closeParenIndex
            let modifier = String(fullName[modifierRange])
            
            return (name: String(baseName), modifier: modifier)
        }
        
        return (name: fullName, modifier: nil)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                // Item number per Blambot guidelines
                Text("\(index).")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .frame(width: 24, alignment: .leading)
                
                // Character name with proper formatting
                if character.name == "CAPTION" {
                    if !character.dialogue.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CAPTION:")
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.bold)
                            
                            Text(character.dialogue)
                                .font(.system(.body, design: .serif))
                                .italic()
                                .padding(.leading, format == .compact ? 8 : 16)
                        }
                    }
                } else if character.name == "SFX" {
                    if !character.dialogue.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SFX:")
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.bold)
                            
                            Text(character.dialogue)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                                .padding(.leading, format == .compact ? 8 : 16)
                        }
                    }
                } else {
                    // Regular character dialogue
                    if !character.dialogue.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            // Format character name with any modifier
                            let nameInfo = characterNameAndModifier
                            Text(nameInfo.name.uppercased() + (nameInfo.modifier != nil ? " (\(nameInfo.modifier!))" : "") + ":")
                                .font(.system(.subheadline, design: .default))
                                .fontWeight(.bold)
                            
                            // Dialogue with proper indentation
                            Text(character.dialogue)
                                .font(.body)
                                .padding(.leading, format == .compact ? 8 : 16)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let issue: ComicIssue
    
    @State private var selectedCoverStyle: CoverStyle
    @State private var showTitles: Bool
    @State private var titlePosition: TitlePosition
    
    // Initialize with the current issue's settings
    init(issue: ComicIssue) {
        self.issue = issue
        // Convert from string to enum
        self._selectedCoverStyle = State(initialValue: CoverStyle(rawValue: issue.coverImageType.capitalized) ?? .classic)
        self._showTitles = State(initialValue: issue.showCoverTitle)
        self._titlePosition = State(initialValue: TitlePosition(rawValue: issue.coverTitlePosition.capitalized) ?? .bottom)
    }
    
    enum CoverStyle: String, CaseIterable, Identifiable {
        case classic = "Classic"
        case modern = "Modern"
        case minimal = "Minimal"
        case custom = "Custom"
        
        var id: String { self.rawValue }
        
        var imageName: String {
            switch self {
                case .classic: return "coverPlaceholder1"
                case .modern: return "coverPlaceholder2"
                case .minimal: return "coverPlaceholder3"
                case .custom: return "coverPlaceholder4"
            }
        }
    }
    
    enum TitlePosition: String, CaseIterable, Identifiable {
        case top = "Top"
        case bottom = "Bottom"
        case overlay = "Overlay"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Cover Images") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Cover Style")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Cover Style", selection: $selectedCoverStyle) {
                            ForEach(CoverStyle.allCases) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, 10)
                        
                        Toggle("Show Title on Cover", isOn: $showTitles)
                            .padding(.bottom, 6)
                        
                        if showTitles {
                            Text("Title Position")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            
                            Picker("Title Position", selection: $titlePosition) {
                                ForEach(TitlePosition.allCases) { position in
                                    Text(position.rawValue).tag(position)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.bottom, 10)
                        }
                        
                        // Cover preview
                        VStack {
                            if selectedCoverStyle == .custom {
                                CustomCoverSelector(
                                    issue: issue, 
                                    showTitle: showTitles,
                                    titlePosition: titlePosition
                                )
                            } else {
                                CoverPreview(
                                    coverStyle: selectedCoverStyle,
                                    issue: issue,
                                    showTitle: showTitles,
                                    titlePosition: titlePosition
                                )
                            }
                        }
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.vertical, 8)
                }
                
                Section("General") {
                    Text("App Version: 1.0.0")
                    
                    NavigationLink("Export Options") {
                        Text("Export preferences would go here")
                    }
                }
                
                Section("About") {
                    Text("ComicsWriter - Your Scripting Companion")
                    
                    Link("Visit Website", destination: URL(string: "https://example.com")!)
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                }
                
                // Add keyboard toolbar for any text fields that might be added in the future
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                      to: nil, from: nil, for: nil)
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private func saveSettings() {
        // Save the cover settings to the issue
        issue.coverImageType = selectedCoverStyle.rawValue.lowercased()
        issue.coverTitlePosition = titlePosition.rawValue.lowercased()
        issue.showCoverTitle = showTitles
        issue.updatedAt = Date()
    }
}

struct CoverPreview: View {
    let coverStyle: SettingsView.CoverStyle
    let issue: ComicIssue
    let showTitle: Bool
    let titlePosition: SettingsView.TitlePosition
    
    var body: some View {
        ZStack(alignment: getAlignment()) {
            // Cover image
            Image(coverStyle.imageName)
                .resizable()
                .scaledToFill()
            
            // Title overlay - semi-transparent gradient at bottom only
            if showTitle {
                VStack(spacing: 4) {
                    Text(issue.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("ISSUE #\(issue.issueNumber)")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(getGradient())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func getAlignment() -> Alignment {
        switch titlePosition {
            case .top: return .top
            case .overlay: return .center
            default: return .bottom
        }
    }
    
    private func getGradient() -> LinearGradient {
        if titlePosition == .overlay {
            return LinearGradient(
                colors: [Color.black.opacity(0.4), Color.black.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Color.black.opacity(0.7), Color.black.opacity(0)],
                startPoint: titlePosition == .top ? .top : .bottom,
                endPoint: titlePosition == .top ? .bottom : .top
            )
        }
    }
}

struct CustomCoverSelector: View {
    @Environment(\.modelContext) private var modelContext
    let issue: ComicIssue
    let showTitle: Bool
    let titlePosition: SettingsView.TitlePosition
    
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ZStack(alignment: getAlignment()) {
            if let image = selectedImage ?? (issue.customCoverImageData != nil ? UIImage(data: issue.customCoverImageData!) : nil) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .overlay(alignment: .bottomTrailing) {
                        Button {
                            showingImagePicker = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .padding(8)
                        }
                    }
                
                // Show title if needed
                if showTitle {
                    VStack(spacing: 4) {
                        Text(issue.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("ISSUE #\(issue.issueNumber)")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(getGradient())
                }
            } else {
                Color(.systemGray5)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.largeTitle)
                            
                            Text("Select Custom Cover")
                                .font(.headline)
                            
                            Button {
                                showingImagePicker = true
                            } label: {
                                Text("Choose Image")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
    
    private func getAlignment() -> Alignment {
        switch titlePosition {
            case .top: return .top
            case .overlay: return .center
            default: return .bottom
        }
    }
    
    private func getGradient() -> LinearGradient {
        if titlePosition == .overlay {
            return LinearGradient(
                colors: [Color.black.opacity(0.4), Color.black.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Color.black.opacity(0.7), Color.black.opacity(0)],
                startPoint: titlePosition == .top ? .top : .bottom,
                endPoint: titlePosition == .top ? .bottom : .top
            )
        }
    }
}

// Helper struct for measuring text view height
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
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
