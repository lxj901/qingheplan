import SwiftUI

/// 群聊详情管理视图 - 统一管理所有群聊相关操作
struct GroupDetailManagementView: View {
    @State private var conversation: ChatConversation
    @Environment(\.dismiss) private var dismiss
    
    // 导航状态
    @State private var navigationPath = NavigationPath()
    @State private var showingLeaveAlert = false
    
    // 初始化方法
    init(conversation: ChatConversation) {
        self._conversation = State(initialValue: conversation)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // 拖拽指示器
                dragIndicator

                // 群信息头部
                groupInfoHeader

                // 操作选项
                actionOptions

                Spacer(minLength: 0)

                // 底部安全区域
                Color.clear
                    .frame(height: 20)
            }
            .background(Color.white)
            .navigationDestination(for: GroupDetailDestination.self) { destination in
                destinationView(for: destination)
            }
        }
        // 退出群聊确认弹窗
        .alert("退出群聊", isPresented: $showingLeaveAlert) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                // TODO: 实现退出群聊逻辑
                dismiss()
            }
        } message: {
            Text("确定要退出群聊吗？退出后将无法接收群消息。")
        }
    }
    
    // MARK: - 拖拽指示器
    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 36, height: 4)
            .padding(.top, 8)
            .padding(.bottom, 16)
    }
    
    // MARK: - 群信息头部
    private var groupInfoHeader: some View {
        VStack(spacing: ModernDesignSystem.Spacing.sm) {
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                // 群头像
                CachedAsyncImage(url: URL(string: conversation.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(ModernDesignSystem.Colors.backgroundSecondary)
                        .overlay(
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                // 群信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.title ?? "群聊")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                    
                    Text("\(conversation.membersCount ?? 0)名成员")
                        .font(.system(size: 14))
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            // 群描述
            if let description = conversation.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.lg)
    }
    
    // MARK: - 操作选项
    private var actionOptions: some View {
        VStack(spacing: 0) {
            // 群成员管理
            ActionOptionRow(
                icon: "person.2",
                title: "群成员",
                subtitle: "查看和管理群成员",
                action: {
                    navigationPath.append(GroupDetailDestination.memberList)
                }
            )

            // 编辑群信息
            ActionOptionRow(
                icon: "pencil",
                title: "编辑群信息",
                subtitle: "修改群名称、头像等",
                action: {
                    navigationPath.append(GroupDetailDestination.editGroup)
                }
            )

            // 添加成员
            ActionOptionRow(
                icon: "person.badge.plus",
                title: "添加成员",
                subtitle: "邀请新成员加入群聊",
                action: {
                    navigationPath.append(GroupDetailDestination.addMember)
                }
            )

            // 分隔线
            Divider()
                .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                .padding(.vertical, ModernDesignSystem.Spacing.sm)

            // 退出群聊
            ActionOptionRow(
                icon: "rectangle.portrait.and.arrow.right",
                title: "退出群聊",
                subtitle: "退出后将无法接收群消息",
                isDestructive: true,
                action: {
                    showingLeaveAlert = true
                }
            )
        }
        .padding(.top, ModernDesignSystem.Spacing.sm)
        .padding(.bottom, ModernDesignSystem.Spacing.lg)
    }
    
    // MARK: - 目标视图
    @ViewBuilder
    private func destinationView(for destination: GroupDetailDestination) -> some View {
        switch destination {
        case .memberList:
            GroupMemberListView(conversation: conversation)
                .asSubView()
        case .editGroup:
            EditGroupInfoView(conversation: conversation) { updatedConversation in
                // 更新回调 - 更新本地会话信息
                self.conversation = updatedConversation
                navigationPath.removeLast()
            }
            .asSubView()
        case .addMember:
            AddGroupMemberView(conversation: conversation) { _ in
                // 添加成员回调
                navigationPath.removeLast()
            }
            .asSubView()
        }
    }
}

// MARK: - 导航目标枚举
enum GroupDetailDestination: Hashable {
    case memberList
    case editGroup
    case addMember
}



// MARK: - 预览
#Preview {
    let mockConversation = ChatConversation(
        id: "group1",
        title: "李旭杰测试群",
        type: .group,
        avatar: nil,
        lastMessage: nil,
        lastMessageAt: "2024-01-20T14:30:00Z",
        unreadCount: 0,
        isTop: false,
        isMuted: false,
        membersCount: 4,
        creatorId: 1,
        creator: ChatUser(
            id: 1,
            nickname: "群主",
            avatar: nil,
            isVerified: true,
            isOnline: true,
            lastSeenAt: nil
        ),
        memberRecords: [],
        description: "专业的iOS开发技术交流群，欢迎所有对SwiftUI、UIKit、Combine等iOS技术感兴趣的朋友加入",
        maxMembers: 500,
        createdAt: "2024-01-01T00:00:00Z"
    )
    
    GroupDetailManagementView(conversation: mockConversation)
}
