import SwiftUI

// MARK: - 用户资料头部视图
struct ProfileHeaderView: View {
    let userProfile: UserProfile
    
    var body: some View {
        VStack(spacing: 0) {
            // 封面图片区域
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppConstants.Colors.primaryGreen.opacity(0.3), AppConstants.Colors.primaryGreen.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay(
                    // 用户头像
                    VStack {
                        Spacer()
                        HStack {
                            AsyncImage(url: URL(string: userProfile.avatar ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color(.systemGray4))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                    )
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 4)
                            )
                            .shadow(color: Color(.systemGray4).opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .offset(y: 40) // 让头像悬浮在封面图片上
                    }
                )
        }
    }
}

// MARK: - 用户信息视图
struct ProfileInfoView: View {
    let userProfile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部间距（为悬浮头像留空间）
            Spacer()
                .frame(height: 50)
            
            VStack(alignment: .leading, spacing: 8) {
                // 用户昵称和认证标识
                HStack(spacing: 6) {
                    Text(userProfile.nickname)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if userProfile.safeIsVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                
                // 用户名
                Text("@\(userProfile.displayUsername)")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                
                // 个人简介
                if let bio = userProfile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .padding(.top, 4)
                }
                
                // 元信息（位置、网站、加入时间等）
                VStack(alignment: .leading, spacing: 4) {
                    if let location = userProfile.location, !location.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "location")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            Text(location)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    

                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Text(userProfile.joinDateFormatted)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
                
                // 关注和粉丝数量
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Text("\(userProfile.safeFollowingCount)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)

                        Text("正在关注")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 4) {
                        Text("\(userProfile.safeFollowersCount)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)

                        Text("关注者")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - 操作按钮视图
struct ProfileActionButtonsView: View {
    let userProfile: UserProfile
    @ObservedObject var viewModel: UserProfileViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
            
            if !userProfile.safeIsMe {
                // 关注/取消关注按钮
                Button(action: {
                    Task {
                        await viewModel.toggleFollowUser()
                    }
                }) {
                    HStack(spacing: 6) {
                        if viewModel.isFollowActionLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(userProfile.safeIsFollowing ? .primary : .white)
                        }

                        // 判断是否互相关注
                        let isMutualFollow = userProfile.safeIsFollowing && userProfile.safeIsFollowedBy

                        // 根据关注状态显示不同文本和图标
                        if isMutualFollow {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("互相关注")
                                .font(.system(size: 15, weight: .semibold))
                        } else {
                            Text(userProfile.safeIsFollowing ? "已关注" : "关注")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .frame(width: 100, height: 36)
                    .background(
                        userProfile.safeIsFollowing ?
                        Color.clear :
                        AppConstants.Colors.primaryGreen
                    )
                    .foregroundColor(
                        userProfile.safeIsFollowing ?
                        .primary :
                        .white
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                userProfile.safeIsFollowing ?
                                (userProfile.safeIsFollowedBy ?
                                    Color.orange : // 互相关注用橙色边框
                                    Color(.separator)) :
                                Color.clear,
                                lineWidth: userProfile.safeIsFollowing && userProfile.safeIsFollowedBy ? 1.5 : 1
                            )
                    )
                    .cornerRadius(18)
                }
                .disabled(viewModel.isFollowActionLoading)
                
                // 消息按钮
                Button(action: {
                    // TODO: 实现发送消息功能
                }) {
                    Image(systemName: "message")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .cornerRadius(18)
                }
            } else {
                // 编辑资料按钮（如果是自己）
                Button(action: {
                    // TODO: 实现编辑资料功能
                }) {
                    Text("编辑资料")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 100, height: 36)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .cornerRadius(18)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

// MARK: - Tab切换视图
struct ProfileTabView: View {
    @Binding var selectedTab: ProfileTab
    let userProfile: UserProfile
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                                .foregroundColor(selectedTab == tab ? .primary : .secondary)
                            
                            // 显示数量
                            if tab == .posts {
                                Text("(\(userProfile.safePostsCount))")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // 底部指示器
                        Rectangle()
                            .fill(selectedTab == tab ? AppConstants.Colors.primaryGreen : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
        .padding(.top, 16)
    }
}

// MARK: - 内容展示视图
struct ProfileContentView: View {
    let selectedTab: ProfileTab
    let userProfile: UserProfile
    @ObservedObject var viewModel: UserProfileViewModel

    var body: some View {
        Group {
            switch selectedTab {
            case .posts:
                PostsListView(viewModel: viewModel)
            case .bookmarks:
                BookmarksListView(viewModel: viewModel, userProfile: userProfile)
            }
        }
        .padding(.top, 1)
    }
}

// MARK: - 收藏列表视图
struct BookmarksListView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    let userProfile: UserProfile
    @State private var showingPostDetail = false
    @State private var selectedPostId: String?
    @State private var showingReportSheet = false
    @State private var reportingPostId: String?

    var body: some View {
        VStack(spacing: 0) {
            // 检查是否为当前用户本人
            if userProfile.isMe != true {
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "lock")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("私密内容")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("只有本人才能查看收藏内容")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else if viewModel.isLoadingBookmarks && viewModel.bookmarkedPosts.isEmpty {
                // 首次加载状态
                VStack(spacing: 16) {
                    Spacer()

                    ProgressView()
                        .scaleEffect(1.2)
                    Text("加载收藏中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else if viewModel.bookmarkedPosts.isEmpty {
                // 空状态
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "bookmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("暂无收藏")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("收藏的帖子会显示在这里")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Spacer()
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
                                selectedPostId = postId
                                showingPostDetail = true
                            },
                            onNavigateToUserProfile: { author in
                                // 可以跳转到作者的用户详情页面
                            }
                        )
                        .onAppear {
                            // 当滚动到倒数第3个收藏帖子时，加载更多
                            if post.id == viewModel.bookmarkedPosts.suffix(3).first?.id &&
                               viewModel.hasMoreBookmarks &&
                               !viewModel.isLoadingBookmarks {
                                Task {
                                    print("🔄 触发收藏分页加载，当前页: \(viewModel.bookmarksCurrentPage)")
                                    await viewModel.loadMoreBookmarks()
                                }
                            }
                        }
                    }

                    // 加载更多指示器
                    if viewModel.isLoadingBookmarks && !viewModel.bookmarkedPosts.isEmpty {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("加载更多...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 50)
                        .padding(.vertical, 10)
                    } else if !viewModel.hasMoreBookmarks && !viewModel.bookmarkedPosts.isEmpty {
                        Text("没有更多收藏了")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(height: 50)
                            .padding(.vertical, 10)
                    }

                    // 添加底部填充空间
                    Spacer()
                        .frame(minHeight: 100)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            // 首次加载收藏（仅当为本人时）
            if userProfile.isMe == true && viewModel.bookmarkedPosts.isEmpty {
                Task {
                    await viewModel.loadUserBookmarks(refresh: true)
                }
            }
        }
        .navigationDestination(isPresented: $showingPostDetail) {
            if let postId = selectedPostId {
                PostDetailView(postId: postId)
                    .navigationBarHidden(true)
                    .asSubView() // 标记为子页面，隐藏Tab栏
                    .onAppear {
                        print("🔍 用户详情页面：导航到帖子详情页面，帖子ID: \(postId)")
                    }
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            if let postId = reportingPostId {
                ReportPostView(postId: postId) { reason, description in
                    // TODO: 实现举报功能
                }
            }
        }
    }

    // MARK: - 收藏帖子交互功能
    private func toggleLikeBookmarkedPost(_ postId: String) async {
        guard let index = viewModel.bookmarkedPosts.firstIndex(where: { $0.id == postId }) else { return }

        do {
            let result = try await CommunityAPIService.shared.toggleLike(postId: postId)
            await MainActor.run {
                viewModel.bookmarkedPosts[index].isLiked = result.isLiked

                if result.isLiked {
                    viewModel.bookmarkedPosts[index].likesCount += 1
                } else {
                    viewModel.bookmarkedPosts[index].likesCount = max(0, viewModel.bookmarkedPosts[index].likesCount - 1)
                }
            }
        } catch {
            print("点赞失败：\(error)")
        }
    }

    private func toggleBookmarkBookmarkedPost(_ postId: String) async {
        guard let index = viewModel.bookmarkedPosts.firstIndex(where: { $0.id == postId }) else { return }

        do {
            let result = try await CommunityAPIService.shared.toggleBookmark(postId: postId)
            await MainActor.run {
                viewModel.bookmarkedPosts[index].isBookmarked = result.isBookmarked

                if result.isBookmarked {
                    viewModel.bookmarkedPosts[index].bookmarksCount += 1
                } else {
                    viewModel.bookmarkedPosts[index].bookmarksCount = max(0, viewModel.bookmarkedPosts[index].bookmarksCount - 1)
                    // 如果取消收藏，从收藏列表中移除
                    viewModel.bookmarkedPosts.remove(at: index)
                }
            }
        } catch {
            print("收藏失败：\(error)")
        }
    }

    private func shareBookmarkedPost(_ postId: String) async {
        do {
            let _ = try await CommunityAPIService.shared.sharePost(postId: postId)
            print("分享成功")
        } catch {
            print("分享失败：\(error)")
        }
    }
}

// MARK: - 帖子列表视图
struct PostsListView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    @State private var showingPostDetail = false
    @State private var selectedPostId: String?
    @State private var showingReportSheet = false
    @State private var reportingPostId: String?

    var body: some View {
        LazyVStack(spacing: 0) {
            if viewModel.userPosts.isEmpty && !viewModel.isLoadingPosts {
                EmptyStateView(
                    icon: "doc.text",
                    title: "还没有帖子",
                    message: "该用户还没有发布任何帖子"
                )
                .padding(.top, 60)
            } else {
                ForEach(viewModel.userPosts) { post in
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
                            // 使用父视图的导航状态管理
                            selectedPostId = postId
                            showingPostDetail = true
                        },
                        onNavigateToUserProfile: { author in
                            // 在用户详情页面，不需要跳转到自己
                        }
                    )
                    .buttonStyle(PlainButtonStyle()) // 确保NavigationLink不影响内部按钮的样式
                    .onAppear {
                        // 当滚动到倒数第3个帖子时，加载更多
                        if post.id == viewModel.userPosts.suffix(3).first?.id {
                            Task {
                                await viewModel.loadMorePosts()
                            }
                        }
                    }
                }
            }

            if viewModel.isLoadingPosts && !viewModel.userPosts.isEmpty {
                LoadingMoreView()
                    .padding(.vertical, 20)
            }
        }
        .navigationDestination(isPresented: $showingPostDetail) {
            if let postId = selectedPostId {
                PostDetailView(postId: postId)
                    .navigationBarHidden(true)
                    .asSubView() // 标记为子页面，隐藏Tab栏
                    .onAppear {
                        print("🔍 用户详情页面：导航到帖子详情页面，帖子ID: \(postId)")
                    }
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            if let postId = reportingPostId {
                ReportPostView(postId: postId) { reason, description in
                    Task {
                        // TODO: 实现举报功能
                        print("举报帖子: \(postId), 原因: \(reason), 描述: \(description ?? "无")")
                    }
                }
            }
        }
    }

    // MARK: - 帖子交互功能
    private func toggleLikePost(_ postId: String) async {
        guard let index = viewModel.userPosts.firstIndex(where: { $0.id == postId }) else { return }

        do {
            let result = try await CommunityAPIService.shared.toggleLike(postId: postId)
            await MainActor.run {
                viewModel.userPosts[index].isLiked = result.isLiked

                if result.isLiked {
                    viewModel.userPosts[index].likesCount += 1
                } else {
                    viewModel.userPosts[index].likesCount = max(0, viewModel.userPosts[index].likesCount - 1)
                }
            }
        } catch {
            print("点赞失败：\(error)")
        }
    }

    private func toggleBookmarkPost(_ postId: String) async {
        guard let index = viewModel.userPosts.firstIndex(where: { $0.id == postId }) else { return }

        do {
            let result = try await CommunityAPIService.shared.toggleBookmark(postId: postId)
            await MainActor.run {
                viewModel.userPosts[index].isBookmarked = result.isBookmarked

                if result.isBookmarked {
                    viewModel.userPosts[index].bookmarksCount += 1
                } else {
                    viewModel.userPosts[index].bookmarksCount = max(0, viewModel.userPosts[index].bookmarksCount - 1)
                }
            }
        } catch {
            print("收藏失败：\(error)")
        }
    }

    private func sharePost(_ postId: String) async {
        do {
            let _ = try await CommunityAPIService.shared.sharePost(postId: postId)
            print("分享成功")
        } catch {
            print("分享失败：\(error)")
        }
    }
}

// MARK: - 关注列表视图
struct FollowingListView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    let userProfile: UserProfile

    var body: some View {
        LazyVStack(spacing: 0) {
            if viewModel.followingUsers.isEmpty && !viewModel.isLoadingFollowing {
                EmptyStateView(
                    icon: "person.2",
                    title: "还没有关注任何人",
                    message: "该用户还没有关注任何人"
                )
                .padding(.top, 60)
            } else {
                ForEach(viewModel.followingUsers) { user in
                    UserRowView(user: user)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    if user.id == viewModel.followingUsers.last?.id && viewModel.hasMoreFollowing {
                        LoadingMoreView()
                            .onAppear {
                                Task {
                                    await viewModel.loadMoreFollowing()
                                }
                            }
                    }
                }
            }

            if viewModel.isLoadingFollowing && !viewModel.followingUsers.isEmpty {
                LoadingMoreView()
                    .padding(.vertical, 20)
            }
        }
        .onAppear {
            if viewModel.followingUsers.isEmpty {
                Task {
                    await viewModel.loadFollowingUsers(userId: String(userProfile.id))
                }
            }
        }
    }
}

// MARK: - 粉丝列表视图
struct FollowersListView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    let userProfile: UserProfile

    var body: some View {
        LazyVStack(spacing: 0) {
            if viewModel.followerUsers.isEmpty && !viewModel.isLoadingFollowers {
                EmptyStateView(
                    icon: "heart",
                    title: "还没有粉丝",
                    message: "该用户还没有任何粉丝"
                )
                .padding(.top, 60)
            } else {
                ForEach(viewModel.followerUsers) { user in
                    UserRowView(user: user)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    if user.id == viewModel.followerUsers.last?.id && viewModel.hasMoreFollowers {
                        LoadingMoreView()
                            .onAppear {
                                Task {
                                    await viewModel.loadMoreFollowers()
                                }
                            }
                    }
                }
            }

            if viewModel.isLoadingFollowers && !viewModel.followerUsers.isEmpty {
                LoadingMoreView()
                    .padding(.vertical, 20)
            }
        }
        .onAppear {
            if viewModel.followerUsers.isEmpty {
                Task {
                    await viewModel.loadFollowerUsers(userId: String(userProfile.id))
                }
            }
        }
    }
}

// MARK: - 用户行视图
struct UserRowView: View {
    let user: UserProfile
    let onUserTap: ((String) -> Void)?
    @State private var isFollowActionLoading = false
    @State private var localIsFollowing: Bool
    @State private var localIsFollowedBy: Bool
    @State private var hasInitialized = false

    init(user: UserProfile, onUserTap: ((String) -> Void)? = nil) {
        self.user = user
        self.onUserTap = onUserTap
        self._localIsFollowing = State(initialValue: user.safeIsFollowing)
        self._localIsFollowedBy = State(initialValue: user.safeIsFollowedBy)
        print("🔍 UserRowView init - 用户ID: \(user.id), 昵称: \(user.nickname), isMe: \(user.isMe ?? false), safeIsMe: \(user.safeIsMe)")
    }

    var body: some View {
        HStack(spacing: 12) {
            // 可点击的用户信息区域
            Button(action: {
                if !user.safeIsMe {
                    onUserTap?(String(user.id))
                }
            }) {
                HStack(spacing: 12) {
                    // 用户头像
                    AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color(.systemGray4))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(user.nickname)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)

                            if user.safeIsVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            }
                        }

                        Text("@\(user.displayUsername)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        if let bio = user.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .padding(.top, 2)
                        }
                    }

                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(user.safeIsMe) // 如果是自己，禁用点击

            // 关注按钮或自己标识
            if user.safeIsMe {
                // 如果是自己，显示"自己"标识
                Text("自己")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
            } else {
                // 如果不是自己，显示关注按钮
                Button(action: {
                    Task {
                        await toggleFollow()
                    }
                }) {
                    HStack(spacing: 4) {
                        if isFollowActionLoading {
                            ProgressView()
                                .scaleEffect(0.6)
                                .tint(localIsFollowing ? .primary : .white)
                        } else {
                            // 判断是否互相关注
                            let isMutualFollow = localIsFollowing && localIsFollowedBy

                            if isMutualFollow {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("互相关注")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                            } else {
                                Text(localIsFollowing ? "已关注" : "关注")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(localIsFollowing ? .primary : .white)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        localIsFollowing ?
                        Color.clear :
                        AppConstants.Colors.primaryGreen
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                localIsFollowing ?
                                (localIsFollowedBy ?
                                    Color.orange : // 互相关注用橙色边框
                                    Color(.separator)) :
                                Color.clear,
                                lineWidth: localIsFollowing && localIsFollowedBy ? 1.5 : 1
                            )
                    )
                    .cornerRadius(15)
                }
                .disabled(isFollowActionLoading)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            // 调试信息
            if user.safeIsMe {
                print("🔍 UserRowView onAppear - 显示'自己'标识，用户ID: \(user.id), isMe: \(user.isMe ?? false)")
            } else {
                print("🔍 UserRowView onAppear - 显示关注按钮，用户ID: \(user.id), isMe: \(user.isMe ?? false), safeIsMe: \(user.safeIsMe)")
            }

            // 初始化时刷新关注状态，确保显示最新状态
            if !hasInitialized && !user.safeIsMe {
                hasInitialized = true
                Task {
                    await refreshFollowStatus()
                }
            }
        }
    }

    // MARK: - 关注操作
    private func toggleFollow() async {
        // 防止重复操作
        guard !isFollowActionLoading else { return }

        isFollowActionLoading = true

        do {
            let response: CommunityAPIResponse<FollowResponse>

            if localIsFollowing {
                response = try await CommunityAPIService.shared.unfollowUser(userId: user.id)
            } else {
                response = try await CommunityAPIService.shared.followUser(userId: user.id)
            }

            // 检查响应状态
            if response.success {
                // 更新本地状态
                if let data = response.data {
                    localIsFollowing = data.isFollowing
                } else {
                    // 如果服务器没有返回data字段，根据消息内容判断最终状态
                    if let message = response.message {
                        if message.contains("已经关注了该用户") || message.contains("关注成功") {
                            localIsFollowing = true
                        } else if message.contains("未关注该用户") || message.contains("没有关注该用户") || message.contains("取消关注成功") {
                            localIsFollowing = false
                        } else {
                            // 如果消息不明确，根据操作类型推断
                            localIsFollowing = !localIsFollowing
                        }
                    } else {
                        // 如果没有消息，根据操作类型推断
                        localIsFollowing = !localIsFollowing
                    }
                }

                // 操作成功后，重新获取最新的关注状态以确保准确性
                await refreshFollowStatus()

                // 根据最终状态显示消息
                if let message = response.message {
                    print("✅ 关注操作成功: \(message)")
                }
            } else {
                // 处理失败情况
                print("❌ 关注操作失败: \(response.message ?? "未知错误")")
            }
        } catch {
            // 处理网络错误
            print("❌ 关注操作失败: \(error)")
        }

        isFollowActionLoading = false
    }

    // MARK: - 刷新关注状态
    private func refreshFollowStatus() async {
        do {
            let response = try await CommunityAPIService.shared.getUserProfile(userId: user.id)
            if response.success, let data = response.data {
                await MainActor.run {
                    localIsFollowing = data.isFollowing ?? false
                    print("🔄 UserRowView 关注状态已刷新: \(data.isFollowing ?? false)")
                }
            }
        } catch {
            print("❌ UserRowView 刷新关注状态失败: \(error)")
        }
    }
}
