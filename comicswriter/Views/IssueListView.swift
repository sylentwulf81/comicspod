import SwiftUI
import SwiftData
import UIKit

struct IssueListView: View {
    @Environment(\.modelContext) private var modelContext
    let series: Series
    @State private var showingAddIssueSheet = false
    @State private var issueForDeletion: ComicIssue? = nil
    @State private var showingDeleteConfirmation = false
    
    private let gridColumns = [
        GridItem(.adaptive(minimum: 150), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 20) {
                ForEach(series.issues.sorted(by: { $0.issueNumber < $1.issueNumber })) { issue in
                    ZStack(alignment: .topTrailing) {
                        NavigationLink(destination: ScriptEditorView(issue: issue)) {
                            IssueCoverView(issue: issue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Options menu for each issue
                        Menu {
                            Button(role: .destructive) {
                                issueForDeletion = issue
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Issue", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .padding(8)
                        }
                    }
                }
                
                // Add new issue button
                Button(action: { showingAddIssueSheet = true }) {
                    VStack {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 40))
                        Text("New Issue")
                            .font(.caption)
                    }
                    .frame(width: 150, height: 200)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle(series.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddIssueSheet) {
            AddIssueSheetView(series: series)
        }
        .alert("Delete Issue", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                issueForDeletion = nil
            }
            Button("Delete", role: .destructive) {
                if let issue = issueForDeletion {
                    deleteIssue(issue)
                    issueForDeletion = nil
                }
            }
        } message: {
            if let issue = issueForDeletion {
                Text("Are you sure you want to delete Issue #\(issue.issueNumber): \"\(issue.title)\"? This will delete all pages and content within this issue. This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete this issue?")
            }
        }
    }
    
    private func deleteIssue(_ issue: ComicIssue) {
        // First delete all pages, panels, and characters in the issue
        for page in issue.pages {
            for panel in page.panels {
                // Delete all characters in the panel
                for character in panel.characters {
                    modelContext.delete(character)
                }
                modelContext.delete(panel)
            }
            modelContext.delete(page)
        }
        
        // Remove the issue from the series
        series.issues.removeAll(where: { $0.id == issue.id })
        
        // Then delete the issue itself
        modelContext.delete(issue)
        
        // Update the series lastUpdated timestamp
        series.updatedAt = Date()
    }
}

struct IssueCoverView: View {
    let issue: ComicIssue
    
    var body: some View {
        VStack(spacing: 0) {
            // Cover image or placeholder with issue number
            if let coverImage = issue.coverImage {
                coverImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipped()
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 150)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "magazine")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("ISSUE #\(issue.issueNumber)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Issue number and title in a more prominent container
            VStack(spacing: 2) {
                Text("Issue #\(issue.issueNumber)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text(issue.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .frame(width: 150)
            .background(Color(.systemGray6))
        }
        .frame(width: 150, height: 200)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

struct AddIssueSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let series: Series
    
    @State private var title = ""
    @State private var issueNumber = 1
    @State private var synopsis = ""
    @State private var selectedCategory: CoverCategory = .other
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Issue Details")) {
                    TextField("Title", text: $title)
                    
                    Stepper("Issue #\(issueNumber)", value: $issueNumber, in: 1...1000)
                    
                    TextField("Synopsis", text: $synopsis, axis: .vertical)
                        .lineLimit(4)
                }
                
                Section(header: Text("Cover Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(CoverCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: categoryIcon(for: category))
                                .foregroundColor(category.color)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section(header: Text("Cover Image")) {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    
                    Button("Select Image") {
                        showingImagePicker = true
                    }
                }
            }
            .navigationTitle("New Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createIssue()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onAppear {
                // Set default issue number to next in series
                issueNumber = (series.issues.map { $0.issueNumber }.max() ?? 0) + 1
            }
        }
    }
    
    private func createIssue() {
        let newIssue = ComicIssue(
            title: title,
            issueNumber: issueNumber,
            synopsis: synopsis,
            coverImageData: selectedImage?.jpegData(compressionQuality: 0.8),
            series: series,
            coverCategory: selectedCategory
        )
        modelContext.insert(newIssue)
        series.issues.append(newIssue)
        series.updatedAt = Date()
    }
    
    // Helper to get appropriate icon for each category
    private func categoryIcon(for category: CoverCategory) -> String {
        switch category {
        case .superhero: return "bolt.fill"
        case .horror: return "ghost.fill"
        case .sciFi: return "planet"
        case .fantasy: return "wand.and.stars"
        case .action: return "flame.fill"
        case .drama: return "theatermasks.fill"
        case .comedy: return "face.smiling.fill"
        case .western: return "tent.fill"
        case .crime: return "magnifyingglass"
        case .indie: return "figure"
        case .other: return "book.fill"
        }
    }
}

struct IssueRowView: View {
    let issue: ComicIssue
    @State private var showEditSheet = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Issue cover image or placeholder
            if let image = issue.coverImage {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 70)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 70)
                    .cornerRadius(6)
                    .overlay(
                        Image(systemName: "book.closed")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.headline)
                
                Text("Issue #\(issue.issueNumber)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    // Pages count
                    Text("\(issue.pages.count) pages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Category badge
                    Text(issue.category.rawValue)
                        .font(.caption)
                        .foregroundColor(issue.category.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(issue.category.color.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(issue.category.color.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
            Spacer()
            
            Button(action: {
                showEditSheet = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showEditSheet) {
            EditIssueView(issue: issue)
        }
    }
}

// Edit Issue View
struct EditIssueView: View {
    @Environment(\.dismiss) private var dismiss
    
    let issue: ComicIssue
    
    @State private var title: String
    @State private var issueNumber: Int
    @State private var synopsis: String
    @State private var selectedCategory: CoverCategory
    @State private var showImagePicker = false
    @State private var coverImage: UIImage?
    
    init(issue: ComicIssue) {
        self.issue = issue
        _title = State(initialValue: issue.title)
        _issueNumber = State(initialValue: issue.issueNumber)
        _synopsis = State(initialValue: issue.synopsis)
        _selectedCategory = State(initialValue: issue.category)
        
        if let imageData = issue.coverImageData, 
           let uiImage = UIImage(data: imageData) {
            _coverImage = State(initialValue: uiImage)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Issue Information") {
                    TextField("Title", text: $title)
                    
                    Stepper("Issue Number: \(issueNumber)", value: $issueNumber, in: 1...1000)
                    
                    TextField("Synopsis", text: $synopsis, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
                
                Section("Cover Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(CoverCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: categoryIcon(for: category))
                                .foregroundColor(category.color)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section("Cover Image") {
                    HStack {
                        Spacer()
                        
                        if let image = coverImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(8)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                
                                Text("No Image Selected")
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 200)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showImagePicker = true
                    }
                }
            }
            .navigationTitle("Edit Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateIssue()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $coverImage)
            }
        }
    }
    
    private func updateIssue() {
        // Only update if title is not empty
        guard !title.isEmpty else { return }
        
        // Update issue properties
        issue.title = title
        issue.issueNumber = issueNumber
        issue.synopsis = synopsis
        issue.category = selectedCategory
        
        // Update cover image if changed
        if let image = coverImage {
            issue.coverImageData = image.jpegData(compressionQuality: 0.8)
        }
        
        // Update timestamp
        issue.updatedAt = Date()
        
        // Dismiss sheet
        dismiss()
    }
    
    // Helper to get appropriate icon for each category
    private func categoryIcon(for category: CoverCategory) -> String {
        switch category {
        case .superhero: return "bolt.fill"
        case .horror: return "ghost.fill"
        case .sciFi: return "planet"
        case .fantasy: return "wand.and.stars"
        case .action: return "flame.fill"
        case .drama: return "theatermasks.fill"
        case .comedy: return "face.smiling.fill"
        case .western: return "tent.fill"
        case .crime: return "magnifyingglass"
        case .indie: return "figure"
        case .other: return "book.fill"
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Series.self, ComicIssue.self, Page.self, Panel.self, Character.self, configurations: config)
    
    let previewSeries = Series(title: "Amazing Series")
    container.mainContext.insert(previewSeries)
    
    return NavigationStack {
        IssueListView(series: previewSeries)
            .modelContainer(container)
    }
} 
