import SwiftUI
import SwiftData

struct IssueCard: View {
    let issue: ComicIssue
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationLink(destination: ScriptEditorView(issue: issue)) {
            VStack(spacing: 0) {
                // Cover image with transparent title overlay
                ZStack(alignment: getAlignment()) {
                    coverImage
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(2/3, contentMode: .fill)
                        .clipped()
                        .overlay(alignment: .topTrailing) {
                            // Edit button for changing cover
                            Button {
                                showingImagePicker = true
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                                    .padding(8)
                            }
                        }
                    
                    // Title overlay - made smaller and more transparent
                    VStack(spacing: 2) {
                        Text(issue.title)
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                        
                        Text("ISSUE #\(issue.issueNumber)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6) // Reduced padding
                    .background(getGradient())
                }
                
                // Info bar
                HStack {
                    Text("Pages: \(issue.pages.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDate(issue.updatedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
            }
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .shadow(radius: 1)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
                .onDisappear {
                    if let selectedImage {
                        updateCoverImage(selectedImage)
                    }
                }
        }
    }
    
    private var coverImage: Image {
        if issue.coverImageType == "custom", let imageData = issue.customCoverImageData, let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        } else {
            // Use the predefined image based on coverImageType
            return Image(getCoverImageName())
        }
    }
    
    private func getCoverImageName() -> String {
        switch issue.coverImageType {
            case "modern": return "coverPlaceholder2"
            case "minimal": return "coverPlaceholder3"
            case "custom": return "coverPlaceholder4"
            default: return "coverPlaceholder1"
        }
    }
    
    private func getAlignment() -> Alignment {
        switch issue.coverTitlePosition {
            case "top": return .top
            case "overlay": return .center
            default: return .bottom
        }
    }
    
    private func getGradient() -> LinearGradient {
        if issue.coverTitlePosition == "overlay" {
            return LinearGradient(
                colors: [Color.black.opacity(0.3), Color.black.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Color.black.opacity(0.7), Color.black.opacity(0)],
                startPoint: issue.coverTitlePosition == "top" ? .top : .bottom,
                endPoint: issue.coverTitlePosition == "top" ? .bottom : .top
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    // Function to update the cover image
    private func updateCoverImage(_ image: UIImage) {
        // Set the new cover image
        issue.customCoverImageData = image.jpegData(compressionQuality: 0.8)
        
        // Set the cover type to custom since we now have a custom image
        issue.coverImageType = "custom"
        
        // Update the timestamp
        issue.updatedAt = Date()
        
        // Clear the selected image
        selectedImage = nil
    }
}

struct IssueGridView: View {
    let series: Series
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddSheet = false
    @State private var issues: [ComicIssue] = []
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 180))], spacing: 16) {
                // Use the filtered issues rather than directly using the @Query results
                ForEach(issues.sorted(by: { $0.issueNumber < $1.issueNumber })) { issue in
                    IssueCard(issue: issue)
                        .aspectRatio(0.7, contentMode: .fit)
                }
                
                // Add Issue Button
                Button {
                    showingAddSheet = true
                } label: {
                    VStack {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 30))
                        Text("Add Issue")
                            .font(.headline)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(0.7, contentMode: .fit)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle(series.title)
        .sheet(isPresented: $showingAddSheet) {
            NewIssueSheetView(series: series)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            // Load issues from the series relationship directly
            issues = Array(series.issues)
        }
        .onChange(of: series.issues.count) { _, _ in
            // Refresh the issues when the count changes
            issues = Array(series.issues)
        }
    }
}

struct NewIssueSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let series: Series
    
    @State private var title = ""
    @State private var issueNumber = ""
    @State private var synopsis = ""
    @State private var coverStyle: CoverStyleOption = .classic
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, issueNumber, synopsis
    }
    
    enum CoverStyleOption: String, CaseIterable, Identifiable {
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
    
    var body: some View {
        NavigationStack {
            Form {
                // Split into separate sections for better layout
                Section("Title") {
                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title)
                }
                
                Section("Issue Number") {
                    TextField("Issue Number", text: $issueNumber)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .issueNumber)
                }
                
                Section("Synopsis") {
                    TextField("Synopsis", text: $synopsis, axis: .vertical)
                        .lineLimit(4...)
                        .focused($focusedField, equals: .synopsis)
                }
                
                Section("Cover Style") {
                    Picker("Style", selection: $coverStyle) {
                        ForEach(CoverStyleOption.allCases) { style in
                            HStack {
                                Image(style.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 60)
                                    .cornerRadius(4)
                                    .clipped()
                                
                                Text(style.rawValue)
                            }
                            .tag(style)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    // Preview of selected style
                    coverPreview
                }
                
                Section {
                    Button("Create Issue") {
                        saveIssue()
                    }
                    .disabled(title.isEmpty)
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
                
                // Add keyboard toolbar
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private var coverPreview: some View {
        ZStack(alignment: .bottom) {
            Image(coverStyle.imageName)
                .resizable()
                .scaledToFill()
                .cornerRadius(8)
                .clipped()
            
            // Title overlay
            VStack(spacing: 2) {
                Text(title.isEmpty ? "Issue Title" : title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("ISSUE #\(issueNumber.isEmpty ? "1" : issueNumber)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.8), Color.black.opacity(0)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
        .frame(height: 200)
        .padding(.vertical, 8)
    }
    
    private func saveIssue() {
        let issueNum = Int(issueNumber) ?? 1
        
        let newIssue = ComicIssue(
            title: title,
            issueNumber: issueNum,
            synopsis: synopsis,
            series: series
        )
        
        // Set cover image properties
        newIssue.coverImageType = coverStyle.rawValue.lowercased()
        newIssue.coverTitlePosition = "bottom" // Default
        newIssue.showCoverTitle = true
        
        modelContext.insert(newIssue)
        series.issues.append(newIssue)
        
        // Create the first page
        let firstPage = Page(pageNumber: 1, issue: newIssue)
        modelContext.insert(firstPage)
        newIssue.pages.append(firstPage)
        
        // Create the first panel on the first page
        let firstPanel = Panel(panelNumber: 1, page: firstPage)
        modelContext.insert(firstPanel)
        firstPage.panels.append(firstPanel)
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Series.self, ComicIssue.self, Page.self, Panel.self, Character.self, configurations: config)
    
    let previewSeries = Series(title: "Example Series")
    let previewIssue = ComicIssue(title: "First Issue", issueNumber: 1, series: previewSeries)
    
    container.mainContext.insert(previewSeries)
    container.mainContext.insert(previewIssue)
    previewSeries.issues.append(previewIssue)
    
    return NavigationStack {
        IssueGridView(series: previewSeries)
    }
    .modelContainer(container)
} 