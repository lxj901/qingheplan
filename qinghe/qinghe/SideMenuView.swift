import SwiftUI

// MARK: - 侧边菜单管理器
class SideMenuManager: ObservableObject {
    static let shared = SideMenuManager()

    @Published var isMenuOpen = false
    @Published var selectedMenuItem: MenuItem = .home
    @Published var showingCommunityView = false
    @Published var showingMessagesView = false
    @Published var showingMembershipView = false
    @Published var showingSettingsView = false
    @Published var pendingNavigation: CommunityNavigationDestination? = nil // 待处理的导航

    private init() {} // 单例模式

    func toggleMenu() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isMenuOpen.toggle()
        }
    }

    func openMenu() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isMenuOpen = true
        }
    }

    func closeMenu() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isMenuOpen = false
        }
    }

    func selectItem(_ item: MenuItem) {
        selectedMenuItem = item
        closeMenu()

        // 根据选择的菜单项显示对应的视图
        switch item {
        case .home:
            // 首页是主页面，重置所有弹出的视图
            resetAllViews()
        case .community:
            resetAllViews()
            showingCommunityView = true
        case .messages:
            resetAllViews()
            showingMessagesView = true
        case .membership:
            resetAllViews()
            showingMembershipView = true
        case .settings:
            resetAllViews()
            showingSettingsView = true
        }
    }

    private func resetAllViews() {
        showingCommunityView = false
        showingMessagesView = false
        showingMembershipView = false
        showingSettingsView = false
    }

    func setHomeSelected() {
        selectedMenuItem = .home
        resetAllViews()
    }
}

// MARK: - 菜单项定义
enum MenuItem: String, CaseIterable {
    case home = "首页"
    case community = "社区"
    case messages = "消息"
    case membership = "会员中心"
    case settings = "设置"

    var icon: String {
        switch self {
        case .home:
            return "leaf.fill"
        case .community:
            return "person.3.fill"
        case .messages:
            return "message.fill"
        case .membership:
            return "crown.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .home:
            return ModernDesignSystem.Colors.primaryGreen // 青禾绿色
        case .community:
            return Color(red: 52/255, green: 152/255, blue: 219/255) // 社区蓝色
        case .messages:
            return Color(red: 255/255, green: 165/255, blue: 0/255) // 消息橙色
        case .membership:
            return Color(red: 255/255, green: 215/255, blue: 0/255) // 会员金色
        case .settings:
            return Color(red: 99/255, green: 99/255, blue: 102/255) // 设置深灰
        }
    }
}

// MARK: - 侧边菜单视图
struct SideMenuView: View {
    @ObservedObject var menuManager: SideMenuManager
    @Binding var navigationPath: NavigationPath
    @Binding var showingPublishPost: Bool
    @State private var animateItems = false

    var body: some View {
        HStack {
            // 侧边菜单内容 - 只有在菜单打开时才显示
            if menuManager.isMenuOpen {
                menuContent
                    .frame(width: 280)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 5, y: 0)
                    .transition(.move(edge: .leading))
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateItems = true
            }
        }
    }
    
    // MARK: - 菜单内容
    private var menuContent: some View {
        VStack(spacing: 0) {
            // 顶部标题
            HStack {
                Text("菜单")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 20)

            Divider()

            // 菜单项列表
            ScrollView {
                VStack(spacing: 0) {
                    // 书城
                    menuItem(title: "书城") {
                        menuManager.closeMenu()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            menuManager.pendingNavigation = .bookCategory
                        }
                    }

                    Divider().padding(.leading, 20)

                    // AI 题库
                    menuItem(title: "AI 题库") {
                        menuManager.closeMenu()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            menuManager.pendingNavigation = .aiQuestionBank
                        }
                    }

                    Divider().padding(.leading, 20)

                    // 了凡四训
                    menuItem(title: "了凡四训") {
                        menuManager.closeMenu()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            menuManager.pendingNavigation = .meritStatistics
                        }
                    }

                    Divider().padding(.leading, 20)

                    // 笔记中心
                    menuItem(title: "笔记中心") {
                        menuManager.closeMenu()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            menuManager.pendingNavigation = .noteCenter
                        }
                    }

                    Divider().padding(.leading, 20)

                    // 复习计划
                    menuItem(title: "复习计划") {
                        menuManager.closeMenu()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            menuManager.pendingNavigation = .reviewPlan
                        }
                    }

                    Divider().padding(.leading, 20)

                    // 睡眠管理
                    menuItem(title: "睡眠管理") {
                        menuManager.closeMenu()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            menuManager.pendingNavigation = .sleepManagement
                        }
                    }
                }
                .padding(.top, 10)
            }

            Spacer()
        }
    }
    
    // MARK: - 菜单项
    private func menuItem(title: String, badge: Int = 0, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Spacer()

                // 未读消息角标
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 预览
#Preview {
    struct PreviewWrapper: View {
        @State private var navigationPath = NavigationPath()
        @State private var showingPublishPost = false

        var body: some View {
            ZStack {
                Color.gray.opacity(0.3).ignoresSafeArea()

                SideMenuView(
                    menuManager: SideMenuManager.shared,
                    navigationPath: $navigationPath,
                    showingPublishPost: $showingPublishPost
                )
            }
        }
    }

    return PreviewWrapper()
}
