import SwiftUI

// 公开结构体，使其可以从其他模块访问
public struct SettingsView: View {
    @StateObject private var preferencesService = UserPreferencesService.shared
    @StateObject private var translationService = TranslationService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingResetAlert = false
    @State private var showingCacheAlert = false
    
    public init() {
        // 公开初始化器
    }
    
    public var body: some View {
        NavigationStack {
            List {
                // 翻译设置
                Section {
                    // 目标语言选择
                    Picker("翻译语言", selection: $preferencesService.preferredLanguage) {
                        ForEach(TranslateLanguage.allCases.filter({ $0 != .autoDetection }), id: \.self) { language in
                            HStack {
                                Text(language.displayName)
                                
                                if !translationService.isModelDownloaded[language, default: false] {
                                    Spacer()
                                    Image(systemName: "icloud.and.arrow.down")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tag(language)
                        }
                    }
                    
                    // 自动翻译设置
                    Toggle("自动翻译外语新闻", isOn: $preferencesService.autoTranslate)
                    
                    // 下载模型管理
                    if let currentLang = translationService.isModelDownloaded.first(where: { $0.key == preferencesService.preferredLanguage }) {
                        if !currentLang.value {
                            HStack {
                                Text("下载翻译模型")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                if translationService.downloadProgress > 0 && translationService.downloadProgress < 1.0 {
                                    ProgressView(value: translationService.downloadProgress)
                                        .progressViewStyle(.linear)
                                        .frame(width: 100)
                                } else {
                                    Button("下载") {
                                        Task {
                                            try? await translationService.downloadModelIfNeeded(for: preferencesService.preferredLanguage)
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .buttonBorderShape(.capsule)
                                    .controlSize(.small)
                                }
                            }
                        } else {
                            HStack {
                                Text("翻译模型已下载")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                } header: {
                    Text("翻译设置")
                } footer: {
                    Text("自动翻译使用设备端机器学习模型，无需网络连接")
                }
                
                // 外观设置
                Section {
                    Toggle("深色模式", isOn: $preferencesService.useDarkMode)
                } header: {
                    Text("外观")
                }
                
                // 内容偏好
                Section {
                    NavigationLink(destination: FavoriteLeaguesView()) {
                        HStack {
                            Text("收藏联赛")
                            Spacer()
                            Text("\(preferencesService.favoriteLeagues.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink(destination: BlockedSourcesView()) {
                        HStack {
                            Text("屏蔽来源")
                            Spacer()
                            Text("\(preferencesService.blockedSources.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("内容偏好")
                }
                
                // 数据管理
                Section {
                    Button("清除翻译缓存") {
                        showingCacheAlert = true
                    }
                    .foregroundColor(.accentColor)
                    
                    Button("重置所有设置") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("数据管理")
                }
                
                // 关于
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Text("隐私政策")
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Text("使用条款")
                    }
                } header: {
                    Text("关于")
                } footer: {
                    Text("© 2023 球界通 - 您的全球足球新闻中心")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("重置所有设置", isPresented: $showingResetAlert) {
                Button("取消", role: .cancel) { }
                Button("重置", role: .destructive) {
                    preferencesService.resetAllPreferences()
                }
            } message: {
                Text("此操作将清除您的所有偏好设置，包括收藏的联赛和屏蔽的新闻来源。此操作无法撤销。")
            }
            .alert("清除翻译缓存", isPresented: $showingCacheAlert) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    translationService.clearCache()
                }
            } message: {
                Text("此操作将清除所有已缓存的翻译结果，但不会删除已下载的翻译模型。")
            }
        }
        .preferredColorScheme(preferencesService.useDarkMode ? .dark : nil)
    }
}

// 收藏联赛视图
struct FavoriteLeaguesView: View {
    @StateObject private var preferencesService = UserPreferencesService.shared
    @State private var leagues: [League] = []
    @State private var isLoading = true
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(leagues) { league in
                    HStack {
                        // 联赛图标
                        AsyncImage(url: league.logoURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "soccerball")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .frame(width: 30, height: 30)
                        
                        // 联赛名称
                        Text(league.name)
                        
                        Spacer()
                        
                        // 收藏按钮
                        Button {
                            preferencesService.toggleFavoriteLeague(league)
                        } label: {
                            Image(systemName: preferencesService.isLeagueFavorite(league) ? "star.fill" : "star")
                                .foregroundColor(preferencesService.isLeagueFavorite(league) ? .yellow : .gray)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
        }
        .navigationTitle("收藏联赛")
        .onAppear {
            // 模拟加载联赛数据
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                leagues = [
                    League(id: "epl", name: "英超", countryCode: "GB", logoURL: URL(string: "https://example.com/epl.png")!),
                    League(id: "laliga", name: "西甲", countryCode: "ES", logoURL: URL(string: "https://example.com/laliga.png")!),
                    League(id: "bundesliga", name: "德甲", countryCode: "DE", logoURL: URL(string: "https://example.com/bundesliga.png")!),
                    League(id: "seriea", name: "意甲", countryCode: "IT", logoURL: URL(string: "https://example.com/seriea.png")!),
                    League(id: "ligue1", name: "法甲", countryCode: "FR", logoURL: URL(string: "https://example.com/ligue1.png")!),
                    League(id: "csl", name: "中超", countryCode: "CN", logoURL: URL(string: "https://example.com/csl.png")!)
                ]
                isLoading = false
            }
        }
    }
}

// 屏蔽来源视图
struct BlockedSourcesView: View {
    @StateObject private var preferencesService = UserPreferencesService.shared
    @State private var sources: [NewsSource] = []
    @State private var isLoading = true
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(sources) { source in
                    HStack {
                        // 来源图标
                        AsyncImage(url: source.iconURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "newspaper")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .frame(width: 24, height: 24)
                        
                        // 来源名称
                        VStack(alignment: .leading) {
                            Text(source.name)
                            
                            // 可信度星级
                            HStack(spacing: 2) {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < source.reliabilityScore / 2 ? "star.fill" : "star")
                                        .font(.system(size: 10))
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // 屏蔽切换
                        Button {
                            preferencesService.toggleBlockedSource(source)
                        } label: {
                            Image(systemName: preferencesService.isSourceBlocked(source) ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(preferencesService.isSourceBlocked(source) ? .red : .gray)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
        }
        .navigationTitle("屏蔽来源")
        .onAppear {
            // 模拟加载新闻来源数据
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                sources = [
                    NewsSource(id: "skysports", name: "Sky Sports", iconURL: URL(string: "https://example.com/icons/skysports.png")!, reliabilityScore: 8),
                    NewsSource(id: "bbc", name: "BBC Sport", iconURL: URL(string: "https://example.com/icons/bbc.png")!, reliabilityScore: 9),
                    NewsSource(id: "marca", name: "Marca", iconURL: URL(string: "https://example.com/icons/marca.png")!, reliabilityScore: 7),
                    NewsSource(id: "goal", name: "Goal.com", iconURL: URL(string: "https://example.com/icons/goal.png")!, reliabilityScore: 6),
                    NewsSource(id: "espn", name: "ESPN FC", iconURL: URL(string: "https://example.com/icons/espn.png")!, reliabilityScore: 8)
                ]
                isLoading = false
            }
        }
    }
}

#Preview {
    SettingsView()
} 