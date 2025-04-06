import SwiftUI
import SwiftData

// MARK: - New Script Editor View (Traditional Format)

struct FormattedScriptPageView: View {
    @Bindable var page: Page // Use @Bindable for direct editing
    @Binding var selectedPanel: PanelID?
    var onDeletePanel: (Panel) -> Void
    var onDeleteElement: (Character) -> Void
    // Add closures for commands
    var onCommandAddPage: () -> Void
    var onCommandAddPanel: (Page) -> Void
    var onCommandAddCharacter: (String, Panel) -> Void
    
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedField: AnyHashable?

    private var sortedPanels: [Panel] {
        page.panels.sorted { $0.panelNumber < $1.panelNumber }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Page Header
            Text("PAGE \(page.pageNumber)")
                .font(.system(size: 18, weight: .bold))
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .center) // Centered page number

            // Panels
            ForEach(sortedPanels) { panel in
                PanelItemView(panel: panel, 
                              selectedPanel: $selectedPanel, 
                              focusedField: $focusedField, 
                              onDeletePanel: onDeletePanel, 
                              onDeleteElement: onDeleteElement,
                              onCommandAddPage: onCommandAddPage,
                              onCommandAddPanel: { _ in onCommandAddPanel(page) }, // Pass page context
                              onCommandAddCharacter: onCommandAddCharacter)
            }
        }
        .padding() 
    }
    
    // Modify renderCharacterElement to accept and pass command closures
    /* @ViewBuilder // Comment out or remove the old @ViewBuilder function
    private func renderCharacterElement(character: Character, panelId: PersistentIdentifier, 
                                        deleteAction: @escaping () -> Void, 
                                        onCommandAddPage: @escaping () -> Void, 
                                        parentOnCommandAddPanel: @escaping (Page) -> Void, 
                                        parentOnCommandAddCharacter: @escaping (String, Panel) -> Void) -> some View {
        // ... implementation commented out or removed ...
    } */
}

// MARK: - Panel Item View
struct PanelItemView: View {
    @Bindable var panel: Panel
    @Binding var selectedPanel: PanelID?
    @FocusState.Binding var focusedField: AnyHashable?
    var onDeletePanel: (Panel) -> Void
    var onDeleteElement: (Character) -> Void
    // Add closures for commands
    var onCommandAddPage: () -> Void
    var onCommandAddPanel: (Page) -> Void
    var onCommandAddCharacter: (String, Panel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Panel Header
            HStack { // Wrap header in HStack for Menu button
                Text("PANEL \(panel.panelNumber)")
                    .font(.system(size: 16, weight: .bold))
                    .padding(.bottom, 4) 
                    .contentShape(Rectangle()) 
                    .onTapGesture {          
                        print("Tapped Panel Header: \(panel.panelNumber). Setting selectedPanel.") // DEBUG
                        selectedPanel = panel.persistentModelID
                        focusedField = nil 
                    }
                Spacer() // Push menu button to the right
                Menu {
                    Button(role: .destructive) {
                        onDeletePanel(panel)
                    } label: {
                        Label("Delete Panel", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.body) 
                        .contentShape(Rectangle())
                        .padding(.leading, 5) 
                }
                .buttonStyle(.plain) 
            }
            
            // Panel Description 
            ScriptTextEditor(text: $panel.details, // Use direct binding
                             placeholder: "Panel description...", 
                             fieldId: "panel_\(panel.id)_details", 
                             focusedField: $focusedField,
                             pageContext: panel.page, // Pass page context if needed by editor
                             panelContext: panel,     // Pass panel context
                             onCommandAddPage: onCommandAddPage, 
                             onCommandAddPanel: onCommandAddPanel, // Pass function directly
                             onCommandAddCharacter: onCommandAddCharacter)
            .padding(.leading, 10) 
            .padding(.trailing, 30)
            
            // --- Character Elements --- 
            ForEach(panel.characters.sorted(by: { $0.createdAt < $1.createdAt })) { character in
                 CharacterElementView(character: character, 
                                      focusedField: $focusedField, 
                                      deleteAction: { onDeleteElement(character) }, 
                                      onCommandAddPage: onCommandAddPage, 
                                      onCommandAddPanel: onCommandAddPanel, // Pass function directly
                                      onCommandAddCharacter: onCommandAddCharacter)
            }
        }
        .padding(.vertical, 10) 
        .padding(.horizontal, 8)
        .background(selectedPanel == panel.persistentModelID ? Color.blue.opacity(0.1) : Color.clear) 
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(selectedPanel == panel.persistentModelID ? Color.blue : Color.clear, lineWidth: 1) 
        )
        .padding(.bottom, 15) 
    }
}

// MARK: - Character Element View
struct CharacterElementView: View {
    @Bindable var character: Character
    @FocusState.Binding var focusedField: AnyHashable?
    var deleteAction: () -> Void
    var onCommandAddPage: () -> Void
    var onCommandAddPanel: (Page) -> Void
    var onCommandAddCharacter: (String, Panel) -> Void
    
    var body: some View {
        let fieldId = "char_\(character.id)"
        VStack(alignment: .leading, spacing: 2) {
            if character.name == "CAPTION" { 
                Text("CAPTION:") 
                    .font(.system(size: 14, weight: .bold))
                    .padding(.leading, 10)
                ScriptTextEditor(text: $character.dialogue, // Use direct binding
                                 placeholder: "Caption text...", 
                                 fieldId: fieldId, 
                                 focusedField: $focusedField,
                                 characterToDelete: character,
                                 onDeleteTrigger: deleteAction,
                                 panelContext: character.panel, // Pass panel context
                                 onCommandAddPage: onCommandAddPage,
                                 onCommandAddPanel: onCommandAddPanel, // Pass function directly
                                 onCommandAddCharacter: onCommandAddCharacter)
                 .padding(.leading, 20) 
            } else if character.name == "SFX" { 
                Text("SFX:") 
                     .font(.system(size: 14, weight: .bold))
                     .padding(.leading, 10)
                ScriptTextEditor(text: $character.dialogue, // Use direct binding
                                 placeholder: "Sound effect...", 
                                 fieldId: fieldId, 
                                 focusedField: $focusedField,
                                 characterToDelete: character,
                                 onDeleteTrigger: deleteAction,
                                 panelContext: character.panel, // Pass panel context
                                 onCommandAddPage: onCommandAddPage,
                                 onCommandAddPanel: onCommandAddPanel, // Pass function directly
                                 onCommandAddCharacter: onCommandAddCharacter)
                 .padding(.leading, 20) 
            } else { 
                Text("\(character.name.uppercased()):") 
                    .font(.system(size: 14, weight: .bold))
                    .padding(.leading, 60) 
                ScriptTextEditor(text: $character.dialogue, // Use direct binding
                                 placeholder: "Dialogue...", 
                                 fieldId: fieldId, 
                                 focusedField: $focusedField,
                                 characterToDelete: character,
                                 onDeleteTrigger: deleteAction,
                                 panelContext: character.panel, // Pass panel context
                                 onCommandAddPage: onCommandAddPage,
                                 onCommandAddPanel: onCommandAddPanel, // Pass function directly
                                 onCommandAddCharacter: onCommandAddCharacter)
                 .padding(.leading, 30) 
                 .padding(.trailing, 30)
            }
        }
        .padding(.bottom, 5)
    }
}

// MARK: - Helper TextEditor View (Reusable)

struct ScriptTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let fieldId: AnyHashable
    @FocusState.Binding var focusedField: AnyHashable?
    // Add properties for backspace deletion
    var characterToDelete: Character? = nil 
    var onDeleteTrigger: (() -> Void)? = nil 
    // Add properties for command execution
    var pageContext: Page? = nil
    var panelContext: Panel? = nil
    var onCommandAddPage: (() -> Void)? = nil
    var onCommandAddPanel: ((Page) -> Void)? = nil
    var onCommandAddCharacter: ((String, Panel) -> Void)? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.top, 8) 
                    .padding(.leading, 5)
                    .allowsHitTesting(false) 
            }
            TextEditor(text: $text)
                .frame(minHeight: 40) 
                .focused($focusedField, equals: fieldId)
                .scrollContentBackground(.hidden) 
        }
    }
    
    // --- Add Coordinator for Delegate Methods --- 
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ScriptTextEditor

        init(_ parent: ScriptTextEditor) {
            self.parent = parent
        }
        
        // --- Implement delegate method for Backspace & Commands --- 
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            
            // --- BACKSPACE --- 
            if textView.text.isEmpty && range.location == 0 && range.length == 1 && text.isEmpty {
                if let deleteAction = parent.onDeleteTrigger, let character = parent.characterToDelete {
                    print("Backspace in empty field for \(character.name), triggering delete.")
                    deleteAction()
                    return false 
                }
            }
            
            // --- ENTER KEY / COMMANDS --- 
            if text == "\n" { 
                let currentText = textView.text ?? ""
                let lineRange = currentText.lineRange(for: Range(range, in: currentText)!)
                let lineText = String(currentText[lineRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if range.location == lineRange.upperBound.utf16Offset(in: currentText) - lineText.utf16.count + lineText.utf16.count { 
                    if lineText.lowercased() == "page", let commandAction = parent.onCommandAddPage {
                        print("Page command detected")
                        commandAction()
                        textView.text = "" 
                        return false
                    }
                    if lineText.lowercased() == "panel", let commandAction = parent.onCommandAddPanel, let pageCtx = parent.pageContext {
                        print("Panel command detected")
                        commandAction(pageCtx)
                        textView.text = ""
                        return false
                    }
                    let nameRegex = try! NSRegularExpression(pattern: "^([A-Za-z0-9\\s()]+):$") 
                    if let match = nameRegex.firstMatch(in: lineText, range: NSRange(lineText.startIndex..., in: lineText)),
                       let nameRange = Range(match.range(at: 1), in: lineText), 
                       let commandAction = parent.onCommandAddCharacter,
                       let panelCtx = parent.panelContext {
                        let characterName = String(lineText[nameRange]).trimmingCharacters(in: .whitespaces)
                        print("Character command detected: \(characterName)")
                        commandAction(characterName, panelCtx)
                        textView.text = ""
                        return false
                    }
                }
                // --- Default Enter: Newline --- 
                if textView.isFirstResponder {
                    textView.textStorage.replaceCharacters(in: range, with: "\n")
                    if let newPosition = textView.position(from: textView.beginningOfDocument, offset: range.location + 1) {
                        textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                    }
                    return false 
                }
            }
            return true
        }
        
        func textViewDidChange(_ textView: UITextView) {
             parent.text = textView.text
        }
    }
} 
