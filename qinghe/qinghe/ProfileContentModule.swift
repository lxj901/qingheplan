import SwiftUI

// MARK: - 用户资料内容模块
struct ProfileContentModule: View {
    let selectedTab: ProfileTab
    let userProfile: UserProfile
    @ObservedObject var viewModel: UserProfileViewModel
    let minHeight: CGFloat
    
    var body: some View {
        Group {
            switch selectedTab {
            case .posts:
                PostsContentView(
                    viewModel: viewModel,
                    minHeight: minHeight
                )
            case .bookmarks:
                BookmarksContentView(
                    viewModel: viewModel,
                    userProfile: userProfile,
                    minHeight: minHeight
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }
}

// MARK: - 帖子内容视图
struct PostsContentView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    let minHeight: CGFloat
    
    @State private var showingReportSheet = false
    @State private var reportingPostId: String?
    
    var body: some View {
        LazyVStack(spacing: 12) {
            if viewModel.isLoadingPosts && viewModel.userPosts.isEmpty {
                // 加载状态
                loadingView
            } else if viewModel.userPosts.isEmpty {
                // 空状态
                emptyPostsView
            } else {
                // 帖子列表
                postsListView
            }
        }
        .frame(minHeight: minHeight)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .sheet(isPresented: $showingReportSheet) {
            if reportingPostId != nil {
                // TODO: 实现举报视图
                Text("举报功能待实现")
                    .padding()
            }
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppConstants.Colors.primaryGreen)
            
            Text("加载帖子中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    // MARK: - 空状态视图
    private var emptyPostsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("还没有发布任何帖子")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("当用户发布帖子时，它们会显示在这里")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    // MARK: - 帖子列表视图
    private var postsListView: some View {
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
                    // 使用通知系统导航
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToPost"),
                        object: nil,
                        userInfo: ["postId": Int(postId) ?? 0]
                    )
                },
                onNavigateToUserProfile: { author in
                    // 在用户详情页面，不需要跳转到自己
                }
            )
            .buttonStyle(PlainButtonStyle())
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
    
    // MARK: - 帖子操作方法
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

// MARK: - 收藏内容视图
struct BookmarksContentView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    let userProfile: UserProfile
    let minHeight: CGFloat
    
    @State private var showingReportSheet = false
    @State private var reportingPostId: String?
    
    var body: some View {
        LazyVStack(spacing: 12) {
            if !userProfile.safeIsMe {
                // 非本人查看收藏的提示
                privateBookmarksView
            } else if viewModel.isLoadingBookmarks && viewModel.bookmarkedPosts.isEmpty {
                // 加载状态
                loadingView
            } else if viewModel.bookmarkedPosts.isEmpty {
                // 空状态
                emptyBookmarksView
            } else {
                // 收藏列表
                bookmarksListView
            }
        }
        .frame(minHeight: minHeight)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .onAppear {
            if userProfile.safeIsMe && viewModel.bookmarkedPosts.isEmpty {
                Task {
                    await viewModel.loadUserBookmarks(refresh: true)
                }
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            if reportingPostId != nil {
                // TODO: 实现举报视图
                Text("举报功能待实现")
                    .padding()
            }
        }
    }
    
    // MARK: - 私有收藏提示视图
    private var privateBookmarksView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("收藏是私人的")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("只有用户本人可以查看自己的收藏")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppConstants.Colors.primaryGreen)
            
            Text("加载收藏中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    // MARK: - 空收藏视图
    private var emptyBookmarksView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("还没有收藏任何帖子")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("收藏的帖子会显示在这里")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    // MARK: - 收藏列表视图
    private var bookmarksListView: some View {
        ForEach(viewModel.bookmarkedPosts) { post in
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
                    // 使用通知系统导航
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToPost"),
                        object: nil,
                        userInfo: ["postId": Int(postId) ?? 0]
                    )
                },
                onNavigateToUserProfile: { author in
                    // TODO: 导航到其他用户资料页面
                }
            )
            .buttonStyle(PlainButtonStyle())
            .onAppear {
                // 当滚动到倒数第3个帖子时，加载更多
                if post.id == viewModel.bookmarkedPosts.suffix(3).first?.id {
                    Task {
                        await viewModel.loadUserBookmarks(page: viewModel.bookmarksCurrentPage + 1)
                    }
                }
            }
        }
    }
    
    // MARK: - 收藏帖子操作方法
    private func toggleLikePost(_ postId: String) async {
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

    private func toggleBookmarkPost(_ postId: String) async {
        guard let index = viewModel.bookmarkedPosts.firstIndex(where: { $0.id == postId }) else { return }

        do {
            let result = try await CommunityAPIService.shared.toggleBookmark(postId: postId)
            await MainActor.run {
                viewModel.bookmarkedPosts[index].isBookmarked = result.isBookmarked

                if result.isBookmarked {
                    viewModel.bookmarkedPosts[index].bookmarksCount += 1
                } else {
                    viewModel.bookmarkedPosts[index].bookmarksCount = max(0, viewModel.bookmarkedPosts[index].bookmarksCount - 1)
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

// MARK: - 预览
struct ProfileContentModule_Previews: PreviewProvider {
    static var previews: some View {
        ProfileContentModule(
            selectedTab: .posts,
            userProfile: UserProfile(
                id: 1,
                nickname: "测试用户",
                avatar: nil,
                backgroundImage: nil,
                bio: "这是一个测试用户",
                location: "北京",
                gender: "男",
                birthday: "1990-01-01",
                constellation: "摩羯座",
                hometown: "北京",
                school: "某某大学",
                ipLocation: "北京市朝阳区",
                qingheId: "qinghe123456",
                level: 1,
                isVerified: true,
                followersCount: 100,
                followingCount: 50,
                postsCount: 25,
                createdAt: "2024-01-01T00:00:00.000Z",
                lastActiveAt: "2024-01-01T00:00:00.000Z",
                isFollowing: false,
                isFollowedBy: false,
                isBlocked: false,
                isMe: true
            ),
            viewModel: UserProfileViewModel(),
            minHeight: 300
        )
        .previewLayout(.sizeThatFits)
    }
}
