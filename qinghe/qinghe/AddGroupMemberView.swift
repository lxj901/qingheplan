import SwiftUI

/// 添加群成员视图
struct AddGroupMemberView: View {
    let conversation: ChatConversation
    let onMembersAdded: ([MemberRecord]) -> Void
    
    @StateObject private var viewModel = AddGroupMemberViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedUsers: Set<ChatUser> = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            searchBar

            // 已选择的用户
            if !selectedUsers.isEmpty {
                selectedUsersSection
            }

            // 用户列表
            usersList
        }
        .navigationTitle("添加群成员")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("确定(\(selectedUsers.count))") {
                    addSelectedMembers()
                }
                .disabled(selectedUsers.isEmpty || viewModel.isLoading)
            }
        }
        .onAppear {
            viewModel.loadAvailableUsers(excludingConversation: conversation)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        .asSubView() // 确保添加群成员页面也隐藏Tab栏
    }
    
    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            
            TextField("搜索联系人", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: searchText) { _, newValue in
                    viewModel.searchUsers(keyword: newValue)
                }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.md)
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
        .background(ModernDesignSystem.Colors.backgroundSecondary)
        .cornerRadius(ModernDesignSystem.CornerRadius.md)
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.md)
    }
    
    // MARK: - 已选择的用户
    private var selectedUsersSection: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
            Text("已选择 \(selectedUsers.count) 人")
                .font(ModernDesignSystem.Typography.footnote)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ModernDesignSystem.Spacing.sm) {
                    ForEach(Array(selectedUsers), id: \.id) { user in
                        SelectedUserChip(user: user) {
                            selectedUsers.remove(user)
                        }
                    }
                }
                .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            }
        }
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
        .background(ModernDesignSystem.Colors.backgroundSecondary)
    }
    
    // MARK: - 用户列表
    private var usersList: some View {
        List {
            ForEach(viewModel.filteredUsers) { user in
                let isAlreadyInGroup = isUserInGroup(user)
                GroupMemberRowView(
                    user: user,
                    isSelected: selectedUsers.contains(user),
                    isAlreadyInGroup: isAlreadyInGroup,
                    onToggle: {
                        if !isAlreadyInGroup {
                            toggleUserSelection(user)
                        }
                    }
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
    }

    // MARK: - 辅助方法
    private func isUserInGroup(_ user: ChatUser) -> Bool {
        let existingMemberIds = Set((conversation.memberRecords ?? []).map { $0.user.id })
        return existingMemberIds.contains(user.id)
    }

    // MARK: - 私有方法
    
    private func toggleUserSelection(_ user: ChatUser) {
        if selectedUsers.contains(user) {
            selectedUsers.remove(user)
        } else {
            selectedUsers.insert(user)
        }
    }
    
    private func addSelectedMembers() {
        let userIds = Array(selectedUsers).map { $0.id }
        
        Task {
            await viewModel.addMembersToGroup(
                groupId: conversation.id,
                memberIds: userIds
            )
            
            if !viewModel.showError {
                // 创建新的成员记录
                let newMemberRecords = Array(selectedUsers).map { user in
                    MemberRecord(
                        id: UUID().uuidString,
                        role: .member,
                        status: .active,
                        joinedAt: ISO8601DateFormatter().string(from: Date()),
                        user: user
                    )
                }
                
                onMembersAdded(newMemberRecords)
                dismiss()
            }
        }
    }
}

// MARK: - 已选择用户芯片
struct SelectedUserChip: View {
    let user: ChatUser
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(ModernDesignSystem.Colors.backgroundCard)
                    .overlay(
                        Text(String(user.nickname.prefix(1)))
                            .font(ModernDesignSystem.Typography.caption2)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    )
            }
            .frame(width: 24, height: 24)
            .clipShape(Circle())
            
            Text(user.nickname)
                .font(ModernDesignSystem.Typography.caption1)
                .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ModernDesignSystem.Colors.backgroundCard)
        .cornerRadius(16)
    }
}

// MARK: - 群成员行视图
struct GroupMemberRowView: View {
    let user: ChatUser
    let isSelected: Bool
    let isAlreadyInGroup: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            // 选择状态或已在群聊状态
            Group {
                if isAlreadyInGroup {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.textTertiary)
                }
            }
            
            // 头像
            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(ModernDesignSystem.Colors.backgroundSecondary)
                    .overlay(
                        Text(String(user.nickname.prefix(1)))
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    )
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            
            // 用户信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.nickname)
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(isAlreadyInGroup ? ModernDesignSystem.Colors.textTertiary : ModernDesignSystem.Colors.textPrimary)

                    if user.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                    }

                    // 已在群聊标识
                    if isAlreadyInGroup {
                        Text("已在群聊")
                            .font(ModernDesignSystem.Typography.caption2)
                            .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ModernDesignSystem.Colors.backgroundSecondary)
                            .cornerRadius(4)
                    }
                }

                if !isAlreadyInGroup {
                    HStack(spacing: 4) {
                        Circle()
                            .fill((user.isOnline == true) ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.textTertiary)
                            .frame(width: 8, height: 8)

                        Text((user.isOnline == true) ? "在线" : "离线")
                            .font(ModernDesignSystem.Typography.caption1)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.md)
        .background(Color.clear)
        .contentShape(Rectangle())
        .opacity(isAlreadyInGroup ? 0.6 : 1.0)
        .onTapGesture {
            if !isAlreadyInGroup {
                onToggle()
            }
        }
    }
}

// MARK: - 添加群成员视图模型
@MainActor
class AddGroupMemberViewModel: ObservableObject {
    @Published var availableUsers: [ChatUser] = []
    @Published var filteredUsers: [ChatUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let chatService = ChatAPIService.shared
    private let userManager = UserManager.shared
    private let communityService = CommunityAPIService.shared
    
    /// 加载可添加的用户
    func loadAvailableUsers(excludingConversation conversation: ChatConversation) {
        isLoading = true

        Task {
            do {
                // 使用与创建群聊相同的逻辑：获取关注和粉丝列表
                let users = try await loadUsersFromFollowingAndFollowers()

                await MainActor.run {
                    // 显示所有用户，不进行过滤，让用户看到完整的列表
                    self.availableUsers = users
                    self.filteredUsers = users
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载用户列表失败: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false

                    // 如果API失败，使用备用的模拟数据
                    let mockUsers = [
                        ChatUser(id: 3, nickname: "李四", avatar: nil, isVerified: false, isOnline: true, lastSeenAt: nil),
                        ChatUser(id: 4, nickname: "王五", avatar: nil, isVerified: true, isOnline: false, lastSeenAt: "2024-01-20T10:00:00Z"),
                        ChatUser(id: 5, nickname: "赵六", avatar: nil, isVerified: false, isOnline: true, lastSeenAt: nil)
                    ]

                    // 显示所有模拟用户，不进行过滤
                    self.availableUsers = mockUsers
                    self.filteredUsers = mockUsers
                }
            }
        }
    }

    /// 从关注和粉丝列表加载用户（与NewChatViewModel相同的逻辑）
    private func loadUsersFromFollowingAndFollowers() async throws -> [ChatUser] {
        var allUsers: [ChatUser] = []

        // 获取当前用户ID
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NetworkManager.NetworkError.networkError("未登录")
        }

        // 1. 获取关注列表
        do {
            let followingResponse = try await communityService.getUserFollowing(
                userId: currentUserId,
                page: 1,
                limit: 50
            )

            if followingResponse.success, let followingData = followingResponse.data {
                let followingUsers = followingData.items.map { userProfile in
                    ChatUser(
                        id: userProfile.id,
                        nickname: userProfile.nickname,
                        avatar: userProfile.avatar,
                        isVerified: userProfile.isVerified,
                        isOnline: nil, // 在线状态需要单独获取
                        lastSeenAt: nil
                    )
                }
                allUsers.append(contentsOf: followingUsers)
                print("✅ 成功获取关注列表: \(followingUsers.count) 个用户")
            }
        } catch {
            print("⚠️ 获取关注列表失败: \(error.localizedDescription)")
        }

        // 2. 获取粉丝列表
        do {
            let followersResponse = try await communityService.getUserFollowers(
                userId: currentUserId,
                page: 1,
                limit: 50
            )

            if followersResponse.success, let followersData = followersResponse.data {
                let followerUsers = followersData.items.map { userProfile in
                    ChatUser(
                        id: userProfile.id,
                        nickname: userProfile.nickname,
                        avatar: userProfile.avatar,
                        isVerified: userProfile.isVerified,
                        isOnline: nil,
                        lastSeenAt: nil
                    )
                }

                // 去重：避免同时关注和被关注的用户重复
                let existingUserIds = Set(allUsers.map { $0.id })
                let newFollowerUsers = followerUsers.filter { !existingUserIds.contains($0.id) }
                allUsers.append(contentsOf: newFollowerUsers)
                print("✅ 成功获取粉丝列表: \(newFollowerUsers.count) 个新用户")
            }
        } catch {
            print("⚠️ 获取粉丝列表失败: \(error.localizedDescription)")
        }

        print("✅ 总共获取到 \(allUsers.count) 个用户")
        return allUsers
    }
    
    /// 搜索用户
    func searchUsers(keyword: String) {
        if keyword.isEmpty {
            filteredUsers = availableUsers
        } else {
            filteredUsers = availableUsers.filter { user in
                user.nickname.localizedCaseInsensitiveContains(keyword)
            }
        }
    }
    
    /// 添加成员到群聊
    func addMembersToGroup(groupId: String, memberIds: [Int]) async {
        isLoading = true
        
        do {
            _ = try await chatService.addGroupMembers(groupId: groupId, memberIds: memberIds)
        } catch {
            errorMessage = "添加群成员失败: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - 预览
#Preview {
    let mockConversation = ChatConversation(
        id: "group1",
        title: "iOS开发交流群",
        type: .group,
        avatar: nil,
        lastMessage: nil,
        lastMessageAt: "2024-01-20T14:30:00Z",
        unreadCount: 0,
        isTop: false,
        isMuted: false,
        membersCount: 2,
        creatorId: 1,
        creator: ChatUser(id: 1, nickname: "群主", avatar: nil, isVerified: true, isOnline: true, lastSeenAt: nil),
        memberRecords: [],
        description: "专业的iOS开发技术交流群",
        maxMembers: 500,
        createdAt: "2024-01-01T00:00:00Z"
    )
    
    AddGroupMemberView(conversation: mockConversation) { addedMembers in
        print("添加了 \(addedMembers.count) 个成员")
    }
}
