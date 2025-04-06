import SwiftUI

struct CoverSelector: View {
    @Binding var selectedImage: UIImage?
    @Binding var selectedCategory: CoverCategory
    @Environment(\.dismiss) private var presentationModeDismiss
    @State private var showCustomImagePicker = false
    
    // Grid layout
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 10)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categorySelector
                contentScrollView
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if newValue != nil {
                    presentationModeDismiss()
                }
            }
            .navigationTitle("Select Cover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationModeDismiss()
                    }
                }
            }
            .sheet(isPresented: $showCustomImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    // MARK: - Subviews (Computed Properties)
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CoverCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var contentScrollView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Predefined Covers")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(CoverCategory.coverImages(for: selectedCategory), id: \.self) { imageName in
                        PredefinedCoverButton(
                            imageName: imageName,
                            onSelect: { image in
                                self.selectedImage = image
                                presentationModeDismiss()
                            }
                        )
                    }
                }
                .padding()
                
                Text("Custom Cover")
                    .font(.headline)
                    .padding(.horizontal)
                
                Button(action: {
                    showCustomImagePicker = true
                }) {
                    VStack {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 30))
                        Text("Choose Photo")
                            .font(.caption)
                    }
                    .frame(width: 100, height: 140)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

struct CategoryButton: View {
    let category: CoverCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? 
                              category.color.opacity(0.2) : 
                              Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? 
                                category.color.opacity(0.5) : 
                                Color(.systemGray4), 
                                lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct PredefinedCoverButton: View {
    let imageName: String
    let onSelect: (UIImage) -> Void
    
    var body: some View {
        Button(action: {
            if let image = UIImage(named: imageName) {
                onSelect(image)
            }
        }) {
            if let image = UIImage(named: imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 140)
                    .cornerRadius(8)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                // Placeholder if image not found
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                    Text(imageName)
                        .font(.caption)
                        .lineLimit(1)
                }
                .frame(width: 100, height: 140)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @State var selectedImage: UIImage? = nil
    @State var selectedCategory: CoverCategory = .superhero
    
    return CoverSelector(selectedImage: $selectedImage, selectedCategory: $selectedCategory)
} 