import SwiftUI
import SwiftData

struct IssueListView: View {
    @Environment(\.modelContext) private var modelContext
    let series: Series
    @State private var showingAddIssueSheet = false
    @State private var issueForDeletion: Issue? = nil
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
            AddIssueSheet(series: series)
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
    
    private func deleteIssue(_ issue: Issue) {
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
    let issue: Issue
    
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

struct AddIssueSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let series: Series
    
    @State private var title = ""
    @State private var issueNumber = 1
    @State private var synopsis = ""
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
        let newIssue = Issue(
            title: title,
            issueNumber: issueNumber,
            synopsis: synopsis,
            coverImageData: selectedImage?.jpegData(compressionQuality: 0.8),
            series: series
        )
        modelContext.insert(newIssue)
        series.issues.append(newIssue)
        series.updatedAt = Date()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Series.self, Issue.self, Page.self, Panel.self, Character.self, configurations: config)
    
    let previewSeries = Series(title: "Amazing Series")
    container.mainContext.insert(previewSeries)
    
    return IssueListView(series: previewSeries)
        .modelContainer(container)
} 