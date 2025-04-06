import SwiftUI
import SwiftData

struct SeriesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var series: [Series]
    @State private var showingAddSeries = false
    @State private var searchText = ""
    @State private var selectedCategory: CoverCategory? = nil
    
    // Apply both text search and category filter
    private var filteredSeries: [Series] {
        series.filter { item in
            let matchesText = searchText.isEmpty || 
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.synopsis.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || 
                item.category == selectedCategory
                
            return matchesText && matchesCategory
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // All category option
                        CategoryChip(
                            category: nil, 
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )
                        
                        // Individual categories
                        ForEach(CoverCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { 
                                    if selectedCategory == category {
                                        selectedCategory = nil
                                    } else {
                                        selectedCategory = category 
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
                
                // Series list
                List {
                    ForEach(filteredSeries) { seriesItem in
                        NavigationLink {
                            IssueListView(series: seriesItem)
                        } label: {
                            SeriesRowView(series: seriesItem)
                        }
                    }
                    .onDelete(perform: deleteSeries)
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search series")
            }
            .navigationTitle("Series")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSeries = true
                    } label: {
                        Label("Add Series", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSeries) {
                AddSeriesView()
            }
        }
    }
    
    private func deleteSeries(offsets: IndexSet) {
        for index in offsets {
            let seriesToDelete = filteredSeries[index]
            modelContext.delete(seriesToDelete)
        }
    }
}

// Category chip component for filtering
struct CategoryChip: View {
    let category: CoverCategory?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category?.rawValue ?? "All")
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? 
                              (category?.color ?? Color.primary).opacity(0.2) : 
                              Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? 
                                (category?.color ?? Color.primary).opacity(0.5) : 
                                Color(.systemGray4), 
                                lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// Update SeriesRowView to show the category
struct SeriesRowView: View {
    let series: Series
    @State private var showEditSheet = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Series cover image or placeholder
            if let image = series.coverImage {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 80)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 80)
                    .cornerRadius(6)
                    .overlay(
                        Image(systemName: "book.closed")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(series.title)
                    .font(.headline)
                
                Text("\(series.issues.count) issue\(series.issues.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Category badge
                Text(series.category.rawValue)
                    .font(.caption)
                    .foregroundColor(series.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(series.category.color.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(series.category.color.opacity(0.3), lineWidth: 1)
                    )
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
            EditSeriesView(series: series)
        }
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

// Edit Series View
struct EditSeriesView: View {
    @Environment(\.dismiss) private var dismiss
    
    let series: Series
    
    @State private var title: String
    @State private var synopsis: String
    @State private var selectedCategory: CoverCategory
    @State private var showImagePicker = false
    @State private var coverImage: UIImage?
    
    init(series: Series) {
        self.series = series
        _title = State(initialValue: series.title)
        _synopsis = State(initialValue: series.synopsis)
        _selectedCategory = State(initialValue: series.category)
        
        if let imageData = series.coverImageData, 
           let uiImage = UIImage(data: imageData) {
            _coverImage = State(initialValue: uiImage)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Series Information") {
                    TextField("Title", text: $title)
                    
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
            .navigationTitle("Edit Series")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateSeries()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $coverImage)
            }
        }
    }
    
    private func updateSeries() {
        // Only update if title is not empty
        guard !title.isEmpty else { return }
        
        // Update series properties
        series.title = title
        series.synopsis = synopsis
        series.category = selectedCategory
        
        // Update cover image if changed
        if let image = coverImage {
            series.coverImageData = image.jpegData(compressionQuality: 0.8)
        }
        
        // Update timestamp
        series.updatedAt = Date()
        
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
        case .indie: return "music.note.list"
        case .other: return "book.fill"
        }
    }
}

#Preview {
    SeriesListView()
        .modelContainer(for: [Series.self], inMemory: true)
} 
