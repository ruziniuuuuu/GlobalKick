import Foundation
import Combine
import SwiftUI

class UserPreferencesService: ObservableObject {
    static let shared = UserPreferencesService()
    
    // MARK: - 用户偏好设置
    @Published var favoriteLeagues: [League] = []
    @Published var blockedSources: [NewsSource] = []
    @Published var preferredLanguage: TranslateLanguage = .chineseSimplified
    @Published var autoTranslate: Bool = true
    @Published var useDarkMode: Bool = false
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    
    // 订阅取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        // 从UserDefaults加载数据
        loadPreferences()
        
        // 监控数据变化，自动保存
        setupListeners()
    }
    
    // MARK: - 配置变更监听
    private func setupListeners() {
        // 逐个添加监听器，避免类型不匹配问题
        $favoriteLeagues
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .removeDuplicates()
            .dropFirst() // 忽略初始值
            .sink { [weak self] _ in
                self?.savePreferences()
            }
            .store(in: &cancellables)
        
        $blockedSources
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.savePreferences()
            }
            .store(in: &cancellables)
        
        $preferredLanguage
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.savePreferences()
            }
            .store(in: &cancellables)
        
        $autoTranslate
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.savePreferences()
            }
            .store(in: &cancellables)
        
        $useDarkMode
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.savePreferences()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 从UserDefaults加载偏好设置
    private func loadPreferences() {
        let defaults = UserDefaults.standard
        
        // 加载收藏联赛
        if let data = defaults.data(forKey: "favoriteLeagues") {
            do {
                favoriteLeagues = try decoder.decode([League].self, from: data)
            } catch {
                print("加载收藏联赛失败: \(error.localizedDescription)")
            }
        }
        
        // 加载屏蔽的新闻来源
        if let data = defaults.data(forKey: "blockedSources") {
            do {
                blockedSources = try decoder.decode([NewsSource].self, from: data)
            } catch {
                print("加载屏蔽来源失败: \(error.localizedDescription)")
            }
        }
        
        // 加载偏好语言
        if let languageCode = defaults.string(forKey: "preferredLanguage"),
           let language = TranslateLanguage(rawValue: languageCode) {
            preferredLanguage = language
        }
        
        // 加载自动翻译设置
        autoTranslate = defaults.bool(forKey: "autoTranslate")
        
        // 加载暗色模式设置
        useDarkMode = defaults.bool(forKey: "useDarkMode")
    }
    
    // MARK: - 保存偏好设置到UserDefaults
    private func savePreferences() {
        let defaults = UserDefaults.standard
        
        // 保存收藏联赛
        if let data = try? encoder.encode(favoriteLeagues) {
            defaults.set(data, forKey: "favoriteLeagues")
        }
        
        // 保存屏蔽的新闻来源
        if let data = try? encoder.encode(blockedSources) {
            defaults.set(data, forKey: "blockedSources")
        }
        
        // 保存偏好语言
        defaults.set(preferredLanguage.rawValue, forKey: "preferredLanguage")
        
        // 保存自动翻译设置
        defaults.set(autoTranslate, forKey: "autoTranslate")
        
        // 保存暗色模式设置
        defaults.set(useDarkMode, forKey: "useDarkMode")
    }
    
    // MARK: - 用户操作方法
    func toggleFavoriteLeague(_ league: League) {
        if let index = favoriteLeagues.firstIndex(where: { $0.id == league.id }) {
            favoriteLeagues.remove(at: index)
        } else {
            favoriteLeagues.append(league)
        }
    }
    
    func toggleBlockedSource(_ source: NewsSource) {
        if let index = blockedSources.firstIndex(where: { $0.id == source.id }) {
            blockedSources.remove(at: index)
        } else {
            blockedSources.append(source)
        }
    }
    
    func isLeagueFavorite(_ league: League) -> Bool {
        return favoriteLeagues.contains(where: { $0.id == league.id })
    }
    
    func isSourceBlocked(_ source: NewsSource) -> Bool {
        return blockedSources.contains(where: { $0.id == source.id })
    }
    
    func completeFirstLaunch() {
        isFirstLaunch = false
    }
    
    func resetAllPreferences() {
        favoriteLeagues = []
        blockedSources = []
        preferredLanguage = .chineseSimplified
        autoTranslate = true
        useDarkMode = false
        savePreferences()
    }
} 