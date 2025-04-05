// This file is for type compatibility with the ComicsModels.swift file
import SwiftUI
import SwiftData

// Add a typealias to create compatibility between the two model types
typealias Issue = ComicIssue

extension ComicIssue {
    // Add these properties for compatibility with newer code
    var coverImageType: String {
        get { UserDefaults.standard.string(forKey: "issue_\(String(describing: self.id))_coverImageType") ?? "classic" }
        set { UserDefaults.standard.set(newValue, forKey: "issue_\(String(describing: self.id))_coverImageType") }
    }
    
    var coverTitlePosition: String {
        get { UserDefaults.standard.string(forKey: "issue_\(String(describing: self.id))_coverTitlePosition") ?? "bottom" }
        set { UserDefaults.standard.set(newValue, forKey: "issue_\(String(describing: self.id))_coverTitlePosition") }
    }
    
    var showCoverTitle: Bool {
        get { UserDefaults.standard.bool(forKey: "issue_\(String(describing: self.id))_showCoverTitle") }
        set { UserDefaults.standard.set(newValue, forKey: "issue_\(String(describing: self.id))_showCoverTitle") }
    }
    
    var customCoverImageData: Data? {
        get { coverImageData }
        set { coverImageData = newValue }
    }
} 