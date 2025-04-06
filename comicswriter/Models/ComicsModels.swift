import Foundation
import SwiftData
import SwiftUI

// Add a CoverCategory enum for categorizing series and issue covers
enum CoverCategory: String, CaseIterable, Codable {
    case superhero = "Superhero"
    case horror = "Horror"
    case sciFi = "Science Fiction"
    case fantasy = "Fantasy"
    case action = "Action"
    case drama = "Drama"
    case comedy = "Comedy"
    case western = "Western"
    case crime = "Crime"
    case indie = "Indie"
    case other = "Other"
    
    var color: Color {
        switch self {
        case .superhero: return .blue
        case .horror: return .red
        case .sciFi: return .purple
        case .fantasy: return .green
        case .action: return .orange
        case .drama: return .indigo
        case .comedy: return .yellow
        case .western: return .brown
        case .crime: return .gray
        case .indie: return .pink
        case .other: return .secondary
        }
    }
    
    // Get predefined cover images for a specific category
    static func coverImages(for category: CoverCategory) -> [String] {
        switch category {
        case .superhero:
            return ["superhero1", "superhero2", "superhero3", "superhero4", "superhero5"]
        case .horror:
            return ["horror1", "horror2", "horror3", "horror4", "horror5"]
        case .sciFi:
            return ["scifi1", "scifi2", "scifi3", "scifi4", "scifi5"]
        case .fantasy:
            return ["fantasy1", "fantasy2", "fantasy3", "fantasy4", "fantasy5"]
        case .action:
            return ["action1", "action2", "action3", "action4", "action5"]
        case .drama:
            return ["drama1", "drama2", "drama3", "drama4", "drama5"]
        case .comedy:
            return ["comedy1", "comedy2", "comedy3", "comedy4", "comedy5"]
        case .western:
            return ["western1", "western2", "western3", "western4", "western5"]
        case .crime:
            return ["crime1", "crime2", "crime3", "crime4", "crime5", "crime6"]
        case .indie:
            return ["indie1", "indie2", "indie3", "indie4", "indie5", "indie6"]
        case .other:
            return ["series1", "series2", "series3", "series4", "series5"]
        }
    }
    
    // Get all predefined cover images organized by category
    static var allCoverImagesByCategory: [CoverCategory: [String]] {
        var result: [CoverCategory: [String]] = [:]
        for category in CoverCategory.allCases {
            result[category] = coverImages(for: category)
        }
        return result
    }
}

@Model
final class Series {
    var title: String
    var synopsis: String
    var coverImageData: Data?
    @Relationship(deleteRule: .cascade, inverse: \ComicIssue.series)
    var issues: [ComicIssue] = []
    var createdAt: Date
    var updatedAt: Date
    var coverCategory: String // Store the cover category as a string
    
    var coverImage: Image? {
        if let data = coverImageData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    init(title: String, synopsis: String = "", coverImageData: Data? = nil, coverCategory: CoverCategory = .other) {
        self.title = title
        self.synopsis = synopsis
        self.coverImageData = coverImageData
        self.createdAt = Date()
        self.updatedAt = Date()
        self.coverCategory = coverCategory.rawValue
    }
    
    // Helper computed property to work with the category enum
    var category: CoverCategory {
        get {
            return CoverCategory(rawValue: coverCategory) ?? .other
        }
        set {
            coverCategory = newValue.rawValue
        }
    }
}

@Model
final class ComicIssue {
    var title: String
    var issueNumber: Int
    var synopsis: String
    var coverImageData: Data?
    @Relationship(deleteRule: .cascade, inverse: \Page.issue)
    var pages: [Page] = []
    var series: Series?
    var createdAt: Date
    var updatedAt: Date
    var coverCategory: String // Store the cover category as a string
    
    var coverImage: Image? {
        if let data = coverImageData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    init(title: String, issueNumber: Int, synopsis: String = "", coverImageData: Data? = nil, series: Series? = nil, coverCategory: CoverCategory = .other) {
        self.title = title
        self.issueNumber = issueNumber
        self.synopsis = synopsis
        self.coverImageData = coverImageData
        self.series = series
        self.createdAt = Date()
        self.updatedAt = Date()
        self.coverCategory = coverCategory.rawValue
    }
    
    // Helper computed property to work with the category enum
    var category: CoverCategory {
        get {
            return CoverCategory(rawValue: coverCategory) ?? .other
        }
        set {
            coverCategory = newValue.rawValue
        }
    }
}

@Model
final class Page {
    var pageNumber: Int
    var issue: ComicIssue?
    @Relationship(deleteRule: .cascade, inverse: \Panel.page)
    var panels: [Panel] = []
    var createdAt: Date
    var updatedAt: Date
    
    init(pageNumber: Int, issue: ComicIssue? = nil) {
        self.pageNumber = pageNumber
        self.issue = issue
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class Panel {
    var panelNumber: Int
    var details: String
    var page: Page?
    @Relationship(deleteRule: .cascade, inverse: \Character.panel)
    var characters: [Character] = []
    var createdAt: Date
    var updatedAt: Date
    
    init(panelNumber: Int, details: String = "", page: Page? = nil) {
        self.panelNumber = panelNumber
        self.details = details
        self.page = page
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class Character {
    var name: String
    var dialogue: String
    var panel: Panel?
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, dialogue: String = "", panel: Panel? = nil) {
        self.name = name
        self.dialogue = dialogue
        self.panel = panel
        self.createdAt = Date()
        self.updatedAt = Date()
    }
} 
