import Foundation
import SwiftData
import SwiftUI

@Model
final class Series {
    var title: String
    var synopsis: String
    var coverImageData: Data?
    @Relationship(deleteRule: .cascade, inverse: \ComicIssue.series)
    var issues: [ComicIssue] = []
    var createdAt: Date
    var updatedAt: Date
    
    var coverImage: Image? {
        if let data = coverImageData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    init(title: String, synopsis: String = "", coverImageData: Data? = nil) {
        self.title = title
        self.synopsis = synopsis
        self.coverImageData = coverImageData
        self.createdAt = Date()
        self.updatedAt = Date()
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
    
    var coverImage: Image? {
        if let data = coverImageData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    init(title: String, issueNumber: Int, synopsis: String = "", coverImageData: Data? = nil, series: Series? = nil) {
        self.title = title
        self.issueNumber = issueNumber
        self.synopsis = synopsis
        self.coverImageData = coverImageData
        self.series = series
        self.createdAt = Date()
        self.updatedAt = Date()
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
