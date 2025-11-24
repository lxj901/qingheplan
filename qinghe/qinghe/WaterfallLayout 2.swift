import SwiftUI

/// 瀑布流布局视图 - 类似小红书的两列布局
struct WaterfallLayout<Content: View, Item: Identifiable, Footer: View>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let onLoadMore: (() -> Void)?
    let content: (Item) -> Content
    let footer: () -> Footer

    init(
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = 8,
        horizontalPadding: CGFloat = 8,
        onLoadMore: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.onLoadMore = onLoadMore
        self.content = content
        self.footer = footer
    }

    var body: some View {
        GeometryReader { geometry in
            let totalSpacing = spacing * CGFloat(columns - 1) + horizontalPadding * 2
            let columnWidth = (geometry.size.width - totalSpacing) / CGFloat(columns)

            ScrollView {
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: spacing) {
                        ForEach(0..<columns, id: \.self) { columnIndex in
                            LazyVStack(spacing: spacing) {
                                ForEach(itemsForColumn(columnIndex), id: \.id) { item in
                                    content(item)
                                        .frame(width: columnWidth)
                                        .onAppear {
                                            // 检查是否需要加载更多
                                            if let lastItem = items.last, item.id == lastItem.id {
                                                onLoadMore?()
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, spacing)

                    // 底部内容（如"没有更多数据"提示）
                    footer()
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                }
            }
        }
    }

    /// 获取指定列的items
    private func itemsForColumn(_ columnIndex: Int) -> [Item] {
        return items.enumerated().compactMap { index, item in
            index % columns == columnIndex ? item : nil
        }
    }
}

/// 优化的瀑布流布局 - 使用LazyVStack实现更好的性能
struct OptimizedWaterfallLayout<Content: View, Item: Identifiable>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let content: (Item) -> Content
    
    init(
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = 8,
        horizontalPadding: CGFloat = 8,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            let totalSpacing = spacing * CGFloat(columns - 1) + horizontalPadding * 2
            let columnWidth = (geometry.size.width - totalSpacing) / CGFloat(columns)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(chunkedItems(), id: \.0) { rowIndex, rowItems in
                        HStack(alignment: .top, spacing: spacing) {
                            ForEach(rowItems, id: \.id) { item in
                                content(item)
                                    .frame(width: columnWidth)
                            }
                            
                            // 如果最后一行不满，填充空白
                            if rowItems.count < columns {
                                ForEach(0..<(columns - rowItems.count), id: \.self) { _ in
                                    Color.clear
                                        .frame(width: columnWidth)
                                }
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, rowIndex == 0 ? spacing : 0)
                        .padding(.bottom, spacing)
                    }
                }
                // 添加底部padding，确保最后一行完全可见
                .padding(.bottom, 100)
            }
        }
    }
    
    /// 将items分组为行
    private func chunkedItems() -> [(Int, [Item])] {
        var result: [(Int, [Item])] = []
        var currentRow: [Item] = []
        var rowIndex = 0
        
        for item in items {
            currentRow.append(item)
            if currentRow.count == columns {
                result.append((rowIndex, currentRow))
                currentRow = []
                rowIndex += 1
            }
        }
        
        // 添加最后一行（如果有剩余）
        if !currentRow.isEmpty {
            result.append((rowIndex, currentRow))
        }
        
        return result
    }
}

/// 瀑布流布局容器 - 自动计算高度的版本
struct AdaptiveWaterfallLayout<Content: View, Item: Identifiable>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let content: (Item) -> Content
    
    @State private var itemHeights: [String: CGFloat] = [:]
    
    init(
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = 8,
        horizontalPadding: CGFloat = 8,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            let totalSpacing = spacing * CGFloat(columns - 1) + horizontalPadding * 2
            let columnWidth = (geometry.size.width - totalSpacing) / CGFloat(columns)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(distributedItems(columnWidth: columnWidth), id: \.0) { columnIndex, columnItems in
                        if columnIndex == 0 {
                            // 第一列
                            VStack(spacing: spacing) {
                                ForEach(columnItems, id: \.id) { item in
                                    content(item)
                                        .frame(width: columnWidth)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, spacing)
                // 添加底部padding
                .padding(.bottom, 100)
            }
        }
    }
    
    /// 将items分配到各列
    private func distributedItems(columnWidth: CGFloat) -> [(Int, [Item])] {
        var columns: [[Item]] = Array(repeating: [], count: self.columns)
        var columnHeights: [CGFloat] = Array(repeating: 0, count: self.columns)
        
        for item in items {
            // 找到最短的列
            let minColumn = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            columns[minColumn].append(item)
            
            // 估算高度（这里需要根据实际内容调整）
            let estimatedHeight: CGFloat = 200 // 默认估算高度
            columnHeights[minColumn] += estimatedHeight + spacing
        }
        
        return columns.enumerated().map { ($0, $1) }
    }
}

