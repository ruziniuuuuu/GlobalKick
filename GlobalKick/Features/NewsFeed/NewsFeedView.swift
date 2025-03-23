import SwiftUI

struct NewsFeedView: View {
    @StateObject var viewModel = NewsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColorView
                
                VStack(spacing: 0) {
                    // 筛选器区域
                    NewsFilterChips(
                        selectedFilters: $viewModel.selectedFilters,
                        filters: viewModel.availableFilters,
                        onFilterToggle: { filter in
                            viewModel.toggleFilter(filter)
                        }
                    )
                    .padding(.top, 8)
                    
                    // 新闻列表
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.articles) { article in
                                NewsCard(
                                    article: article,
                                    onTranslate: {
                                        Task {
                                            await viewModel.translateArticle(article.id)
                                        }
                                    },
                                    onFavorite: {
                                        viewModel.toggleFavorite(for: article.id)
                                    }
                                )
                                .onAppear {
                                    viewModel.loadMoreIfNeeded(currentItem: article)
                                }
                            }
                            
                            // 加载指示器
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                    .refreshable {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                }
                
                // 错误提示
                if let error = viewModel.error {
                    VStack {
                        Spacer()
                        
                        ErrorBanner(message: error.localizedDescription) {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                        .transition(.move(edge: .bottom))
                    }
                    .zIndex(100)
                    .animation(.spring(), value: viewModel.error != nil)
                }
                
                // 空状态
                if viewModel.articles.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "newspaper")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("暂无新闻")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("请尝试调整筛选条件或稍后再试")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("刷新") {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("全球球讯")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // 展开更多筛选器
                        // 这里可以添加打开更详细筛选面板的逻辑
                    }) {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
            }
        }
    }
    
    private var backgroundColorView: some View {
        Group {
            if colorScheme == .dark {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
            } else {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
            }
        }
    }
}

// 错误提示条
struct ErrorBanner: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("重试") {
                retryAction()
            }
            .font(.subheadline.bold())
            .foregroundColor(.white)
        }
        .padding()
        .background(Color.red.opacity(0.9))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// 设置视图（占位）
struct NewsFeedSettingsView: View {
    var body: some View {
        Text("设置页面")
            .navigationTitle("设置")
    }
}

#Preview {
    NewsFeedView(viewModel: NewsViewModel.mockViewModel())
} 