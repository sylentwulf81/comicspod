import SwiftUI
import SwiftData

struct SeriesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Series.createdAt, order: .reverse) private var series: [Series]
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
                            NavigationLink(destination: IssueGridView(series: seriesItem)) {
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
                    .ignoresSafeArea(.keyboard, edges: .bottom)
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
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 0) {
            // Cover image or placeholder with title
            ZStack(alignment: .bottom) {
                if let coverImage = series.coverImage {
                    coverImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150)
                        .aspectRatio(2/3, contentMode: .fill)
                        .clipped()
                        .overlay(alignment: .topTrailing) {
                            // Edit button for changing cover
                            Button {
                                showingImagePicker = true
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                                    .padding(8)
                            }
                        }
                } else {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 150)
                        .aspectRatio(2/3, contentMode: .fill)
                        .overlay(alignment: .topTrailing) {
                            // Edit button for adding cover
                            Button {
                                showingImagePicker = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                                    .padding(8)
                            }
                        }
                        
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        Text(series.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 8)
                    }
                }
                
                // Title overlay at the bottom
                VStack(spacing: 1) {
                    Text(series.title)
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("\(series.issues.count) Issue\(series.issues.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.7), Color.black.opacity(0)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
        }
        .frame(width: 150)
        .aspectRatio(2/3, contentMode: .fit)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
                .onDisappear {
                    if let selectedImage {
                        updateCoverImage(selectedImage)
                    }
                }
        }
    }
    
    // Function to update the cover image
    private func updateCoverImage(_ image: UIImage) {
        // Set the new cover image
        series.coverImageData = image.jpegData(compressionQuality: 0.8)
        
        // Update timestamp
        series.updatedAt = Date()
        
        // Clear selected image
        selectedImage = nil
    }
}

struct AddSeriesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title = ""
    @State private var synopsis = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, synopsis
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Split into separate sections for better layout
                Section(header: Text("Title")) {
                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title)
                }
                
                Section(header: Text("Synopsis")) {
                    TextField("Synopsis", text: $synopsis, axis: .vertical)
                        .lineLimit(4)
                        .focused($focusedField, equals: .synopsis)
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
                
                // Add keyboard toolbar
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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