import Foundation
import SwiftUI

/// 新建聊天视图模型
@MainActor
class NewChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var users: [ChatUser] = []
    @Published var filteredUsers: [ChatUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var searchKeyword = ""
    
    // MARK: - Private Properties
    private let chatService = ChatAPIService.shared
    private let communityService = CommunityAPIService.shared
    private var currentLoadTask: Task<Void, Never>?
    
    // MARK: - 公共方法
    
    /// 加载用户列表
    func loadUsers() async {
        // 取消之前的请求
        currentLoadTask?.cancel()

        isLoading = true
        errorMessage = nil

        currentLoadTask = Task {
            do {
                // 获取真实的用户数据
                let realUsers = try await loadRealUsers()

                guard !Task.isCancelled else { return }

                users = realUsers

                // 应用搜索筛选
                applySearchFilter()

            } catch {
                guard !Task.isCancelled else { return }

                print("❌ 加载用户列表失败: \(error.localizedDescription)")

                errorMessage = "加载用户列表失败: \(error.localizedDescription)"
                showError = true

                // 保持空状态
                users = []
                applySearchFilter()
            }

            isLoading = false
        }
    }


    
    /// 搜索用户
    func searchUsers(keyword: String) {
        searchKeyword = keyword
        applySearchFilter()
    }
    
    /// 清除搜索
    func clearSearch() {
        searchKeyword = ""
        applySearchFilter()
    }
    
    /// 创建会话
    func createConversation(
        type: ConversationType,
        participantIds: [Int],
        title: String?
    ) async throws -> ChatConversation {
        return try await chatService.createConversation(
            type: type,
            participantIds: participantIds,
            title: title
        )
    }

    /// 加载真实用户数据
    private func loadRealUsers() async throws -> [ChatUser] {
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
    
    // MARK: - 私有方法
    
    /// 应用搜索筛选
    private func applySearchFilter() {
        if searchKeyword.isEmpty {
            filteredUsers = users
        } else {
            filteredUsers = users.filter { user in
                user.nickname.localizedCaseInsensitiveContains(searchKeyword)
            }
        }
    }
    

}

// MARK: - ChatUser扩展，使其符合Hashable协议
extension ChatUser: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChatUser, rhs: ChatUser) -> Bool {
        return lhs.id == rhs.id
    }
}
