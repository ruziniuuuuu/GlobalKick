import SwiftUI

struct NewsFilterChips: View {
    @Binding var selectedFilters: [NewsFilter]
    let filters: [NewsFilter]
    var onFilterToggle: ((NewsFilter) -> Void)
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters) { filter in
                    FilterChip(
                        title: filter.name,
                        isSelected: isFilterSelected(filter),
                        action: {
                            onFilterToggle(filter)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 44)
    }
    
    private func isFilterSelected(_ filter: NewsFilter) -> Bool {
        return selectedFilters.contains(where: { $0.id == filter.id })
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 扩展版筛选器 - 带分类标签
struct CategorizedNewsFilterChips: View {
    @Binding var selectedFilters: [NewsFilter]
    let filters: [NewsFilter]
    var onFilterToggle: ((NewsFilter) -> Void)
    
    private var leagueFilters: [NewsFilter] {
        filters.filter { $0.type == .league }
    }
    
    private var tagFilters: [NewsFilter] {
        filters.filter { $0.type == .tag }
    }
    
    private var teamFilters: [NewsFilter] {
        filters.filter { $0.type == .team }
    }
    
    private var playerFilters: [NewsFilter] {
        filters.filter { $0.type == .player }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !leagueFilters.isEmpty {
                FilterSection(title: "联赛", filters: leagueFilters, selectedFilters: $selectedFilters, onFilterToggle: onFilterToggle)
            }
            
            if !tagFilters.isEmpty {
                FilterSection(title: "标签", filters: tagFilters, selectedFilters: $selectedFilters, onFilterToggle: onFilterToggle)
            }
            
            if !teamFilters.isEmpty {
                FilterSection(title: "球队", filters: teamFilters, selectedFilters: $selectedFilters, onFilterToggle: onFilterToggle)
            }
            
            if !playerFilters.isEmpty {
                FilterSection(title: "球员", filters: playerFilters, selectedFilters: $selectedFilters, onFilterToggle: onFilterToggle)
            }
        }
    }
}

struct FilterSection: View {
    let title: String
    let filters: [NewsFilter]
    @Binding var selectedFilters: [NewsFilter]
    var onFilterToggle: ((NewsFilter) -> Void)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters) { filter in
                        FilterChip(
                            title: filter.name,
                            isSelected: selectedFilters.contains(where: { $0.id == filter.id }),
                            action: {
                                onFilterToggle(filter)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    VStack {
        NewsFilterChips(
            selectedFilters: .constant([NewsFilter(id: "epl", name: "英超", type: .league)]),
            filters: [
                NewsFilter(id: "epl", name: "英超", type: .league),
                NewsFilter(id: "laliga", name: "西甲", type: .league),
                NewsFilter(id: "bundesliga", name: "德甲", type: .league),
                NewsFilter(id: "transfer", name: "转会", type: .tag),
                NewsFilter(id: "injury", name: "伤病", type: .tag)
            ],
            onFilterToggle: { _ in }
        )
        
        Divider()
            .padding(.vertical)
        
        CategorizedNewsFilterChips(
            selectedFilters: .constant([NewsFilter(id: "epl", name: "英超", type: .league)]),
            filters: [
                NewsFilter(id: "epl", name: "英超", type: .league),
                NewsFilter(id: "laliga", name: "西甲", type: .league),
                NewsFilter(id: "bundesliga", name: "德甲", type: .league),
                NewsFilter(id: "transfer", name: "转会", type: .tag),
                NewsFilter(id: "injury", name: "伤病", type: .tag),
                NewsFilter(id: "realmadrid", name: "皇马", type: .team),
                NewsFilter(id: "barca", name: "巴萨", type: .team),
                NewsFilter(id: "messi", name: "梅西", type: .player),
                NewsFilter(id: "ronaldo", name: "C罗", type: .player)
            ],
            onFilterToggle: { _ in }
        )
    }
    .padding()
    .previewLayout(.sizeThatFits)
} 