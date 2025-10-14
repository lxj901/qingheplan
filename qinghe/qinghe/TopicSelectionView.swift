import SwiftUI

/// 现代化话题选择页面 - 小红书风格列表设计
struct TopicSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedTopics: Set<String> = []
    @State private var allTags: [TagDTO] = []
    @State private var popularTags: [PopularTag] = []
    @State private var userTags: [UserTag] = []
    @State private var searchSuggestions: [TagSuggestion] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    let initialSelectedTopics: [String]
    let onTopicsSelected: ([String]) -> Void

    private let tagsAPIService = TagsAPIService.shared
    private let maxTags = 10

    init(selectedTopics: [String] = [], onTopicsSelected: @escaping ([String]) -> Void) {
        self.initialSelectedTopics = selectedTopics
        self.onTopicsSelected = onTopicsSelected
    }

    var body: some View {
        VStack(spacing: 0) {
            // 现代化顶部标题栏
            modernHeaderSection

            // 搜索栏
            modernSearchSection

            // 内容列表
            modernContentList

            // 底部确认按钮
            modernBottomSection
        }
        .background(modernBackgroundGradient)
        .navigationBarHidden(true)
        .onAppear {
            setupInitialState()
            loadInitialData()
        }
        .onChange(of: searchText) { newValue in
            handleSearchTextChange(newValue)
        }
        .alert("错误", isPresented: $showError) {
            Button("确定") {
                showError = false
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - 现代化背景渐变
    private var modernBackgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 250/255, green: 250/255, blue: 252/255),
                Color(red: 248/255, green: 249/255, blue: 251/255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - 现代化顶部标题栏
    private var modernHeaderSection: some View {
        VStack(spacing: 0) {
            // 紧凑的标题区域
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("返回")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.blue)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("选择话题")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text("已选择 \(selectedTopics.count)/\(maxTags)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 占位符保持平衡
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("返回")
                        .font(.system(size: 16, weight: .medium))
                }
                .opacity(0) // 隐藏但占用空间
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12) // 减小垂直间距
            .background(.ultraThinMaterial)

            // 细分割线
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 0.5)
        }
    }

    // MARK: - 现代化搜索栏
    private var modernSearchSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)

                TextField("搜索或输入新话题", text: $searchText)
                    .font(.system(size: 16))
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        addTopicFromSearch()
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchSuggestions = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }


    // MARK: - 现代化内容列表
    private var modernContentList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // 搜索建议
                if !searchSuggestions.isEmpty && !searchText.isEmpty {
                    modernSearchSuggestionsSection
                }

                // 我的常用话题
                if !userTags.isEmpty {
                    modernUserTagsSection
                }
                // 全部话题
                if !allTags.isEmpty && searchText.isEmpty {
                    modernAllTagsSection
                }


                // 热门话题
                if !popularTags.isEmpty {
                    modernPopularTagsSection
                }

                // 加载状态
                if isLoading {
                    modernLoadingView
                }

                // 空状态
                if !isLoading && popularTags.isEmpty && userTags.isEmpty && searchSuggestions.isEmpty {
                    modernEmptyStateView
                }
            }
        }
    }

    // MARK: - 搜索建议列表
    private var modernSearchSuggestionsSection: some View {
        VStack(spacing: 0) {
            // 分组标题
            modernSectionHeader(title: "搜索建议", subtitle: "根据输入内容推荐")

            // 建议列表
            ForEach(searchSuggestions.prefix(8), id: \.tag) { suggestion in
                ModernTagListItem(
                    tag: suggestion.tag,
                    count: 0,
                    isSelected: selectedTopics.contains(suggestion.tag),
                    showTrending: false
                ) {
                    toggleTag(suggestion.tag)
                }
            }
        }
    }

    // MARK: - 我的常用话题
    private var modernUserTagsSection: some View {
        VStack(spacing: 0) {
            modernSectionHeader(title: "我的常用", subtitle: "最近使用的话题")

            ForEach(userTags.prefix(6), id: \.tag) { userTag in
                ModernTagListItem(
                    tag: userTag.tag,
                    count: userTag.count,
                    isSelected: selectedTopics.contains(userTag.tag),
                    showTrending: false
                ) {
                    toggleTag(userTag.tag)
                }
            }
        }
    }

    // MARK: - 热门话题
    private var modernPopularTagsSection: some View {
        VStack(spacing: 0) {
            modernSectionHeader(title: "热门话题", subtitle: "当前最受欢迎")

            ForEach(popularTags.prefix(15), id: \.tag) { popularTag in
                ModernTagListItem(
                    tag: popularTag.tag,
                    count: popularTag.count,
                    isSelected: selectedTopics.contains(popularTag.tag),
                    showTrending: true
                ) {
                    toggleTag(popularTag.tag)
                }
            }
        }
    }

    // MARK: - 分组标题
    private func modernSectionHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)

            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - 底部确认按钮
    private var modernBottomSection: some View {
        VStack(spacing: 0) {
            // 细分割线
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 0.5)

            // 紧凑的按钮区域
            VStack(spacing: 8) {
                // 已选择话题预览（如果有的话）
                if !selectedTopics.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array(selectedTopics.prefix(3)), id: \.self) { topic in
                                Text(topic)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color(red: 76/255, green: 175/255, blue: 80/255))
                                    )
                            }
                            if selectedTopics.count > 3 {
                                Text("...")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(height: 24)
                }

                // 确认按钮
                Button(action: confirmSelection) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))

                        Text(selectedTopics.isEmpty ? "请选择话题" : "确认选择(\(selectedTopics.count))")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48) // 适当增加按钮高度
                    .background(
                        RoundedRectangle(cornerRadius: 12) // 减小圆角
                            .fill(
                                selectedTopics.isEmpty
                                ? LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color(red: 76/255, green: 175/255, blue: 80/255), Color(red: 56/255, green: 142/255, blue: 60/255)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                }
                .disabled(selectedTopics.isEmpty)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 14) // 适当增加垂直间距
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - 加载和空状态
    private var modernLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color(red: 76/255, green: 175/255, blue: 80/255))

            Text("正在加载话题...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var modernEmptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tag.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))

            VStack(spacing: 8) {
                Text("暂无话题数据")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Text("请检查网络连接或稍后重试")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("重新加载") {
                loadInitialData()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 76/255, green: 175/255, blue: 80/255), lineWidth: 1.5)
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: - 全部话题区块
    private var modernAllTagsSection: some View {
        VStack(spacing: 0) {
            modernSectionHeader(title: "全部话题", subtitle: "系统内可选的话题")
            ForEach(Array(allTags.prefix(30).enumerated()), id: \.offset) { index, tag in
                ModernTagListItem(
                    tag: tag.tag,
                    count: tag.count,
                    isSelected: selectedTopics.contains(tag.tag),
                    showTrending: false
                ) {
                    toggleTag(tag.tag)
                }
            }
        }
    }

    // MARK: - Methods

    private func setupInitialState() {
        selectedTopics = Set(initialSelectedTopics)
    }

    private func loadInitialData() {
        isLoading = true
        errorMessage = nil

        Task {
            await loadAllTags()
            await loadPopularTags()
            await loadUserFrequentTags()



            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func loadPopularTags() async {
        do {
            let response = try await tagsAPIService.getPopularTags(limit: 20)
            await MainActor.run {
                self.popularTags = response
            }
        } catch {
            await MainActor.run {
                self.handleError(error)
            }
        }
    }

    private func loadAllTags(search: String? = nil) async {
        do {
            let response = try await tagsAPIService.getAllTags(limit: 50, search: search)
            await MainActor.run {
                self.allTags = response
            }
        } catch {
            await MainActor.run {
                self.handleError(error)
            }
        }
    }

    private func loadUserFrequentTags() async {
        // 只有登录用户才加载常用标签
        guard AuthManager.shared.isLoggedIn() else { return }

        do {
            let response = try await tagsAPIService.getUserTags(limit: 10)
            await MainActor.run {
                self.userTags = response
            }
        } catch {
            // 用户常用标签加载失败不显示错误，因为可能是未登录
            print("加载用户常用标签失败: \(error)")
        }
    }

    private func handleSearchTextChange(_ newValue: String) {
        guard !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchSuggestions = []
            return
        }

        // 使用防抖搜索
        Task {
            do {
                let results = try await tagsAPIService.getAllTags(limit: 10, search: newValue)
                await MainActor.run {
                    // 用全部标签搜索结果替换建议
                    self.searchSuggestions = results.prefix(8).map { TagSuggestion(tag: $0.tag, relevance: 1.0, category: nil) }
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }

    private func addTopicFromSearch() {
        let cleanTopic = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTopic.isEmpty else { return }

        if selectedTopics.count >= maxTags {
            showErrorMessage("最多只能选择\(maxTags)个话题")
            return
        }

        if !selectedTopics.contains(cleanTopic) {
            selectedTopics.insert(cleanTopic)
            searchText = ""
            searchSuggestions = []
        }
    }

    private func toggleTag(_ tag: String) {
        if selectedTopics.contains(tag) {
            selectedTopics.remove(tag)
        } else if selectedTopics.count < maxTags {
            selectedTopics.insert(tag)
        } else {
            showErrorMessage("最多只能选择\(maxTags)个话题")
        }
    }

    private func confirmSelection() {
        onTopicsSelected(Array(selectedTopics))
        dismiss()
    }
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    // MARK: - 安全区域辅助方法
    private func getSafeAreaTop() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 44 // 默认状态栏高度
        }
        return window.safeAreaInsets.top
    }

    private func getSafeAreaBottom() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 34 // 默认底部安全区域高度
        }
        return window.safeAreaInsets.bottom
    }

    // MARK: - 错误处理
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

// MARK: - 现代化列表项组件
struct ModernTagListItem: View {
    let tag: String
    let count: Int?
    let isSelected: Bool
    let showTrending: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 左侧：话题图标和内容
                HStack(spacing: 12) {
                    // 话题图标
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.15) : Color.gray.opacity(0.1))
                            .frame(width: 44, height: 44)

                        Image(systemName: "number")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isSelected ? Color(red: 76/255, green: 175/255, blue: 80/255) : .secondary)
                    }

                    // 话题信息
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(tag)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            // 热门标识
                            if showTrending {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                        }

                        if let count = count {
                            Text("\(count.formatted())人使用")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // 右侧：选择状态
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Rectangle()
                    .fill(isSelected ? Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 已选择话题标签组件
struct ModernSelectedTag: View {
    let text: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(red: 76/255, green: 175/255, blue: 80/255))
        )
    }
}

// MARK: - 毛玻璃效果组件
struct VisualEffectView: UIViewRepresentable {
    let effect: UIVisualEffect

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: effect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

// MARK: - Preview

#Preview {
    TopicSelectionView(selectedTopics: ["健身", "减肥"]) { topics in
        print("Selected topics: \(topics)")
    }
}
