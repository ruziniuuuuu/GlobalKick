import Foundation
import Combine

// 注意：这里我们定义一个接口，实际实现需要在项目中添加MLKit依赖
// 添加依赖: MLKitTranslate

enum TranslateLanguage: String, CaseIterable {
    case english = "en"
    case chineseSimplified = "zh"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case japanese = "ja"
    case korean = "ko"
    case russian = "ru"
    case autoDetection = "auto"
    
    var displayName: String {
        switch self {
        case .english: return "英语"
        case .chineseSimplified: return "简体中文"
        case .spanish: return "西班牙语"
        case .french: return "法语"
        case .german: return "德语"
        case .italian: return "意大利语"
        case .portuguese: return "葡萄牙语"
        case .japanese: return "日语"
        case .korean: return "韩语"
        case .russian: return "俄语"
        case .autoDetection: return "自动检测"
        }
    }
}

class TranslationService: ObservableObject {
    static let shared = TranslationService()
    
    @Published var isModelDownloaded: [TranslateLanguage: Bool] = [:]
    @Published var downloadProgress: Double = 0.0
    @Published var targetLanguage: TranslateLanguage = .chineseSimplified
    
    private let cache = NSCache<NSString, NSString>()
    private var modelDownloadTask: Task<Void, Error>?
    
    private init() {
        cache.countLimit = 500 // 最多缓存500条翻译
        
        // 初始化已下载状态
        for language in TranslateLanguage.allCases {
            isModelDownloaded[language] = false
        }
        
        // 自动检测总是可用的
        isModelDownloaded[.autoDetection] = true
        
        // 检查常用语言模型是否已下载
        Task {
            await checkModelStatus()
        }
    }
    
    // MARK: - 检查模型下载状态
    private func checkModelStatus() async {
        // 实际实现需要调用MLKit检查模型状态
        // 示例实现，实际项目中需要替换
        isModelDownloaded[.chineseSimplified] = true
        isModelDownloaded[.english] = true
    }
    
    // MARK: - 下载翻译模型
    func downloadModelIfNeeded(for language: TranslateLanguage) async throws {
        guard language != .autoDetection else { return }
        
        if isModelDownloaded[language] == true {
            return
        }
        
        // 取消之前的下载任务(如果有)
        modelDownloadTask?.cancel()
        
        // 实际实现需要调用MLKit下载模型
        // 简化的模拟实现
        modelDownloadTask = Task {
            // 模拟下载进度
            for progress in stride(from: 0.0, to: 1.0, by: 0.1) {
                try await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    self.downloadProgress = progress
                }
            }
            
            // 下载完成
            await MainActor.run {
                self.downloadProgress = 1.0
                self.isModelDownloaded[language] = true
            }
        }
        
        // 等待下载完成
        try await modelDownloadTask!.value
    }
    
    // MARK: - 翻译文本
    func translate(text: String, from sourceLanguage: TranslateLanguage = .autoDetection, to targetLanguage: TranslateLanguage) async throws -> String {
        // 如果源语言和目标语言相同，不需要翻译
        if sourceLanguage == targetLanguage && sourceLanguage != .autoDetection {
            return text
        }
        
        // 检查缓存
        let cacheKey = NSString(string: "\(sourceLanguage.rawValue)_\(targetLanguage.rawValue)_\(text)")
        if let cachedTranslation = cache.object(forKey: cacheKey) {
            return cachedTranslation as String
        }
        
        // 下载模型(如果需要)
        try await downloadModelIfNeeded(for: targetLanguage)
        
        // 实际实现需要调用MLKit翻译API
        // 模拟翻译结果
        let translatedText: String
        
        // 简化的翻译模拟逻辑
        switch (sourceLanguage, targetLanguage) {
        case (_, .chineseSimplified):
            // 模拟英文到中文翻译
            if text.range(of: "[a-zA-Z]", options: .regularExpression) != nil {
                translatedText = "这是翻译后的中文内容: " + text
            } else {
                translatedText = text
            }
            
        case (_, .english):
            // 模拟中文到英文翻译
            if text.range(of: "\\p{Han}", options: .regularExpression) != nil {
                translatedText = "This is translated English: " + text
            } else {
                translatedText = text
            }
            
        default:
            translatedText = text
        }
        
        // 缓存翻译结果
        cache.setObject(NSString(string: translatedText), forKey: cacheKey)
        
        return translatedText
    }
    
    // MARK: - 翻译新闻文章
    func translateArticle(_ article: NewsArticle) async throws -> NewsArticle {
        var updatedArticle = article
        
        // 如果文章已经是目标语言，不需要翻译
        if article.detectedLanguage == targetLanguage.rawValue {
            updatedArticle.isTranslated = false
            return updatedArticle
        }
        
        // 翻译标题和内容
        async let translatedTitle = translate(
            text: article.title,
            from: TranslateLanguage(rawValue: article.detectedLanguage) ?? .autoDetection,
            to: targetLanguage
        )
        
        async let translatedContent = translate(
            text: article.rawContent,
            from: TranslateLanguage(rawValue: article.detectedLanguage) ?? .autoDetection,
            to: targetLanguage
        )
        
        // 等待所有翻译完成
        updatedArticle.translatedTitle = try await translatedTitle
        updatedArticle.translatedContent = try await translatedContent
        updatedArticle.isTranslated = true
        
        return updatedArticle
    }
    
    // MARK: - 清除翻译缓存
    func clearCache() {
        cache.removeAllObjects()
    }
} 