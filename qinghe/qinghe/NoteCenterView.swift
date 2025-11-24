import SwiftUI

// MARK: - 笔记中心主视图
struct NoteCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NoteCenterViewModel()

    // UI 状态
    @State private var selectedFilter: MarkFilterType = .all
    @State private var selectedGrouping: GroupingOption = .none
    @State private var selectedSorting: SortingOption = .newestFirst

    // 导航状态
    @State private var navigationPath = NavigationPath()
    @State private var showReadingView = false
    @State private var selectedBookId: String?
    @State private var selectedChapterId: String?
    @State private var selectedBookTitle: String?

    // 搜索和设置
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var showSettings = false
    
    // 背景渐变色
    private let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 245/255, green: 242/255, blue: 237/255),
            Color(red: 239/255, green: 235/255, blue: 224/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            // 背景
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // 导航栏
                customNavigationBar

                // 搜索栏（条件显示）
                if showSearch {
                    searchBar
                }

                // 筛选标签栏
                filterTabBar

                // 分组/排序选项栏
                groupingSortingBar

                // 内容区域
                contentArea
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showReadingView) {
            if let bookId = selectedBookId, let bookTitle = selectedBookTitle {
                ClassicsReadingView(
                    bookId: bookId,
                    bookTitle: bookTitle
                )
                .asSubView()
            }
        }
        .sheet(isPresented: $showSettings) {
            settingsSheet
        }
        .enableSwipeBack() // 启用系统原生滑动返回手势
        .onAppear {
            viewModel.loadMarks()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToClassicsReading"))) { notification in
            if let bookId = notification.userInfo?["bookId"] as? String,
               let chapterId = notification.userInfo?["chapterId"] as? String,
               let bookTitle = notification.userInfo?["bookTitle"] as? String {
                // 保存导航参数
                selectedBookId = bookId
                selectedChapterId = chapterId
                selectedBookTitle = bookTitle

                // 触发导航
                showReadingView = true
            }
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchMarks(keyword: newValue)
        }
    }
    
    // MARK: - 导航栏
    private var customNavigationBar: some View {
        HStack(spacing: 16) {
            // 返回按钮
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.7))
                )
            }

            Spacer()

            // 标题
            Text("笔记中心")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

            Spacer()

            // 搜索和设置按钮
            HStack(spacing: 12) {
                // 搜索按钮
                Button(action: { showSearch.toggle() }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.7))
                        )
                }

                // 设置按钮
                Button(action: { showSettings = true }) {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.7))
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.3))
    }
    
    // MARK: - 筛选标签栏
    private var filterTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MarkFilterType.allCases, id: \.self) { filter in
                    FilterTabButton(
                        filter: filter,
                        count: viewModel.getCount(for: filter),
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                            viewModel.applyFilter(filter)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.white.opacity(0.3))
    }
    
    // MARK: - 分组/排序选项栏
    private var groupingSortingBar: some View {
        HStack(spacing: 0) {
            // 分组选项
            Menu {
                ForEach(GroupingOption.allCases, id: \.self) { option in
                    Button(action: {
                        selectedGrouping = option
                        viewModel.applyGrouping(option)
                    }) {
                        HStack {
                            Text(option.title)
                            if selectedGrouping == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedGrouping.icon)
                        .font(.system(size: 14))
                    Text(selectedGrouping.title)
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                .padding(.vertical, 12)
            }
            
            Spacer()
            
            // 分隔线
            Rectangle()
                .fill(Color(red: 0.85, green: 0.82, blue: 0.76))
                .frame(width: 1, height: 20)
            
            Spacer()
            
            // 排序选项
            Menu {
                ForEach(SortingOption.allCases, id: \.self) { option in
                    Button(action: {
                        selectedSorting = option
                        viewModel.applySorting(option)
                    }) {
                        HStack {
                            Text(option.title)
                            if selectedSorting == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedSorting.icon)
                        .font(.system(size: 14))
                    Text(selectedSorting.title)
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
        .background(Color.white)
    }
    
    // MARK: - 内容区域
    private var contentArea: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredMarks.isEmpty {
                emptyStateView
            } else {
                marksList
            }
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.2, green: 0.55, blue: 0.45)))
            
            Text("加载中...")
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedFilter == .all ? "book.closed" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.6))
            
            Text(selectedFilter == .all ? "还没有任何标记" : "没有找到相关标记")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
            
            Text(selectedFilter == .all ? "在阅读时选中文字即可添加高亮、收藏或笔记" : "试试其他筛选条件")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if selectedFilter == .all {
                Button(action: { dismiss() }) {
                    Text("开始阅读")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.2, green: 0.55, blue: 0.45),
                                            Color(red: 0.15, green: 0.45, blue: 0.37)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.3), radius: 4, y: 2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 标记列表
    private var marksList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                if selectedGrouping == .none {
                    // 不分组 - 直接显示列表
                    ForEach(viewModel.filteredMarks) { mark in
                        MarkCardView(mark: mark, viewModel: viewModel)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                    }
                } else {
                    // 分组显示
                    ForEach(viewModel.groupedMarks.keys.sorted(), id: \.self) { groupKey in
                        Section(header: GroupHeaderView(title: groupKey, count: viewModel.groupedMarks[groupKey]?.count ?? 0)) {
                            ForEach(viewModel.groupedMarks[groupKey] ?? []) { mark in
                                MarkCardView(mark: mark, viewModel: viewModel)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))

            TextField("搜索笔记内容...", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.7))
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - 设置面板
    private var settingsSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 导出笔记
                Button(action: {
                    viewModel.exportMarks()
                    showSettings = false
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                            .frame(width: 32)

                        Text("导出所有笔记")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                }

                Divider()
                    .padding(.leading, 52)

                // 清空所有笔记
                Button(action: {
                    viewModel.clearAllMarks()
                    showSettings = false
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                            .frame(width: 32)

                        Text("清空所有笔记")
                            .font(.system(size: 16))
                            .foregroundColor(.red)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                }

                Spacer()
            }
            .background(Color(red: 0.96, green: 0.94, blue: 0.92))
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showSettings = false
                    }
                }
            }
        }
    }
}

// MARK: - 筛选标签按钮
struct FilterTabButton: View {
    let filter: MarkFilterType
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14))

                Text(filter.title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))

                if count > 0 {
                    Text("(\(count))")
                        .font(.system(size: 12))
                }
            }
            .foregroundColor(isSelected ? .white : Color(red: 0.4, green: 0.34, blue: 0.3))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.55, blue: 0.45),
                                        Color(red: 0.15, green: 0.45, blue: 0.37)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.3), radius: 4, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.96, green: 0.95, blue: 0.93))
                    }
                }
            )
        }
    }
}

// MARK: - 分组标题
struct GroupHeaderView: View {
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            // 左侧装饰线
            Rectangle()
                .fill(Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.3))
                .frame(height: 1)

            // 标题
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.45))

                Text("(\(count))")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.7))
            }

            // 右侧装饰线
            Rectangle()
                .fill(Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.3))
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.98, green: 0.97, blue: 0.95))
    }
}

// MARK: - 标记卡片
struct MarkCardView: View {
    let mark: TextMark
    @ObservedObject var viewModel: NoteCenterViewModel

    @State private var isPressed = false
    @State private var showEditSheet = false
    @State private var showColorPicker = false
    @State private var showDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部 - 书籍和章节信息
            HStack(spacing: 6) {
                Image(systemName: "book.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                // 显示书籍名称和章节名称
                if let bookTitle = mark.section?.bookTitle, !bookTitle.isEmpty {
                    Text(bookTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))

                    // 如果有章节名称，也显示
                    if let chapterTitle = mark.section?.chapterTitle, !chapterTitle.isEmpty {
                        Text("·")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))

                        Text(chapterTitle)
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    }
                } else {
                    Text("未知书籍")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                }

                Spacer()

                // 如果有笔记，显示笔记图标
                if let note = mark.note, !note.isEmpty {
                    Image(systemName: "note.text.badge.plus")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                }
            }

            // 中部 - 原文（带高亮背景）
            // 优先显示 section.original，确保总是有内容显示
            if let displayText = mark.section?.original {
                Text(displayText)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .lineLimit(3)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(highlightBackgroundColor(for: mark.highlightColor))
                    )
            } else if let textRange = mark.textRange?.text {
                // 降级：如果 section.original 为空，尝试使用 textRange.text
                Text(textRange)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .lineLimit(3)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(highlightBackgroundColor(for: mark.highlightColor))
                    )
            }

            // 笔记内容（如果有）
            if let note = mark.note, !note.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))

                    Text(note)
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
                        .lineLimit(3)

                    Image(systemName: "quote.closing")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.99, green: 0.98, blue: 0.96))
                )
            }

            // 底部 - 标签和时间
            HStack(spacing: 8) {
                // 高亮颜色标签
                if let color = mark.highlightColor {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(highlightColor(for: color))
                            .frame(width: 8, height: 8)
                        Text(colorName(for: color))
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.96, green: 0.95, blue: 0.93))
                    )
                }

                // 收藏标签
                if mark.isFavorite {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("已收藏")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.9, green: 0.6, blue: 0.2).opacity(0.1))
                    )
                }

                Spacer()

                // 时间
                Text(formatDate(mark.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.6, green: 0.55, blue: 0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            // 点击跳转到原文
            viewModel.navigateToOriginalText(mark: mark)
        }
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }, perform: {
            // 长按显示操作菜单
            showActionMenu()
        })
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // 删除按钮
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("删除", systemImage: "trash.fill")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            // 编辑按钮
            Button {
                showEditSheet = true
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            .tint(Color(red: 0.2, green: 0.55, blue: 0.45))
        }
        .sheet(isPresented: $showEditSheet) {
            EditNoteSheet(mark: mark, viewModel: viewModel)
        }
        .confirmationDialog("选择高亮颜色", isPresented: $showColorPicker) {
            ColorPickerButtons(mark: mark, viewModel: viewModel)
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                viewModel.deleteMark(mark)
            }
        } message: {
            Text("确定要删除这条标记吗？")
        }
    }

    private func showActionMenu() {
        // 震动反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // 显示操作菜单（使用系统菜单）
        // 这里可以使用 UIMenu 或者自定义弹窗
    }

    // 高亮背景颜色
    private func highlightBackgroundColor(for color: String?) -> Color {
        guard let color = color else {
            return Color(red: 0.98, green: 0.97, blue: 0.95)
        }

        switch color {
        case "yellow":
            return Color.yellow.opacity(0.2)
        case "green":
            return Color.green.opacity(0.15)
        case "blue":
            return Color.blue.opacity(0.15)
        case "pink":
            return Color.pink.opacity(0.15)
        case "purple":
            return Color.purple.opacity(0.15)
        default:
            return Color(red: 0.98, green: 0.97, blue: 0.95)
        }
    }

    // 高亮颜色
    private func highlightColor(for color: String) -> Color {
        switch color {
        case "yellow":
            return Color.yellow
        case "green":
            return Color.green
        case "blue":
            return Color.blue
        case "pink":
            return Color.pink
        case "purple":
            return Color.purple
        default:
            return Color.gray
        }
    }

    // 颜色名称
    private func colorName(for color: String) -> String {
        switch color {
        case "yellow":
            return "黄色"
        case "green":
            return "绿色"
        case "blue":
            return "蓝色"
        case "pink":
            return "粉色"
        case "purple":
            return "紫色"
        default:
            return "未知"
        }
    }

    // 格式化日期
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return displayFormatter.string(from: date)
    }
}

// MARK: - 编辑笔记弹窗
struct EditNoteSheet: View {
    let mark: TextMark
    @ObservedObject var viewModel: NoteCenterViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var noteText: String
    @State private var isSaving = false

    init(mark: TextMark, viewModel: NoteCenterViewModel) {
        self.mark = mark
        self.viewModel = viewModel
        _noteText = State(initialValue: mark.note ?? "")
    }

    private let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 245/255, green: 242/255, blue: 237/255),
            Color(red: 239/255, green: 235/255, blue: 224/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                VStack(spacing: 20) {
                    // 原文（只读）
                    // 优先显示 section.original，确保总是有内容显示
                    if let displayText = mark.section?.original ?? mark.textRange?.text {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("原文")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            Text(displayText)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.7))
                                )
                        }
                    }

                    // 笔记编辑器
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "note.text")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))

                            Text("笔记内容")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("\(noteText.count) / 500")
                                .font(.system(size: 12))
                                .foregroundColor(noteText.count > 500 ? .red : .secondary)
                        }

                        TextEditor(text: $noteText)
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                            .frame(height: 200)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.2), lineWidth: 1)
                            )
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("编辑笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveNote()
                    }
                    .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.45))
                    .disabled(isSaving || noteText.count > 500)
                }
            }
        }
    }

    private func saveNote() {
        isSaving = true
        viewModel.updateNote(mark: mark, note: noteText) {
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - 颜色选择器按钮
struct ColorPickerButtons: View {
    let mark: TextMark
    @ObservedObject var viewModel: NoteCenterViewModel

    var body: some View {
        Group {
            ColorButton(color: "yellow", name: "黄色", isSelected: mark.highlightColor == "yellow") {
                viewModel.updateHighlightColor(mark: mark, color: "yellow")
            }

            ColorButton(color: "green", name: "绿色", isSelected: mark.highlightColor == "green") {
                viewModel.updateHighlightColor(mark: mark, color: "green")
            }

            ColorButton(color: "blue", name: "蓝色", isSelected: mark.highlightColor == "blue") {
                viewModel.updateHighlightColor(mark: mark, color: "blue")
            }

            ColorButton(color: "pink", name: "粉色", isSelected: mark.highlightColor == "pink") {
                viewModel.updateHighlightColor(mark: mark, color: "pink")
            }

            ColorButton(color: "purple", name: "紫色", isSelected: mark.highlightColor == "purple") {
                viewModel.updateHighlightColor(mark: mark, color: "purple")
            }

            Button("无高亮") {
                viewModel.updateHighlightColor(mark: mark, color: nil)
            }

            Button("取消", role: .cancel) { }
        }
    }
}

struct ColorButton: View {
    let color: String
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(colorValue)
                    .frame(width: 20, height: 20)

                Text(name)

                if isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    private var colorValue: Color {
        switch color {
        case "yellow":
            return Color.yellow
        case "green":
            return Color.green
        case "blue":
            return Color.blue
        case "pink":
            return Color.pink
        case "purple":
            return Color.purple
        default:
            return Color.gray
        }
    }
}

// MARK: - 预览
#Preview {
    NoteCenterView()
}

