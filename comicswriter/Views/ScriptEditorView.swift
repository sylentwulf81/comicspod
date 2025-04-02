import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ScriptEditorView: View {
    @Environment(\.modelContext) private var modelContext
    let issue: Issue
    @State private var selectedPage: Page?
    @State private var selectedPanel: Panel?
    @State private var showingScriptPreview = false
    
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
    let issue: Issue
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
        
        // Check if this is a duplicate name in the current panel
        let duplicates = targetPanel.characters.filter { $0.name == trimmedName }
        let finalName: String
        
        if !duplicates.isEmpty {
            // Create a name with a number suffix (Character, Character 2, etc.)
            finalName = "\(trimmedName) \(duplicates.count + 1)"
        } else {
            finalName = trimmedName
        }
        
        let newCharacter = Character(name: finalName)
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
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
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
                    // Toggle expanded state if needed
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            TextEditor(text: $panelDetails)
                .font(.body)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(6)
                .frame(height: 100)
                .onChange(of: panelDetails) { _, newValue in
                    panel.details = newValue
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
        
        // Check if this is a duplicate name in the current panel
        let duplicates = panel.characters.filter { $0.name == trimmedName }
        let finalName: String
        
        if !duplicates.isEmpty {
            // Create a name with a number suffix (Character, Character 2, etc.)
            finalName = "\(trimmedName) \(duplicates.count + 1)"
        } else {
            finalName = trimmedName
        }
        
        let newCharacter = Character(name: finalName)
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
    
    init(character: Character) {
        self.character = character
        self._characterDialogue = State(initialValue: character.dialogue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Character name header with controls
            HStack {
                // Replace drag handle with a more appropriate icon
                Image(systemName: character.name == "CAPTION" ? "text.quote" : 
                       character.name == "SFX" ? "waveform" : "person.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                    .padding(.trailing, 4)
                
                Text(character.name.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
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
                TextEditor(text: $characterDialogue)
                    .font(.body)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                    .frame(height: 70) // Smaller height to accommodate arrows
                    .onChange(of: characterDialogue) { _, newValue in
                        character.dialogue = newValue
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
}

// New view for formatted script preview
struct ScriptPreviewView: View {
    let issue: Issue
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .standard
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case standard = "Standard"
        case compact = "Compact"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title block
                    VStack(alignment: .center, spacing: 8) {
                        Text(issue.title.uppercased())
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("ISSUE #\(issue.issueNumber)")
                            .font(.title2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                        
                        if !issue.synopsis.isEmpty {
                            Text(issue.synopsis)
                                .font(.body)
                                .italic()
                                .padding(.top, 8)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 30)
                    
                    // Pages and panels
                    ForEach(issue.pages.sorted(by: { $0.pageNumber < $1.pageNumber })) { page in
                        FormattedPageView(page: page, format: exportFormat)
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
                        Picker("Format", selection: $exportFormat) {
                            ForEach(ExportFormat.allCases) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        
                        Button {
                            shareScript()
                        } label: {
                            Label("Share PDF", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Label("Options", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func shareScript() {
        // This is a placeholder for PDF generation and sharing functionality
        // In a real implementation, this would generate a PDF and present
        // a share sheet for exporting the script
    }
}

struct FormattedPageView: View {
    let page: Page
    let format: ScriptPreviewView.ExportFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Page header
            Text("PAGE \(page.pageNumber)")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.bottom, 4)
            
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
            // Panel header
            Text("PANEL \(panel.panelNumber)")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Panel description
            if !panel.details.isEmpty {
                Text(panel.details)
                    .font(.body)
                    .padding(.leading, format == .compact ? 8 : 16)
                    .padding(.bottom, 4)
            }
            
            // Character dialogues
            ForEach(panel.characters.sorted(by: { $0.createdAt < $1.createdAt })) { character in
                FormattedCharacterView(character: character, format: format)
            }
            
            Spacer()
                .frame(height: 10)
        }
        .padding(.leading, format == .compact ? 8 : 16)
        .padding(.bottom, 8)
    }
}

struct FormattedCharacterView: View {
    let character: Character
    let format: ScriptPreviewView.ExportFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Special formatting for captions and SFX
            if character.name == "CAPTION" {
                if !character.dialogue.isEmpty {
                    Text("CAPTION:")
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.bold)
                    
                    Text(character.dialogue)
                        .font(.system(.body, design: .serif))
                        .italic()
                        .padding(.leading, format == .compact ? 8 : 16)
                }
            } else if character.name == "SFX" {
                if !character.dialogue.isEmpty {
                    Text("SFX:")
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.bold)
                    
                    Text(character.dialogue)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .padding(.leading, format == .compact ? 8 : 16)
                }
            } else {
                // Regular character dialogue
                if !character.dialogue.isEmpty {
                    Text(character.name + ":")
                        .font(.system(.subheadline, design: .default))
                        .fontWeight(.bold)
                    
                    Text(character.dialogue)
                        .font(.body)
                        .padding(.leading, format == .compact ? 8 : 16)
                }
            }
        }
        .padding(.leading, format == .compact ? 8 : 16)
        .padding(.bottom, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Series.self, Issue.self, Page.self, Panel.self, Character.self, configurations: config)
    
    let previewSeries = Series(title: "Example Series")
    let previewIssue = Issue(title: "First Issue", issueNumber: 1, series: previewSeries)
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
