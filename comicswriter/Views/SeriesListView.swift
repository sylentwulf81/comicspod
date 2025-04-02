import SwiftUI
import SwiftData

struct SeriesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var series: [Series]
    @State private var showingAddSeriesSheet = false
    @State private var seriesForDeletion: Series? = nil
    @State private var showingDeleteConfirmation = false
    
    private let gridColumns = [
        GridItem(.adaptive(minimum: 150), spacing: 20)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(series) { seriesItem in
                        ZStack(alignment: .topTrailing) {
                            NavigationLink(destination: IssueListView(series: seriesItem)) {
                                SeriesCoverView(series: seriesItem)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Options menu for each series
                            Menu {
                                Button(role: .destructive) {
                                    seriesForDeletion = seriesItem
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete Series", systemImage: "trash")
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
                    
                    // Add new series button
                    Button(action: { showingAddSeriesSheet = true }) {
                        VStack {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 40))
                            Text("New Series")
                                .font(.caption)
                        }
                        .frame(width: 150, height: 200)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Comic Series")
            .sheet(isPresented: $showingAddSeriesSheet) {
                AddSeriesSheet()
            }
            .alert("Delete Series", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    seriesForDeletion = nil
                }
                Button("Delete", role: .destructive) {
                    if let seriesItem = seriesForDeletion {
                        deleteSeries(seriesItem)
                        seriesForDeletion = nil
                    }
                }
            } message: {
                if let seriesItem = seriesForDeletion {
                    Text("Are you sure you want to delete \"\(seriesItem.title)\"? This will delete all issues and pages within this series. This action cannot be undone.")
                } else {
                    Text("Are you sure you want to delete this series?")
                }
            }
        }
    }
    
    private func deleteSeries(_ series: Series) {
        // First delete all associated issues, pages, panels, and characters
        for issue in series.issues {
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
            modelContext.delete(issue)
        }
        
        // Then delete the series itself
        modelContext.delete(series)
    }
}

struct SeriesCoverView: View {
    let series: Series
    
    var body: some View {
        VStack(spacing: 0) {
            // Cover image or placeholder with title
            if let coverImage = series.coverImage {
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
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text(series.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 8)
                    }
                }
            }
            
            // Title and issue count in a more prominent container
            VStack(spacing: 2) {
                Text(series.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("\(series.issues.count) Issue\(series.issues.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

struct AddSeriesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title = ""
    @State private var synopsis = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Series Details")) {
                    TextField("Title", text: $title)
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
            .navigationTitle("New Series")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSeries()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    private func createSeries() {
        let newSeries = Series(
            title: title,
            synopsis: synopsis,
            coverImageData: selectedImage?.jpegData(compressionQuality: 0.8)
        )
        modelContext.insert(newSeries)
    }
}

#Preview {
    SeriesListView()
        .modelContainer(for: [Series.self], inMemory: true)
} 