import SwiftUI

struct CommunitySearchView: View {
    let viewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var searchHistory: [String] = []
    @State private var searchResults: [CommunityPost] = []
    @State private var searchUsers: [CommunityUserProfile] = []
    @State private var searchTopics: [String] = []
    @State private var isSearching = false
    @State private var selectedFilter: SearchFilter = .all
    @State private var selectedSortType: SortType = .latest
    @State private var showingFilters = false
    @FocusState private var isSearchFieldFocused: Bool
    @State private var totalResults = 0
    @State private var currentPage = 1
    @State private var hasNextPage = false
    @State private var errorMessage: String?
    @State private var showingUserProfile = false
    @State private var selectedUserId: String?
    @State private var navigationPath = NavigationPath()
    @State private var selectedPostId: String?

    private let communityService = CommunityAPIService.shared

    // 新增：预设搜索关键词
    private let presetSearchKeyword: String?

    // 新增：自定义初始化方法
    init(viewModel: CommunityViewModel, presetSearchKeyword: String? = nil) {
        self.viewModel = viewModel
        self.presetSearchKeyword = presetSearchKeyword

        print("🔍 CommunitySearchView 初始化开始")
        print("🔍 传入的预设关键词: '\(presetSearchKeyword ?? "nil")'")
        print("🔍 预设关键词类型: \(type(of: presetSearchKeyword))")

        // 如果有预设关键词，直接初始化searchText和selectedFilter
        if let keyword = presetSearchKeyword, !keyword.isEmpty {
            print("🔍 ✅ 有预设关键词，设置搜索文本: '\(keyword)'")
            self._searchText = State(initialValue: keyword)
            self._selectedFilter = State(initialValue: .posts)
        } else {
            print("🔍 ❌ 没有预设关键词，使用默认设置")
            print("🔍 预设关键词为空或nil: isEmpty=\(presetSearchKeyword?.isEmpty ?? true)")
        }
        
        print("🔍 CommunitySearchView 初始化完成")
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // 搜索栏
                searchHeader
                
                // 内容区域
                if searchText.isEmpty {
                    searchSuggestions
                        .transition(.opacity)
                } else {
                    searchResultsView
                        .transition(.opacity)
                }
            }
            .background(AppConstants.Colors.backgroundGray)
            .navigationBarHidden(true)
            .asSubView()
            .navigationDestination(for: String.self) { postId in
                PostDetailView(postId: postId)
                    .navigationBarHidden(true)
                    .asSubView() // 标记为子页面，隐藏Tab栏
                    .id(postId)
            }
            .onAppear {
                loadSearchHistory()

                // 如果有预设搜索关键词，则自动搜索
                if let keyword = presetSearchKeyword, !keyword.isEmpty {
                    print("🔍 搜索页面初始化，预设关键词: \(keyword)")

                    // 确保searchText已经设置为预设关键词
                    searchText = keyword
                    selectedFilter = .posts

                    // 使用异步延迟确保UI完全初始化后执行搜索
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        print("🔍 开始自动搜索: \(keyword)")
                        performSearch()
                    }
                } else {
                    // 没有预设关键词时，聚焦搜索框
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSearchFieldFocused = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingUserProfile) {
            if let userId = selectedUserId {
                UserProfileView(userId: userId)
                    .onAppear {
                        print("🔍 搜索页面：导航到用户详情页面，用户ID: \(userId)")
                    }
            }
        }
    }
    
    // MARK: - 搜索头部
    private var searchHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 返回按钮
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppConstants.Colors.primaryText)
                }
                
                // 搜索输入框
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.Colors.tertiaryText)
                    
                    TextField("搜索用户、内容或话题", text: $searchText)
                        .focused($isSearchFieldFocused)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: clearSearch) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AppConstants.Colors.tertiaryText)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppConstants.Colors.separatorGray, lineWidth: 1)
                )
                
                // 搜索按钮
                Button("搜索") {
                    performSearch()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppConstants.Colors.primaryGreen)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            
            // 筛选栏（仅在有搜索结果时显示）
            if !searchText.isEmpty {
                filterBar
            }
        }
    }
    
    // MARK: - 筛选栏
    private var filterBar: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SearchFilter.allCases, id: \.self) { filter in
                        CommunityFilterChip(
                            title: filter.displayName,
                            isSelected: selectedFilter == filter,
                            action: {
                                selectedFilter = filter
                                performSearch()
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // 更多筛选按钮
            Button(action: { showingFilters = true }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16))
                    .foregroundColor(AppConstants.Colors.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppConstants.Colors.backgroundGray)
                    .cornerRadius(6)
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 8)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(AppConstants.Colors.separatorGray)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - 搜索建议
    private var searchSuggestions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 搜索历史
                if !searchHistory.isEmpty {
                    searchHistorySection
                } else {
                    // 当没有搜索历史时显示提示
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(AppConstants.Colors.tertiaryText)

                        Text("开始搜索")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppConstants.Colors.primaryText)

                        Text("搜索帖子、用户或话题")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - 搜索历史
    private var searchHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16))
                    .foregroundColor(AppConstants.Colors.tertiaryText)
                
                Text("最近搜索")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppConstants.Colors.primaryText)
                
                Spacer()
                
                Button("清空") {
                    clearSearchHistory()
                }
                .font(.system(size: 14))
                .foregroundColor(AppConstants.Colors.tertiaryText)
            }
            .padding(.horizontal, 16)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(searchHistory, id: \.self) { keyword in
                    Button(action: { selectSearchKeyword(keyword) }) {
                        Text(keyword)
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.Colors.secondaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
    }
    

    
    // MARK: - 搜索结果视图
    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // 结果统计
            HStack {
                Text("找到 \(totalResults) 条相关内容")
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.secondaryText)
                
                Spacer()
                
                // 排序选择
                Menu {
                    ForEach(SortType.allCases, id: \.self) { sortType in
                        Button(sortType.displayName) {
                            selectedSortType = sortType
                            performSearch()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedSortType.displayName)
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.Colors.secondaryText)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(AppConstants.Colors.tertiaryText)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            
            // 搜索结果列表
            if isSearching {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("搜索中...")
                            .font(.system(size: 16))
                            .foregroundColor(AppConstants.Colors.secondaryText)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppConstants.Colors.backgroundGray)
            } else if let errorMessage = errorMessage {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(AppConstants.Colors.systemRed)
                        
                        Text("搜索出错")
                            .font(.system(size: 16))
                            .foregroundColor(AppConstants.Colors.secondaryText)
                        
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.Colors.tertiaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button("重新搜索") {
                            performSearch()
                        }
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppConstants.Colors.backgroundGray)
            } else if searchResults.isEmpty && searchUsers.isEmpty && searchTopics.isEmpty {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(AppConstants.Colors.tertiaryText)
                        
                        Text("没有找到相关内容")
                            .font(.system(size: 16))
                            .foregroundColor(AppConstants.Colors.secondaryText)
                        
                        Text("试试其他关键词或浏览热门内容")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.Colors.tertiaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppConstants.Colors.backgroundGray)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // 用户搜索结果
                        if selectedFilter == .users || selectedFilter == .all {
                            ForEach(searchUsers) { user in
                                UserSearchResultCard(user: user, onUserTap: { userId in
                                    // 点击用户卡片跳转到用户主页
                                    print("🔍 搜索页面：点击用户卡片，用户ID: \(userId)")
                                    selectedUserId = userId
                                    showingUserProfile = true
                                }, onFollowStatusChanged: { userId, isFollowing in
                                    // 更新搜索结果中的关注状态
                                    updateUserFollowStatus(userId: userId, isFollowing: isFollowing)
                                })
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }

                        // 话题搜索结果
                        if selectedFilter == .topics || selectedFilter == .all {
                            // 优先使用服务端返回的话题名数组；若为空且是topics筛选，则从帖子中提取
                            let topicsArray: [String] = {
                                if !searchTopics.isEmpty { return searchTopics }
                                if selectedFilter == .topics { return extractUniqueTopics(from: searchResults) }
                                return []
                            }()
                            let uniqueTopics = Array(Set(topicsArray)).sorted()

                            if !uniqueTopics.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "number")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(AppConstants.Colors.primaryGreen)

                                        Text("相关话题")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(AppConstants.Colors.primaryText)

                                        Spacer()

                                        Text("\(uniqueTopics.count)个")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppConstants.Colors.secondaryText)
                                    }
                                    .padding(.horizontal, 16)

                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                                        ForEach(uniqueTopics, id: \.self) { topic in
                                            TopicSearchResultCard(topic: topic, count: nil) {
                                                // 点击话题，搜索该话题下的帖子
                                                searchText = "#\(topic)"
                                                selectedFilter = .posts
                                                performSearch()
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                .padding(.vertical, 16)
                            }
                        }

                        // 帖子搜索结果
                        if selectedFilter == .posts || selectedFilter == .all {
                            ForEach(searchResults) { post in
                                PostCardView(
                                    post: convertCommunityPostToPost(post),
                                    showHotBadge: false,
                                    showEditButton: false,
                                    onLike: {
                                        // 处理点赞
                                        toggleLikePost(post.id)
                                    },
                                    onBookmark: {
                                        // 处理收藏
                                        toggleBookmarkPost(post.id)
                                    },
                                    onShare: {
                                        // 处理分享
                                    },
                                    onReport: {
                                        // 处理举报
                                    },
                                    onNavigateToDetail: { postId in
                                        print("🔍 搜索页面：导航到帖子详情，帖子ID: \(postId)")
                                        Task { @MainActor in
                                            selectedPostId = postId
                                            navigationPath.append(postId)
                                        }
                                    },
                                    onNavigateToUserProfile: { author in
                                        selectedUserId = String(author.id)
                                        showingUserProfile = true
                                    }
                                )
                                .onTapGesture {
                                    print("🔍 搜索页面：帖子卡片点击，帖子ID: \(post.id)")
                                    Task { @MainActor in
                                        selectedPostId = post.id
                                        navigationPath.append(post.id)
                                    }
                                }
                                .onAppear {
                                    // 调试信息：检查打卡和运动数据
                                    if post.checkin != nil {
                                        print("🔍 搜索结果包含打卡数据: 帖子ID \(post.id)")
                                    }
                                    if post.workout != nil {
                                        print("🔍 搜索结果包含运动数据: 帖子ID \(post.id)")
                                    }
                                }
                            }
                        }
                        
                        // 加载更多按钮
                        if hasNextPage && !isSearching {
                            Button("加载更多") {
                                loadMoreResults()
                            }
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                            .padding()
                        }
                    }
                    .padding(.vertical, 16)
                }
                .background(AppConstants.Colors.backgroundGray)
            }
        }
        .fullScreenCover(isPresented: $showingFilters) {
            SearchFiltersSheet(
                selectedFilter: $selectedFilter,
                selectedSortType: $selectedSortType,
                onApply: {
                    // 应用筛选后重新搜索
                    performSearch()
                }
            )
        }
    }
    
    // MARK: - 私有方法
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        isSearchFieldFocused = false
        errorMessage = nil
        currentPage = 1
        
        // 添加到搜索历史
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        updateSearchHistory(keyword)
        
        // 调用真实的搜索API
        Task {
            await performSearchAPI(keyword: keyword, page: currentPage)
        }
    }
    
    private func updateSearchHistory(_ keyword: String) {
        if !searchHistory.contains(keyword) {
            searchHistory.insert(keyword, at: 0)
            if searchHistory.count > 10 {
                searchHistory.removeLast()
            }
        } else {
            // 移动到最前面
            searchHistory.removeAll { $0 == keyword }
            searchHistory.insert(keyword, at: 0)
        }
        
        // 保存到本地存储
        UserDefaults.standard.set(searchHistory, forKey: "search_history")
    }
    
    private func performSearchAPI(keyword: String, page: Int) async {
        do {
            // 处理标签搜索：如果关键词以#开头，去掉#号发送给后端
            let processedKeyword = processSearchKeyword(keyword)

            let searchRequest = SearchRequest(
                q: processedKeyword,
                type: selectedFilter.apiValue,
                sort: selectedSortType.apiValue,
                page: page,
                limit: 20
            )

            print("🔍 原始关键词: '\(keyword)', 处理后关键词: '\(processedKeyword)'")

            let response = try await communityService.search(searchRequest)
            
            await MainActor.run {
                if response.isSuccess, let data = response.data {
                    if page == 1 {
                        // 首次搜索，清空之前的结果
                        searchResults = data.results.posts ?? []
                        searchUsers = data.results.users ?? []
                        searchTopics = data.results.topics ?? []
                    } else {
                        // 加载更多，追加结果
                        searchResults.append(contentsOf: data.results.posts ?? [])
                    }

                    totalResults = data.pagination.total
                    hasNextPage = data.pagination.hasNext
                    currentPage = page

                    // 调试信息
                    print("🔍 搜索结果更新: posts=\(searchResults.count), total=\(totalResults)")

                    // 调试打卡和运动数据
                    for post in data.results.posts ?? [] {
                        if post.checkin != nil {
                            print("🔍 发现包含打卡数据的帖子: \(post.id)")
                        }
                        if post.workout != nil {
                            print("🔍 发现包含运动数据的帖子: \(post.id)")
                        }
                    }
                } else {
                    if page == 1 {
                        searchResults = []
                        searchUsers = []
                        searchTopics = []
                        totalResults = 0
                    }
                    print("❌ 搜索响应失败或数据为空")
                }

                isSearching = false
            }
        } catch {
            print("❌ 搜索API调用失败: \(error)")
            print("❌ 错误详细信息: \(error.localizedDescription)")
            if let networkError = error as? NetworkManager.NetworkError {
                print("❌ 网络错误类型: \(networkError)")
            }
            
            // 检查是否是特定的解码错误
            if error.localizedDescription.contains("decode") {
                print("⚠️ 检测到解码错误，这可能不影响标签搜索功能")
            }
            
            await MainActor.run {
                isSearching = false
                errorMessage = "搜索失败：\(error.localizedDescription)"
                if page == 1 {
                    searchResults = []
                    searchUsers = []
                    searchTopics = []
                    totalResults = 0
                    hasNextPage = false
                }
                
                // 如果是标签搜索失败，尝试使用标签API
                if keyword.hasPrefix("#") {
                    print("🔍 标签搜索失败，尝试使用标签API...")
                    Task {
                        await tryTagSearch(keyword: keyword)
                    }
                }
            }
        }
    }
    
    /// 标签搜索后备方案
    private func tryTagSearch(keyword: String) async {
        guard keyword.hasPrefix("#") else { return }
        
        do {
            // 去掉所有开头的 # 号
            var tagName = keyword
            while tagName.hasPrefix("#") {
                tagName = String(tagName.dropFirst())
            }
            tagName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
            print("🏷️ 尝试标签API搜索: '\(tagName)'")
            
            let response = try await communityService.getPostsByTag(tagName: tagName)
            
            await MainActor.run {
                if response.success, let data = response.data {
                    // TagPostsData 使用 items 字段，需要转换为 CommunityPost
                    searchResults = data.items.map { convertPostToCommunityPost($0) }
                    searchUsers = []
                    searchTopics = []
                    totalResults = data.pagination.total
                    hasNextPage = data.pagination.hasNext
                    errorMessage = nil

                    print("🏷️ 标签API搜索成功: 找到 \(data.items.count) 个帖子")
                } else {
                    print("🏷️ 标签API搜索也失败了")
                    errorMessage = "标签搜索失败，请稍后重试"
                }
                isSearching = false
            }
        } catch {
            print("❌ 标签API搜索失败: \(error)")
            await MainActor.run {
                isSearching = false
                errorMessage = "标签搜索出现错误：\(error.localizedDescription)"
            }
        }
    }

    private func selectSearchKeyword(_ keyword: String) {
        searchText = keyword
        performSearch()
    }



    private func clearSearch() {
        searchText = ""
        searchResults.removeAll()
        searchUsers.removeAll()
        totalResults = 0
        hasNextPage = false
        errorMessage = nil
        isSearchFieldFocused = true
    }
    
    private func clearSearchHistory() {
        searchHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: "search_history")
    }
    
    private func sortSearchResults() {
        // API已经按照指定的排序返回了结果，这里不需要再次排序
        // 如果需要客户端排序，可以在这里实现
    }
    
    private func loadMoreResults() {
        guard !isSearching && hasNextPage else { return }
        
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return }
        
        Task {
            await performSearchAPI(keyword: keyword, page: currentPage + 1)
        }
    }
    


    /// 处理搜索关键词：如果是标签搜索（以#开头），去掉所有开头的#号
    private func processSearchKeyword(_ keyword: String) -> String {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        // 如果关键词以#开头，去掉所有开头的#号发送给后端
        if trimmedKeyword.hasPrefix("#") {
            // 去掉所有开头的 # 号
            var cleanKeyword = trimmedKeyword
            while cleanKeyword.hasPrefix("#") {
                cleanKeyword = String(cleanKeyword.dropFirst())
            }
            cleanKeyword = cleanKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleanKeyword.isEmpty ? trimmedKeyword : cleanKeyword
        }

        return trimmedKeyword
    }

    /// 从帖子数组中提取唯一的话题标签
    private func extractUniqueTopics(from posts: [CommunityPost]) -> [String] {
        var uniqueTopics = Set<String>()

        for post in posts {
            if let tags = post.tags {
                for tag in tags {
                    // 去掉#号前缀（如果有的话）
                    let cleanTag = tag.hasPrefix("#") ? String(tag.dropFirst()) : tag
                    if !cleanTag.isEmpty {
                        uniqueTopics.insert(cleanTag)
                    }
                }
            }
        }

        return Array(uniqueTopics).sorted()
    }
    
    private func loadSearchHistory() {
        if let history = UserDefaults.standard.array(forKey: "search_history") as? [String] {
            searchHistory = history
        }
    }
    
    private func toggleLikePost(_ postId: String) {
        Task {
            do {
                let _ = try await communityService.toggleLikePost(postId: postId)
                // 可以在这里更新本地状态
            } catch {
                print("点赞失败：\(error)")
            }
        }
    }
    
    private func toggleBookmarkPost(_ postId: String) {
        Task {
            do {
                let _ = try await communityService.toggleBookmarkPost(postId: postId)
                // 可以在这里更新本地状态
            } catch {
                print("收藏失败：\(error)")
            }
        }
    }

    /// 更新搜索结果中用户的关注状态
    private func updateUserFollowStatus(userId: Int, isFollowing: Bool) {
        if let index = searchUsers.firstIndex(where: { $0.id == userId }) {
            var updatedUser = searchUsers[index]
            updatedUser.isFollowing = isFollowing
            searchUsers[index] = updatedUser
            print("🔍 搜索页面：更新用户 \(userId) 的关注状态为: \(isFollowing)")
        }
    }
}

// MARK: - 用户搜索结果卡片
struct UserSearchResultCard: View {
    let user: CommunityUserProfile
    let onUserTap: ((String) -> Void)?
    let onFollowStatusChanged: ((Int, Bool) -> Void)?
    @State private var isFollowing: Bool = false
    @State private var hasInitialized = false

    init(user: CommunityUserProfile, onUserTap: ((String) -> Void)? = nil, onFollowStatusChanged: ((Int, Bool) -> Void)? = nil) {
        self.user = user
        self.onUserTap = onUserTap
        self.onFollowStatusChanged = onFollowStatusChanged
        self._isFollowing = State(initialValue: user.isFollowing ?? false)
    }

    var body: some View {
        HStack(spacing: 12) {
            // 用户头像
            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(AppConstants.Colors.tertiaryText)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            // 用户信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(user.nickname)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppConstants.Colors.primaryText)

                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                    }
                }

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.Colors.secondaryText)
                        .lineLimit(2)
                }

                Text("\(user.followersCount ?? 0) 粉丝")
                    .font(.system(size: 12))
                    .foregroundColor(AppConstants.Colors.tertiaryText)
            }

            Spacer()

            // 关注按钮
            Button(action: {
                toggleFollow()
            }) {
                Text(isFollowing ? "已关注" : "关注")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isFollowing ? AppConstants.Colors.secondaryText : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(isFollowing ? AppConstants.Colors.backgroundGray : AppConstants.Colors.primaryGreen)
                    .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle()) // 确保整个区域可点击
        .onTapGesture {
            // 点击卡片跳转到用户主页
            onUserTap?(String(user.id))
        }
        .onAppear {
            // 初始化时刷新关注状态，确保显示最新状态
            if !hasInitialized {
                hasInitialized = true
                Task {
                    await refreshFollowStatus()
                }
            }
        }
        .onChange(of: user.isFollowing) { newValue in
            // 当父视图更新了用户的关注状态时，同步更新本地状态
            if let newFollowingStatus = newValue {
                isFollowing = newFollowingStatus
                print("🔍 UserSearchResultCard: 检测到用户 \(user.id) 的关注状态变化: \(newFollowingStatus)")
            }
        }
    }
    
    private func toggleFollow() {
        // 实现关注/取消关注逻辑
        Task {
            do {
                let originalFollowState = isFollowing
                let response: CommunityAPIResponse<FollowResponse>

                if isFollowing {
                    response = try await CommunityAPIService.shared.unfollowUser(userId: user.id)
                } else {
                    response = try await CommunityAPIService.shared.followUser(userId: user.id)
                }

                await MainActor.run {
                    if response.success {
                        if let data = response.data {
                            // 如果服务器返回了data字段，使用服务器返回的状态
                            isFollowing = data.isFollowing
                        } else {
                            // 如果服务器没有返回data字段，根据操作类型推断最终状态
                            isFollowing = !originalFollowState
                        }

                        // 通知父视图更新关注状态
                        onFollowStatusChanged?(user.id, isFollowing)

                        // 操作成功后，重新获取最新的关注状态以确保准确性
                        Task {
                            await refreshFollowStatus()
                        }
                    } else {
                        print("关注操作失败：\(response.message ?? "未知错误")")
                    }
                }
            } catch {
                print("关注操作失败：\(error)")
            }
        }
    }

    /// 刷新关注状态
    private func refreshFollowStatus() async {
        do {
            let response = try await CommunityAPIService.shared.getUserProfile(userId: user.id)
            if response.success, let data = response.data {
                await MainActor.run {
                    isFollowing = data.isFollowing ?? false
                    print("🔄 UserSearchResultCard 关注状态已刷新: \(data.isFollowing ?? false)")
                    // 通知父视图更新关注状态
                    onFollowStatusChanged?(user.id, isFollowing)
                }
            }
        } catch {
            print("❌ UserSearchResultCard 刷新关注状态失败: \(error)")
        }
    }
}

// MARK: - 社区筛选芯片
struct CommunityFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : AppConstants.Colors.secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppConstants.Colors.primaryGreen : Color.clear)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : AppConstants.Colors.separatorGray, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}



// MARK: - 推荐用户卡片
struct RecommendedUserCard: View {
    var body: some View {
        VStack(spacing: 8) {
            // 用户头像
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(AppConstants.Colors.tertiaryText)
                .frame(width: 50, height: 50)
                .background(AppConstants.Colors.backgroundGray)
                .clipShape(Circle())

            // 用户名
            Text("用户名")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppConstants.Colors.primaryText)
                .lineLimit(1)

            // 关注按钮
            Button("关注") {
                // 关注逻辑
            }
            .font(.system(size: 11))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(AppConstants.Colors.primaryGreen)
            .cornerRadius(12)
        }
        .padding(12)
        .frame(width: 100)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - 弹性网格布局
struct FlexibleGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(chunked(data: Array(data)), id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                    Spacer()
                }
            }
        }
    }
    
    private func chunked(data: [Data.Element]) -> [[Data.Element]] {
        let screenWidth = UIScreen.main.bounds.width - 32 // 减去左右边距
        let itemWidth: CGFloat = 120 // 估计的项目宽度
        let itemsPerRow = max(1, Int(screenWidth / itemWidth))
        
        return data.chunked(into: itemsPerRow)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - 话题搜索结果卡片
struct TopicSearchResultCard: View {
    let topic: String
    let count: Int?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "number")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("#\(topic)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppConstants.Colors.primaryText)
                        .lineLimit(1)

                    if let count = count {
                        Text("\(count)个帖子")
                            .font(.system(size: 12))
                            .foregroundColor(AppConstants.Colors.secondaryText)
                    } else {
                        Text("点击查看相关帖子")
                            .font(.system(size: 12))
                            .foregroundColor(AppConstants.Colors.secondaryText)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppConstants.Colors.tertiaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppConstants.Colors.separatorGray, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 搜索筛选枚举
enum SearchFilter: String, CaseIterable {
    case all = "全部"
    case posts = "动态"
    case users = "用户"
    case topics = "话题"

    var displayName: String {
        return rawValue
    }

    var apiValue: String {
        switch self {
        case .all:
            return "all"
        case .posts:
            return "posts"
        case .users:
            return "users"
        case .topics:
            return "topics"
        }
    }
}

enum SortType: String, CaseIterable {
    case latest = "最新"
    case popular = "最热"
    case mostCommented = "评论最多"
    
    var displayName: String {
        return rawValue
    }
    
    var apiValue: String {
        switch self {
        case .latest:
            return "latest"
        case .popular:
            return "hot"
        case .mostCommented:
            return "relevant"
        }
    }
}

// MARK: - 搜索筛选弹窗
struct SearchFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFilter: SearchFilter
    @Binding var selectedSortType: SortType
    let onApply: () -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                // 内容类型
                VStack(alignment: .leading, spacing: 16) {
                    Text("内容类型")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppConstants.Colors.primaryText)
                    
                    VStack(spacing: 12) {
                        ForEach(SearchFilter.allCases, id: \.self) { filter in
                            FilterOptionRow(
                                title: filter.displayName,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                
                // 排序方式
                VStack(alignment: .leading, spacing: 16) {
                    Text("排序方式")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppConstants.Colors.primaryText)
                    
                    VStack(spacing: 12) {
                        ForEach(SortType.allCases, id: \.self) { sortType in
                            FilterOptionRow(
                                title: sortType.displayName,
                                isSelected: selectedSortType == sortType
                            ) {
                                selectedSortType = sortType
                            }
                        }
                    }
                }
                
                Spacer()

                // 应用按钮
                Button("应用筛选") {
                    dismiss()
                    onApply()
                }
                .buttonStyle(PrimaryButtonStyle(color: AppConstants.Colors.primaryGreen))
            }
            .padding(20)
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FilterOptionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(AppConstants.Colors.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isSelected ? AppConstants.Colors.primaryGreen.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 转换函数

/// 将 CommunityPost 转换为 Post
func convertCommunityPostToPost(_ communityPost: CommunityPost) -> Post {
    return Post(
        id: communityPost.id,
        authorId: communityPost.authorId,
        content: communityPost.content,
        images: communityPost.images,
        video: communityPost.video,
        tags: communityPost.tags,
        category: communityPost.category,
        location: communityPost.location,
        latitude: communityPost.latitude,
        longitude: communityPost.longitude,
        checkinId: communityPost.checkinId,
        workoutId: communityPost.workoutId,
        dataType: communityPost.dataType,
        likesCount: communityPost.likesCount,
        commentsCount: communityPost.commentsCount,
        sharesCount: communityPost.sharesCount,
        bookmarksCount: communityPost.bookmarksCount,
        viewsCount: communityPost.viewsCount,
        isLiked: communityPost.isLiked,
        isBookmarked: communityPost.isBookmarked,
        allowComments: communityPost.allowComments,
        allowShares: communityPost.allowShares,
        visibility: PostVisibility(rawValue: communityPost.visibility) ?? .public,
        status: PostStatus(rawValue: communityPost.status) ?? .active,
        isTop: communityPost.isTop,
        hotScore: communityPost.hotScore,
        lastActiveAt: communityPost.lastActiveAt,
        createdAt: communityPost.createdAt,
        updatedAt: communityPost.updatedAt,
        author: communityPost.author,
        checkin: communityPost.checkin,
        workout: communityPost.workout,
        finalScore: nil,
        explanation: nil,
        strategy: nil
    )
}

/// 将 Post 转换为 CommunityPost
func convertPostToCommunityPost(_ post: Post) -> CommunityPost {
    return CommunityPost(
        id: post.id,
        authorId: post.authorId,
        content: post.content,
        images: post.images,
        video: post.video,
        tags: post.tags,
        category: post.category,
        location: post.location,
        latitude: post.latitude,
        longitude: post.longitude,
        checkinId: post.checkinId,
        workoutId: post.workoutId,
        dataType: post.dataType,
        likesCount: post.likesCount,
        commentsCount: post.commentsCount,
        sharesCount: post.sharesCount,
        bookmarksCount: post.bookmarksCount,
        viewsCount: post.viewsCount,
        isLiked: post.isLiked,
        isBookmarked: post.isBookmarked,
        allowComments: post.allowComments,
        allowShares: post.allowShares,
        visibility: post.visibility.rawValue,
        status: post.status.rawValue,
        isTop: post.isTop,
        hotScore: post.hotScore,
        lastActiveAt: post.lastActiveAt,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
        author: post.author,
        checkin: post.checkin,
        workout: post.workout
    )
}

#Preview {
    CommunitySearchView(viewModel: CommunityViewModel.shared)
}
