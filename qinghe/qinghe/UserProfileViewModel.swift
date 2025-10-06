import Foundation
import SwiftUI

// MARK: - 用户详情页面ViewModel
@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var userPosts: [Post] = []
    @Published var followingUsers: [UserProfile] = []
    @Published var followerUsers: [UserProfile] = []
    
    @Published var isLoading = true
    @Published var isLoadingPosts = false
    @Published var isLoadingFollowing = false
    @Published var isLoadingFollowers = false
    
    @Published var hasError = false
    @Published var errorMessage: String?
    
    @Published var isFollowActionLoading = false
    
    // 屏蔽用户相关的错误提示
    @Published var showBlockedUserAlert = false
    @Published var blockedUserMessage: String?

    // 收藏相关
    @Published var bookmarkedPosts: [Post] = []
    @Published var isLoadingBookmarks = false
    @Published var bookmarksCurrentPage = 1
    @Published var hasMoreBookmarks = true

    // 分页信息
    @Published var postsCurrentPage = 1
    @Published var followingCurrentPage = 1
    @Published var followersCurrentPage = 1

    @Published var hasMorePosts = true
    @Published var hasMoreFollowing = true
    @Published var hasMoreFollowers = true

    // 当前页面属性（用于调试）
    var currentPage: Int {
        return postsCurrentPage
    }
    
    private let networkManager = NetworkManager.shared
    private let apiService = CommunityAPIService.shared
    
    // MARK: - 加载用户资料
    func loadUserProfile(userId: String) async {
        print("🔍 UserProfileViewModel: 开始加载用户资料, userId: \(userId)")

        // 将String类型的userId转换为Int类型
        guard let userIdInt = Int(userId) else {
            print("❌ UserProfileViewModel: userId转换失败, userId: \(userId)")
            await MainActor.run {
                hasError = true
                errorMessage = "用户ID格式错误"
                isLoading = false
            }
            return
        }

        print("🔍 UserProfileViewModel: 转换后的userIdInt: \(userIdInt)")
        await MainActor.run {
            isLoading = true
            hasError = false
            errorMessage = nil
        }

        do {
            print("🔍 UserProfileViewModel: 使用CommunityAPIService调用getUserProfile")
            let response = try await apiService.getUserProfile(userId: userIdInt)

            print("🔍 UserProfileViewModel: API响应成功")
            print("🔍 UserProfileViewModel: response.success = \(response.success)")
            print("🔍 UserProfileViewModel: response.message = \(response.message ?? "nil")")
            print("🔍 UserProfileViewModel: response.data = \(response.data != nil ? "有数据" : "无数据")")

            if response.success, let profile = response.data {
                print("🔍 UserProfileViewModel: 用户资料加载成功")
                print("🔍 UserProfileViewModel: profile.id = \(profile.id)")
                print("🔍 UserProfileViewModel: profile.nickname = \(profile.nickname)")
                
                await MainActor.run {
                    userProfile = profile
                }

                // 如果是第一次加载，同时加载帖子
                if userPosts.isEmpty {
                    print("🔍 UserProfileViewModel: 开始加载用户帖子")
                    await loadUserPosts(userId: userId, page: 1)
                }
            } else {
                print("❌ UserProfileViewModel: 用户资料加载失败")
                print("❌ UserProfileViewModel: response.success = \(response.success)")
                print("❌ UserProfileViewModel: response.message = \(response.message ?? "nil")")
                await MainActor.run {
                    hasError = true
                    errorMessage = response.message ?? "获取用户信息失败"
                }
            }
        } catch {
            print("❌ UserProfileViewModel: API请求异常")
            print("❌ UserProfileViewModel: error = \(error)")
            print("❌ UserProfileViewModel: error.localizedDescription = \(error.localizedDescription)")
            await MainActor.run {
                hasError = true
                errorMessage = "网络请求失败: \(error.localizedDescription)"
            }
        }

        await MainActor.run {
            isLoading = false
        }
        print("🔍 UserProfileViewModel: 加载完成, isLoading = false")
    }
    
    // MARK: - 加载用户帖子
    func loadUserPosts(userId: String, page: Int = 1, refresh: Bool = false) async {
        // 设置加载状态
        await MainActor.run {
            isLoadingPosts = true
            
            if page == 1 || refresh {
                userPosts.removeAll()
                postsCurrentPage = 1
                hasMorePosts = true
            }
        }

        print("🔄 开始加载用户帖子，页码: \(page)，用户ID: \(userId)")

        do {
            let response: BooleanUserAPIResponse<PostListResponse> = try await networkManager.request(
                endpoint: "/users/\(userId)/posts",
                method: .GET,
                parameters: [
                    "page": "\(page)",
                    "limit": "20"
                ],
                responseType: BooleanUserAPIResponse<PostListResponse>.self
            )

            if response.isSuccess, let data = response.data {
                await MainActor.run {
                    if page == 1 {
                        userPosts = data.items
                    } else {
                        userPosts.append(contentsOf: data.items)
                    }

                    postsCurrentPage = data.pagination.page
                    hasMorePosts = data.pagination.hasNext
                }

                print("✅ 成功加载用户帖子: \(data.items.count) 条")
                print("📊 分页信息: 当前页 \(postsCurrentPage)，是否有更多: \(hasMorePosts)")
                print("📊 总帖子数: \(userPosts.count)")
            } else {
                print("❌ 用户帖子响应失败: \(response.message ?? "未知错误")")
            }
        } catch {
            print("❌ 加载用户帖子失败: \(error)")
        }

        await MainActor.run {
            isLoadingPosts = false
        }
        print("🔄 用户帖子加载完成，isLoadingPosts = false")
    }
    
    // MARK: - 加载关注列表
    func loadFollowingUsers(userId: String, page: Int = 1) async {
        guard let userIdInt = Int(userId) else {
            print("❌ 无效的用户ID: \(userId)")
            return
        }

        if page == 1 {
            isLoadingFollowing = true
            followingUsers.removeAll()
            followingCurrentPage = 1
            hasMoreFollowing = true
        }

        do {
            let response = try await apiService.getUserFollowing(userId: userIdInt, page: page, limit: 20)

            if response.success, let userListResponse = response.data {
                let newUsers = userListResponse.items

                if page == 1 {
                    followingUsers = newUsers
                } else {
                    followingUsers.append(contentsOf: newUsers)
                }

                // 更新分页信息
                hasMoreFollowing = userListResponse.pagination.hasNext
                followingCurrentPage = page

                print("✅ 关注列表加载成功，当前共 \(followingUsers.count) 个用户")
            } else {
                print("❌ 关注列表加载失败: \(response.message ?? "未知错误")")
            }
        } catch {
            print("❌ 加载关注列表失败: \(error)")
        }

        isLoadingFollowing = false
    }
    
    // MARK: - 加载粉丝列表
    func loadFollowerUsers(userId: String, page: Int = 1) async {
        guard let userIdInt = Int(userId) else {
            print("❌ 无效的用户ID: \(userId)")
            return
        }

        if page == 1 {
            isLoadingFollowers = true
            followerUsers.removeAll()
            followersCurrentPage = 1
            hasMoreFollowers = true
        }

        do {
            let response = try await apiService.getUserFollowers(userId: userIdInt, page: page, limit: 20)

            if response.success, let userListResponse = response.data {
                let newUsers = userListResponse.items

                if page == 1 {
                    followerUsers = newUsers
                } else {
                    followerUsers.append(contentsOf: newUsers)
                }

                // 更新分页信息
                hasMoreFollowers = userListResponse.pagination.hasNext
                followersCurrentPage = page

                print("✅ 粉丝列表加载成功，当前共 \(followerUsers.count) 个用户")
            } else {
                print("❌ 粉丝列表加载失败: \(response.message ?? "未知错误")")
            }
        } catch {
            print("❌ 加载粉丝列表失败: \(error)")
        }

        isLoadingFollowers = false
    }

    // MARK: - 加载更多关注
    func loadMoreFollowing() async {
        guard let userProfile = userProfile, hasMoreFollowing, !isLoadingFollowing else { return }
        await loadFollowingUsers(userId: String(userProfile.id), page: followingCurrentPage + 1)
    }

    // MARK: - 加载更多粉丝
    func loadMoreFollowers() async {
        guard let userProfile = userProfile, hasMoreFollowers, !isLoadingFollowers else { return }
        await loadFollowerUsers(userId: String(userProfile.id), page: followersCurrentPage + 1)
    }

    // MARK: - 关注/取消关注用户
    func toggleFollowUser() async {
        guard let userProfile = userProfile else { return }

        // 防止重复操作
        guard !isFollowActionLoading else { return }

        isFollowActionLoading = true

        do {
            let response: CommunityAPIResponse<FollowResponse>

            if userProfile.safeIsFollowing {
                response = try await apiService.unfollowUser(userId: userProfile.id)
            } else {
                response = try await apiService.followUser(userId: userProfile.id)
            }

            // 检查响应状态
            if response.success {
                // 更新关注状态
                if let data = response.data {
                    self.userProfile?.isFollowing = data.isFollowing
                    if let followersCount = data.followersCount {
                        self.userProfile?.followersCount = followersCount
                    }
                } else {
                    // 如果服务器没有返回data字段，根据消息内容判断最终状态
                    if let message = response.message {
                        if message.contains("已经关注了该用户") || message.contains("关注成功") {
                            self.userProfile?.isFollowing = true
                        } else if message.contains("未关注该用户") || message.contains("没有关注该用户") || message.contains("取消关注成功") {
                            self.userProfile?.isFollowing = false
                        } else {
                            // 如果消息不明确，根据操作类型推断
                            self.userProfile?.isFollowing = !userProfile.safeIsFollowing
                        }
                    } else {
                        // 如果没有消息，根据操作类型推断
                        self.userProfile?.isFollowing = !userProfile.safeIsFollowing
                    }
                }

                // 操作成功后，重新获取最新的关注状态以确保准确性
                await refreshFollowStatus(userId: userProfile.id)

                // 根据最终状态显示消息
                if let message = response.message,
                   (message.contains("已经关注了该用户") || message.contains("未关注该用户") || message.contains("没有关注该用户") || message.contains("关注成功") || message.contains("取消关注成功")) {
                    // 显示服务器返回的具体消息
                    print("✅ 关注操作成功: \(message)")
                } else {
                    // 显示默认成功消息
                    let isFollowing = self.userProfile?.isFollowing ?? false
                    print("✅ 关注操作成功: \(isFollowing ? "关注成功" : "取消关注成功")")
                }
            } else {
                // 处理失败情况
                print("❌ 关注操作失败: \(response.message ?? "未知错误")")
            }
        } catch {
            // 由于CommunityAPIService已经处理了大部分特殊情况，这里主要处理真正的网络错误
            print("❌ 关注操作失败: \(error)")
        }

        isFollowActionLoading = false
    }

    // MARK: - 刷新关注状态
    private func refreshFollowStatus(userId: Int) async {
        do {
            let response = try await apiService.getUserProfile(userId: userId)
            if response.success, let data = response.data {
                await MainActor.run {
                    self.userProfile?.isFollowing = data.isFollowing
                    print("🔄 关注状态已刷新: \(data.isFollowing ?? false)")
                }
            }
        } catch {
            print("❌ 刷新关注状态失败: \(error)")
        }
    }

    // MARK: - 加载更多数据
    func loadMorePosts() async {
        guard let userProfile = userProfile, hasMorePosts, !isLoadingPosts else { return }
        await loadUserPosts(userId: String(userProfile.id), page: postsCurrentPage + 1)
    }

    // MARK: - 关注用户
    func followUser() async {
        guard let userProfile = userProfile else { return }

        isFollowActionLoading = true

        do {
            let response = try await apiService.followUser(userId: userProfile.id)

            if response.success {
                // 更新本地状态
                if let data = response.data {
                    self.userProfile?.isFollowing = data.isFollowing
                    if let followersCount = data.followersCount {
                        self.userProfile?.followersCount = followersCount
                    }
                } else {
                    // 如果没有返回data，根据操作类型推断状态
                    self.userProfile?.isFollowing = true
                }

                // 操作成功后，重新获取最新的关注状态以确保准确性
                await refreshFollowStatus(userId: userProfile.id)

                // 根据消息显示提示
                if let message = response.message {
                    print("✅ 关注操作成功: \(message)")
                }
            } else {
                // 处理失败情况
                let errorMsg = response.message ?? "未知错误"
                print("❌ 关注操作失败: \(errorMsg)")
                
                // 检查是否是屏蔽用户的错误
                if errorMsg.contains("无法关注已屏蔽的用户") || errorMsg.contains("屏蔽") {
                    blockedUserMessage = "您已屏蔽该用户，如需关注请先从黑名单中移除"
                    showBlockedUserAlert = true
                }
            }
        } catch {
            print("❌ 关注用户失败: \(error)")
            
            // 检查是否是 NetworkError.serverMessage
            if let networkError = error as? NetworkManager.NetworkError,
               case .serverMessage(let message) = networkError {
                print("🔍 捕获到服务器错误消息: \(message)")
                
                // 检查是否是屏蔽用户的错误
                if message.contains("无法关注已屏蔽的用户") || message.contains("屏蔽") {
                    blockedUserMessage = "您已屏蔽该用户，如需关注请先从黑名单中移除"
                    showBlockedUserAlert = true
                }
            }
        }

        isFollowActionLoading = false
    }

    // MARK: - 取消关注用户
    func unfollowUser() async {
        guard let userProfile = userProfile else { return }

        isFollowActionLoading = true

        do {
            let response = try await apiService.unfollowUser(userId: userProfile.id)

            if response.success {
                // 更新本地状态
                if let data = response.data {
                    self.userProfile?.isFollowing = data.isFollowing
                    if let followersCount = data.followersCount {
                        self.userProfile?.followersCount = followersCount
                    }
                } else {
                    // 如果没有返回data，根据操作类型推断状态
                    self.userProfile?.isFollowing = false
                }

                // 操作成功后，重新获取最新的关注状态以确保准确性
                await refreshFollowStatus(userId: userProfile.id)

                // 根据消息显示提示
                if let message = response.message {
                    print("✅ 取消关注操作成功: \(message)")
                }
            } else {
                print("❌ 取消关注操作失败: \(response.message ?? "未知错误")")
            }
        } catch {
            print("❌ 取消关注用户失败: \(error)")
        }

        isFollowActionLoading = false
    }

    // MARK: - 屏蔽用户
    func blockUser(reason: String) async {
        guard let userProfile = userProfile else { return }

        do {
            let response = try await apiService.blockUser(userId: userProfile.id, reason: reason)
            
            if response.success, let data = response.data {
                // 使用服务器返回的实际数据更新本地状态
                self.userProfile?.isBlocked = data.isBlocked
                if let isFollowing = data.isFollowing {
                    self.userProfile?.isFollowing = isFollowing
                }
                print("✅ 屏蔽用户成功 - isBlocked: \(data.isBlocked), isFollowing: \(data.isFollowing ?? false)")
                
                // 重新加载用户资料以获取最新状态
                await refreshFollowStatus(userId: userProfile.id)
            } else {
                print("❌ 屏蔽用户失败: \(response.message ?? "未知错误")")
            }
        } catch {
            print("❌ 屏蔽用户失败: \(error)")
        }
    }

    // MARK: - 取消屏蔽用户
    func unblockUser() async {
        guard let userProfile = userProfile else { return }

        do {
            let response = try await apiService.unblockUser(userId: userProfile.id)
            
            if response.success, let data = response.data {
                // 使用服务器返回的实际数据更新本地状态
                self.userProfile?.isBlocked = data.isBlocked
                print("✅ 取消屏蔽用户成功 - isBlocked: \(data.isBlocked), canFollow: \(data.canFollow ?? false)")
                
                // 重新加载用户资料以获取最新状态
                await refreshFollowStatus(userId: userProfile.id)
            } else {
                print("❌ 取消屏蔽用户失败: \(response.message ?? "未知错误")")
            }
        } catch {
            print("❌ 取消屏蔽用户失败: \(error)")
        }
    }

    // MARK: - 加载用户收藏
    func loadUserBookmarks(page: Int = 1, refresh: Bool = false) async {
        guard let userProfile = userProfile, userProfile.isMe == true else {
            print("🔍 UserProfileViewModel: 无法加载收藏，用户不是本人或用户资料为空")
            return
        }

        // 设置加载状态
        isLoadingBookmarks = true

        if page == 1 || refresh {
            bookmarkedPosts.removeAll()
            bookmarksCurrentPage = 1
            hasMoreBookmarks = true
        }

        print("🔄 开始加载用户收藏，页码: \(page)")

        do {
            let response = try await apiService.getUserBookmarks(page: page, limit: 20)

            if response.success, let data = response.data {
                if page == 1 {
                    bookmarkedPosts = data.items
                } else {
                    bookmarkedPosts.append(contentsOf: data.items)
                }

                bookmarksCurrentPage = data.pagination.page
                hasMoreBookmarks = data.pagination.hasNext

                print("✅ 成功加载用户收藏: \(data.items.count) 条")
                print("📊 收藏分页信息: 当前页 \(bookmarksCurrentPage)，是否有更多: \(hasMoreBookmarks)")
                print("📊 总收藏数: \(bookmarkedPosts.count)")
            } else {
                print("❌ 用户收藏响应失败: \(response.message ?? "未知错误")")
            }
        } catch {
            print("❌ 加载用户收藏失败: \(error)")
        }

        isLoadingBookmarks = false
        print("🔄 用户收藏加载完成，isLoadingBookmarks = false")
    }

    // MARK: - 加载更多收藏
    func loadMoreBookmarks() async {
        guard let userProfile = userProfile, hasMoreBookmarks, !isLoadingBookmarks else { return }
        await loadUserBookmarks(page: bookmarksCurrentPage + 1)
    }
}

// MARK: - UserProfile 扩展
extension UserProfile {
    // 计算属性
    var displayUsername: String {
        if let qingheId = qingheId, !qingheId.isEmpty {
            return qingheId
        }
        return "user\(id)"
    }

    var joinDateFormatted: String {
        guard let createdAt = createdAt else { return "加入时间未知" }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年M月"
            return "加入时间 \(displayFormatter.string(from: date))"
        }

        return "加入时间未知"
    }

    var safeFollowersCount: Int {
        return followersCount ?? 0
    }

    var safeFollowingCount: Int {
        return followingCount ?? 0
    }

    var safePostsCount: Int {
        return postsCount ?? 0
    }

    var safeIsVerified: Bool {
        return isVerified ?? false
    }

    var safeIsFollowing: Bool {
        return isFollowing ?? false
    }

    var safeIsFollowedBy: Bool {
        return isFollowedBy ?? false
    }

    var safeIsBlocked: Bool {
        return isBlocked ?? false
    }

    var safeIsMe: Bool {
        return isMe ?? false
    }
}

// MARK: - Tab枚举
enum ProfileTab: String, CaseIterable {
    case posts = "帖子"
    case bookmarks = "收藏"

    var systemImage: String {
        switch self {
        case .posts: return "doc.text"
        case .bookmarks: return "bookmark"
        }
    }
}

// MARK: - 空响应模型
struct EmptyResponse: Codable {}
