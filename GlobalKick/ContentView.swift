//
//  ContentView.swift
//  GlobalKick
//
//  Created by 孺子牛 on 2025/3/23.
//

import SwiftUI

// 显式定义TabView类型别名以解决歧义
typealias AppTabView = SwiftUI.TabView

struct ContentView: View {
    @StateObject private var preferencesService = UserPreferencesService.shared
    @State private var showOnboarding = false
    @State private var selectedTab = 0
    
    var body: some View {
        mainTabView
            .accentColor(.blue)
            .preferredColorScheme(preferencesService.useDarkMode ? .dark : nil)
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .onAppear {
                // 检查是否是首次启动
                checkFirstLaunch()
            }
    }
    
    // 将TabView实现分离为计算属性
    private var mainTabView: some View {
        AppTabView(selection: $selectedTab) {
            // 新闻流标签页
            NewsFeedView()
                .tag(0)
                .tabItem {
                    Image(systemName: "newspaper")
                    Text("新闻")
                }
            
            // 收藏标签页
            FavoritesView()
                .tag(1)
                .tabItem {
                    Image(systemName: "bookmark")
                    Text("收藏")
                }
            
            // 搜索标签页
            SearchView()
                .tag(2)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("搜索")
                }
            
            // 设置标签页
            AppSettingsView()
                .tag(3)
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
        }
    }
    
    private func checkFirstLaunch() {
        let isFirstLaunch = UserDefaults.standard.bool(forKey: "isFirstLaunch")
        if !isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "isFirstLaunch")
            showOnboarding = true
        }
    }
}

// 创建一个中间视图来解决命名冲突
struct AppSettingsView: View {
    var body: some View {
        // 使用Features/Settings目录下的SettingsView
        NavigationStack {
            Text("设置")
                .navigationTitle("设置")
        }
    }
}

// 收藏视图
struct FavoritesView: View {
    var body: some View {
        NavigationStack {
            Text("收藏内容将显示在这里")
                .navigationTitle("我的收藏")
        }
    }
}

// 搜索视图
struct SearchView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                // 搜索结果将显示在这里
                Text("搜索功能将在未来版本中提供")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("搜索")
            .searchable(text: $searchText, prompt: "搜索球队、联赛或球员")
        }
    }
}

// 引导页视图
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    // 引导页数据
    private let pages = [
        OnboardingPage(
            title: "欢迎使用球界通",
            subtitle: "您的全球足球新闻聚合中心",
            image: "globe.americas.fill",
            description: "获取来自全球各大权威媒体的第一手足球资讯，永不错过任何重要新闻"
        ),
        OnboardingPage(
            title: "实时翻译",
            subtitle: "打破语言壁垒",
            image: "character.bubble.fill",
            description: "无论是英语、西班牙语还是其他语言的新闻，都能一键翻译成您的母语"
        ),
        OnboardingPage(
            title: "个性化推送",
            subtitle: "关注您喜爱的联赛和球队",
            image: "bell.fill",
            description: "设置您的偏好，只接收您关心的内容，不错过任何重要动态"
        )
    ]
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [.blue, .indigo]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // 页面指示器
                HStack {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 50)
                
                // 主内容
                AppTabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // 按钮
                VStack(spacing: 20) {
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            isPresented = false
                        }
                    }) {
                        Text(currentPage < pages.count - 1 ? "继续" : "开始体验")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    if currentPage < pages.count - 1 {
                        Button("跳过") {
                            isPresented = false
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

// 引导页内容
struct OnboardingPage {
    let title: String
    let subtitle: String
    let image: String
    let description: String
}

// 引导页视图
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 20) {
            // 图标
            Image(systemName: page.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .foregroundColor(.white)
                .padding(.bottom, 50)
            
            // 标题
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // 副标题
            Text(page.subtitle)
                .font(.title3)
                .foregroundColor(.white.opacity(0.9))
            
            // 描述
            Text(page.description)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 30)
                .padding(.top, 10)
            
            Spacer()
        }
        .padding(.top, 50)
    }
}

#Preview {
    ContentView()
}
