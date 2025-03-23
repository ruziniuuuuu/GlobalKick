import Foundation

// MARK: - 新闻文章模型
struct NewsArticle: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let rawContent: String
    let summary: String
    let source: NewsSource
    let detectedLanguage: String
    let publishDate: Date
    let tags: [String]
    var translatedTitle: String?
    var translatedContent: String?
    var isTranslated: Bool = false
    var isFavorite: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, title, rawContent = "content", summary, source, detectedLanguage = "lang", publishDate = "date", tags
        case translatedTitle, translatedContent, isTranslated, isFavorite
    }
    
    static func == (lhs: NewsArticle, rhs: NewsArticle) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 新闻来源模型
struct NewsSource: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let iconURL: URL
    let reliabilityScore: Int
    
    static func == (lhs: NewsSource, rhs: NewsSource) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 联赛模型
struct League: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let countryCode: String
    let logoURL: URL
    
    static func == (lhs: League, rhs: League) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 新闻筛选器
struct NewsFilter: Identifiable, Hashable {
    let id: String
    let name: String
    let type: FilterType
    var isSelected: Bool = false
    
    enum FilterType: String, Codable {
        case league
        case team
        case player
        case tag
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NewsFilter, rhs: NewsFilter) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - API响应模型
struct NewsResponse: Codable {
    let data: [NewsArticle]
    let nextCursor: String?
    
    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
} 