import SwiftUI

/// 用户列表视图（关注者/关注列表）
struct UserListView: View {
    let userId: String
    let listType: UserListType
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UserListViewModel()

    // 导航状态
    @State private var showingUserProfile = false
    @State private var selectedUserId: String?
    
    enum UserListType: String, CaseIterable {
        case followers = "粉丝"
        case following = "关注"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 自定义导航栏
                customNavigationBar

                // 用户列表内容
                userListContent
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingUserProfile) {
                if let userId = selectedUserId {
                    UserProfileView(userId: userId)
                        .navigationBarHidden(true)
                        .onAppear {
                            print("🔍 用户列表页面：导航到用户详情页面，用户ID: \(userId)")
                        }
                }
            }
            .onAppear {
                Task {
                    // 初始化时刷新加载，确保获取最新的关注状态
                    await viewModel.loadUsers(userId: userId, listType: listType, refresh: true)
                }
            }
        }
    }
    
    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            // 返回按钮
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            
            Spacer()
            
            // 标题
            Text(listType.rawValue)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // 占位空间
            Rectangle()
                .fill(Color.clear)
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - 用户列表内容
    private var userListContent: some View {
        Group {
            if viewModel.isLoading && viewModel.users.isEmpty {
                loadingView
            } else if viewModel.users.isEmpty {
                emptyView
            } else {
                userList
            }
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("加载中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 空状态视图
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: listType == .followers ? "person.2" : "person.3")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("暂无\(listType.rawValue)")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(listType == .followers ? "还没有人关注" : "还没有关注任何人")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 用户列表
    private var userList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.users) { user in
                    UserRowView(user: user) { userId in
                        // 处理用户点击
                        print("🔍 用户列表：点击用户，用户ID: \(userId)")
                        selectedUserId = userId
                        showingUserProfile = true
                        print("🔍 用户列表：导航状态已更新 - selectedUserId: \(selectedUserId ?? "nil"), showingUserProfile: \(showingUserProfile)")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                        .onAppear {
                            // 当滚动到倒数第3个用户时，加载更多
                            if user.id == viewModel.users.suffix(3).first?.id {
                                Task {
                                    await viewModel.loadUsers(userId: userId, listType: listType)
                                }
                            }
                        }
                    
                    if user.id != viewModel.users.last?.id {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
                
                // 加载更多指示器
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("加载更多...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 50)
                } else if !viewModel.hasMore && !viewModel.users.isEmpty {
                    Text("没有更多了")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(height: 50)
                }
            }
        }
        .refreshable {
            await viewModel.loadUsers(userId: userId, listType: listType, refresh: true)
        }
    }
}



// MARK: - 用户列表视图模型
@MainActor
class UserListViewModel: ObservableObject {
    @Published var users: [UserProfile] = []
    @Published var isLoading = false
    @Published var hasMore = true
    @Published var currentPage = 1
    @Published var errorMessage: String?
    
    private let communityService = CommunityAPIService.shared
    
    /// 加载用户列表
    func loadUsers(userId: String, listType: UserListView.UserListType, refresh: Bool = false) async {
        guard let userIdInt = Int(userId) else {
            print("❌ 无效的用户ID: \(userId)")
            return
        }
        
        if refresh {
            currentPage = 1
            hasMore = true
            users.removeAll()
        }
        
        guard hasMore else {
            print("📄 没有更多用户了")
            return
        }
        
        print("🔍 开始加载\(listType.rawValue)列表，用户ID: \(userId), 页码: \(currentPage)")
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response: CommunityAPIResponse<UserListResponse>
            
            switch listType {
            case .followers:
                response = try await communityService.getUserFollowers(userId: userIdInt, page: currentPage, limit: 5)
            case .following:
                response = try await communityService.getUserFollowing(userId: userIdInt, page: currentPage, limit: 5)
            }
            
            if response.success, let userListResponse = response.data {
                let newUsers = userListResponse.items
                
                if refresh {
                    users = newUsers
                } else {
                    users.append(contentsOf: newUsers)
                }
                
                // 更新分页信息
                hasMore = userListResponse.pagination.hasNext
                currentPage += 1
                
                print("✅ \(listType.rawValue)列表加载成功，当前共 \(users.count) 个用户")
            } else {
                errorMessage = response.message ?? "加载\(listType.rawValue)列表失败"
                print("❌ \(listType.rawValue)列表加载失败: \(errorMessage ?? "未知错误")")
            }
        } catch {
            errorMessage = "网络请求失败: \(error.localizedDescription)"
            print("❌ 网络请求失败: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - 预览
struct UserListView_Previews: PreviewProvider {
    static var previews: some View {
        UserListView(userId: "123", listType: .followers)
    }
}
