import SwiftUI

// MARK: - AppDelegate for handling push notifications
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("🔔 AppDelegate: 应用启动完成")

        // 设置推送通知代理
        UNUserNotificationCenter.current().delegate = PushNotificationManager.shared

        // 检查是否通过推送通知启动
        if let notificationUserInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            print("🔔 AppDelegate: 通过推送通知启动应用")
            // 延迟处理推送通知，确保应用完全启动
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                Task {
                    await PushNotificationManager.shared.handleNotificationTap(notificationUserInfo)
                }
            }
        }

        return true
    }

    @objc func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("🔔 AppDelegate: 设备Token注册成功")
        Task {
            await PushNotificationManager.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        }
    }

    @objc func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("🔔 AppDelegate: 设备Token注册失败: \(error)")
        Task {
            await PushNotificationManager.shared.didFailToRegisterForRemoteNotifications(withError: error)
        }
    }

    @objc func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("🔔 AppDelegate: 收到远程推送通知")
        Task {
            let result = await PushNotificationManager.shared.didReceiveRemoteNotification(userInfo)
            completionHandler(result)
        }
    }
}

@main
struct qingheApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showSplash = true
    @State private var showSplashAd = false
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var sideMenuManager = SideMenuManager()
    @StateObject private var webSocketManager = WebSocketManager.shared
    @StateObject private var pushNotificationManager = PushNotificationManager.shared
    @StateObject private var locationManager = AppleMapService.shared
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            showSplash = false
                            showSplashAd = true
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))
                } else if showSplashAd {
                    SplashAdView {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            showSplashAd = false
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity
                    ))
                } else if authManager.isAuthenticated {
                    MainTabView()
                        .environmentObject(sideMenuManager)
                        .environmentObject(themeManager)
                        .preferredColorScheme(themeManager.currentColorScheme)
                } else {
                    LoginView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            // 登录成功后会自动更新 authManager.isAuthenticated
                        }
                    }
                }
            }
            .onAppear {
                // 应用启动时检查认证状态
                authManager.checkAuthenticationStatus()

                // 初始化定位服务
                print("🛰️ 初始化定位服务")
                locationManager.requestLocationPermission()

                // 初始化推送通知
                Task {
                    await pushNotificationManager.checkNotificationPermission()

                    // 如果用户已认证，请求推送通知权限
                    if authManager.isAuthenticated {
                        _ = await pushNotificationManager.requestNotificationPermission()
                        await webSocketManager.connect()
                        await pushNotificationManager.updateBadgeCount()
                    }
                }
            }
            .onChange(of: authManager.isAuthenticated) { isAuthenticated in
                // 监听认证状态变化
                if isAuthenticated {
                    // 用户登录成功，连接WebSocket并请求推送权限
                    Task {
                        await webSocketManager.connect()
                        _ = await pushNotificationManager.requestNotificationPermission()
                        await pushNotificationManager.updateBadgeCount()
                    }
                } else {
                    // 用户登出，断开WebSocket并清除角标
                    Task {
                        await webSocketManager.disconnect()
                        await pushNotificationManager.clearBadge()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // 应用进入前台时，检查并重连WebSocket，更新角标
                if authManager.isAuthenticated {
                    Task {
                        if !webSocketManager.isConnected {
                            await webSocketManager.connect()
                        }
                        await pushNotificationManager.updateBadgeCount()
                    }
                }

                // 发送睡眠追踪前台通知
                print("📱 应用进入前台，发送睡眠追踪通知")
                NotificationCenter.default.post(name: .sleepTrackingWillEnterForeground, object: nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                // 应用进入后台时，保持连接以接收推送通知
                print("应用进入后台，WebSocket保持连接")

                // 发送睡眠追踪后台通知
                print("📱 应用进入后台，发送睡眠追踪通知")
                NotificationCenter.default.post(name: .sleepTrackingDidEnterBackground, object: nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                // 应用即将终止时，发送睡眠追踪终止通知
                print("📱 应用即将终止，发送睡眠追踪终止通知")
                NotificationCenter.default.post(name: .sleepTrackingWillTerminate, object: nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openConversation)) { notification in
                // 处理推送通知点击跳转到对话
                if let conversationId = notification.object as? String {
                    handleNavigateToConversation(conversationId)
                }
            }
        }
    }

    // MARK: - Private Methods

    /// 处理导航到对话
    private func handleNavigateToConversation(_ conversationId: String) {
        // 这里可以实现导航逻辑
        // 例如：设置当前选中的对话ID，触发导航
        print("🔔 导航到对话: \(conversationId)")

        // 可以通过环境变量或其他方式传递给视图
        // 暂时通过通知的方式处理
        NotificationCenter.default.post(
            name: .openConversation,
            object: conversationId
        )
    }
}



// MARK: - Notification Extensions

extension Notification.Name {
    static let openConversation = Notification.Name("OpenConversation")
}
