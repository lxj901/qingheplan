import SwiftUI

/// 圈主管理视图 - 现代化设计
struct CircleManagementView: View {
    @StateObject private var viewModel = CircleManagementViewModel()
    @State private var activeTab: ManagementTab = .home
    @State private var scrollOffset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    enum ManagementTab: String, CaseIterable {
        case home = "数据"
        case members = "成员"
        case content = "内容"
        case settings = "设置"

        var icon: String {
            switch self {
            case .home: return "chart.bar.fill"
            case .members: return "person.3.fill"
            case .content: return "doc.text.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.97, blue: 0.96),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 主内容
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    switch activeTab {
                    case .home:
                        CircleHomeTabView(viewModel: viewModel)
                    case .members:
                        CircleMembersTabView()
                    case .content:
                        CircleContentTabView()
                    case .settings:
                        CircleSettingsTabView()
                    }
                }
                .padding(.top, 100)
                .padding(.bottom, 100)
            }

            // 浮动头部
            CircleFloatingHeader(scrollOffset: scrollOffset, dismiss: dismiss)

            // 底部 Tab 栏
            CircleBottomTabBar(activeTab: $activeTab)
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadCircles(status: "owned")
            viewModel.loadMockData()
        }
    }
}

// MARK: - 浮动头部
struct CircleFloatingHeader: View {
    let scrollOffset: CGFloat
    let dismiss: DismissAction

    var isScrolled: Bool {
        scrollOffset > 20
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(isScrolled ? 0 : 0.2))
                        )
                }

                Spacer()

                Text("绿野社群")
                    .font(.system(size: 16, weight: .bold))
                    .opacity(isScrolled ? 1 : 0)

                Spacer()

                Button(action: {}) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(isScrolled ? 0 : 0.2))
                            )

                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: -8, y: 8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(
                Group {
                    if isScrolled {
                        Color.white
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    } else {
                        Color.clear
                    }
                }
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - 底部 Tab 栏
struct CircleBottomTabBar: View {
    @Binding var activeTab: CircleManagementView.ManagementTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CircleManagementView.ManagementTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        activeTab = tab
                    }
                }) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: activeTab == tab ? .semibold : .regular))
                        .foregroundColor(activeTab == tab ? .white : Color.gray.opacity(0.6))
                        .frame(width: 48, height: 48)
                        .background(
                            activeTab == tab ?
                            AppConstants.Colors.primaryGreen : Color.clear
                        )
                        .clipShape(Circle())
                        .scaleEffect(activeTab == tab ? 1.1 : 1.0)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(red: 0.11, green: 0.11, blue: 0.12)
                .opacity(0.9)
                .background(.ultraThinMaterial)
        )
        .cornerRadius(30)
        .shadow(color: AppConstants.Colors.primaryGreen.opacity(0.2), radius: 20, x: 0, y: -5)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - 首页 Tab 视图
struct CircleHomeTabView: View {
    @ObservedObject var viewModel: CircleManagementViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 欢迎区域
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Hello, 圈主")
                        .font(.system(size: 28, weight: .black))
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                }
                Text("保持热爱，奔赴山海 ⛰️")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)

            // 数据统计卡片
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.stats) { stat in
                        if stat.label == "活跃指数" {
                            NavigationLink {
                                ActivityIndexView()
                                    .asSubView() // 标记为子页面，隐藏主 Tab 栏
                            } label: {
                                CircleStatCard(stat: stat)
                            }
                            .buttonStyle(.plain)
                        } else if stat.label == "新增禾友" {
                            NavigationLink {
                                NewMembersView()
                                    .asSubView() // 隐藏主 Tab 栏
                            } label: {
                                CircleStatCard(stat: stat)
                            }
                            .buttonStyle(.plain)
                        } else if stat.label == "内容产出" {
                            NavigationLink {
                                ContentProductionView()
                                    .asSubView() // 隐藏主 Tab 栏
                            } label: {
                                CircleStatCard(stat: stat)
                            }
                            .buttonStyle(.plain)
                        } else {
                            CircleStatCard(stat: stat)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            // 收益中心
            CircleRevenueCard(revenue: viewModel.revenue)
                .padding(.horizontal, 20)

            // 运营工具箱
            CircleOperationToolsSection()
                .padding(.horizontal, 20)

            // 入群申请
            CircleJoinRequestsSection(requests: viewModel.joinRequests)
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - 数据统计卡片
struct CircleStatCard: View {
    let stat: CircleStatData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(stat.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Image(systemName: stat.isUp ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(stat.isUp ? AppConstants.Colors.primaryGreen : .orange)
                    .frame(width: 24, height: 24)
                    .background(
                        (stat.isUp ? AppConstants.Colors.primaryGreen : Color.orange)
                            .opacity(0.1)
                    )
                    .clipShape(Circle())
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(stat.value)
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(stat.trend)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(stat.isUp ? AppConstants.Colors.primaryGreen : .orange)
                    Text("周同比")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.1))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: stat.gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.67)
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .frame(width: 144, height: 160)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: AppConstants.Colors.primaryGreen.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 收益中心卡片
struct CircleRevenueCard: View {
    let revenue: CircleRevenueData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 12))
                        Text("本月预估收益")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(AppConstants.Colors.primaryGreen.opacity(0.8))

                    Text("¥ \(revenue.total, specifier: "%.2f")")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                NavigationLink {
                    WithdrawView()
                        .asSubView() // 隐藏底部 Tab 栏
                } label: {
                    Text("提现")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppConstants.Colors.primaryGreen)
                        .cornerRadius(20)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("付费入群")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    Text("¥ \(revenue.membership, specifier: "%.0f")")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 4) {
                    Text("内容打赏")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    Text("¥ \(revenue.tips, specifier: "%.0f")")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.11, blue: 0.12),
                    AppConstants.Colors.primaryGreen.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(32)
        .shadow(color: AppConstants.Colors.primaryGreen.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - 运营工具箱
struct CircleOperationToolsSection: View {
    let tools = [
        CircleOperationTool(label: "发布活动", icon: "calendar", color: Color.orange),
        CircleOperationTool(label: "创建话题", icon: "number", color: Color.blue),
        CircleOperationTool(label: "发起投票", icon: "chart.bar", color: Color.purple)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("运营工具")
                    .font(.system(size: 18, weight: .bold))

                Spacer()

                HStack(spacing: 4) {
                    Text("全部")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 12) {
                ForEach(tools, id: \.label) { tool in
                    if tool.label == "发布活动" {
                        NavigationLink {
                            CreateEventView()
                                .asSubView() // 隐藏底部 Tab 栏
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: tool.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(tool.color)
                                    .frame(width: 40, height: 40)
                                    .background(tool.color.opacity(0.1))
                                    .clipShape(Circle())

                                Text(tool.label)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    } else if tool.label == "创建话题" {
                        NavigationLink {
                            CreateTopicView()
                                .asSubView() // 隐藏底部 Tab 栏
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: tool.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(tool.color)
                                    .frame(width: 40, height: 40)
                                    .background(tool.color.opacity(0.1))
                                    .clipShape(Circle())

                                Text(tool.label)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    } else if tool.label == "发起投票" {
                        NavigationLink {
                            CreatePollView()
                                .asSubView() // 隐藏底部 Tab 栏
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: tool.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(tool.color)
                                    .frame(width: 40, height: 40)
                                    .background(tool.color.opacity(0.1))
                                    .clipShape(Circle())

                                Text(tool.label)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: {}) {
                            VStack(spacing: 8) {
                                Image(systemName: tool.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(tool.color)
                                    .frame(width: 40, height: 40)
                                    .background(tool.color.opacity(0.1))
                                    .clipShape(Circle())

                                Text(tool.label)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 入群申请区域
struct CircleJoinRequestsSection: View {
    let requests: [CircleJoinRequest]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("入群申请")
                    .font(.system(size: 18, weight: .bold))

                Spacer()

                if !requests.isEmpty {
                    Text("\(requests.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppConstants.Colors.primaryGreen)
                        .clipShape(Capsule())
                }
            }

            ForEach(requests) { request in
                CircleJoinRequestCard(request: request)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 入群申请卡片
struct CircleJoinRequestCard: View {
    let request: CircleJoinRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(request.name)
                            .font(.system(size: 15, weight: .bold))

                        Spacer()

                        Text(request.time)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppConstants.Colors.primaryGreen.opacity(0.8))
                            .cornerRadius(8)
                    }

                    Text(request.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 8) {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("同意")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppConstants.Colors.primaryGreen)
                    .cornerRadius(20)
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.94, green: 0.99, blue: 0.96))
        .cornerRadius(24)
    }
}

// MARK: - 成员管理 Tab 视图（新版）
struct CircleMembersTabView: View {
    private enum MembersViewType {
        case main
        case admins
        case blacklist
    }

    @State private var searchQuery: String = ""
    @State private var currentView: MembersViewType = .main
    @State private var selectedMember: CircleMemberInfo?

    private var filteredMembers: [CircleMemberInfo] {
        guard !searchQuery.isEmpty else { return allCircleMembersMock }
        return allCircleMembersMock.filter { $0.name.contains(searchQuery) }
    }

    var body: some View {
        ZStack {
            switch currentView {
            case .main:
                mainMembersView
            case .admins:
                adminsManagementView
            case .blacklist:
                blacklistView
            }

            if let member = selectedMember {
                MemberActionSheet(member: member) {
                    selectedMember = nil
                }
            }
        }
    }

    // MARK: 主视图：成员列表
    private var mainMembersView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("成员管理")
                .font(.system(size: 24, weight: .black))
                .padding(.horizontal, 20)

            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索成员昵称", text: $searchQuery)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)

            // 管理入口卡片
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentView = .admins
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 14))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .opacity(0.7)
                        }

                        Spacer()

                        Text("管理员")
                            .font(.system(size: 14, weight: .bold))
                        Text("3 人在职")
                            .font(.system(size: 11))
                            .opacity(0.85)
                    }
                    .foregroundColor(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 110)
                    .background(
                        LinearGradient(
                            colors: [AppConstants.Colors.primaryGreen, Color.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(24)
                    .shadow(color: AppConstants.Colors.primaryGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                }

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentView = .blacklist
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .opacity(0.7)
                        }

                        Spacer()

                        Text("小黑屋")
                            .font(.system(size: 14, weight: .bold))
                        Text("\(bannedUsersMock.count) 人封禁中")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 110)
                    .background(Color.black.opacity(0.92))
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
            .padding(.horizontal, 20)

            // 全部成员列表
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("全部成员")
                        .font(.system(size: 16, weight: .bold))
                    Text("\(allCircleMembersMock.count)人")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)

                VStack(spacing: 0) {
                    ForEach(filteredMembers) { member in
                        CircleMemberListRow(member: member) {
                            selectedMember = member
                        }

                        if member.id != filteredMembers.last?.id {
                            Divider()
                                .background(Color(.systemGray6))
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppConstants.Colors.primaryGreen.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: 管理员管理视图
    private var adminsManagementView: some View {
        VStack(alignment: .leading, spacing: 16) {
            simpleNavBar(title: "管理员管理") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentView = .main
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                        .padding(8)
                        .background(AppConstants.Colors.primaryGreen.opacity(0.1))
                        .clipShape(Circle())

                    Text("管理员拥有「置顶帖子、管理评论、审核入群」等权限，请谨慎添加。")
                        .font(.system(size: 12))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                        .lineSpacing(2)
                }
                .padding(12)
            }
            .background(Color(red: 240/255, green: 249/255, blue: 244/255))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppConstants.Colors.primaryGreen.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 20)

            let admins = allCircleMembersMock.filter { $0.role == .owner || $0.role == .admin }

            VStack(spacing: 0) {
                ForEach(admins) { admin in
                    HStack(spacing: 12) {
                        AvatarView(urlString: admin.avatarURL)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(admin.name)
                                .font(.system(size: 14, weight: .bold))

                            Text(admin.role == .owner ? "创建者" : "加入于 \(admin.joinTime)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if admin.role == .owner {
                            Text("不可操作")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        } else {
                            Button(action: {
                                // 撤销管理员操作占位
                            }) {
                                Text("撤销")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(999)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if admin.id != admins.last?.id {
                        Divider()
                            .background(Color(.systemGray6))
                            .padding(.leading, 72)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)

            Button(action: {
                // 添加管理员操作占位
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 16))
                    Text("添加管理员")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(AppConstants.Colors.primaryGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppConstants.Colors.primaryGreen.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                )
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: 小黑屋视图
    private var blacklistView: some View {
        VStack(spacing: 16) {
            simpleNavBar(title: "小黑屋") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentView = .main
                }
            }

            if bannedUsersMock.isEmpty {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 64, height: 64)
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                    Text("圈子环境良好，暂无封禁人员")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(bannedUsersMock) { user in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top, spacing: 10) {
                                ZStack(alignment: .bottomTrailing) {
                                    AvatarView(urlString: user.avatarURL)
                                        .grayscale(1.0)

                                    ZStack {
                                        Circle()
                                            .fill(Color(.systemGray))
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 14, height: 14)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.name)
                                        .font(.system(size: 14, weight: .bold))
                                    Text("\(user.banTime) 被封禁")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button(action: {
                                    // 解封操作占位
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "lock.open.fill")
                                            .font(.system(size: 10))
                                        Text("解封")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AppConstants.Colors.primaryGreen.opacity(0.1))
                                    .foregroundColor(AppConstants.Colors.primaryGreen)
                                    .cornerRadius(999)
                                }
                            }

                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .padding(6)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("违规原因：\(user.reason)")
                                    Text("操作人：\(user.operatorName)")
                                }
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(22)
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
    }

    // MARK: 简单导航栏（用于管理员 / 小黑屋）
    private func simpleNavBar(title: String, onBack: @escaping () -> Void) -> some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.9))
                    )
            }

            Spacer()

            Text(title)
                .font(.system(size: 16, weight: .bold))

            Spacer()

            Color.clear
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }
}

// MARK: - 成员 / 黑名单数据模型
private enum CircleMemberRole {
    case owner
    case admin
    case member
}

private struct CircleMemberInfo: Identifiable, Equatable {
    let id: Int
    let name: String
    let avatarURL: String
    let role: CircleMemberRole
    let joinTime: String
}

private struct BannedUserInfo: Identifiable {
    let id: Int
    let name: String
    let avatarURL: String
    let reason: String
    let banTime: String
    let operatorName: String
}

// 模拟数据（与前端示例保持一致）
private let allCircleMembersMock: [CircleMemberInfo] = [
    CircleMemberInfo(
        id: 1,
        name: "森系生活",
        avatarURL: "https://api.dicebear.com/7.x/notionists/svg?seed=Forest",
        role: .owner,
        joinTime: "2023-01-01"
    ),
    CircleMemberInfo(
        id: 2,
        name: "露营达人",
        avatarURL: "https://api.dicebear.com/7.x/notionists/svg?seed=Camp",
        role: .admin,
        joinTime: "2023-02-14"
    ),
    CircleMemberInfo(
        id: 3,
        name: "植物研究所",
        avatarURL: "https://api.dicebear.com/7.x/notionists/svg?seed=Plant",
        role: .admin,
        joinTime: "2023-03-20"
    ),
    CircleMemberInfo(
        id: 4,
        name: "快乐小狗",
        avatarURL: "https://api.dicebear.com/7.x/notionists/svg?seed=Dog",
        role: .member,
        joinTime: "2023-05-01"
    ),
    CircleMemberInfo(
        id: 5,
        name: "山谷里的风",
        avatarURL: "https://api.dicebear.com/7.x/notionists/svg?seed=Wind",
        role: .member,
        joinTime: "2023-06-12"
    ),
    CircleMemberInfo(
        id: 6,
        name: "周末去野餐",
        avatarURL: "https://api.dicebear.com/7.x/notionists/svg?seed=Picnic",
        role: .member,
        joinTime: "2023-07-08"
    )
]

private let bannedUsersMock: [BannedUserInfo] = [
    BannedUserInfo(
        id: 99,
        name: "广告狂人",
        avatarURL: "https://api.dicebear.com/7.x/notionists/svg?seed=Spam",
        reason: "发布违规广告",
        banTime: "2023-11-10",
        operatorName: "森系生活"
    ),
    BannedUserInfo(
        id: 98,
        name: "暴躁老哥",
        avatarURL: "https://api.dicebear.com/7.x/notionists/svg?seed=Angry",
        reason: "言语辱骂他人",
        banTime: "2023-11-12",
        operatorName: "露营达人"
    )
]

// MARK: - 成员列表行
private struct CircleMemberListRow: View {
    let member: CircleMemberInfo
    let onMoreTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                AvatarView(urlString: member.avatarURL)

                if member.role == .owner {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                        .padding(4)
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                } else if member.role == .admin {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                        .padding(4)
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(member.name)
                        .font(.system(size: 14, weight: .bold))

                    if member.role == .owner {
                        Text("圈主")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(8)
                    } else if member.role == .admin {
                        Text("管理员")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppConstants.Colors.primaryGreen.opacity(0.12))
                            .cornerRadius(8)
                    }
                }

                Text("活跃于 10 分钟前")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onMoreTapped) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .rotationEffect(.degrees(90))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - 成员头像视图
private struct AvatarView: View {
    let urlString: String

    var body: some View {
        Group {
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Color(.systemGray5)
                    }
                }
            } else {
                Color(.systemGray5)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }
}

// MARK: - 成员操作底部弹窗
private struct MemberActionSheet: View {
    let member: CircleMemberInfo
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    AvatarView(urlString: member.avatarURL)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(member.name)
                            .font(.system(size: 16, weight: .bold))
                        Text("加入时间：\(member.joinTime)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.bottom, 8)
                .padding(.horizontal, 4)

                VStack(spacing: 10) {
                    if member.role == .member {
                        actionButton(
                            title: "设为管理员",
                            systemImage: "shield.fill",
                            foreground: AppConstants.Colors.primaryGreen,
                            background: AppConstants.Colors.primaryGreen.opacity(0.1)
                        ) {
                            // 设为管理员占位
                        }
                    } else if member.role == .admin {
                        actionButton(
                            title: "撤销管理员",
                            systemImage: "person.crop.circle.badge.minus",
                            foreground: .primary,
                            background: Color(.systemGray6)
                        ) {
                            // 撤销管理员占位
                        }
                    }

                    actionButton(
                        title: "禁言 (1天 / 3天 / 永久)",
                        systemImage: "nosign",
                        foreground: .primary,
                        background: Color(.systemGray6)
                    ) {
                        // 禁言占位
                    }

                    actionButton(
                        title: "踢出圈子",
                        systemImage: "rectangle.portrait.and.arrow.right",
                        foreground: .red,
                        background: Color(.systemGray6)
                    ) {
                        // 踢出圈子占位
                    }

                    actionButton(
                        title: "关进小黑屋 (拉黑)",
                        systemImage: "lock.fill",
                        foreground: .primary,
                        background: Color(.systemGray6)
                    ) {
                        // 拉黑占位
                    }
                }

                Button(action: {
                    onDismiss()
                }) {
                    Text("取消")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(999)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(28, corners: [.topLeft, .topRight])
            .ignoresSafeArea(edges: .bottom)
        }
        .animation(.easeInOut(duration: 0.25), value: member.id)
    }

    private func actionButton(
        title: String,
        systemImage: String,
        foreground: Color,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }
            .foregroundColor(foreground)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(background)
            .cornerRadius(18)
        }
    }
}

// MARK: - 内容管理 Tab 视图（新版）
struct CircleContentTabView: View {
    private enum ContentTab: String, CaseIterable {
        case published
        case pending
        case reported

        var title: String {
            switch self {
            case .published: return "内容列表"
            case .pending: return "待审核"
            case .reported: return "举报处理"
            }
        }
    }

    @State private var activeTab: ContentTab = .published
    @State private var publishedPosts: [CirclePublishedPost] = CircleContentMockData.published
    @State private var pendingPosts: [CirclePendingPost] = CircleContentMockData.pending
    @State private var reportedPosts: [CircleReportedPost] = CircleContentMockData.reported
    @State private var selectedPublishedPost: CirclePublishedPost?

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 16) {
                header
                tabs
                contentList
            }

            if selectedPublishedPost != nil {
                CircleContentActionSheet {
                    selectedPublishedPost = nil
                }
            }
        }
    }

    // 顶部标题
    private var header: some View {
        HStack {
            Text("内容管理")
                .font(.system(size: 24, weight: .black))

            Spacer()

            Button(action: {
                // 搜索 / 筛选占位
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
    }

    // 顶部 Tab 切换
    private var tabs: some View {
        HStack(spacing: 8) {
            ForEach(ContentTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeTab = tab
                    }
                } label: {
                    ZStack {
                        Capsule()
                            .fill(activeTab == tab ? AppConstants.Colors.primaryGreen : Color.white)
                            .shadow(color: activeTab == tab ? AppConstants.Colors.primaryGreen.opacity(0.2) : Color.clear,
                                    radius: 6, x: 0, y: 3)

                        HStack(spacing: 4) {
                            Text(tab.title)
                                .font(.system(size: 12, weight: .bold))
                            if badgeCount(for: tab) > 0 {
                                Text("\(badgeCount(for: tab))")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(tab == .reported ? Color.red : Color.orange)
                                    )
                                    .foregroundColor(.white)
                            }
                        }
                        .foregroundColor(activeTab == tab ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func badgeCount(for tab: ContentTab) -> Int {
        switch tab {
        case .pending: return pendingPosts.count
        case .reported: return reportedPosts.count
        case .published: return 0
        }
    }

    // 主内容列表
    private var contentList: some View {
        VStack(spacing: 8) {
            switch activeTab {
            case .published:
                if publishedPosts.isEmpty {
                    emptyPlaceholder
                } else {
                    ForEach(publishedPosts) { post in
                        CirclePublishedPostCard(
                            post: post,
                            onMoreTapped: { selectedPublishedPost = post }
                        )
                        .padding(.horizontal, 20)
                    }
                }

            case .pending:
                if pendingPosts.isEmpty {
                    emptyPlaceholder
                } else {
                    ForEach(pendingPosts) { post in
                        CircleModerationPendingCard(
                            post: post,
                            onReject: {
                                pendingPosts.removeAll { $0.id == post.id }
                            },
                            onPass: {
                                pendingPosts.removeAll { $0.id == post.id }
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                }

            case .reported:
                if reportedPosts.isEmpty {
                    emptyPlaceholder
                } else {
                    ForEach(reportedPosts) { post in
                        CircleReportedPostCard(
                            post: post,
                            onKeep: {
                                reportedPosts.removeAll { $0.id == post.id }
                            },
                            onDelete: {
                                reportedPosts.removeAll { $0.id == post.id }
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 28))
                    .foregroundColor(.gray)
            }
            Text("暂无待处理内容")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - 内容管理数据模型
private struct CirclePublishedPost: Identifiable, Equatable {
    let id: Int
    let author: String
    let avatarURL: String
    let content: String
    let imageColors: [Color]
    let time: String
    let views: Int
    let comments: Int
    let isPinned: Bool
    let isEssence: Bool
}

private struct CirclePendingPost: Identifiable, Equatable {
    let id: Int
    let author: String
    let avatarURL: String
    let content: String
    let imageColors: [Color]
    let time: String
    let reason: String?
}

private struct CircleReportedPost: Identifiable, Equatable {
    let id: Int
    let author: String
    let avatarURL: String
    let content: String
    let imageColors: [Color]
    let time: String
    let reportReason: String
    let reportCount: Int
}

private struct CircleContentMockData {
    static let published: [CirclePublishedPost] = [
        CirclePublishedPost(
            id: 1,
            author: "森系生活",
            avatarURL: "https://api.dicebear.com/7.x/notionists/svg?seed=Forest",
            content: "分享一个最近发现的超棒露营地，人少景美！就在临安附近...",
            imageColors: [Color.green.opacity(0.15)],
            time: "2小时前",
            views: 1204,
            comments: 32,
            isPinned: true,
            isEssence: false
        ),
        CirclePublishedPost(
            id: 2,
            author: "摄影大叔",
            avatarURL: "https://api.dicebear.com/7.x/notionists/svg?seed=Jack",
            content: "胶片摄影的魅力在于不可预知性。这组照片是用 Kodak Gold 200 拍的。",
            imageColors: [Color.orange.opacity(0.15), Color.blue.opacity(0.15)],
            time: "5小时前",
            views: 890,
            comments: 15,
            isPinned: false,
            isEssence: true
        ),
        CirclePublishedPost(
            id: 3,
            author: "小白",
            avatarURL: "https://api.dicebear.com/7.x/notionists/svg?seed=White",
            content: "萌新求问，第一次买帐篷应该注意什么？",
            imageColors: [],
            time: "1天前",
            views: 230,
            comments: 45,
            isPinned: false,
            isEssence: false
        )
    ]

    static let pending: [CirclePendingPost] = [
        CirclePendingPost(
            id: 101,
            author: "新用户882",
            avatarURL: "https://api.dicebear.com/7.x/notionists/svg?seed=New",
            content: "出一套闲置的露营装备，99新，需要的私聊。",
            imageColors: [Color(.systemGray4)],
            time: "10分钟前",
            reason: "包含敏感词：私聊"
        )
    ]

    static let reported: [CircleReportedPost] = [
        CircleReportedPost(
            id: 201,
            author: "广告狂人",
            avatarURL: "https://api.dicebear.com/7.x/notionists/svg?seed=Ad",
            content: "兼职刷单，日赚300+，加V：xxxxx",
            imageColors: [],
            time: "30分钟前",
            reportReason: "垃圾广告",
            reportCount: 5
        )
    ]
}

// MARK: - 不同状态下的内容卡片
private struct CirclePublishedPostCard: View {
    let post: CirclePublishedPost
    let onMoreTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 用户信息 + 更多
            HStack(alignment: .top, spacing: 10) {
                AvatarView(urlString: post.avatarURL)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(.system(size: 14, weight: .bold))
                    Text(post.time)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onMoreTapped) {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }

            // 内容文本
            Text(post.content)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .lineLimit(3)

            // 图片占位
            if !post.imageColors.isEmpty {
                HStack(spacing: 8) {
                    ForEach(post.imageColors.indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(post.imageColors[index])
                            .frame(width: 72, height: 72)
                    }
                }
            }

            Divider()
                .background(Color(.systemGray6))
                .padding(.vertical, 2)

            // 底部标签 + 数据
            HStack {
                HStack(spacing: 4) {
                    if post.isPinned {
                        labelChip(icon: "pin.fill", text: "置顶", color: .blue)
                    }
                    if post.isEssence {
                        labelChip(icon: "bolt.fill", text: "精华", color: .yellow)
                    }
                }

                Spacer()

                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                            .font(.system(size: 10))
                        Text("\(post.views)")
                            .font(.system(size: 10))
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 10))
                        Text("\(post.comments)")
                            .font(.system(size: 10))
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(.systemGray6), lineWidth: 1)
        )
    }

    private func labelChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 9, weight: .bold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

private struct CircleModerationPendingCard: View {
    let post: CirclePendingPost
    let onReject: () -> Void
    let onPass: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 机审提示
            if let reason = post.reason {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text("机审拦截：\(reason)")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(10)
            }

            // 用户信息
            HStack(alignment: .top, spacing: 10) {
                AvatarView(urlString: post.avatarURL)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(.system(size: 14, weight: .bold))
                    Text(post.time)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // 内容
            Text(post.content)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .lineLimit(3)

            if !post.imageColors.isEmpty {
                HStack(spacing: 8) {
                    ForEach(post.imageColors.indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(post.imageColors[index])
                            .frame(width: 72, height: 72)
                    }
                }
            }

            Divider()
                .background(Color(.systemGray6))

            HStack {
                Spacer()
                Button(action: onReject) {
                    Text("拒绝")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(.systemGray6))
                        .cornerRadius(999)
                }

                Button(action: onPass) {
                    Text("通过")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(AppConstants.Colors.primaryGreen)
                        .cornerRadius(999)
                        .shadow(color: AppConstants.Colors.primaryGreen.opacity(0.25), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(.systemGray6), lineWidth: 1)
        )
    }
}

private struct CircleReportedPostCard: View {
    let post: CircleReportedPost
    let onKeep: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 举报信息条
            HStack(spacing: 6) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 12))
                Text("举报理由：\(post.reportReason)")
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Text("x\(post.reportCount)")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(6)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.08))
            .foregroundColor(.red)
            .cornerRadius(10)

            // 用户信息
            HStack(alignment: .top, spacing: 10) {
                AvatarView(urlString: post.avatarURL)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(.system(size: 14, weight: .bold))
                    Text(post.time)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // 内容
            Text(post.content)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .lineLimit(3)

            if !post.imageColors.isEmpty {
                HStack(spacing: 8) {
                    ForEach(post.imageColors.indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(post.imageColors[index])
                            .frame(width: 72, height: 72)
                    }
                }
            }

            Divider()
                .background(Color(.systemGray6))

            HStack {
                Spacer()
                Button(action: onKeep) {
                    Text("忽略")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(.systemGray6))
                        .cornerRadius(999)
                }

                Button(action: onDelete) {
                    Text("删除")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(999)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.red.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - 内容操作 Action Sheet
private struct CircleContentActionSheet: View {
    let onDismiss: () -> Void

    private struct SheetAction: Identifiable {
        let id = UUID()
        let label: String
        let systemImage: String
        let background: Color
        let foreground: Color
    }

    private let actions: [SheetAction] = [
        SheetAction(label: "置顶", systemImage: "pin.fill",
                    background: Color.blue.opacity(0.1), foreground: .blue),
        SheetAction(label: "加精", systemImage: "bolt.fill",
                    background: Color.yellow.opacity(0.12), foreground: .yellow),
        SheetAction(label: "禁言作者", systemImage: "xmark.circle.fill",
                    background: Color(.systemGray5), foreground: .secondary),
        SheetAction(label: "删除", systemImage: "trash.fill",
                    background: Color.red.opacity(0.08), foreground: .red)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 999)
                    .fill(Color(.systemGray4))
                    .frame(width: 40, height: 4)
                    .padding(.top, 4)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4),
                          spacing: 16) {
                    ForEach(actions) { action in
                        Button {
                            // 这里只做占位，不改变数据
                            onDismiss()
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(action.background)
                                        .frame(width: 56, height: 56)
                                    Image(systemName: action.systemImage)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(action.foreground)
                                }

                                Text(action.label)
                                    .font(.system(size: 11))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)

                Button(action: onDismiss) {
                    Text("取消")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(999)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(28, corners: [.topLeft, .topRight])
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - 设置 Tab 视图
struct CircleSettingsTabView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("圈子设置")
                .font(.system(size: 28, weight: .black))
                .padding(.horizontal, 20)

            // 封面预览
            ZStack {
                LinearGradient(
                    colors: [AppConstants.Colors.primaryGreen, Color.teal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack {
                    Text("绿野社群")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("ID: 9527")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(height: 144)
            .cornerRadius(32)
            .shadow(color: AppConstants.Colors.primaryGreen.opacity(0.3), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)

            // 设置选项
            VStack(spacing: 0) {
                ForEach([
                    ("基本信息", "doc.text.fill"),
                    ("账户设置", "creditcard.fill"),
                    ("入群门槛", "lock.fill"),
                    ("隐私设置", "shield.fill")
                ], id: \.0) { item in
                    if item.0 == "基本信息" {
                        NavigationLink {
                            CircleBasicInfoView()
                                .asSubView()
                        } label: {
                            settingsRow(title: item.0, systemImage: item.1)
                        }
                    } else if item.0 == "账户设置" {
                        NavigationLink {
                            CircleAccountSettingsView()
                                .asSubView()
                        } label: {
                            settingsRow(title: item.0, systemImage: item.1)
                        }
                    } else if item.0 == "入群门槛" {
                        NavigationLink {
                            CircleEntryThresholdView()
                                .asSubView()
                        } label: {
                            settingsRow(title: item.0, systemImage: item.1)
                        }
                    } else if item.0 == "隐私设置" {
                        NavigationLink {
                            CirclePrivacySettingsView()
                                .asSubView()
                        } label: {
                            settingsRow(title: item.0, systemImage: item.1)
                        }
                    } else {
                        Button(action: {
                            // 其他设置项占位
                        }) {
                            settingsRow(title: item.0, systemImage: item.1)
                        }
                    }

                    if item.0 != "隐私设置" {
                        Divider()
                            .padding(.leading, 64)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(32)
            .padding(.horizontal, 20)

            Button(action: {}) {
                Text("退出并解散圈子")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(24)
            }
            .padding(.horizontal, 20)
        }
    }

    // 通用设置行
    private func settingsRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(20)
    }
}

// MARK: - 圈子基本信息页面
struct CircleBasicInfoView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isSaving = false
    @State private var hasChanged = false

    @State private var name: String = "绿野社群"
    private let circleId: String = "9527882"
    @State private var intro: String = "保持热爱，奔赴山海。这里是徒步、露营爱好者的聚集地 ⛰️"
    @State private var location: String = "杭州 · 西湖区"
    @State private var tags: [String] = ["户外", "露营", "摄影"]
    private let avatarURL: String = "https://api.dicebear.com/7.x/notionists/svg?seed=Forest"

    private let backgroundColor = Color(red: 240/255, green: 247/255, blue: 244/255)

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        coverAndAvatarSection
                        coreInfoSection
                        attributesSection
                        transferSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }

    // 顶部导航栏
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.9))
                    )
            }

            Spacer()

            Text("基本信息")
                .font(.system(size: 16, weight: .bold))

            Spacer()

            Button(action: handleSave) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 40, height: 28)
                } else {
                    Text("保存")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(hasChanged ? AppConstants.Colors.primaryGreen : Color.clear)
                        .foregroundColor(hasChanged ? .white : Color(.systemGray3))
                        .cornerRadius(999)
                        .shadow(
                            color: hasChanged ? AppConstants.Colors.primaryGreen.opacity(0.25) : .clear,
                            radius: 4, x: 0, y: 2
                        )
                }
            }
            .disabled(!hasChanged || isSaving)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            ZStack(alignment: .bottom) {
                backgroundColor.opacity(0.95)
                Divider()
            }
        )
    }

    // 封面 + 头像
    private var coverAndAvatarSection: some View {
        ZStack(alignment: .bottomLeading) {
            ZStack {
                LinearGradient(
                    colors: [AppConstants.Colors.primaryGreen, Color.teal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // 简单纹理占位
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .blendMode(.softLight)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .cornerRadius(24)
            .shadow(color: AppConstants.Colors.primaryGreen.opacity(0.2), radius: 8, x: 0, y: 4)
            .overlay(
                // 更换封面提示
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("更换封面")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(999)
                .padding(10),
                alignment: .bottomTrailing
            )

            // 头像
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 84, height: 84)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

                    AvatarView(urlString: avatarURL)
                        .frame(width: 76, height: 76)
                        .overlay(
                            Circle()
                                .fill(Color.black.opacity(0.25))
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .opacity(0), alignment: .center
                        )
                }
                Spacer()
            }
            .padding(.leading, 24)
            .offset(y: 40)
        }
        .padding(.bottom, 40)
    }

    // 核心信息表单
    private var coreInfoSection: some View {
        VStack(spacing: 0) {
            // 名称
            VStack(alignment: .leading, spacing: 8) {
                Text("圈子名称")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)

                TextField("", text: $name, onEditingChanged: { _ in
                    markChanged()
                })
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            }
            .padding(16)
            .background(Color.white)

            Divider()
                .background(Color(.systemGray6))

            // 圈子 ID
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("圈子 ID")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(circleId)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    // 模拟复制行为
                    print("复制圈子ID: \(circleId)")
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
            .padding(16)
            .background(Color.white)

            Divider()
                .background(Color(.systemGray6))

            // 简介
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("简介")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(intro.count)/100")
                        .font(.system(size: 10))
                        .foregroundColor(intro.count > 50 ? .red : Color(.systemGray3))
                }

                TextEditor(text: $intro)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6).opacity(0.6))
                    .cornerRadius(12)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .onChange(of: intro) { _ in
                        markChanged()
                    }
            }
            .padding(16)
            .background(Color.white)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppConstants.Colors.primaryGreen.opacity(0.06), lineWidth: 1)
        )
    }

    // 属性设置（标签 + 地区）
    private var attributesSection: some View {
        VStack(spacing: 0) {
            // 标签
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                        Text("圈子标签")
                            .font(.system(size: 14, weight: .bold))
                    }

                    Spacer()

                    Text("最多 3 个")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                HStack {
                    tagList
                    Spacer()
                }
            }
            .padding(16)
            .background(Color.white)

            Divider()
                .background(Color(.systemGray6))

            // 地区
            Button(action: {
                // 地区选择占位
            }) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        Text("常驻地区")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text(location)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(Color.white)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppConstants.Colors.primaryGreen.opacity(0.06), lineWidth: 1)
        )
    }

    private var tagList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                    HStack(spacing: 4) {
                        Text(tag)
                            .font(.system(size: 11, weight: .bold))

                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .opacity(0.7)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppConstants.Colors.primaryGreen.opacity(0.08))
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                    .cornerRadius(10)
                    .onTapGesture {
                        tags.remove(at: index)
                        markChanged()
                    }
                }

                if tags.count < 3 {
                    Button(action: {
                        // 简单添加一个占位标签
                        let newTag = "标签\(tags.count + 1)"
                        tags.append(newTag)
                        markChanged()
                    }) {
                        Text("+ 添加")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [4]))
                            )
                    }
                }
            }
        }
    }

    // 底部操作
    private var transferSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Button(action: {
                // 转让圈主占位
            }) {
                Text("转让圈主")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .cornerRadius(18)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    private func handleSave() {
        guard hasChanged, !isSaving else { return }
        isSaving = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSaving = false
            hasChanged = false
        }
    }

    private func markChanged() {
        if !hasChanged {
            hasChanged = true
        }
    }
}

// MARK: - 圈子账户设置页面
struct CircleAccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var paidEntry: Bool = false
    @State private var entryFee: String = "29.90"
    @State private var allowTipping: Bool = false
    @State private var alipayBound: Bool = true
    @State private var wechatBound: Bool = false

    private let backgroundColor = Color(red: 240/255, green: 247/255, blue: 244/255)

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        balanceCard
                        incomeSettingsSection
                        withdrawAccountsSection
                        securitySection
                        bottomNote
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }

    // 顶部导航
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Spacer()

            Text("账户设置")
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            // 占位，让标题居中
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(backgroundColor)
    }

    // 可提现余额卡片
    private var balanceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("可提现余额")
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.8))
                Text("¥ 4,285.50")
                    .font(.system(size: 24, weight: .black))
            }

            Spacer()

            NavigationLink {
                WithdrawView()
                    .asSubView()
            } label: {
                Text("去提现")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(999)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color(red: 5/255, green: 150/255, blue: 105/255), Color.teal],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(22)
    }

    // 收入配置
    private var incomeSettingsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("收入配置")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(.systemGray3))
                .padding(.leading, 8)

            VStack(spacing: 0) {
                // 付费入群
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "banknote.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppConstants.Colors.primaryGreen)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("付费入群")
                                    .font(.system(size: 14, weight: .bold))
                                Text("成员需支付费用才能加入")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        switchView(isOn: paidEntry) {
                            paidEntry.toggle()
                        }
                    }

                    if paidEntry {
                        HStack {
                            Text("入群费用")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)

                            Spacer()

                            HStack(spacing: 4) {
                                Text("¥")
                                    .font(.system(size: 12, weight: .bold))
                                TextField("", text: $entryFee)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(width: 60)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        .padding(10)
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(12)
                        .padding(.leading, 46)
                    }
                }
                .padding(12)

                Divider()
                    .background(Color(.systemGray6))

                // 内容打赏
                HStack(alignment: .top) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: "centsign.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("允许内容打赏")
                                .font(.system(size: 14, weight: .bold))
                            Text("开启后成员可对优质内容打赏")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    switchView(isOn: allowTipping) {
                        allowTipping.toggle()
                    }
                }
                .padding(12)
            }
            .background(Color.white)
            .cornerRadius(24)
        }
    }

    // 提现账户
    private var withdrawAccountsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("提现账户")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(.systemGray3))
                .padding(.leading, 8)

            VStack(spacing: 0) {
                // 支付宝
                Button(action: {
                    alipayBound.toggle()
                }) {
                    HStack {
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.09, green: 0.47, blue: 1.0))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text("支")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("支付宝")
                                    .font(.system(size: 14, weight: .bold))

                                if alipayBound {
                                    Text("已绑定: 138****8888")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 9))
                                        Text("未绑定")
                                    }
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                                }
                            }
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Text(alipayBound ? "解绑" : "去绑定")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    alipayBound ? Color(.systemGray6) : AppConstants.Colors.primaryGreen.opacity(0.1)
                                )
                                .foregroundColor(alipayBound ? .secondary : AppConstants.Colors.primaryGreen)
                                .cornerRadius(8)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                }

                Divider()
                    .background(Color(.systemGray6))

                // 微信
                Button(action: {
                    wechatBound.toggle()
                }) {
                    HStack {
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.03, green: 0.76, blue: 0.38))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text("微")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("微信支付")
                                    .font(.system(size: 14, weight: .bold))

                                Text(wechatBound ? "已绑定" : "未绑定")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Text(wechatBound ? "解绑" : "去绑定")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    wechatBound ? Color(.systemGray6) : AppConstants.Colors.primaryGreen.opacity(0.1)
                                )
                                .foregroundColor(wechatBound ? .secondary : AppConstants.Colors.primaryGreen)
                                .cornerRadius(8)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                }
            }
            .background(Color.white)
            .cornerRadius(24)
        }
    }

    // 安全与明细
    private var securitySection: some View {
        VStack(spacing: 0) {
            // 交易明细
            NavigationLink {
                AccountTransactionsView()
                    .asSubView()
            } label: {
                HStack {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(.systemGray6))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            )

                        Text("交易明细")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.white)
            }

            Divider()
                .background(Color(.systemGray6))

            // 支付密码
            Button(action: {
                // 支付密码设置占位
            }) {
                HStack {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(AppConstants.Colors.primaryGreen.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppConstants.Colors.primaryGreen)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("支付密码")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                            Text("提现时需验证")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Text("已设置")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.white)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppConstants.Colors.primaryGreen.opacity(0.06), lineWidth: 1)
        )
    }

    // 底部说明
    private var bottomNote: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "shield.checkerboard")
                    .font(.system(size: 10, weight: .semibold))
                Text("资金由持牌支付机构托管，安全保障中")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6).opacity(0.7))
            .foregroundColor(.secondary)
            .cornerRadius(999)
            Spacer()
        }
    }

    // 自定义开关
    private func switchView(isOn: Bool, toggle: @escaping () -> Void) -> some View {
        Button(action: toggle) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? AppConstants.Colors.primaryGreen : Color(.systemGray4))
                    .frame(width: 44, height: 24)

                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .padding(3)
                    .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 隐私设置页面（无内容安全 Section）
struct CirclePrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var allowSearch: Bool = true
    @State private var contentPreview: Bool = true
    @State private var showMemberList: Bool = true
    @State private var allowPrivateMsg: Bool = false

    @State private var hasChanged: Bool = false
    @State private var isSaving: Bool = false

    private let backgroundColor = Color(red: 240/255, green: 247/255, blue: 244/255)

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        visibilitySection
                        memberProtectionSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.9))
                    )
            }

            Spacer()

            Text("隐私设置")
                .font(.system(size: 16, weight: .bold))

            Spacer()

            Button(action: handleSave) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 40, height: 28)
                } else {
                    Text("保存")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(hasChanged ? AppConstants.Colors.primaryGreen : Color.clear)
                        .foregroundColor(hasChanged ? .white : Color(.systemGray3))
                        .cornerRadius(999)
                        .shadow(
                            color: hasChanged ? AppConstants.Colors.primaryGreen.opacity(0.25) : .clear,
                            radius: 4, x: 0, y: 2
                        )
                }
            }
            .disabled(!hasChanged || isSaving)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            ZStack(alignment: .bottom) {
                backgroundColor.opacity(0.95)
                Divider()
            }
        )
    }

    // 对外展示
    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("对外展示")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(.systemGray3))
                .padding(.leading, 8)

            VStack(spacing: 0) {
                // 允许搜索
                VStack(spacing: 0) {
                    Button(action: {
                        allowSearch.toggle()
                        markChanged()
                    }) {
                        HStack {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(allowSearch ? Color.blue.opacity(0.08) : Color(.systemGray6))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 16))
                                        .foregroundColor(allowSearch ? .blue : .secondary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("允许被搜索")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("关闭后，只能通过邀请链接加入")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            toggleView(isOn: allowSearch)
                        }
                        .padding(12)
                    }

                    if !allowSearch {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text("注意：关闭后将无法获得任何自然流量推荐。")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.06))
                    }
                }

                Divider()
                    .background(Color(.systemGray6))

                // 内容预览
                Button(action: {
                    contentPreview.toggle()
                    markChanged()
                }) {
                    HStack {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(contentPreview ? AppConstants.Colors.primaryGreen.opacity(0.1) : Color(.systemGray6))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "globe.asia.australia.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(contentPreview ? AppConstants.Colors.primaryGreen : .secondary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("允许游客预览")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("未加入成员可查看部分精华内容")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        toggleView(isOn: contentPreview)
                    }
                    .padding(12)
                }
            }
            .background(Color.white)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AppConstants.Colors.primaryGreen.opacity(0.06), lineWidth: 1)
            )
        }
    }

    // 成员保护
    private var memberProtectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("成员保护")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(.systemGray3))
                .padding(.leading, 8)

            VStack(spacing: 0) {
                // 成员列表可见性
                Button(action: {
                    showMemberList.toggle()
                    markChanged()
                }) {
                    HStack {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray6))
                                    .frame(width: 36, height: 36)
                                Image(systemName: showMemberList ? "person.3.fill" : "eye.slash.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("公开成员列表")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("关闭后，普通成员无法查看群成员列表")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        toggleView(isOn: showMemberList)
                    }
                    .padding(12)
                }

                Divider()
                    .background(Color(.systemGray6))

                // 禁止陌生人私信
                Button(action: {
                    allowPrivateMsg.toggle()
                    markChanged()
                }) {
                    HStack {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.08))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "text.bubble.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("禁止陌生人私信")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("开启后，非好友成员无法发起私聊")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        toggleView(isOn: allowPrivateMsg)
                    }
                    .padding(12)
                }
            }
            .background(Color.white)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AppConstants.Colors.primaryGreen.opacity(0.06), lineWidth: 1)
            )
        }
    }

    // 小开关
    private func toggleView(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? AppConstants.Colors.primaryGreen : Color(.systemGray4))
                .frame(width: 44, height: 24)

            Circle()
                .fill(Color.white)
                .frame(width: 18, height: 18)
                .padding(3)
                .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
        }
    }

    private func handleSave() {
        guard hasChanged, !isSaving else { return }
        isSaving = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            hasChanged = false
        }
    }

    private func markChanged() {
        if !hasChanged {
            hasChanged = true
        }
    }
}
// MARK: - 入群门槛页面
struct CircleEntryThresholdView: View {
    @Environment(\.dismiss) private var dismiss

    private enum EntryMode {
        case publicFree
        case approval
        case paid
    }

    @State private var mode: EntryMode = .approval
    @State private var price: String = "29.90"
    @State private var question: String = "你为什么想加入这个圈子？"
    @State private var allowInvite: Bool = true

    @State private var isSaving = false
    @State private var hasChanged = false

    private let backgroundColor = Color(red: 240/255, green: 247/255, blue: 244/255)

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        modeSection
                        inviteSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }

    // 顶部导航
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.9))
                    )
            }

            Spacer()

            Text("入群门槛")
                .font(.system(size: 16, weight: .bold))

            Spacer()

            Button(action: handleSave) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 40, height: 28)
                } else {
                    Text("保存")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(hasChanged ? AppConstants.Colors.primaryGreen : Color.clear)
                        .foregroundColor(hasChanged ? .white : Color(.systemGray3))
                        .cornerRadius(999)
                        .shadow(
                            color: hasChanged ? AppConstants.Colors.primaryGreen.opacity(0.25) : .clear,
                            radius: 4, x: 0, y: 2
                        )
                }
            }
            .disabled(!hasChanged || isSaving)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            ZStack(alignment: .bottom) {
                backgroundColor.opacity(0.95)
                Divider()
            }
        )
    }

    // 模式选择
    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("加入方式")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(.systemGray3))
                .padding(.leading, 8)

            VStack(spacing: 10) {
                modeCard(
                    mode: .publicFree,
                    title: "免费公开",
                    subtitle: "用户可直接加入圈子，无需审核。适合开放性较强的兴趣社群。",
                    systemImage: "person.3.fill"
                )

                modeCard(
                    mode: .approval,
                    title: "需要审核",
                    subtitle: "用户申请后需管理员同意方可加入。适合私密或高质量社群。",
                    systemImage: "shield.fill",
                    extraContent: approvalExtra
                )

                modeCard(
                    mode: .paid,
                    title: "付费加入",
                    subtitle: "支付费用后自动入群。适合知识付费或门槛较高的社群。",
                    systemImage: "creditcard.fill",
                    extraContent: paidExtra
                )
            }
        }
    }

    private func modeCard(
        mode cardMode: EntryMode,
        title: String,
        subtitle: String,
        systemImage: String,
        extraContent: (() -> AnyView)? = nil
    ) -> some View {
        let isSelected = (mode == cardMode)

        return Button(action: {
            if mode != cardMode {
                mode = cardMode
                markChanged()
            }
        }) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppConstants.Colors.primaryGreen.opacity(0.12) : Color(.systemGray6))
                        .frame(width: 40, height: 40)
                    Image(systemName: systemImage)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? AppConstants.Colors.primaryGreen : .secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isSelected ? AppConstants.Colors.primaryGreen : .primary)

                        Spacer()

                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundColor(isSelected ? AppConstants.Colors.primaryGreen : Color(.systemGray4))
                    }

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if isSelected, let extra = extraContent {
                        extra()
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isSelected ? 1.0 : 0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? AppConstants.Colors.primaryGreen : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? AppConstants.Colors.primaryGreen.opacity(0.18) : .clear,
                            radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // 审核模式附加内容
    private func approvalExtra() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 6) {
                Divider()
                    .background(Color(.systemGray6))
                    .padding(.vertical, 4)

                HStack(spacing: 4) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 11))
                    Text("设置入群问题")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(AppConstants.Colors.primaryGreen)

                TextEditor(text: $question)
                    .frame(minHeight: 60)
                    .padding(8)
                    .background(AppConstants.Colors.primaryGreen.opacity(0.06))
                    .cornerRadius(10)
                    .font(.system(size: 12))
                    .onChange(of: question) { _ in
                        markChanged()
                    }
            }
            .padding(.top, 4)
        )
    }

    // 付费模式附加内容
    private func paidExtra() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 4) {
                Divider()
                    .background(Color(.systemGray6))
                    .padding(.vertical, 4)

                HStack {
                    Text("入群费用")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppConstants.Colors.primaryGreen)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("¥")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                        TextField("", text: $price)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 70)
                            .onChange(of: price) { _ in
                                markChanged()
                            }
                    }
                }
                .padding(10)
                .background(AppConstants.Colors.primaryGreen.opacity(0.06))
                .cornerRadius(12)

                Text("* 平台将收取 1% 技术服务费")
                    .font(.system(size: 10))
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.top, 2)
        )
    }

    // 邀请权限
    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("允许成员邀请")
                            .font(.system(size: 14, weight: .bold))
                        Text("开启后，普通成员可邀请好友直接入群")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                switchView(isOn: allowInvite) {
                    allowInvite.toggle()
                    markChanged()
                }
            }

            if !allowInvite {
                Text("注意：关闭后，仅管理员可邀请或通过搜索加入。")
                    .font(.system(size: 10))
                    .foregroundColor(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.06))
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppConstants.Colors.primaryGreen.opacity(0.06), lineWidth: 1)
        )
    }

    // 小开关（复用账户设置的样式）
    private func switchView(isOn: Bool, toggle: @escaping () -> Void) -> some View {
        Button(action: toggle) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? AppConstants.Colors.primaryGreen : Color(.systemGray4))
                    .frame(width: 44, height: 24)

                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .padding(3)
                    .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func handleSave() {
        guard hasChanged, !isSaving else { return }
        isSaving = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSaving = false
            hasChanged = false
        }
    }

    private func markChanged() {
        if !hasChanged {
            hasChanged = true
        }
    }
}

// MARK: - 数据模型
struct CircleStatData: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let trend: String
    let isUp: Bool
    let gradientColors: [Color]
}

struct CircleRevenueData {
    let total: Double
    let membership: Double
    let tips: Double
}

struct CircleJoinRequest: Identifiable {
    let id = UUID()
    let name: String
    let avatar: String
    let description: String
    let time: String
}

struct CircleOperationTool {
    let label: String
    let icon: String
    let color: Color
}

// MARK: - 圈子管理ViewModel
class CircleManagementViewModel: ObservableObject {
    @Published var circles: [OrganizationCircle] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var stats: [CircleStatData] = []
    @Published var revenue: CircleRevenueData = CircleRevenueData(total: 0, membership: 0, tips: 0)
    @Published var joinRequests: [CircleJoinRequest] = []

    private let apiService = OrganizationAPIService.shared

    func loadCircles(status: String) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await apiService.getMyOrganizations(status: status, page: 1, limit: 50)

                await MainActor.run {
                    self.circles = response.data.organizations
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.circles = []
                    self.isLoading = false
                    print("❌ 加载圈子列表失败: \(error)")
                }
            }
        }
    }

    func loadMockData() {
        // 统计数据
        stats = [
            CircleStatData(
                label: "活跃指数",
                value: "98.2",
                trend: "+2.4%",
                isUp: true,
                gradientColors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color.teal]
            ),
            CircleStatData(
                label: "新增禾友",
                value: "1,204",
                trend: "+12.5%",
                isUp: true,
                gradientColors: [Color.blue, Color.cyan]
            ),
            CircleStatData(
                label: "内容产出",
                value: "856",
                trend: "+8.3%",
                isUp: true,
                gradientColors: [Color.purple, Color.pink]
            )
        ]

        // 收益数据
        revenue = CircleRevenueData(
            total: 12845.00,
            membership: 8420,
            tips: 4425
        )

        // 入群申请
        joinRequests = [
            CircleJoinRequest(
                name: "森林漫步者",
                avatar: "https://via.placeholder.com/48",
                description: "热爱户外，想加入组织一起探索自然",
                time: "2分钟前"
            ),
            CircleJoinRequest(
                name: "山野清风",
                avatar: "https://via.placeholder.com/48",
                description: "喜欢徒步和露营，期待认识更多朋友",
                time: "15分钟前"
            )
        ]
    }
}

// MARK: - 预览
#Preview {
    NavigationStack {
        CircleManagementView()
    }
}
