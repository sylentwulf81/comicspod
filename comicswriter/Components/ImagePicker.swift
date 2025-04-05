import SwiftUI
import UIKit

// Simplified image picker that doesn't rely on PhotosUI
struct ImagePicker: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    @State private var selectedGenre: Genre = .all
    @State private var availableCovers: [Int] = []
    @State private var showingUIImagePicker = false
    
    enum Genre: String, CaseIterable, Identifiable {
        case all = "All"
        case indie = "Indie"
        case superHero = "Super-Hero" 
        case crime = "Crime"
        case western = "Western"
        case horror = "Horror"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Genre selector
            VStack(alignment: .leading) {
                Text("Select Genre")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Genre.allCases) { genre in
                            Button {
                                selectedGenre = genre
                            } label: {
                                Text(genre.rawValue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedGenre == genre ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedGenre == genre ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
            
            // Preview of selected image
            if let image = image {
                VStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding()
                    
                    Button("Choose Different Cover") {
                        self.image = nil
                    }
                    .padding(.bottom)
                }
            } else {
                // Tabs for template vs custom
                VStack {
                    HStack {
                        Button {
                            showingUIImagePicker = true
                        } label: {
                            Label("Choose from Photos", systemImage: "photo.on.rectangle.angled")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("Or Choose a Template")
                        .font(.headline)
                        .padding(.top)
                    
                    // Cover templates grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 100))], spacing: 16) {
                            // Use available placeholder images
                            ForEach(availableCovers, id: \.self) { index in
                                Button {
                                    if let templateImage = UIImage(named: "coverPlaceholder\(index)") {
                                        self.image = templateImage
                                    }
                                } label: {
                                    VStack {
                                        // Use UIImage instead of Image for more reliable loading
                                        if let uiImage = UIImage(named: "coverPlaceholder\(index)") {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 120)
                                                .cornerRadius(8)
                                                .clipped()
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 80, height: 120)
                                                .overlay(
                                                    Text("\(index)")
                                                        .foregroundColor(.white)
                                                )
                                        }
                                        
                                        Text("Cover \(index)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            
            Button("Done") {
                dismiss()
            }
            .disabled(image == nil)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(image == nil ? Color.gray.opacity(0.3) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onAppear {
            // Check which images actually exist
            checkAvailableCovers()
        }
        .sheet(isPresented: $showingUIImagePicker) {
            UIImagePickerControllerRepresentation(image: $image)
        }
    }
    
    // Function to check which cover images are available
    private func checkAvailableCovers() {
        var available: [Int] = []
        
        for index in 1...22 {
            if UIImage(named: "coverPlaceholder\(index)") != nil {
                available.append(index)
            }
        }
        
        self.availableCovers = available
    }
}

// UIKit Image Picker wrapper
struct UIImagePickerControllerRepresentation: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: UIImagePickerControllerRepresentation
        
        init(_ parent: UIImagePickerControllerRepresentation) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
} 