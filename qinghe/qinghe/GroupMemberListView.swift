import SwiftUI

/// 群成员列表视图
struct GroupMemberListView: View {
    let conversation: ChatConversation
    @StateObject private var viewModel = GroupMemberListViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var showingAddMember = false
    @State private var selectedMember: MemberRecord?
    @State private var showingMemberActions = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            searchBar

            // 成员列表
            membersList
        }
        .navigationTitle("群成员(\(viewModel.members.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("关闭") {
                    dismiss()
                }
            }

            if viewModel.canAddMembers {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        showingAddMember = true
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showingAddMember) {
            AddGroupMemberView(conversation: conversation) { addedMembers in
                viewModel.addMembers(addedMembers)
            }
            .asSubView()
        }
        .actionSheet(isPresented: $showingMemberActions) {
            memberActionSheet
        }
        .onAppear {
            viewModel.loadMembers(conversation)
        }
    }
    
    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            
            TextField("搜索群成员", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: searchText) { _, newValue in
                    viewModel.searchMembers(keyword: newValue)
                }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.md)
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
        .background(ModernDesignSystem.Colors.backgroundSecondary)
        .cornerRadius(ModernDesignSystem.CornerRadius.md)
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.md)
    }
    
    // MARK: - 成员列表
    private var membersList: some View {
        List {
            ForEach(viewModel.filteredMembers) { member in
                MemberRowView(
                    member: member,
                    isCreator: member.user.id == conversation.creatorId,
                    canRemove: viewModel.canRemoveMember(member),
                    onTap: {
                        selectedMember = member
                        showingMemberActions = true
                    },
                    onRemove: {
                        Task {
                            await viewModel.removeMember(member)
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
    
    // MARK: - 成员操作菜单
    private var memberActionSheet: ActionSheet {
        guard let member = selectedMember else {
            return ActionSheet(title: Text(""), buttons: [.cancel()])
        }
        
        var buttons: [ActionSheet.Button] = []
        
        // 查看资料
        buttons.append(.default(Text("查看资料")) {
            // TODO: 显示用户资料
        })
        
        // 发送消息
        if member.user.id != AuthManager.shared.currentUser?.id {
            buttons.append(.default(Text("发送消息")) {
                // TODO: 跳转到私聊
            })
        }
        
        // 移除成员（仅群主和管理员）
        if viewModel.canRemoveMember(member) {
            buttons.append(.destructive(Text("移出群聊")) {
                Task {
                    await viewModel.removeMember(member)
                }
            })
        }
        
        buttons.append(.cancel())
        
        return ActionSheet(
            title: Text(member.user.nickname),
            buttons: buttons
        )
    }
}

// MARK: - 成员行视图
struct MemberRowView: View {
    let member: MemberRecord
    let isCreator: Bool
    let canRemove: Bool
    let onTap: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            // 头像
            AsyncImage(url: URL(string: member.user.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(ModernDesignSystem.Colors.backgroundSecondary)
                    .overlay(
                        Text(String(member.user.nickname.prefix(1)))
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    )
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            
            // 用户信息
            HStack {
                Text(member.user.nickname)
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)

                // 认证标识
                if member.user.isVerified == true {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                }

                // 群主标识
                if isCreator {
                    Text("群主")
                        .font(ModernDesignSystem.Typography.caption2)
                        .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ModernDesignSystem.Colors.primaryGreen.opacity(0.1))
                        .cornerRadius(4)
                }

                // 管理员标识
                if member.role == .admin {
                    Text("管理员")
                        .font(ModernDesignSystem.Typography.caption2)
                        .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ModernDesignSystem.Colors.primaryGreen.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // 操作按钮
            if canRemove {
                Button("移除") {
                    onRemove()
                }
                .font(ModernDesignSystem.Typography.caption1)
                .foregroundColor(ModernDesignSystem.Colors.errorRed)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ModernDesignSystem.Colors.errorRed.opacity(0.1))
                .cornerRadius(ModernDesignSystem.CornerRadius.sm)
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.md)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - 群成员列表视图模型
@MainActor
class GroupMemberListViewModel: ObservableObject {
    @Published var members: [MemberRecord] = []
    @Published var filteredMembers: [MemberRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let chatService = ChatAPIService.shared
    private let authManager = AuthManager.shared
    private var conversation: ChatConversation?
    
    /// 是否可以添加成员
    var canAddMembers: Bool {
        guard let conversation = conversation,
              let currentUser = authManager.currentUser else { return false }
        
        return conversation.creatorId == currentUser.id
    }
    
    /// 加载成员列表
    func loadMembers(_ conversation: ChatConversation) {
        self.conversation = conversation
        self.members = conversation.memberRecords ?? []
        self.filteredMembers = conversation.memberRecords ?? []
    }
    
    /// 搜索成员
    func searchMembers(keyword: String) {
        if keyword.isEmpty {
            filteredMembers = members
        } else {
            filteredMembers = members.filter { member in
                member.user.nickname.localizedCaseInsensitiveContains(keyword)
            }
        }
    }
    
    /// 是否可以移除成员
    func canRemoveMember(_ member: MemberRecord) -> Bool {
        guard let conversation = conversation,
              let currentUser = authManager.currentUser else { return false }
        
        // 不能移除自己
        if member.user.id == currentUser.id {
            return false
        }
        
        // 不能移除群主
        if member.user.id == conversation.creatorId {
            return false
        }
        
        // 群主可以移除任何人
        if conversation.creatorId == currentUser.id {
            return true
        }
        
        return false
    }
    
    /// 添加成员
    func addMembers(_ newMembers: [MemberRecord]) {
        members.append(contentsOf: newMembers)
        filteredMembers = members
    }
    
    /// 移除成员
    func removeMember(_ member: MemberRecord) async {
        guard let conversationId = conversation?.id else { return }
        
        isLoading = true
        
        do {
            try await chatService.removeGroupMember(
                groupId: conversationId,
                memberId: String(member.user.id)
            )
            
            // 从本地列表移除
            members.removeAll { $0.id == member.id }
            filteredMembers.removeAll { $0.id == member.id }
            
        } catch {
            errorMessage = "移除成员失败: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - 预览
#Preview {
    let mockMembers = [
        MemberRecord(
            id: "1",
            role: .admin,
            status: .active,
            joinedAt: "2024-01-01T00:00:00Z",
            user: ChatUser(
                id: 1,
                nickname: "群主",
                avatar: nil,
                isVerified: true,
                isOnline: true,
                lastSeenAt: nil
            )
        ),
        MemberRecord(
            id: "2",
            role: .member,
            status: .active,
            joinedAt: "2024-01-02T00:00:00Z",
            user: ChatUser(
                id: 2,
                nickname: "张三",
                avatar: nil,
                isVerified: false,
                isOnline: false,
                lastSeenAt: "2024-01-20T10:00:00Z"
            )
        )
    ]
    
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
        creator: mockMembers[0].user,
        memberRecords: mockMembers,
        description: "专业的iOS开发技术交流群",
        maxMembers: 500,
        createdAt: "2024-01-01T00:00:00Z"
    )
    
    GroupMemberListView(conversation: mockConversation)
}
