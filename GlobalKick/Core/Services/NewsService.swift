import Foundation

class NewsService {
    static let shared = NewsService()
    
    private let networkService = NetworkService.shared
    private let cache = NSCache<NSString, NSArray>()
    
    private init() {
        // 配置缓存
        cache.countLimit = 100 // 最多缓存100个请求结果
    }
    
    // MARK: - 获取新闻列表
    func fetchNews(
        leagues: [String]? = nil,
        cursor: String? = nil,
        limit: Int = 20
    ) async throws -> NewsResponse {
        var parameters: [String: Any] = ["limit": limit]
        
        if let leagues = leagues, !leagues.isEmpty {
            parameters["leagues"] = leagues.joined(separator: ",")
        }
        
        if let cursor = cursor {
            parameters["after"] = cursor
        }
        
        // 尝试从缓存获取数据（如果没有游标，表示是第一页）
        if cursor == nil, let leagues = leagues {
            let cacheKey = NSString(string: "news_\(leagues.joined(separator: "_"))")
            if let cachedResponse = cache.object(forKey: cacheKey) as? [NewsArticle] {
                return NewsResponse(data: cachedResponse, nextCursor: nil)
            }
        }
        
        // 从网络获取数据
        let response: NewsResponse = try await networkService.request(
            endpoint: "/news",
            parameters: parameters
        )
        
        // 缓存第一页数据
        if cursor == nil, let leagues = leagues {
            let cacheKey = NSString(string: "news_\(leagues.joined(separator: "_"))")
            cache.setObject(response.data as NSArray, forKey: cacheKey)
        }
        
        return response
    }
    
    // MARK: - 获取新闻详情
    func fetchNewsDetail(id: String) async throws -> NewsArticle {
        return try await networkService.request(endpoint: "/news/\(id)")
    }
    
    // MARK: - 获取可用联赛列表
    func fetchAvailableLeagues() async throws -> [League] {
        return try await networkService.request(endpoint: "/leagues")
    }
    
    // MARK: - 清除缓存
    func clearCache() {
        cache.removeAllObjects()
    }
    
    // MARK: - 模拟数据(用于预览和测试)
    #if DEBUG
    static func mockArticles() -> [NewsArticle] {
        let source = NewsSource(
            id: "skysports",
            name: "Sky Sports", 
            iconURL: URL(string: "https://example.com/icons/skysports.png")!,
            reliabilityScore: 8
        )
        
        return [
            NewsArticle(
                id: "article1",
                title: "梅西打进赛季第20球，国际迈阿密战胜对手",
                rawContent: "在周末比赛中，梅西上演了精彩表现，帮助球队获得胜利...",
                summary: "梅西进球帮助球队获胜",
                source: source,
                detectedLanguage: "zh",
                publishDate: Date(),
                tags: ["梅西", "美职联", "国际迈阿密"],
                translatedTitle: nil,
                translatedContent: nil,
                isTranslated: false,
                isFavorite: false
            ),
            NewsArticle(
                id: "article2",
                title: "Manchester United considering new manager after poor results",
                rawContent: "Following another disappointing result, Manchester United's board is reportedly considering options for a new manager...",
                summary: "ManUtd might change their manager soon",
                source: source, 
                detectedLanguage: "en",
                publishDate: Date().addingTimeInterval(-86400),
                tags: ["Manchester United", "Premier League", "Manager"],
                translatedTitle: "曼联在糟糕战绩后考虑换帅",
                translatedContent: "在又一场令人失望的比赛后，曼联董事会据报道正在考虑新主帅的选择...",
                isTranslated: true,
                isFavorite: true
            )
        ]
    }
    #endif
} 