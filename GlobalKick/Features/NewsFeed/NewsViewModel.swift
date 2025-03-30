import Foundation
import Combine

class NewsViewModel: ObservableObject {
    // MARK: - 发布属性
    @Published var articles: [NewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var error: NetworkError? = nil
    @Published var selectedFilters: [NewsFilter] = []
    @Published var availableFilters: [NewsFilter] = []
    @Published var searchQuery = ""
    
    // MARK: - 私有属性
    private let newsService = NewsService.shared
    private let translationService = TranslationService.shared
    private let preferencesService = UserPreferencesService.shared
    
    private var nextCursor: String? = nil
    private var hasMoreContent: Bool = true
    private var currentTask: Task<Void, Never>? = nil
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    
    // MARK: - 初始化
    init() {
        setupBindings()
        
        // 初始化筛选器
        loadAvailableFilters()
        
        // 加载第一页数据
        Task {
            await loadFirstPage()
        }
    }
    
    private func setupBindings() {
        // 监听用户偏好的变化
        preferencesService.$favoriteLeagues
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.refresh()
                }
            }
            .store(in: &cancellables)
        
        preferencesService.$blockedSources
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterBlockedSources()
            }
            .store(in: &cancellables)
        
        preferencesService.$preferredLanguage
            .receive(on: RunLoop.main)
            .sink { [weak self] newLanguage in
                self?.translationService.targetLanguage = newLanguage
                Task {
                    try? await self?.translateArticlesIfNeeded()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 数据加载方法
    @MainActor
    func loadFirstPage() async {
        // 取消正在进行的任务
        currentTask?.cancel()
        
        isLoading = true
        error = nil
        
        // 清除现有数据
        articles = []
        nextCursor = nil
        hasMoreContent = true
        
        currentTask = Task {
            do {
                // 获取筛选后的联赛ID
                let leagues = getSelectedLeagueIds()
                
                let response = try await newsService.fetchNews(leagues: leagues)
                
                // 更新数据
                articles = response.data.filter { article in
                    !preferencesService.isSourceBlocked(article.source)
                }
                nextCursor = response.nextCursor
                hasMoreContent = response.nextCursor != nil
                
                // 自动翻译(如果需要)
                if preferencesService.autoTranslate {
                    try await translateArticlesIfNeeded()
                }
            } catch let networkError as NetworkError {
                error = networkError
            } catch {
                self.error = NetworkError.requestFailed(error)
            }
            
            isLoading = false
        }
    }
    
    @MainActor
    func loadNextPage() async {
        guard hasMoreContent && !isLoading, let cursor = nextCursor else { return }
        
        // 取消正在进行的任务
        currentTask?.cancel()
        
        isLoading = true
        
        currentTask = Task {
            do {
                // 获取筛选后的联赛ID
                let leagues = getSelectedLeagueIds()
                
                let response = try await newsService.fetchNews(
                    leagues: leagues,
                    cursor: cursor
                )
                
                // 过滤屏蔽的来源
                let newArticles = response.data.filter { article in
                    !preferencesService.isSourceBlocked(article.source)
                }
                
                // 更新数据，避免重复
                let uniqueArticles = newArticles.filter { newArticle in
                    !articles.contains { $0.id == newArticle.id }
                }
                
                articles.append(contentsOf: uniqueArticles)
                nextCursor = response.nextCursor
                hasMoreContent = response.nextCursor != nil
                
                // 自动翻译(如果需要)
                if preferencesService.autoTranslate {
                    try await translateArticlesIfNeeded(startIndex: articles.count - uniqueArticles.count)
                }
            } catch let networkError as NetworkError {
                error = networkError
            } catch {
                self.error = NetworkError.requestFailed(error)
            }
            
            isLoading = false
        }
    }
    
    // MARK: - 滚动加载检查
    func loadMoreIfNeeded(currentItem item: NewsArticle) {
        // 当用户滚动到最后20%的内容时加载更多
        let thresholdIndex = Int(Double(articles.count) * 0.8)
        
        if let itemIndex = articles.firstIndex(where: { $0.id == item.id }),
           itemIndex >= thresholdIndex,
           hasMoreContent && !isLoading {
            Task {
                await loadNextPage()
            }
        }
    }
    
    // MARK: - 刷新
    @MainActor
    func refresh() async {
        await loadFirstPage()
    }
    
    // MARK: - 翻译方法
    @MainActor
    private func translateArticlesIfNeeded(startIndex: Int = 0) async throws {
        // 如果不需要自动翻译，直接返回
        if !preferencesService.autoTranslate {
            return
        }
        
        let targetLang = preferencesService.preferredLanguage
        
        for i in startIndex..<articles.count {
            // 检查是否需要翻译
            let article = articles[i]
            if article.detectedLanguage == targetLang.rawValue || article.isTranslated {
                continue
            }
            
            do {
                let translatedArticle = try await translationService.translateArticle(article)
                
                // 确保视图更新
                if i < articles.count {
                    articles[i] = translatedArticle
                }
            } catch {
                print("翻译失败: \(error.localizedDescription)")
                // 继续处理下一篇文章
            }
        }
    }
    
    // MARK: - 单篇文章翻译
    func translateArticle(_ articleId: String) async {
        guard let index = articles.firstIndex(where: { $0.id == articleId }) else { return }
        
        let article = articles[index]
        
        do {
            let translatedArticle = try await translationService.translateArticle(article)
            
            await MainActor.run {
                articles[index] = translatedArticle
            }
        } catch {
            print("翻译失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 筛选相关方法
    func toggleFilter(_ filter: NewsFilter) {
        if let index = selectedFilters.firstIndex(where: { $0.id == filter.id }) {
            selectedFilters.remove(at: index)
        } else {
            selectedFilters.append(filter)
        }
        
        // 刷新数据
        Task {
            await refresh()
        }
    }
    
    func isFilterSelected(_ filter: NewsFilter) -> Bool {
        return selectedFilters.contains(where: { $0.id == filter.id })
    }
    
    private func getSelectedLeagueIds() -> [String]? {
        let leagueFilters = selectedFilters.filter { $0.type == .league }
        
        if leagueFilters.isEmpty {
            // 如果没有选择联赛筛选器，使用收藏的联赛
            if !preferencesService.favoriteLeagues.isEmpty {
                return preferencesService.favoriteLeagues.map { $0.id }
            }
            return nil
        }
        
        return leagueFilters.map { $0.id }
    }
    
    private func filterBlockedSources() {
        // 过滤掉被屏蔽的新闻来源
        articles = articles.filter { article in
            !preferencesService.isSourceBlocked(article.source)
        }
    }
    
    // MARK: - 加载筛选器
    private func loadAvailableFilters() {
        // 此处可以从API加载联赛和标签等，现在使用模拟数据
        availableFilters = [
            NewsFilter(id: "epl", name: "英超", type: .league),
            NewsFilter(id: "laliga", name: "西甲", type: .league),
            NewsFilter(id: "bundesliga", name: "德甲", type: .league),
            NewsFilter(id: "serieA", name: "意甲", type: .league),
            NewsFilter(id: "ligue1", name: "法甲", type: .league),
            NewsFilter(id: "csl", name: "中超", type: .league),
            NewsFilter(id: "transfer", name: "转会", type: .tag),
            NewsFilter(id: "injury", name: "伤病", type: .tag),
            NewsFilter(id: "highlight", name: "集锦", type: .tag)
        ]
    }
    
    // MARK: - 收藏文章
    func toggleFavorite(for articleId: String) {
        guard let index = articles.firstIndex(where: { $0.id == articleId }) else { return }
        
        articles[index].isFavorite.toggle()
        
        // 这里可以实现收藏同步到服务器的逻辑
    }
    
    // MARK: - 获取模拟数据(用于SwiftUI预览)
    #if DEBUG
    static func mockViewModel() -> NewsViewModel {
        let viewModel = NewsViewModel()
        viewModel.articles = NewsService.mockArticles()
        viewModel.isLoading = false
        return viewModel
    }
    #endif
    
    // MARK: - 搜索方法
    func debounceSearch() async {
        // 取消之前的搜索任务
        searchTask?.cancel()
        
        // 如果搜索字符串为空，刷新全部内容
        if searchQuery.isEmpty {
            await refresh()
            return
        }
        
        // 创建新的搜索任务
        searchTask = Task {
            // 延迟500毫秒，实现防抖
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                isLoading = true
                error = nil
            }
            
            do {
                // 调用搜索API
                let searchResults = try await searchArticles(query: searchQuery)
                
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    articles = searchResults
                    isLoading = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
    
    // 实际的搜索API调用
    private func searchArticles(query: String) async throws -> [NewsArticle] {
        // 这里替换为实际的API调用
        // 下面是模拟的实现
        try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟网络延迟
        
        // 从现有文章中过滤
        // 在实际应用中，应该调用后端API
        return MockData.sampleArticles.filter { 
            $0.title.localizedCaseInsensitiveContains(query) || 
            $0.content.localizedCaseInsensitiveContains(query)
        }
    }
} 