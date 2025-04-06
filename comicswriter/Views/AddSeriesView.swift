import SwiftUI
import SwiftData

struct AddSeriesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title = ""
    @State private var synopsis = ""
    @State private var selectedCategory: CoverCategory = .other
    @State private var showImagePicker = false
    @State private var coverImage: UIImage?
    
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
                
                Section {
                    Button("Create Series") {
                        createSeries()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(title.isEmpty)
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
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $coverImage)
            }
        }
    }
    
    private func createSeries() {
        guard !title.isEmpty else { return }
        
        // Convert UIImage to Data if available
        let imageData = coverImage?.jpegData(compressionQuality: 0.8)
        
        // Create new series with the selected category
        let newSeries = Series(
            title: title,
            synopsis: synopsis,
            coverImageData: imageData,
            coverCategory: selectedCategory
        )
        
        // Save to database
        modelContext.insert(newSeries)
        
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
        case .indie: return "figure"
        case .crime: return "magnifyingglass"
        case .other: return "book.fill"
        }
    }
} 
