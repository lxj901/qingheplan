import Foundation
import SwiftUI

/// 群聊信息视图模型 - 增强版
@MainActor
class GroupInfoViewModel: ObservableObject {
    @Published var conversation: ChatConversation?
    @Published var previewMembers: [MemberRecord] = []
    @Published var adminMembers: [MemberRecord] = []
    @Published var activeMembersPreview: [MemberRecord] = []
    @Published var recentMembersPreview: [MemberRecord] = []
    @Published var onlineMembersCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let chatService = ChatAPIService.shared
    private let authManager = AuthManager.shared
    
    // MARK: - 权限检查
    
    /// 是否可以编辑群信息
    var canEditGroup: Bool {
        guard let conversation = conversation,
              let currentUser = authManager.currentUser else { return false }
        
        // 群主可以编辑
        if conversation.creatorId == currentUser.id {
            return true
        }
        
        // TODO: 检查是否为管理员
        return false
    }
    
    /// 是否可以添加成员
    var canAddMembers: Bool {
        guard let conversation = conversation,
              let currentUser = authManager.currentUser else { return false }
        
        // 群主和管理员可以添加成员
        if conversation.creatorId == currentUser.id {
            return true
        }
        
        // TODO: 检查是否为管理员
        return false
    }
    
    /// 是否可以移除成员
    func canRemoveMember(_ member: MemberRecord) -> Bool {
        guard let conversation = conversation,
              let currentUser = authManager.currentUser else { return false }
        
        // 不能移除自己
        if member.user.id == currentUser.id {
            return false
        }
        
        // 群主可以移除任何人
        if conversation.creatorId == currentUser.id {
            return true
        }
        
        // TODO: 管理员可以移除普通成员
        return false
    }

    /// 是否可以解散群聊
    var canDeleteGroup: Bool {
        guard let conversation = conversation,
              let currentUser = authManager.currentUser else { return false }

        // 只有群主可以解散群聊
        return conversation.creatorId == currentUser.id
    }

    // MARK: - 数据加载
    
    /// 加载群聊信息
    func loadGroupInfo(_ conversation: ChatConversation) {
        self.conversation = conversation
        self.previewMembers = Array((conversation.memberRecords ?? []).prefix(10))

        // 分类成员
        categorizeMembers(conversation.memberRecords ?? [])

        Task {
            await refreshGroupInfo()
        }
    }

    /// 分类成员
    private func categorizeMembers(_ members: [MemberRecord]) {
        // 管理员成员（群主和管理员）
        adminMembers = members.filter { $0.role.rawValue == "owner" || $0.role.rawValue == "admin" }

        // 活跃成员（模拟数据，实际应该根据最近活跃时间排序）
        let regularMembers = members.filter { $0.role.rawValue == "member" }
        activeMembersPreview = Array(regularMembers.prefix(8))

        // 最近加入成员（模拟数据，实际应该根据加入时间排序）
        recentMembersPreview = Array(regularMembers.suffix(6))

        // 在线成员数量（模拟数据）
        onlineMembersCount = Int.random(in: 1...(members.count / 2))
    }
    
    /// 刷新群聊信息
    func refreshGroupInfo() async {
        guard let conversationId = conversation?.id else { return }
        
        isLoading = true
        
        do {
            let updatedConversation = try await chatService.getConversationDetail(conversationId: conversationId)
            self.conversation = updatedConversation
            self.previewMembers = Array((updatedConversation.memberRecords ?? []).prefix(10))

            // 重新分类成员
            categorizeMembers(updatedConversation.memberRecords ?? [])
        } catch {
            errorMessage = "加载群聊信息失败: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - 群聊操作
    
    /// 更新群聊信息
    func updateGroupInfo(name: String?, description: String?, avatar: String?) async {
        guard let conversationId = conversation?.id else { return }
        
        isLoading = true
        
        do {
            try await chatService.updateGroupInfo(
                groupId: conversationId,
                name: name,
                description: description,
                avatar: avatar
            )
            
            // 更新本地数据
            if var updatedConversation = conversation {
                if let name = name {
                    updatedConversation = ChatConversation(
                        id: updatedConversation.id,
                        title: name,
                        type: updatedConversation.type,
                        avatar: avatar ?? updatedConversation.avatar,
                        lastMessage: updatedConversation.lastMessage,
                        lastMessageAt: updatedConversation.lastMessageAt,
                        unreadCount: updatedConversation.unreadCount,
                        isTop: updatedConversation.isTop,
                        isMuted: updatedConversation.isMuted,
                        membersCount: updatedConversation.membersCount,
                        creatorId: updatedConversation.creatorId,
                        creator: updatedConversation.creator,
                        memberRecords: updatedConversation.memberRecords,
                        description: description,
                        maxMembers: updatedConversation.maxMembers,
                        createdAt: updatedConversation.createdAt
                    )
                }
                self.conversation = updatedConversation
            }
            
        } catch {
            errorMessage = "更新群聊信息失败: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    /// 添加群成员
    func addMembers(_ memberIds: [Int]) async {
        guard let conversationId = conversation?.id else { return }
        
        isLoading = true
        
        do {
            let addedUsers = try await chatService.addGroupMembers(
                groupId: conversationId,
                memberIds: memberIds
            )
            
            // 更新本地成员列表
            let newMemberRecords = addedUsers.map { user in
                MemberRecord(
                    id: UUID().uuidString,
                    role: .member,
                    status: .active,
                    joinedAt: ISO8601DateFormatter().string(from: Date()),
                    user: user
                )
            }
            
            if var updatedConversation = conversation {
                let updatedMemberRecords = (updatedConversation.memberRecords ?? []) + newMemberRecords
                updatedConversation = ChatConversation(
                    id: updatedConversation.id,
                    title: updatedConversation.title,
                    type: updatedConversation.type,
                    avatar: updatedConversation.avatar,
                    lastMessage: updatedConversation.lastMessage,
                    lastMessageAt: updatedConversation.lastMessageAt,
                    unreadCount: updatedConversation.unreadCount,
                    isTop: updatedConversation.isTop,
                    isMuted: updatedConversation.isMuted,
                    membersCount: (updatedConversation.membersCount ?? 0) + addedUsers.count,
                    creatorId: updatedConversation.creatorId,
                    creator: updatedConversation.creator,
                    memberRecords: updatedMemberRecords,
                    description: updatedConversation.description,
                    maxMembers: updatedConversation.maxMembers,
                    createdAt: updatedConversation.createdAt
                )
                self.conversation = updatedConversation
                self.previewMembers = Array(updatedMemberRecords.prefix(10))
            }
            
        } catch {
            errorMessage = "添加群成员失败: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    /// 移除群成员
    func removeMember(_ memberId: String) async {
        guard let conversationId = conversation?.id else { return }
        
        isLoading = true
        
        do {
            try await chatService.removeGroupMember(
                groupId: conversationId,
                memberId: memberId
            )
            
            // 更新本地成员列表
            if var updatedConversation = conversation {
                let updatedMemberRecords = (updatedConversation.memberRecords ?? []).filter { $0.user.id.description != memberId }
                updatedConversation = ChatConversation(
                    id: updatedConversation.id,
                    title: updatedConversation.title,
                    type: updatedConversation.type,
                    avatar: updatedConversation.avatar,
                    lastMessage: updatedConversation.lastMessage,
                    lastMessageAt: updatedConversation.lastMessageAt,
                    unreadCount: updatedConversation.unreadCount,
                    isTop: updatedConversation.isTop,
                    isMuted: updatedConversation.isMuted,
                    membersCount: max(0, (updatedConversation.membersCount ?? 0) - 1),
                    creatorId: updatedConversation.creatorId,
                    creator: updatedConversation.creator,
                    memberRecords: updatedMemberRecords,
                    description: updatedConversation.description,
                    maxMembers: updatedConversation.maxMembers,
                    createdAt: updatedConversation.createdAt
                )
                self.conversation = updatedConversation
                self.previewMembers = Array(updatedMemberRecords.prefix(10))
            }
            
        } catch {
            errorMessage = "移除群成员失败: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    /// 退出群聊
    func leaveGroup(_ groupId: String) async {
        isLoading = true
        
        do {
            try await chatService.leaveGroup(groupId: groupId)
        } catch {
            errorMessage = "退出群聊失败: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - 辅助方法
    
    /// 更新会话信息
    func updateConversation(_ conversation: ChatConversation) {
        self.conversation = conversation
        self.previewMembers = Array((conversation.memberRecords ?? []).prefix(10))
    }
    
    /// 添加成员到预览列表
    func addMembers(_ members: [MemberRecord]) {
        if var updatedConversation = conversation {
            let updatedMemberRecords = (updatedConversation.memberRecords ?? []) + members
            updatedConversation = ChatConversation(
                id: updatedConversation.id,
                title: updatedConversation.title,
                type: updatedConversation.type,
                avatar: updatedConversation.avatar,
                lastMessage: updatedConversation.lastMessage,
                lastMessageAt: updatedConversation.lastMessageAt,
                unreadCount: updatedConversation.unreadCount,
                isTop: updatedConversation.isTop,
                isMuted: updatedConversation.isMuted,
                membersCount: (updatedConversation.membersCount ?? 0) + members.count,
                creatorId: updatedConversation.creatorId,
                creator: updatedConversation.creator,
                memberRecords: updatedMemberRecords,
                description: updatedConversation.description,
                maxMembers: updatedConversation.maxMembers,
                createdAt: updatedConversation.createdAt
            )
            self.conversation = updatedConversation
            self.previewMembers = Array(updatedMemberRecords.prefix(10))
        }
    }
}
