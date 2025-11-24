import SwiftUI

/// 标签详情页面
struct TagDetailView: View {
    let tagName: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TagDetailViewModel()
    @State private var selectedSortType: TagSortType = .latest
    @State private var showingSortOptions = false

    // 移除本地导航路径，使用父级导航系统

    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            navigationHeader

            // 排序选择栏
            sortBar

            // 内容区域
            contentView
        }
        .background(AppConstants.Colors.backgroundGray)
        .navigationBarHidden(true)
        .asSubView()
        // 移除本地导航目标，使用父级导航系统
        .onAppear {
            Task {
                await viewModel.loadTagPosts(tagName: tagName, sortBy: selectedSortType.rawValue)
            }
        }
    }
    
    // MARK: - 导航栏
    private var navigationHeader: some View {
        HStack {
            // 返回按钮
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppConstants.Colors.primaryText)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("#\(tagName)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppConstants.Colors.primaryText)
                
                if let totalCount = viewModel.totalCount {
                    Text("\(totalCount) 个帖子")
                        .font(.system(size: 12))
                        .foregroundColor(AppConstants.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            // 排序按钮
            Button(action: { showingSortOptions = true }) {
                HStack(spacing: 4) {
                    Text(selectedSortType.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.Colors.primaryText)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppConstants.Colors.secondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white)
                .cornerRadius(16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }
    
    // MARK: - 排序栏
    private var sortBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TagSortType.allCases, id: \.self) { sortType in
                    Button(action: {
                        selectedSortType = sortType
                        Task {
                            await viewModel.loadTagPosts(tagName: tagName, sortBy: sortType.rawValue, refresh: true)
                        }
                    }) {
                        Text(sortType.displayName)
                            .font(.system(size: 14, weight: selectedSortType == sortType ? .semibold : .regular))
                            .foregroundColor(selectedSortType == sortType ? .white : AppConstants.Colors.primaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedSortType == sortType ? AppConstants.Colors.primaryGreen : Color.white)
                            .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(AppConstants.Colors.backgroundGray)
    }
    
    // MARK: - 内容视图
    private var contentView: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                // 加载状态
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("加载中...")
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppConstants.Colors.backgroundGray)
            } else if let errorMessage = viewModel.errorMessage {
                // 错误状态
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(AppConstants.Colors.systemRed)
                    
                    Text(errorMessage)
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Button("重试") {
                        Task {
                            await viewModel.loadTagPosts(tagName: tagName, sortBy: selectedSortType.rawValue, refresh: true)
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppConstants.Colors.primaryGreen)
                    .cornerRadius(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppConstants.Colors.backgroundGray)
            } else if viewModel.posts.isEmpty {
                // 空状态
                VStack(spacing: 16) {
                    Image(systemName: "tag")
                        .font(.system(size: 48))
                        .foregroundColor(AppConstants.Colors.secondaryText)
                    
                    Text("暂无相关帖子")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.Colors.primaryText)
                    
                    Text("该标签下还没有帖子，快来发布第一个吧！")
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppConstants.Colors.backgroundGray)
            } else {
                // 帖子列表
                postsListView
            }
        }
    }
    
    // MARK: - 帖子列表
    private var postsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.posts) { post in
                    PostCardView(
                        post: post,
                        showHotBadge: false,
                        showEditButton: false,
                        onLike: {
                            Task {
                                await viewModel.toggleLike(postId: post.id)
                            }
                        },
                        onBookmark: {
                            Task {
                                await viewModel.toggleBookmark(postId: post.id)
                            }
                        },
                        onShare: {
                            // 处理分享
                        },
                        onReport: {
                            // 处理举报
                        },
                        onNavigateToDetail: { postId in
                            print("🔍 标签详情页面：导航到帖子详情，帖子ID: \(postId)")
                            Task { @MainActor in
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("NavigateToPost"),
                                    object: nil,
                                    userInfo: ["postId": Int(postId) ?? 0]
                                )
                            }
                        },
                        onNavigateToUserProfile: { author in
                            print("🔍 标签详情页面：导航到用户详情，用户ID: \(author.id)")
                            Task { @MainActor in
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("ShowUserProfileInCommunity"),
                                    object: nil,
                                    userInfo: ["userId": String(author.id)]
                                )
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                
                // 加载更多
                if viewModel.hasMorePosts && !viewModel.isLoading {
                    Button("加载更多") {
                        Task {
                            await viewModel.loadMorePosts()
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                    .padding()
                } else if viewModel.isLoading && !viewModel.posts.isEmpty {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.top, 8)
        }
        .background(AppConstants.Colors.backgroundGray)
        .refreshable {
            await viewModel.loadTagPosts(tagName: tagName, sortBy: selectedSortType.rawValue, refresh: true)
        }
    }
}

// MARK: - 排序选择弹窗
struct TagSortOptionsSheet: View {
    @Binding var selectedSortType: TagSortType
    @Environment(\.dismiss) private var dismiss
    let onSortChanged: (TagSortType) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ForEach(TagSortType.allCases, id: \.self) { sortType in
                    Button(action: {
                        selectedSortType = sortType
                        onSortChanged(sortType)
                        dismiss()
                    }) {
                        HStack {
                            Text(sortType.displayName)
                                .font(.system(size: 16))
                                .foregroundColor(AppConstants.Colors.primaryText)
                            
                            Spacer()
                            
                            if selectedSortType == sortType {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppConstants.Colors.primaryGreen)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if sortType != TagSortType.allCases.last {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("排序方式")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TagDetailView(tagName: "健身")
}
