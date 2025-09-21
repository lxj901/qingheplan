import SwiftUI

// MARK: - 侧边菜单管理器
class SideMenuManager: ObservableObject {
    @Published var isMenuOpen = false
    @Published var selectedMenuItem: MenuItem = .home
    @Published var showingCommunityView = false
    @Published var showingMessagesView = false
    @Published var showingMembershipView = false
    @Published var showingSettingsView = false

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
    @State private var animateItems = false
    
    var body: some View {
        HStack {
            // 侧边菜单内容 - 只有在菜单打开时才显示
            if menuManager.isMenuOpen {
                menuContent
                    .frame(width: 280)
                    .background(menuBackground)
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
    
    // MARK: - 菜单背景
    private var menuBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.08, green: 0.12, blue: 0.25),
                Color(red: 0.05, green: 0.08, blue: 0.18)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - 菜单内容
    private var menuContent: some View {
        VStack(spacing: 0) {
            // 顶部用户信息区域
            userInfoSection
                .padding(.top, 60)
                .padding(.bottom, 30)
            
            // 菜单项列表
            menuItemsList
            
            Spacer()
            
            // 底部信息
            bottomSection
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - 用户信息区域
    private var userInfoSection: some View {
        VStack(spacing: 16) {
            // 用户头像
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 0.8, blue: 0.6),
                            Color(red: 0.3, green: 0.6, blue: 0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                )
                .scaleEffect(animateItems ? 1.0 : 0.8)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: animateItems)
            
            // 用户信息
            VStack(spacing: 4) {
                Text("青禾用户")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                RealTimeClockView()
            }
            .opacity(animateItems ? 1.0 : 0.0)
            .offset(y: animateItems ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: animateItems)
        }
    }
    
    // MARK: - 菜单项列表
    private var menuItemsList: some View {
        VStack(spacing: 16) {
            ForEach(Array(MenuItem.allCases.enumerated()), id: \.element) { index, item in
                MenuItemRow(
                    item: item,
                    isSelected: menuManager.selectedMenuItem == item,
                    animationDelay: Double(index) * 0.1
                ) {
                    menuManager.selectItem(item)
                }
                .opacity(animateItems ? 1.0 : 0.0)
                .offset(x: animateItems ? 0 : -50)
                .animation(.easeOut(duration: 0.5).delay(0.4 + Double(index) * 0.1), value: animateItems)
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - 底部区域
    private var bottomSection: some View {
        VStack(spacing: 12) {
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                
                Text("青禾计划 v1.0.1")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
            }
        }
        .opacity(animateItems ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.6).delay(0.8), value: animateItems)
    }
}

// MARK: - 菜单项行组件
struct MenuItemRow: View {
    let item: MenuItem
    let isSelected: Bool
    let animationDelay: Double
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 16) {
                // 图标
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : item.color)
                    .frame(width: 28, height: 28)

                // 文本
                Text(item.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))

                Spacer()

                // 选中指示器
                if isSelected {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [item.color.opacity(0.8), item.color.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.clear, Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - 实时时钟视图
struct RealTimeClockView: View {
    @State private var currentTime = Date()
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 2) {
            Text(personalizedGreeting)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .animation(.easeInOut(duration: 0.5), value: personalizedGreeting)

            Text(timeString)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
                .animation(.easeInOut(duration: 0.3), value: timeString)
        }
        .onAppear {
            updateTime()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private var personalizedGreeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        _ = Calendar.current.component(.minute, from: currentTime)

        switch hour {
        case 5..<9:
            return "🌅 美好的晨光，自律从现在开始"
        case 9..<12:
            return "☀️ 上午时光，专注成就梦想"
        case 12..<14:
            return "🌞 午间小憩，为下午蓄力"
        case 14..<18:
            return "⛅️ 下午阳光，坚持就是胜利"
        case 18..<22:
            return "🌆 夜幕降临，总结今日收获"
        case 22..<24, 0..<5:
            return "🌙 夜深了，早睡早起身体好"
        default:
            return "🌱 青禾陪伴，自律成就更好的自己"
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: currentTime)
    }

    private func updateTime() {
        currentTime = Date()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                updateTime()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - 预览
#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()

        SideMenuView(menuManager: SideMenuManager())
    }
}
