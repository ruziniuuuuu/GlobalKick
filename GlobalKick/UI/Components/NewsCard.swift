import SwiftUI

struct NewsCard: View {
    let article: NewsArticle
    var onTranslate: (() -> Void)? = nil
    var onFavorite: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isShowingDetail = false
    
    var body: some View {
        Button(action: {
            isShowingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // 标题部分
                HStack(alignment: .center) {
                    // 来源图标
                    AsyncImage(url: article.source.iconURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "globe")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .frame(width: 16, height: 16)
                    
                    // 来源名称
                    Text(article.source.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 可信度指示器
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < article.source.reliabilityScore / 2 ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    // 日期
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // 文章标题
                Text(article.isTranslated ? article.translatedTitle ?? article.title : article.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // 摘要
                Text(article.summary)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                // 底部操作按钮
                HStack {
                    // 标签
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(article.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .frame(height: 24)
                    
                    Spacer()
                    
                    // 翻译按钮 (仅当文章语言与目标语言不同时显示)
                    if article.detectedLanguage != TranslationService.shared.targetLanguage.rawValue {
                        Button(action: {
                            onTranslate?()
                        }) {
                            Image(systemName: article.isTranslated ? "globe.americas.fill" : "globe.americas")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.horizontal, 8)
                    }
                    
                    // 收藏按钮
                    Button(action: {
                        onFavorite?()
                    }) {
                        Image(systemName: article.isFavorite ? "bookmark.fill" : "bookmark")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isShowingDetail) {
            NewsDetailView(article: article)
        }
    }
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: article.publishDate, relativeTo: Date())
    }
    
    private var cardBackground: some View {
        Group {
            if colorScheme == .dark {
                Color(UIColor.secondarySystemBackground)
            } else {
                Color.white
            }
        }
    }
}

// 新闻详情视图
struct NewsDetailView: View {
    let article: NewsArticle
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var translationService = TranslationService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 标题
                    Text(article.isTranslated ? article.translatedTitle ?? article.title : article.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // 来源和日期
                    HStack {
                        AsyncImage(url: article.source.iconURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "globe")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .frame(width: 20, height: 20)
                        
                        Text(article.source.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // 内容
                    Text(article.isTranslated ? article.translatedContent ?? article.rawContent : article.rawContent)
                        .font(.body)
                        .lineSpacing(6)
                }
                .padding()
            }
            .navigationBarTitle("新闻详情", displayMode: .inline)
            .navigationBarItems(
                trailing: HStack {
                    if article.detectedLanguage != translationService.targetLanguage.rawValue {
                        Button(action: {
                            // 翻译逻辑
                        }) {
                            Image(systemName: article.isTranslated ? "globe.americas.fill" : "globe.americas")
                        }
                    }
                    
                    Button(action: {
                        // 分享逻辑
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            )
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: article.publishDate)
    }
}

#Preview {
    VStack {
        NewsCard(article: NewsService.mockArticles()[0])
        NewsCard(article: NewsService.mockArticles()[1])
    }
    .padding()
} 