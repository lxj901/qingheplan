import SwiftUI

// MARK: - Tab栏可见性管理器
class TabBarVisibilityManager: ObservableObject {
    static let shared = TabBarVisibilityManager()

    @Published var isTabBarVisible: Bool = true
    private var subViewCount: Int = 0 // 追踪当前子页面数量

    private init() {} // 防止外部创建实例

    /// 显示Tab栏（仅在主页面显示）
    func showTabBar() {
        DispatchQueue.main.async {
            self.isTabBarVisible = true
            print("📱 TabBar: 显示")
        }
    }

    /// 隐藏Tab栏（所有非主页面都隐藏）
    func hideTabBar() {
        DispatchQueue.main.async {
            self.isTabBarVisible = false
            print("📱 TabBar: 隐藏")
        }
    }

    /// 子页面出现
    func subViewDidAppear() {
        DispatchQueue.main.async {
            self.subViewCount += 1
            self.isTabBarVisible = false
            print("📱 TabBar: 子页面出现，当前子页面数量: \(self.subViewCount)")
        }
    }

    /// 子页面消失
    func subViewDidDisappear() {
        DispatchQueue.main.async {
            self.subViewCount = max(0, self.subViewCount - 1)
            print("📱 TabBar: 子页面消失，当前子页面数量: \(self.subViewCount)")

            // 只有当所有子页面都消失时才显示Tab栏
            if self.subViewCount == 0 {
                self.isTabBarVisible = true
                print("📱 TabBar: 所有子页面已消失，恢复显示")
            }
        }
    }

    /// 强制重置（用于Tab切换时）
    func resetSubViewCount() {
        DispatchQueue.main.async {
            self.subViewCount = 0
            self.isTabBarVisible = true
            print("📱 TabBar: 重置子页面计数")
        }
    }
}

// MARK: - 主标签页视图
struct MainTabView: View {
    @StateObject private var navigationManager = NavigationManager.shared
    @ObservedObject private var tabBarManager = TabBarVisibilityManager.shared

    private var selectedTab: Binding<MainTab> {
        Binding(
            get: { navigationManager.selectedTab },
            set: { navigationManager.selectedTab = $0 }
        )
    }

    var body: some View {
        ZStack {
            // TabView 内容
            TabView(selection: selectedTab) {
                // 首页
                NewMainHomeView()
                    .tabItem {
                        Image(systemName: navigationManager.selectedTab == .home ? "house.fill" : "house")
                        Text("首页")
                    }
                    .tag(MainTab.home)

                // 社区
                MainCommunityView()
                    .tabItem {
                        Image(systemName: navigationManager.selectedTab == .community ? "person.3.fill" : "person.3")
                        Text("社区")
                    }
                    .tag(MainTab.community)

                // 消息
                MessagesView()
                    .tabItem {
                        Image(systemName: navigationManager.selectedTab == .messages ? "message.fill" : "message")
                        Text("消息")
                    }
                    .tag(MainTab.messages)

                // 我的
                ProfileView()
                    .tabItem {
                        Image(systemName: navigationManager.selectedTab == .profile ? "person.fill" : "person")
                        Text("我的")
                        }
                    .tag(MainTab.profile)
            }
            .accentColor(.blue)
            .environmentObject(tabBarManager)

            // 自定义 TabBar（只在主页面显示）
            if tabBarManager.isTabBarVisible {
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: selectedTab, tabBarManager: tabBarManager)
                }
            }
        }
        .onAppear {
            // 隐藏系统默认的 TabBar
            UITabBar.appearance().isHidden = true
            // 确保初始状态下Tab栏是显示的
            tabBarManager.showTabBar()
        }
        .onChange(of: navigationManager.selectedTab) { _, _ in
            // 当用户切换Tab时，重置子页面计数并显示Tab栏
            tabBarManager.resetSubViewCount()
        }
        .withNavigationHandler()
    }
}

// MARK: - 自定义 TabBar
struct CustomTabBar: View {
    @Binding var selectedTab: MainTab
    @ObservedObject var tabBarManager: TabBarVisibilityManager

    var body: some View {
        HStack {
            ForEach(MainTab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    selectedTab: $selectedTab,
                    isSelected: selectedTab == tab
                )
            }
        }
        .padding(.horizontal)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .ignoresSafeArea(edges: .bottom) // 背景延伸到底部
        )
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
        .opacity(tabBarManager.isTabBarVisible ? 1 : 0)
        .offset(y: tabBarManager.isTabBarVisible ? 0 : 100)
        .animation(.easeInOut(duration: 0.3), value: tabBarManager.isTabBarVisible)
    }
}

// MARK: - TabBar 按钮
struct TabBarButton: View {
    let tab: MainTab
    @Binding var selectedTab: MainTab
    let isSelected: Bool
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some View {
        Button(action: {
            selectedTab = tab
            // 用户点击Tab按钮时，强制显示Tab栏
            TabBarVisibilityManager.shared.showTabBar()
        }) {
            VStack(spacing: 2) {
                ZStack {
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.textSecondary)

                    // 消息Tab的通知角标
                    if tab == .messages && notificationManager.unreadCount > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 14, height: 14)

                            Text("\(notificationManager.unreadCount > 99 ? "99+" : "\(notificationManager.unreadCount)")")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 10, y: -8)
                    }
                }
                .frame(height: 24)

                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 主标签页枚举
enum MainTab: String, CaseIterable {
    case home = "home"
    case community = "community"
    case messages = "messages"
    case profile = "profile"

    var title: String {
        switch self {
        case .home: return "首页"
        case .community: return "社区"
        case .messages: return "消息"
        case .profile: return "我的"
        }
    }

    var icon: String {
        switch self {
        case .home: return "leaf"
        case .community: return "person.2"
        case .messages: return "bubble.left"
        case .profile: return "person.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "leaf.fill"
        case .community: return "person.2.fill"
        case .messages: return "bubble.left.fill"
        case .profile: return "person.circle.fill"
        }
    }
}

// MARK: - View扩展，用于控制Tab栏显示
extension View {
    /// 标记为主页面（显示Tab栏）- 只有4个主页面使用
    func asRootView() -> some View {
        self.modifier(TabBarVisibilityModifier(shouldShow: true))
    }

    /// 标记为子页面（隐藏Tab栏）- 所有其他页面使用
    func asSubView() -> some View {
        self.modifier(TabBarVisibilityModifier(shouldShow: false))
    }
}

// MARK: - Tab栏可见性修饰符
struct TabBarVisibilityModifier: ViewModifier {
    let shouldShow: Bool

    func body(content: Content) -> some View {
        content
            .onAppear {
                let tabBarManager = TabBarVisibilityManager.shared
                if shouldShow {
                    // 主页面显示Tab栏，重置子页面计数
                    tabBarManager.resetSubViewCount()
                    print("📱 TabBarVisibilityModifier: 主页面出现 - 显示Tab栏")
                } else {
                    // 子页面隐藏Tab栏，增加子页面计数
                    tabBarManager.subViewDidAppear()
                    print("📱 TabBarVisibilityModifier: 子页面出现 - 隐藏Tab栏")
                }
            }
            .onDisappear {
                if !shouldShow {
                    // 子页面消失时，减少子页面计数
                    let tabBarManager = TabBarVisibilityManager.shared
                    tabBarManager.subViewDidDisappear()
                    print("📱 TabBarVisibilityModifier: 子页面消失")
                }
            }
    }
}

// MARK: - 个人资料页面
struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        NavigationStack {
            if let currentUser = authManager.currentUser {
                // 直接使用 UserProfileView 显示当前用户的资料，标记为个人中心
                UserProfileView(userId: String(currentUser.id), isRootView: true, isPersonalCenter: true)
            } else {
                // 未登录状态
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "person.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)

                    Text("未登录")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text("请先登录以查看个人资料")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .navigationTitle("我的")
            }
        }
        .asRootView()
    }
}

// MARK: - 预览
#Preview {
    MainTabView()
}