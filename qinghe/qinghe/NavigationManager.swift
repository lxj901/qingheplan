import Foundation
import SwiftUI

/// 导航管理器 - 处理应用内的跨页面导航
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab: MainTab = .home
    
    private init() {}
    
    // MARK: - 通知相关导航
    
    /// 导航到帖子详情页（支持字符串ID）
    func navigateToPost(id: String, highlightSection: String? = nil, highlightUserId: String? = nil) {
        // 切换到社区Tab
        selectedTab = .community
        
        // 发送导航通知
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var userInfo: [String: Any] = ["postId": id]
            if let section = highlightSection {
                userInfo["highlightSection"] = section
            }
            if let userId = highlightUserId {
                userInfo["highlightUserId"] = userId
            }
            
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToPost"),
                object: nil,
                userInfo: userInfo
            )
        }
    }
    
    /// 导航到帖子详情页（支持Int ID，用于兼容）
    func navigateToPost(id: Int, highlightSection: String? = nil, highlightUserId: String? = nil) {
        navigateToPost(id: String(id), highlightSection: highlightSection, highlightUserId: highlightUserId)
    }
    
    /// 导航到用户资料页
    func navigateToProfile(userId: Int) {
        // 发送导航通知
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToUserProfile"),
            object: nil,
            userInfo: ["userId": "\(userId)"]
        )
    }
    
    /// 导航到评论详情（支持字符串ID）
    func navigateToComment(postId: String, commentId: String) {
        // 先导航到帖子详情，然后定位到特定评论
        navigateToPost(id: postId)
        
        // 延迟发送评论定位通知
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: NSNotification.Name("ScrollToComment"),
                object: nil,
                userInfo: ["commentId": commentId]
            )
        }
    }
    
    /// 导航到评论详情（支持Int ID，用于兼容）
    func navigateToComment(postId: Int, commentId: Int) {
        navigateToComment(postId: String(postId), commentId: String(commentId))
    }
    
    /// 导航到聊天页面
    func navigateToChat(userId: Int) {
        // 切换到消息Tab
        selectedTab = .messages
        
        // 发送导航通知
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToChat"),
                object: nil,
                userInfo: ["userId": userId]
            )
        }
    }
    
    // MARK: - Tab切换
    
    /// 切换到指定Tab
    func switchToTab(_ tab: MainTab) {
        selectedTab = tab
    }
    
    /// 切换到首页
    func switchToHome() {
        selectedTab = .home
    }

    /// 切换到新首页
    func switchToNewHome() {
        selectedTab = .newHome
    }

    /// 切换到社区
    func switchToCommunity() {
        selectedTab = .community
    }
    
    /// 切换到消息
    func switchToMessages() {
        selectedTab = .messages
    }
    
    /// 切换到个人资料
    func switchToProfile() {
        selectedTab = .profile
    }

    /// 切换到书斋
    func switchToLibrary() {
        selectedTab = .library
    }
}

// MARK: - 通知名称扩展
extension NSNotification.Name {
    static let navigateToPost = NSNotification.Name("NavigateToPost")
    static let navigateToUserProfile = NSNotification.Name("NavigateToUserProfile")
    static let navigateToChat = NSNotification.Name("NavigateToChat")
    static let scrollToComment = NSNotification.Name("ScrollToComment")
    static let notificationTapped = NSNotification.Name("notificationTapped")
    static let openNewChat = NSNotification.Name("OpenNewChat")
}

// MARK: - 导航辅助视图修饰符
struct NavigationHandlerModifier: ViewModifier {
    @StateObject private var navigationManager = NavigationManager.shared
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .navigateToPost)) { notification in
                if let postId = notification.userInfo?["postId"] as? Int {
                    handlePostNavigation(postId: postId)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToUserProfile)) { notification in
                if let userId = notification.userInfo?["userId"] as? String {
                    handleProfileNavigation(userId: userId)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToChat)) { notification in
                if let userId = notification.userInfo?["userId"] as? Int {
                    handleChatNavigation(userId: userId)
                }
            }
    }
    
    private func handlePostNavigation(postId: Int) {
        print("🔍 导航到帖子详情: \(postId)")
        // 这里可以添加具体的导航逻辑
    }
    
    private func handleProfileNavigation(userId: String) {
        print("🔍 导航到用户资料: \(userId)")
        // 这里可以添加具体的导航逻辑
    }
    
    private func handleChatNavigation(userId: Int) {
        print("🔍 导航到聊天页面: \(userId)")
        // 这里可以添加具体的导航逻辑
    }
}

// MARK: - View扩展
extension View {
    /// 添加导航处理器
    func withNavigationHandler() -> some View {
        self.modifier(NavigationHandlerModifier())
    }
}

// MARK: - MainTab枚举在MainTabView.swift中定义
