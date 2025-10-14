import SwiftUI

/// 帖子互动用户列表视图（点赞和收藏用户）
struct PostInteractionUsersView: View {
    let postId: String
    let highlightUserId: String?
    @StateObject private var viewModel: PostInteractionUsersViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Sheet 状态管理
    @State private var showingUserProfile = false
    @State private var selectedUserId: String?
    
    // 高亮动画状态
    @State private var highlightedUserId: String?
    
    init(postId: String, type: InteractionType, highlightUserId: String? = nil) {
        self.postId = postId
        self.highlightUserId = highlightUserId
        self._viewModel = StateObject(wrappedValue: PostInteractionUsersViewModel(postId: postId, type: type))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.users.isEmpty {
                    loadingView
                } else if viewModel.users.isEmpty {
                    emptyView
                } else {
                    userListView
                }
            }
            .navigationTitle(viewModel.type == .likes ? "点赞列表" : "收藏列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("确定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showingUserProfile) {
                if let userId = selectedUserId {
                    UserProfileView(userId: userId)
                }
            }
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("加载中...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 空状态视图
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.type == .likes ? "heart.slash" : "bookmark.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(viewModel.type == .likes ? "还没有人点赞" : "还没有人收藏")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 用户列表视图
    private var userListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.users) { user in
                        let isHighlighted = highlightedUserId == user.id
                        
                        UserInteractionRow(user: user, type: viewModel.type)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                isHighlighted 
                                    ? Color.yellow.opacity(0.3)
                                    : Color(.systemBackground)
                            )
                            .animation(.easeInOut(duration: 0.3), value: isHighlighted)
                            .id(user.id)
                            .onTapGesture {
                                navigateToUserProfile(userId: user.id)
                            }
                        
                        if user.id != viewModel.users.last?.id {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                    
                    // 加载更多指示器
                    if viewModel.hasMore {
                        HStack {
                            Spacer()
                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .padding()
                            } else {
                                Button("加载更多") {
                                    Task {
                                        await viewModel.loadMore()
                                    }
                                }
                                .padding()
                            }
                            Spacer()
                        }
                    }
                }
            }
            .onAppear {
                // 如果有需要高亮的用户ID，延迟触发高亮和滚动
                if let userId = highlightUserId {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        highlightedUserId = userId
                        
                        // 滚动到高亮的用户
                        withAnimation {
                            proxy.scrollTo(userId, anchor: .center)
                        }
                        
                        // 3秒后取消高亮
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            highlightedUserId = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    private func navigateToUserProfile(userId: String) {
        selectedUserId = userId
        showingUserProfile = true
    }
}

// MARK: - 用户互动行视图
struct UserInteractionRow: View {
    let user: PostInteractionUser
    let type: InteractionType
    
    var body: some View {
        HStack(spacing: 12) {
            // 用户头像
            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(AppConstants.Colors.primaryGreen.opacity(0.2))
                    .overlay(
                        Text(String(user.nickname.prefix(1)))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                    )
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            
            // 用户信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.nickname)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
                
                // 显示互动时间
                if let timeString = type == .likes ? user.likedAt : user.bookmarkedAt {
                    Text(formatInteractionTime(timeString))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 右侧箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 辅助方法
    private func formatInteractionTime(_ timeString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: timeString) else {
            return timeString
        }
        
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))小时前"
        } else if interval < 604800 {
            return "\(Int(interval / 86400))天前"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.string(from: date)
        }
    }
}

// MARK: - 互动类型枚举
enum InteractionType {
    case likes
    case bookmarks
}

// MARK: - ViewModel
@MainActor
class PostInteractionUsersViewModel: ObservableObject {
    @Published var users: [PostInteractionUser] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasMore = false
    
    let postId: String
    let type: InteractionType
    private var currentPage = 1
    private let pageSize = 20
    
    private let communityService = CommunityAPIService.shared
    
    init(postId: String, type: InteractionType) {
        self.postId = postId
        self.type = type
        
        Task {
            await loadUsers()
        }
    }
    
    /// 加载用户列表
    func loadUsers() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response: PostInteractionUsersResponse
            
            if type == .likes {
                response = try await communityService.getPostLikes(
                    postId: postId,
                    page: currentPage,
                    limit: pageSize
                )
            } else {
                response = try await communityService.getPostBookmarks(
                    postId: postId,
                    page: currentPage,
                    limit: pageSize
                )
            }
            
            if response.success, let data = response.data {
                users = data.items
                hasMore = data.pagination.hasNext
            } else {
                errorMessage = response.message ?? "加载失败"
            }
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 加载更多
    func loadMore() async {
        guard !isLoadingMore && hasMore else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let response: PostInteractionUsersResponse
            
            if type == .likes {
                response = try await communityService.getPostLikes(
                    postId: postId,
                    page: currentPage,
                    limit: pageSize
                )
            } else {
                response = try await communityService.getPostBookmarks(
                    postId: postId,
                    page: currentPage,
                    limit: pageSize
                )
            }
            
            if response.success, let data = response.data {
                users.append(contentsOf: data.items)
                hasMore = data.pagination.hasNext
            } else {
                errorMessage = response.message ?? "加载更多失败"
                currentPage -= 1 // 回退页码
            }
        } catch {
            errorMessage = "加载更多失败: \(error.localizedDescription)"
            currentPage -= 1 // 回退页码
        }
        
        isLoadingMore = false
    }
}

