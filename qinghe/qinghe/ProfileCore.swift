import SwiftUI
import Foundation

// MARK: - Profile模块核心定义

/// 用户资料页面状态管理
@MainActor
class ProfileViewState: ObservableObject {
    @Published var selectedTab: ProfileTab = .posts
    @Published var scrollOffset: CGFloat = 0
    @Published var showNavTitle: Bool = false
    @Published var showStickyTabs: Bool = false
    
    // 交互状态
    @Published var showFollowersList = false
    @Published var showFollowingList = false
    @Published var showEditProfile = false
    @Published var showMoreOptions = false
    @Published var showBlockConfirmation = false
    
    // 导航状态
    @Published var navigationPath = NavigationPath()
    @Published var selectedPostId: String?
    @Published var showingChatDetail = false
    @Published var createdConversation: ChatConversation?
    
    // 计算属性
    var shouldShowStickyTabs: Bool {
        scrollOffset <= -200
    }
    
    var shouldShowNavTitle: Bool {
        scrollOffset <= -100
    }
    
    func updateScrollOffset(_ offset: CGFloat) {
        scrollOffset = offset
        showStickyTabs = shouldShowStickyTabs
        showNavTitle = shouldShowNavTitle
    }
}

/// 用户资料模块常量
struct ProfileConstants {
    
    struct Layout {
        static let headerHeight: CGFloat = 200
        static let avatarSize: CGFloat = 80
        static let tabBarHeight: CGFloat = 44
        static let stickyThreshold: CGFloat = -200
        static let titleThreshold: CGFloat = -100
    }
    
    struct Animation {
        static let springResponse: Double = 0.4
        static let springDamping: Double = 0.8
        static let standardDuration: Double = 0.25
    }
    
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
    }
}

/// 用户资料协调器 - 管理页面间的导航和交互
@MainActor
class ProfileCoordinator: ObservableObject {
    @Published var currentUserId: String
    @Published var viewState = ProfileViewState()
    
    private let profileService: ProfileServiceProtocol
    private let interactionService: ProfileInteractionServiceProtocol
    
    init(
        userId: String,
        profileService: ProfileServiceProtocol = ProfileService.shared,
        interactionService: ProfileInteractionServiceProtocol = ProfileInteractionService.shared
    ) {
        self.currentUserId = userId
        self.profileService = profileService
        self.interactionService = interactionService
    }
    
    // MARK: - Navigation Methods
    
    func navigateToPost(_ postId: String) {
        viewState.selectedPostId = postId
        viewState.navigationPath.append(postId)
    }
    
    func navigateToFollowersList() {
        viewState.showFollowersList = true
    }
    
    func navigateToFollowingList() {
        viewState.showFollowingList = true
    }
    
    func navigateToEditProfile() {
        viewState.showEditProfile = true
    }
    
    func navigateToChat(with conversation: ChatConversation) {
        viewState.createdConversation = conversation
        viewState.showingChatDetail = true
    }
    
    // MARK: - State Management
    
    func switchTab(to tab: ProfileTab) {
        withAnimation(.easeInOut(duration: ProfileConstants.Animation.standardDuration)) {
            viewState.selectedTab = tab
        }
    }
    
    func updateScrollPosition(_ offset: CGFloat) {
        viewState.updateScrollOffset(offset)
    }
}

// MARK: - Profile Service Protocols

protocol ProfileServiceProtocol {
    func loadUserProfile(userId: String) async throws -> UserProfile
    func loadUserPosts(userId: String, page: Int) async throws -> [Post]
    func loadUserBookmarks(page: Int) async throws -> [Post]
}

protocol ProfileInteractionServiceProtocol {
    func followUser(_ userId: Int) async throws -> FollowResponse
    func unfollowUser(_ userId: Int) async throws -> FollowResponse
    func blockUser(_ userId: Int) async throws
    func unblockUser(_ userId: Int) async throws
    func createChat(with userId: Int) async throws -> ChatConversation
}

// MARK: - Profile Service Implementation

class ProfileService: ProfileServiceProtocol {
    static let shared = ProfileService()
    private init() {}
    
    func loadUserProfile(userId: String) async throws -> UserProfile {
        let response = try await CommunityAPIService.shared.getUserProfile(userId: Int(userId) ?? 0)
        
        guard response.success, let userProfile = response.data else {
            throw ProfileError.loadFailed(response.message ?? "加载失败")
        }
        
        return userProfile
    }
    
    func loadUserPosts(userId: String, page: Int) async throws -> [Post] {
        let response = try await CommunityAPIService.shared.getUserPosts(userId: Int(userId) ?? 0, page: page, limit: 10)
        
        guard response.success, let posts = response.data?.items else {
            throw ProfileError.loadFailed(response.message ?? "加载帖子失败")
        }
        
        return posts
    }
    
    func loadUserBookmarks(page: Int) async throws -> [Post] {
        let response = try await CommunityAPIService.shared.getUserBookmarks(page: page, limit: 10)
        
        guard response.success, let posts = response.data?.items else {
            throw ProfileError.loadFailed(response.message ?? "加载收藏失败")
        }
        
        return posts
    }
}

// MARK: - Profile Interaction Service Implementation

class ProfileInteractionService: ProfileInteractionServiceProtocol {
    static let shared = ProfileInteractionService()
    private init() {}
    
    func followUser(_ userId: Int) async throws -> FollowResponse {
        let response = try await CommunityAPIService.shared.followUser(userId: userId)
        
        guard response.success, let data = response.data else {
            throw ProfileError.interactionFailed(response.message ?? "关注失败")
        }
        
        return data
    }
    
    func unfollowUser(_ userId: Int) async throws -> FollowResponse {
        let response = try await CommunityAPIService.shared.unfollowUser(userId: userId)
        
        guard response.success, let data = response.data else {
            throw ProfileError.interactionFailed(response.message ?? "取消关注失败")
        }
        
        return data
    }
    
    func blockUser(_ userId: Int) async throws {
        let response = try await CommunityAPIService.shared.blockUser(userId: userId, reason: "用户举报")
        
        guard response.success else {
            throw ProfileError.interactionFailed(response.message ?? "屏蔽失败")
        }
    }
    
    func unblockUser(_ userId: Int) async throws {
        let response = try await CommunityAPIService.shared.unblockUser(userId: userId)
        
        guard response.success else {
            throw ProfileError.interactionFailed(response.message ?? "取消屏蔽失败")
        }
    }
    
    func createChat(with userId: Int) async throws -> ChatConversation {
        return try await ChatAPIService.shared.createPrivateChat(recipientId: userId)
    }
}

// MARK: - Error Types

enum ProfileError: LocalizedError {
    case loadFailed(String)
    case interactionFailed(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .loadFailed(let message):
            return message
        case .interactionFailed(let message):
            return message
        case .networkError:
            return "网络连接失败"
        }
    }
}