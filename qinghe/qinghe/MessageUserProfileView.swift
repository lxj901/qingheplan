import SwiftUI

/// 消息中的用户详情页面 - 基于社区用户详情页面的简化版本
struct MessageUserProfileView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UserProfileViewModel()
    @State private var selectedTab: MessageProfileTab = .posts
    @State private var scrollOffset: CGFloat = 0
    @State private var headerOffset: CGFloat = 0
    @State private var tabBarOffset: CGFloat = 0
    @State private var avatarOffset: CGFloat = 0
    @State private var showNavTitle: Bool = false
    @State private var isAnimationEnabled: Bool = true
    @State private var lastScrollUpdate: Date = Date()
    @State private var scrollTimer: Timer?
    @State private var fallbackScrollOffset: CGFloat = 0

    // 关注列表相关
    @State private var showFollowersList = false
    @State private var showFollowingList = false

    // 更多选项相关
    @State private var showMoreOptions = false
    @State private var showBlockConfirmation = false

    // 编辑资料相关
    @State private var showEditProfile = false

    // 帖子详情导航相关
    @State private var navigationPath = NavigationPath()
    @State private var selectedPostId: String?

    // 防止重复加载
    @State private var isLoadingMore = false
    @State private var showingReportSheet = false
    @State private var reportingPostId: String?
    
    // 聊天相关
    @State private var showingChatDetail = false
    @State private var createdConversation: ChatConversation?

    // 消息版本的标签页
    enum MessageProfileTab: String, CaseIterable {
        case posts = "帖子"
        case bookmarks = "收藏"
        
        var icon: String {
            switch self {
            case .posts: return "doc.text"
            case .bookmarks: return "bookmark"
            }
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // 背景色
                Color(.systemBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.userProfile == nil {
                    loadingView
                } else if let userProfile = viewModel.userProfile {
                    simpleContentView(userProfile)
                } else {
                    errorView
                }

                // 简单的顶部导航栏
                VStack {
                    simpleNavigationBar
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .asSubView()
            .navigationDestination(for: String.self) { postId in
                PostDetailView(postId: postId)
                    .navigationBarHidden(true)
                    .id(postId)
            }
        }
        .sheet(isPresented: $showFollowersList) {
            UserListView(userId: userId, listType: .followers)
        }
        .sheet(isPresented: $showFollowingList) {
            UserListView(userId: userId, listType: .following)
        }
        .navigationDestination(isPresented: $showEditProfile) {
            if let userProfile = viewModel.userProfile {
                EditProfileView(userProfile: Binding(
                    get: { userProfile },
                    set: { newProfile in
                        viewModel.userProfile = newProfile
                    }
                ))
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            if let postId = reportingPostId {
                ReportPostView(postId: postId) { reason, description in
                    Task {
                        // TODO: 实现举报功能
                        print("举报帖子: \(postId), 原因: \(reason), 描述: \(String(describing: description))")
                    }
                }
            }
        }
        .sheet(isPresented: $showingChatDetail) {
            if let userProfile = viewModel.userProfile {
                NavigationView {
                    ChatWithUserView(targetUser: userProfile)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("关闭") {
                                    showingChatDetail = false
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .actionSheet(isPresented: $showMoreOptions) {
            moreOptionsActionSheet
        }
        .actionSheet(isPresented: $showBlockConfirmation) {
            blockConfirmationActionSheet
        }
        .onAppear {
            Task {
                await viewModel.loadUserProfile(userId: userId)
                
                print("🚀 MessageUserProfileView 页面已加载，用户ID: \(userId)")
                print("📊 当前用户资料状态: \(viewModel.userProfile?.nickname ?? "未加载")")
            }
        }
        .onPreferenceChange(AvatarOffsetPreferenceKey.self) { value in
            DispatchQueue.main.async {
                avatarOffset = value
                
                let statusBarHeight: CGFloat = 50
                let distanceToStatusBar = value - statusBarHeight
                
                print("👤 用户头像偏移: \(value)")
                print("📏 距离状态栏距离: \(distanceToStatusBar)")
                print("📱 导航栏背景透明度: \(calculateNavBarBackgroundOpacity())")
                print("✨ 毛玻璃透明度: \(calculateBlurOpacity())")
                print("📝 标题透明度: \(calculateTitleOpacity())")
                print("🔘 按钮透明度: \(calculateButtonOpacity())")
                print("---")
            }
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("加载中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 错误视图
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("加载失败")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("重试") {
                Task {
                    await viewModel.loadUserProfile(userId: userId)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - 简单导航栏
    private var simpleNavigationBar: some View {
        ZStack {
            // 背景
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(calculateNavBarBackgroundOpacity())
                .ignoresSafeArea(edges: .top)

            // 导航栏内容 - 标准44pt高度
            HStack {
                // 返回按钮 - 优化可点击性
                Button(action: {
                    dismiss()
                }) {
                    ZStack {
                        // 透明的可点击区域
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 60, height: 60)

                        // 按钮图标
                        Image(systemName: "arrow.left")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .frame(width: 60, height: 60)
                .contentShape(Rectangle())

                Spacer()

                // 用户名 - 根据滚动位置显示/隐藏
                Text(viewModel.userProfile?.nickname ?? "")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .opacity(calculateTitleOpacity())
                    .scaleEffect(calculateTitleScale())
                    .offset(y: calculateTitleOffset())

                Spacer()

                // 更多按钮
                Button(action: {
                    showMoreOptions = true
                }) {
                    ZStack {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 60, height: 60)

                        Image(systemName: "ellipsis")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.primary)
                            .opacity(calculateButtonOpacity())
                    }
                }
                .frame(width: 60, height: 60)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .padding(.top, 44)
        }
        .frame(height: 88)
    }

    // MARK: - 内容视图
    private func simpleContentView(_ userProfile: UserProfile) -> some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let navBarHeight: CGFloat = 44
            let totalNavHeight = safeAreaTop + navBarHeight

            return ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // 顶部占位空间 - 由于忽略了安全区域，只需要导航栏高度
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: navBarHeight)

                        // 滚动监听器
                        GeometryReader { scrollGeometry in
                            let offset = scrollGeometry.frame(in: .named("scrollView")).minY - totalNavHeight
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: offset)
                        }
                        .frame(height: 0)

                        // 横幅和用户信息区域
                        profileHeaderSection(userProfile)

                        // 标签页导航
                        profileTabsSection
                            .background(
                                GeometryReader { tabGeometry in
                                    Color.clear
                                        .preference(key: TabBarOffsetPreferenceKey.self,
                                                  value: tabGeometry.frame(in: .named("scrollView")).minY - totalNavHeight)
                                }
                            )

                        // 内容区域
                        profileContentSection
                            .frame(minHeight: max(geometry.size.height - totalNavHeight - 400, 300))
                    }
                }
                .ignoresSafeArea(.container, edges: .top) // 让ScrollView忽略顶部安全区域
                .coordinateSpace(name: "scrollView")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    DispatchQueue.main.async {
                        scrollOffset = value
                    }
                }
                .onPreferenceChange(TabBarOffsetPreferenceKey.self) { value in
                    DispatchQueue.main.async {
                        tabBarOffset = value
                    }
                }
            }
        }
    }

    // MARK: - 计算函数
    private func calculateNavBarBackgroundOpacity() -> Double {
        let threshold: CGFloat = -100
        if scrollOffset > threshold {
            return 0
        } else {
            let progress = min(abs(scrollOffset - threshold) / 50, 1.0)
            return Double(progress)
        }
    }

    private func calculateTitleOpacity() -> Double {
        let threshold: CGFloat = -150
        if scrollOffset > threshold {
            return 0
        } else {
            let progress = min(abs(scrollOffset - threshold) / 50, 1.0)
            return Double(progress)
        }
    }

    private func calculateTitleScale() -> Double {
        let threshold: CGFloat = -150
        if scrollOffset > threshold {
            return 0.8
        } else {
            let progress = min(abs(scrollOffset - threshold) / 50, 1.0)
            return 0.8 + (0.2 * progress)
        }
    }

    private func calculateTitleOffset() -> CGFloat {
        let threshold: CGFloat = -150
        if scrollOffset > threshold {
            return 10
        } else {
            let progress = min(abs(scrollOffset - threshold) / 50, 1.0)
            return 10 - (10 * progress)
        }
    }

    private func calculateButtonOpacity() -> Double {
        let threshold: CGFloat = -100
        if scrollOffset > threshold {
            return 0.6
        } else {
            let progress = min(abs(scrollOffset - threshold) / 50, 1.0)
            return 0.6 + (0.4 * progress)
        }
    }

    private func calculateBlurOpacity() -> Double {
        let threshold: CGFloat = -100
        if scrollOffset > threshold {
            return 0
        } else {
            let progress = min(abs(scrollOffset - threshold) / 50, 1.0)
            return Double(progress * 0.8)
        }
    }

    // MARK: - 用户资料头部区域
    private func profileHeaderSection(_ userProfile: UserProfile) -> some View {
        VStack(spacing: 0) {
            // 横幅图片
            bannerImageView

            // 用户信息区域
            userInfoSection(userProfile)
        }
    }

    // MARK: - 横幅图片
    private var bannerImageView: some View {
        GeometryReader { geometry in
            let parallaxOffset = max(scrollOffset * 0.3, 0)
            let scaleEffect = max(1 + (scrollOffset * 0.0008), 1)

            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.7),
                            Color.purple.opacity(0.5),
                            Color.pink.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    AsyncImage(url: URL(string: "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .scaleEffect(scaleEffect)
                    } placeholder: {
                        EmptyView()
                    }
                )
                .scaleEffect(scaleEffect)
                .frame(width: geometry.size.width, height: 200 + parallaxOffset + geometry.safeAreaInsets.top) // 添加顶部安全区域高度
                .offset(y: -parallaxOffset - geometry.safeAreaInsets.top) // 调整偏移以覆盖状态栏
                .clipped()
        }
        .frame(height: 200)
        .ignoresSafeArea(.all, edges: .top) // 确保背景图片忽略顶部安全区域
    }

    // MARK: - 用户信息区域
    private func userInfoSection(_ userProfile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 头像行
            HStack {
                // 头像
                profileAvatarView(userProfile)

                Spacer()
            }
            .padding(.top, -40) // 让头像部分覆盖横幅

            // 用户名和操作按钮行
            HStack(alignment: .center) {
                // 用户名和认证信息
                userNameSection(userProfile)

                Spacer()

                // 操作按钮 - 消息版本的操作按钮
                messageActionButtonsView(userProfile)
            }

            // 个人简介
            if let bio = userProfile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
            }

            // 位置信息
            if let location = userProfile.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text(location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // 统计数据
            userStatsSection(userProfile)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .background(Color(.systemBackground))
    }

    // MARK: - 头像视图
    private func profileAvatarView(_ userProfile: UserProfile) -> some View {
        AsyncImage(url: URL(string: userProfile.avatar ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(Color.gray)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                )
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color(.systemBackground), lineWidth: 4)
        )
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: AvatarOffsetPreferenceKey.self,
                              value: geometry.frame(in: .named("scrollView")).minY)
            }
        )
    }

    // MARK: - 用户名区域
    private func userNameSection(_ userProfile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(userProfile.nickname)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if userProfile.isVerified == true {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
            }

            Text("@\(userProfile.displayUsername)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 消息版本的操作按钮
    private func messageActionButtonsView(_ userProfile: UserProfile) -> some View {
        HStack(spacing: 12) {
            // 发送消息按钮
            Button(action: {
                // 直接打开聊天窗口
                showingChatDetail = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "message")
                        .font(.system(size: 14, weight: .medium))
                    Text("发消息")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(18)
            }

            // 关注/取消关注按钮
            if userProfile.isMe != true {
                Button(action: {
                    Task {
                        await toggleFollow(userProfile)
                    }
                }) {
                    Text(userProfile.isFollowing == true ? "已关注" : "关注")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(userProfile.isFollowing == true ? .primary : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(userProfile.isFollowing == true ? Color(.systemGray5) : Color.black)
                        .cornerRadius(18)
                }
                .disabled(viewModel.isFollowActionLoading)
            }
        }
    }

    // MARK: - 用户统计数据
    private func userStatsSection(_ userProfile: UserProfile) -> some View {
        HStack(spacing: 20) {
            // 帖子数
            HStack(spacing: 4) {
                Text("\(userProfile.postsCount ?? 0)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("帖子")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // 关注数
            Button(action: {
                showFollowingList = true
            }) {
                HStack(spacing: 4) {
                    Text("\(userProfile.safeFollowingCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("正在关注")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // 粉丝数
            Button(action: {
                showFollowersList = true
            }) {
                HStack(spacing: 4) {
                    Text("\(userProfile.safeFollowersCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("关注者")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
    }

    // MARK: - 标签页导航
    private var profileTabsSection: some View {
        HStack(spacing: 0) {
            ForEach(MessageProfileTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }

                    // 当切换到收藏标签时，加载收藏数据
                    if tab == .bookmarks && viewModel.userProfile?.isMe == true && viewModel.bookmarkedPosts.isEmpty {
                        Task {
                            await viewModel.loadUserBookmarks(refresh: true)
                        }
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)

                        Rectangle()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                    .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - 内容区域
    private var profileContentSection: some View {
        VStack(spacing: 0) {
            switch selectedTab {
            case .posts:
                postsContentView
            case .bookmarks:
                bookmarksContentView
            }
        }
    }

    // MARK: - 帖子内容视图
    private var postsContentView: some View {
        Group {
            if viewModel.isLoadingPosts && viewModel.userPosts.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("加载帖子中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else if viewModel.userPosts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)

                    Text("还没有发布任何帖子")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("当用户发布帖子时，它们会显示在这里")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else {
                // 帖子列表
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.userPosts, id: \.id) { post in
                        PostCardView(
                            post: post,
                            showHotBadge: false,
                            showEditButton: false,
                            onLike: {
                                Task {
                                    await toggleLikePost(post.id)
                                }
                            },
                            onBookmark: {
                                Task {
                                    await toggleBookmarkPost(post.id)
                                }
                            },
                            onShare: {
                                Task {
                                    await sharePost(post.id)
                                }
                            },
                            onReport: {
                                reportingPostId = post.id
                                showingReportSheet = true
                            },
                            onNavigateToDetail: { postId in
                                print("🔍 MessageUserProfileView: 导航到帖子详情，帖子ID: \(postId)")
                                Task { @MainActor in
                                    selectedPostId = postId
                                    navigationPath.append(postId)
                                }
                            },
                            onNavigateToUserProfile: { author in
                                // 在用户详情页面，不需要跳转到自己
                            }
                        )
                        .padding(.vertical, 8)

                        Divider()
                            .padding(.leading, 16)
                    }

                    // 加载更多指示器
                    if viewModel.hasMorePosts && !viewModel.isLoadingPosts {
                        Button("加载更多") {
                            Task {
                                await loadMorePosts()
                            }
                        }
                        .padding()
                    } else if viewModel.isLoadingPosts && !viewModel.userPosts.isEmpty {
                        ProgressView()
                            .padding()
                    }
                }
            }
        }
    }

    // MARK: - 收藏内容视图
    private var bookmarksContentView: some View {
        Group {
            if viewModel.userProfile?.isMe != true {
                VStack(spacing: 16) {
                    Image(systemName: "lock")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)

                    Text("收藏内容不公开")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("只有用户自己可以查看收藏的内容")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else if viewModel.isLoadingBookmarks && viewModel.bookmarkedPosts.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("加载收藏中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else if viewModel.bookmarkedPosts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)

                    Text("还没有收藏任何内容")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("收藏的帖子会显示在这里")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else {
                // 收藏列表
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.bookmarkedPosts) { post in
                        PostCardView(
                            post: post,
                            showHotBadge: false,
                            showEditButton: false,
                            onLike: {
                                Task {
                                    await toggleLikeBookmarkedPost(post.id)
                                }
                            },
                            onBookmark: {
                                Task {
                                    await toggleBookmarkBookmarkedPost(post.id)
                                }
                            },
                            onShare: {
                                Task {
                                    await shareBookmarkedPost(post.id)
                                }
                            },
                            onReport: {
                                reportingPostId = post.id
                                showingReportSheet = true
                            },
                            onNavigateToDetail: { postId in
                                print("🔍 MessageUserProfileView: 导航到帖子详情，帖子ID: \(postId)")
                                Task { @MainActor in
                                    selectedPostId = postId
                                    navigationPath.append(postId)
                                }
                            },
                            onNavigateToUserProfile: { author in
                                // 可以跳转到作者的用户详情页面
                            }
                        )
                        .padding(.vertical, 8)

                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }

    // MARK: - 操作菜单
    private var moreOptionsActionSheet: ActionSheet {
        var buttons: [ActionSheet.Button] = []

        if let userProfile = viewModel.userProfile {
            if userProfile.isMe == true {
                // 自己的资料
                buttons.append(.default(Text("编辑资料")) {
                    showEditProfile = true
                })
            } else {
                // 其他用户的资料
                buttons.append(.default(Text("发送消息")) {
                    Task {
                        await createPrivateChat(with: userProfile)
                    }
                })

                buttons.append(.destructive(Text("屏蔽用户")) {
                    showBlockConfirmation = true
                })
            }
        }

        buttons.append(.cancel())

        return ActionSheet(
            title: Text("更多选项"),
            buttons: buttons
        )
    }

    private var blockConfirmationActionSheet: ActionSheet {
        var buttons: [ActionSheet.Button] = []

        buttons.append(.destructive(Text("屏蔽")) {
            Task {
                await blockUser()
            }
        })

        buttons.append(.cancel())

        return ActionSheet(
            title: Text("屏蔽用户"),
            message: Text("屏蔽后将不会看到该用户的内容"),
            buttons: buttons
        )
    }

    // MARK: - 功能函数
    private func createPrivateChat(with userProfile: UserProfile) async {
        print("🔍 MessageUserProfileView: 创建私聊，用户ID: \(userProfile.id)")

        do {
            let conversation = try await ChatAPIService.shared.createPrivateChat(recipientId: userProfile.id)

            await MainActor.run {
                createdConversation = conversation
                showingChatDetail = true
                print("🔍 MessageUserProfileView: 私聊创建成功，会话ID: \(conversation.id)")
            }
        } catch {
            print("❌ MessageUserProfileView: 创建私聊失败: \(error)")
        }
    }

    private func toggleFollow(_ userProfile: UserProfile) async {
        await viewModel.toggleFollowUser()
    }

    private func blockUser() async {
        // TODO: 实现屏蔽用户功能
        print("屏蔽用户功能待实现")
    }

    private func loadMorePosts() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true

        await viewModel.loadUserPosts(
            userId: userId,
            page: viewModel.postsCurrentPage + 1
        )

        isLoadingMore = false
    }

    // MARK: - 帖子操作函数
    private func toggleLikePost(_ postId: String) async {
        // TODO: 实现点赞功能
        print("点赞帖子: \(postId)")
    }

    private func toggleBookmarkPost(_ postId: String) async {
        // TODO: 实现收藏功能
        print("收藏帖子: \(postId)")
    }

    private func sharePost(_ postId: String) async {
        // TODO: 实现分享功能
        print("分享帖子: \(postId)")
    }

    private func toggleLikeBookmarkedPost(_ postId: String) async {
        // TODO: 实现收藏帖子的点赞功能
        print("点赞收藏的帖子: \(postId)")
    }

    private func toggleBookmarkBookmarkedPost(_ postId: String) async {
        // TODO: 实现取消收藏功能
        print("取消收藏帖子: \(postId)")
    }

    private func shareBookmarkedPost(_ postId: String) async {
        // TODO: 实现分享收藏帖子功能
        print("分享收藏的帖子: \(postId)")
    }
}
