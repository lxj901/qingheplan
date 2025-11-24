import SwiftUI

/// 我的收藏页面
struct MyBookmarksView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // 举报相关
    @State private var showingReportSheet = false
    @State private var reportingPostId: String?
    
    // 帖子详情相关
    @State private var showingPostDetail = false
    @State private var selectedPostId: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            // 收藏列表 - 瀑布流布局
            if viewModel.isLoadingBookmarks && viewModel.bookmarkedPosts.isEmpty {
                // 加载状态
                loadingView
            } else if viewModel.bookmarkedPosts.isEmpty {
                // 空状态
                emptyView
            } else {
                // 瀑布流布局
                WaterfallLayout(
                    items: viewModel.bookmarkedPosts,
                    columns: 2,
                    spacing: 4,
                    horizontalPadding: 4,
                    onLoadMore: {
                        if viewModel.hasMoreBookmarks {
                            Task {
                                await viewModel.loadMoreBookmarks()
                            }
                        }
                    }
                ) { post in
                    WaterfallPostCard(
                        post: post,
                        onTap: {
                            selectedPostId = post.id
                            showingPostDetail = true
                        },
                        onLike: {
                            Task {
                                await toggleLikePost(post.id)
                            }
                        },
                        onUserTap: {
                            // 可以跳转到作者的用户详情页面
                        }
                    )
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingReportSheet) {
            if let postId = reportingPostId {
                ReportPostView(postId: postId) { reason, description in
                    Task {
                        print("举报帖子: \(postId), 原因: \(reason), 描述: \(String(describing: description))")
                    }
                }
            }
        }
        .sheet(isPresented: $showingPostDetail) {
            if let postId = selectedPostId {
                NavigationStack {
                    PostDetailView(postId: postId, isSheetPresentation: true)
                        .navigationBarHidden(true)
                }
            }
        }
        .onAppear {
            Task {
                if let userId = authManager.currentUser?.id {
                    await viewModel.loadUserProfile(userId: String(userId))
                    await viewModel.loadUserBookmarks(page: 1)
                }
            }
        }
        .asSubView()
    }
    
    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        ZStack {
            // 居中的标题
            Text("我的收藏")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            // 左侧返回按钮
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("加载收藏中...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 空状态视图
    private var emptyView: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "bookmark")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("暂无收藏")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("收藏你喜欢的内容，方便随时查看")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 点赞帖子
    private func toggleLikePost(_ postId: String) async {
        guard let index = viewModel.bookmarkedPosts.firstIndex(where: { $0.id == postId }) else { return }

        let post = viewModel.bookmarkedPosts[index]
        let isLiked = post.isLiked

        // 乐观更新UI
        viewModel.bookmarkedPosts[index].isLiked = !isLiked
        viewModel.bookmarkedPosts[index].likesCount = (post.likesCount ?? 0) + (isLiked ? -1 : 1)

        // 调用API
        do {
            _ = try await CommunityAPIService.shared.toggleLikePost(postId: postId)
        } catch {
            // 失败时回滚
            viewModel.bookmarkedPosts[index].isLiked = isLiked
            viewModel.bookmarkedPosts[index].likesCount = post.likesCount
            print("❌ 点赞操作失败: \(error)")
        }
    }

    // MARK: - 收藏帖子
    private func toggleBookmarkPost(_ postId: String) async {
        guard let index = viewModel.bookmarkedPosts.firstIndex(where: { $0.id == postId }) else { return }

        let post = viewModel.bookmarkedPosts[index]
        let isBookmarked = post.isBookmarked

        // 乐观更新UI
        viewModel.bookmarkedPosts[index].isBookmarked = !isBookmarked

        // 调用API
        do {
            _ = try await CommunityAPIService.shared.toggleBookmarkPost(postId: postId)
            // 如果取消收藏，从列表中移除
            if isBookmarked {
                viewModel.bookmarkedPosts.remove(at: index)
            }
        } catch {
            // 失败时回滚
            viewModel.bookmarkedPosts[index].isBookmarked = isBookmarked
            print("❌ 收藏操作失败: \(error)")
        }
    }
    
    // MARK: - 分享帖子
    private func sharePost(_ postId: String) async {
        print("分享帖子: \(postId)")
        // TODO: 实现分享功能
    }
}

#Preview {
    NavigationStack {
        MyBookmarksView()
    }
}

