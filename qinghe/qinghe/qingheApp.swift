import SwiftUI

// MARK: - AppDelegate for handling push notifications
class AppDelegate: NSObject, UIApplicationDelegate {
    // 提供全局可访问的共享实例，便于在 SwiftUI 视图中引用
    static weak var shared: AppDelegate?
    // 控制全局方向的开关（需确保工程允许横屏）
    @objc dynamic var orientationMask: UIInterfaceOrientationMask = .portrait

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("🔔 AppDelegate: 应用启动完成")

        // 设置推送通知代理
        UNUserNotificationCenter.current().delegate = PushNotificationManager.shared

        // 开启远程控制事件，确保锁屏/控制中心的播放命令能回调
        UIApplication.shared.beginReceivingRemoteControlEvents()

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

    // 限制支持的方向（受工程设置影响）
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        orientationMask
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

    init() {
        // 临时代码：打印所有可用字体名称（用于获取自定义字体的PostScript名）
        DispatchQueue.main.async {
            print("=== 所有可用字体 ===")
            for family in UIFont.familyNames.sorted() {
                print("字体家族: \(family)")
                for name in UIFont.fontNames(forFamilyName: family).sorted() {
                    print("  PostScript名: \(name)")
                }
            }
        }
    }

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

                // 仅在正在追踪睡眠时发送睡眠追踪前台通知，避免无关日志与处理
                if SleepDataManager.shared.isTrackingSleep {
                    print("📱 应用进入前台（正在追踪睡眠），发送睡眠追踪通知")
                    NotificationCenter.default.post(name: .sleepTrackingWillEnterForeground, object: nil)
                } else {
                    // 非睡眠追踪场景下避免触发 SleepDataManager 流程
                    // print("📱 应用进入前台（非睡眠追踪），略过睡眠通知")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                // 应用进入后台时，保持连接以接收推送通知
                print("应用进入后台，WebSocket保持连接")

                // 仅在正在追踪睡眠时发送睡眠追踪后台通知
                if SleepDataManager.shared.isTrackingSleep {
                    print("📱 应用进入后台（正在追踪睡眠），发送睡眠追踪通知")
                    NotificationCenter.default.post(name: .sleepTrackingDidEnterBackground, object: nil)
                } else {
                    // print("📱 应用进入后台（非睡眠追踪），略过睡眠通知")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                // 仅在正在追踪睡眠时发送睡眠追踪终止通知
                if SleepDataManager.shared.isTrackingSleep {
                    print("📱 应用即将终止（正在追踪睡眠），发送睡眠追踪终止通知")
                    NotificationCenter.default.post(name: .sleepTrackingWillTerminate, object: nil)
                }
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
