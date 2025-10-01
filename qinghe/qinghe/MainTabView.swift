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
            // 根内容（使用自定义 Tab 切换）
            Group {
                if navigationManager.selectedTab == .home {
                    // 首页 -> 社区
                    MainCommunityView()
                } else if navigationManager.selectedTab == .newHome {
                    // 听音 显示我们的新首页页面（重设计页面）
                    HomeRedesignPlaceholderView()
                } else if navigationManager.selectedTab == .record {
                    // 功过格
                    NavigationStack {
                        GongGuoGeView()
                    }
                } else if navigationManager.selectedTab == .health {
                    // 健康助手
                    NavigationStack {
                        HealthAssistantView()
                    }
                } else if navigationManager.selectedTab == .workout {
                    // 运动
                    NavigationStack {
                        WorkoutModeSelectionView()
                    }
                } else if navigationManager.selectedTab == .community {
                    MainCommunityView()
                } else if navigationManager.selectedTab == .messages {
                    MessagesView()
                } else if navigationManager.selectedTab == .profile {
                    ProfileView()
                } else {
                    // 兜底：若出现已移除的Tab类型，回退到社区
                    MainCommunityView()
                }
            }
            .environmentObject(tabBarManager)

            // 自定义 TabBar（只在主页面显示，固定在底部）
            GeometryReader { geometry in
                if tabBarManager.isTabBarVisible {
                    VStack {
                        Spacer()
                        CustomTabBar(selectedTab: selectedTab, tabBarManager: tabBarManager)
                            .frame(width: geometry.size.width)
                    }
                    .ignoresSafeArea(.keyboard)
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
        // 再次显式隐藏系统 TabBar（安全网）
        .toolbar(.hidden, for: .tabBar)
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
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .ignoresSafeArea(edges: .bottom) // 背景延伸到底部
        )
        .opacity(tabBarManager.isTabBarVisible ? 1 : 0)
        .offset(y: tabBarManager.isTabBarVisible ? 0 : 100)
        .animation(.easeInOut(duration: 0.3), value: tabBarManager.isTabBarVisible)
    }
}

// MARK: - TabBar 按钮（纯文字版本）
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
            ZStack(alignment: .topTrailing) {
                Text(tab.title)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(.label) : Color(.systemGray3))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                // 消息Tab的通知角标
                if tab == .messages && notificationManager.unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)

                        Text("\(notificationManager.unreadCount > 99 ? "99+" : "\(notificationManager.unreadCount)")")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 8, y: -4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 主标签页枚举
enum MainTab: String, CaseIterable {
    case home = "home"
    case record = "record"
    case health = "health"
    case workout = "workout"
    case newHome = "newHome"
    case community = "community"
    case messages = "messages"
    case profile = "profile"

    // 自定义可见的 Tab 顺序：首页、记录、健康、运动、我的
    static var allCases: [MainTab] { [.home, .record, .health, .workout, .profile] }

    var title: String {
        switch self {
        case .home: return "首页"
        case .record: return "记录"
        case .health: return "健康"
        case .workout: return "运动"
        case .newHome: return "听音"
        case .community: return "社区"
        case .messages: return "消息"
        case .profile: return "我的"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .record: return "square.and.pencil"
        case .health: return "heart"
        case .workout: return "figure.walk"
        case .newHome: return "headphones"
        case .community: return "person.2"
        case .messages: return "bubble.left"
        case .profile: return "person.circle"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .record: return "square.and.pencil"
        case .health: return "heart.fill"
        case .workout: return "figure.walk.circle.fill"
        case .newHome: return "headphones"
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
