import Foundation
import UserNotifications
import UIKit

/// 推送通知管理器
@MainActor
class PushNotificationManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = PushNotificationManager()
    
    // MARK: - Published Properties
    @Published var isNotificationEnabled = false
    @Published var deviceToken: String?
    @Published var badgeCount = 0
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let deviceTokenKey = "device_token"
    private let notificationEnabledKey = "notification_enabled"
    private let badgeCountKey = "badge_count"
    
    // MARK: - Initialization
    private override init() {
        super.init()
        loadStoredSettings()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Public Methods
    
    /// 请求推送通知权限
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            isNotificationEnabled = granted
            userDefaults.set(granted, forKey: notificationEnabledKey)
            
            if granted {
                // 在主线程注册远程通知
                await UIApplication.shared.registerForRemoteNotifications()
                print("🔔 推送通知权限已授予")
            } else {
                print("🔔 推送通知权限被拒绝")
            }
            
            return granted
        } catch {
            print("🔔 请求推送通知权限失败: \(error)")
            return false
        }
    }
    
    /// 检查当前通知权限状态
    func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        let enabled = settings.authorizationStatus == .authorized
        isNotificationEnabled = enabled
        userDefaults.set(enabled, forKey: notificationEnabledKey)
        
        print("🔔 当前通知权限状态: \(enabled ? "已授权" : "未授权")")
    }
    
    /// 处理设备Token注册成功
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString
        userDefaults.set(tokenString, forKey: deviceTokenKey)
        
        print("🔔 设备Token注册成功: \(tokenString)")
        
        // 上传设备Token到服务器
        Task {
            await uploadDeviceToken(tokenString)
        }
    }
    
    /// 处理设备Token注册失败
    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        print("🔔 设备Token注册失败: \(error)")
    }
    
    /// 处理远程推送通知
    func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        print("🔔 收到远程推送通知: \(userInfo)")
        
        // 解析推送通知数据
        guard let notificationData = parseNotificationData(userInfo) else {
            return .noData
        }
        
        // 处理不同类型的通知
        switch notificationData.type {
        case .newMessage:
            await handleNewMessageNotification(notificationData)
        case .systemNotification:
            await handleSystemNotification(notificationData)
        case .friendRequest:
            await handleFriendRequestNotification(notificationData)
        }
        
        // 更新角标
        await updateBadgeCount()
        
        return .newData
    }
    
    /// 更新应用角标数字
    func updateBadgeCount() async {
        // 获取未读消息总数
        let unreadCount = await getUnreadMessageCount()
        
        badgeCount = unreadCount
        userDefaults.set(unreadCount, forKey: badgeCountKey)
        
        // 更新应用角标
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(unreadCount)
        } catch {
            print("🔔 更新角标失败: \(error)")
        }
        
        print("🔔 更新应用角标: \(unreadCount)")
    }
    
    /// 清除应用角标
    func clearBadge() async {
        badgeCount = 0
        userDefaults.set(0, forKey: badgeCountKey)
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(0)
        } catch {
            print("🔔 清除角标失败: \(error)")
        }
        print("🔔 清除应用角标")
    }
    
    /// 创建本地通知
    func scheduleLocalNotification(title: String, body: String, userInfo: [String: Any] = [:]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("🔔 本地通知创建失败: \(error)")
            } else {
                print("🔔 本地通知已创建")
            }
        }
    }

    /// 测试推送通知功能
    func testPushNotification() {
        print("🔔 开始测试推送通知功能")

        // 1. 检查权限状态
        Task {
            await checkNotificationPermission()
            print("🔔 通知权限状态: \(isNotificationEnabled)")

            // 2. 检查设备Token
            if let token = deviceToken {
                print("🔔 设备Token: \(token)")
            } else {
                print("🔔 设备Token未获取")
            }

            // 3. 发送测试本地通知
            scheduleLocalNotification(
                title: "测试通知",
                body: "这是一条测试推送通知",
                userInfo: [
                    "type": "test",
                    "conversationId": "test-conversation",
                    "messageId": "test-message"
                ]
            )

            // 4. 模拟远程推送通知
            let testUserInfo: [AnyHashable: Any] = [
                "aps": [
                    "alert": [
                        "title": "新消息",
                        "body": "您收到了一条新消息"
                    ],
                    "badge": 1,
                    "sound": "default"
                ],
                "type": "new_message",
                "conversationId": "test-conversation",
                "messageId": "test-message",
                "senderId": 123
            ]

            print("🔔 模拟处理远程推送通知")
            _ = await didReceiveRemoteNotification(testUserInfo)
        }
    }
    
    // MARK: - Private Methods
    
    /// 加载存储的设置
    private func loadStoredSettings() {
        isNotificationEnabled = userDefaults.bool(forKey: notificationEnabledKey)
        deviceToken = userDefaults.string(forKey: deviceTokenKey)
        badgeCount = userDefaults.integer(forKey: badgeCountKey)
    }
    
    /// 上传设备Token到服务器
    private func uploadDeviceToken(_ token: String) async {
        guard AuthManager.shared.isAuthenticated else {
            print("🔔 用户未登录，跳过设备Token上传")
            return
        }
        
        do {
            try await ChatAPIService.shared.uploadDeviceToken(token)
            print("🔔 设备Token上传成功")
        } catch {
            print("🔔 设备Token上传失败: \(error)")
        }
    }
    
    /// 解析推送通知数据
    private func parseNotificationData(_ userInfo: [AnyHashable: Any]) -> NotificationData? {
        guard let aps = userInfo["aps"] as? [String: Any],
              let alert = aps["alert"] as? [String: Any],
              let title = alert["title"] as? String,
              let body = alert["body"] as? String else {
            return nil
        }
        
        let typeString = userInfo["type"] as? String ?? "system"
        let type = NotificationType(rawValue: typeString) ?? .systemNotification
        
        return NotificationData(
            type: type,
            title: title,
            body: body,
            conversationId: userInfo["conversationId"] as? String,
            messageId: userInfo["messageId"] as? String,
            senderId: userInfo["senderId"] as? Int,
            userInfo: userInfo
        )
    }
    
    /// 处理新消息通知
    private func handleNewMessageNotification(_ data: NotificationData) async {
        guard let conversationId = data.conversationId else { return }
        
        // 如果当前正在查看该对话，标记为已读
        if let currentConversationId = getCurrentConversationId(),
           currentConversationId == conversationId {
            await markConversationAsRead(conversationId)
        }
        
        // 通知聊天列表更新
        NotificationCenter.default.post(
            name: .pushNotificationReceived,
            object: data
        )
    }
    
    /// 处理系统通知
    private func handleSystemNotification(_ data: NotificationData) async {
        // 处理系统通知逻辑
        print("🔔 处理系统通知: \(data.title)")
    }
    
    /// 处理好友请求通知
    private func handleFriendRequestNotification(_ data: NotificationData) async {
        // 处理好友请求通知逻辑
        print("🔔 处理好友请求通知: \(data.title)")
    }
    
    /// 获取当前正在查看的对话ID
    func getCurrentConversationId() -> String? {
        // 从UserDefaults获取当前正在查看的对话ID
        return UserDefaults.standard.string(forKey: "current_conversation_id")
    }

    /// 设置当前正在查看的对话ID
    func setCurrentConversationId(_ conversationId: String?) {
        if let conversationId = conversationId {
            UserDefaults.standard.set(conversationId, forKey: "current_conversation_id")
        } else {
            UserDefaults.standard.removeObject(forKey: "current_conversation_id")
        }
    }
    
    /// 标记对话为已读
    private func markConversationAsRead(_ conversationId: String) async {
        do {
            try await ChatAPIService.shared.markConversationAsRead(conversationId: conversationId)
        } catch {
            print("🔔 标记对话已读失败: \(error)")
        }
    }
    
    /// 获取未读消息总数
    private func getUnreadMessageCount() async -> Int {
        do {
            let conversations = try await ChatAPIService.shared.getConversations(tab: "unread", page: 1, limit: 100)
            return conversations.items.reduce(0) { $0 + ($1.unreadCount ?? 0) }
        } catch {
            print("🔔 获取未读消息数失败: \(error)")
            return 0
        }
    }
}

// MARK: - Data Models

/// 通知类型
enum NotificationType: String, CaseIterable {
    case newMessage = "new_message"
    case systemNotification = "system"
    case friendRequest = "friend_request"
}

/// 通知数据
struct NotificationData {
    let type: NotificationType
    let title: String
    let body: String
    let conversationId: String?
    let messageId: String?
    let senderId: Int?
    let userInfo: [AnyHashable: Any]
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: @preconcurrency UNUserNotificationCenterDelegate {

    /// 应用在前台时收到通知
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 前台收到通知: \(notification.request.content.title)")

        // 解析通知数据
        let userInfo = notification.request.content.userInfo

        // 检查是否是聊天消息通知
        if let conversationId = userInfo["conversationId"] as? String {
            // 如果当前正在查看该对话，不显示通知横幅，只播放声音和更新角标
            Task {
                let currentConversationId = await getCurrentConversationId()
                if currentConversationId == conversationId {
                    // 当前正在查看该对话，只播放声音和更新角标
                    completionHandler([.sound, .badge])
                } else {
                    // 不在当前对话，显示完整通知
                    completionHandler([.banner, .sound, .badge])
                }

                // 处理通知数据
                _ = await didReceiveRemoteNotification(userInfo)
            }
        } else {
            // 非聊天消息，显示完整通知
            completionHandler([.banner, .sound, .badge])

            // 处理通知数据
            Task {
                _ = await didReceiveRemoteNotification(userInfo)
            }
        }
    }

    /// 用户点击通知
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("🔔 用户点击通知: \(response.notification.request.content.title)")

        let userInfo = response.notification.request.content.userInfo

        // 处理通知点击
        Task {
            await handleNotificationTap(userInfo)
        }

        completionHandler()
    }

    /// 处理通知点击事件（公开方法，供 AppDelegate 调用）
    func handleNotificationTap(_ userInfo: [AnyHashable: Any]) async {
        guard let notificationData = parseNotificationData(userInfo) else { return }

        switch notificationData.type {
        case .newMessage:
            if let conversationId = notificationData.conversationId {
                // 跳转到对应的聊天页面
                await navigateToConversation(conversationId)
            }
        case .systemNotification:
            // 跳转到系统通知页面
            await navigateToSystemNotifications()
        case .friendRequest:
            // 跳转到好友请求页面
            await navigateToFriendRequests()
        }

        // 更新角标
        await updateBadgeCount()
    }

    /// 导航到指定对话
    private func navigateToConversation(_ conversationId: String) async {
        // 发送导航通知
        NotificationCenter.default.post(
            name: .openConversation,
            object: conversationId
        )
    }

    /// 导航到系统通知
    private func navigateToSystemNotifications() async {
        // 发送导航通知
        NotificationCenter.default.post(
            name: .pushNotificationReceived,
            object: "systemNotifications"
        )
    }

    /// 导航到好友请求
    private func navigateToFriendRequests() async {
        // 发送导航通知
        NotificationCenter.default.post(
            name: .pushNotificationReceived,
            object: "friendRequests"
        )
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let pushNotificationReceived = Notification.Name("PushNotificationReceived")
    static let badgeCountUpdated = Notification.Name("BadgeCountUpdated")
}
