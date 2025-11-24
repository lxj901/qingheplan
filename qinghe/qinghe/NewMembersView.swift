import SwiftUI

/// 新增禾友页面
struct NewMembersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var activeTab: ActiveTab = .list
    @State private var searchText: String = ""

    enum ActiveTab {
        case list
        case analysis
    }

    // 模拟数据 - 近7天趋势
    private let growthData: [GrowthDataPoint] = [
        GrowthDataPoint(day: "周一", count: 12, heightFactor: 0.35),
        GrowthDataPoint(day: "周二", count: 18, heightFactor: 0.55),
        GrowthDataPoint(day: "周三", count: 8,  heightFactor: 0.25),
        GrowthDataPoint(day: "周四", count: 24, heightFactor: 0.70),
        GrowthDataPoint(day: "周五", count: 15, heightFactor: 0.45),
        GrowthDataPoint(day: "周六", count: 32, heightFactor: 0.95),
        GrowthDataPoint(day: "周日", count: 28, heightFactor: 0.85)
    ]

    // 模拟数据 - 新成员列表
    private let newMembers: [NewMember] = [
        NewMember(
            id: 1,
            name: "山谷里的风",
            avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Wind",
            joinTime: "10分钟前",
            source: "搜索发现",
            inviter: nil,
            tag: "摄影小白",
            status: .new,
            intro: "喜欢拍云和树，请多指教 ☁️"
        ),
        NewMember(
            id: 2,
            name: "周末去野餐",
            avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Picnic",
            joinTime: "1小时前",
            source: "成员邀请",
            inviter: "露营达人",
            tag: "美食党",
            status: .normal,
            intro: "带好吃的求组队！🍱"
        ),
        NewMember(
            id: 3,
            name: "Moss",
            avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Moss",
            joinTime: "3小时前",
            source: "活动二维码",
            inviter: nil,
            tag: "装备控",
            status: .normal,
            intro: "硬核徒步爱好者。"
        ),
        NewMember(
            id: 4,
            name: "小松鼠",
            avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Squirrel",
            joinTime: "5小时前",
            source: "首页推荐",
            inviter: nil,
            tag: "潜水员",
            status: .normal,
            intro: "默默围观..."
        )
    ]

    // 模拟数据 - 来源占比
    private let sourceStats: [SourceStat] = [
        SourceStat(label: "搜索发现", percent: 45, color: Color(red: 0.12, green: 0.75, blue: 0.49)),
        SourceStat(label: "首页推荐", percent: 30, color: Color(red: 0.13, green: 0.69, blue: 0.67)),
        SourceStat(label: "成员邀请", percent: 15, color: Color(red: 0.64, green: 0.80, blue: 0.22)),
        SourceStat(label: "活动海报", percent: 10, color: Color.orange)
    ]

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.97, blue: 0.96)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        overviewSection
                        growthTrendSection
                        membersSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }

    // MARK: - 顶部导航
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.6))
                    )
            }

            Spacer()

            Text("新增禾友")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                // 预留日期筛选动作
            }) {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.6))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            Color(red: 0.94, green: 0.97, blue: 0.96)
                .opacity(0.9)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - 核心数据概览
    private var overviewSection: some View {
        HStack(spacing: 12) {
            // 今日新增
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.07, green: 0.67, blue: 0.48), Color(red: 0.05, green: 0.52, blue: 0.60)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 80, height: 80)
                    .offset(x: 40, y: -40)
                    .blur(radius: 18)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("今日新增")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Color.white.opacity(0.9))

                    Text("24")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 10, weight: .bold))
                        Text("+12% 较昨日")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(10)
                }
                .padding(14)
            }
            .cornerRadius(24)
            .shadow(color: Color(red: 0.07, green: 0.67, blue: 0.48).opacity(0.25), radius: 12, x: 0, y: 6)

            // 本周新增
            ZStack {
                Color.white

                Circle()
                    .fill(Color(red: 0.88, green: 0.97, blue: 0.92))
                    .frame(width: 80, height: 80)
                    .offset(x: 36, y: 40)
                    .blur(radius: 18)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("本周累计")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.secondary)

                    Text("137")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                        Text("持续增长中")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                }
                .padding(14)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(red: 0.86, green: 0.96, blue: 0.92), lineWidth: 1)
            )
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        }
    }

    // MARK: - 近7天趋势
    private var growthTrendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("近7天趋势")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(AppConstants.Colors.primaryGreen)
                        .frame(width: 6, height: 6)
                    Text("人数")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            GrowthBarChart(data: growthData)
                .frame(height: 160)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    // MARK: - 新成员列表 & 来源分析
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("新成员列表")
                    .font(.system(size: 18, weight: .bold))

                Spacer()

                HStack(spacing: 4) {
                    segmentButton(title: "列表", tab: .list)
                    segmentButton(title: "来源", tab: .analysis)
                }
                .padding(4)
                .background(Color.white)
                .cornerRadius(999)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 2)

            if activeTab == .list {
                membersListView
            } else {
                sourceAnalysisView
            }
        }
    }

    private func segmentButton(title: String, tab: ActiveTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                activeTab = tab
            }
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(activeTab == tab ? .white : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Group {
                        if activeTab == tab {
                            AppConstants.Colors.primaryGreen
                        } else {
                            Color.clear
                        }
                    }
                )
                .cornerRadius(999)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 列表视图
    private var membersListView: some View {
        VStack(spacing: 0) {
            // 搜索框
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    TextField("搜索新成员", text: $searchText)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                .cornerRadius(18)
            }
            .padding(12)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.06))
                    .frame(height: 1),
                alignment: .bottom
            )

            // 列表
            VStack(spacing: 0) {
                ForEach(filteredMembers) { member in
                    NewMemberRow(member: member)
                        .background(Color.white)
                    Divider()
                        .padding(.leading, 68)
                        .background(Color.gray.opacity(0.05))
                }
            }

            Button(action: {
                // 加载更多历史记录
            }) {
                Text("显示更多历史记录")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private var filteredMembers: [NewMember] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return newMembers
        }
        let keyword = searchText.trimmingCharacters(in: .whitespaces)
        return newMembers.filter { member in
            member.name.contains(keyword) || member.tag.contains(keyword)
        }
    }

    // MARK: - 来源分析视图
    private var sourceAnalysisView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("入群渠道占比")
                .font(.system(size: 14, weight: .bold))

            ForEach(sourceStats) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.label)
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(item.percent)%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.1))

                            Capsule()
                                .fill(item.color)
                                .frame(width: geometry.size.width * CGFloat(item.percent) / 100.0)
                        }
                    }
                    .frame(height: 8)
                }
            }

            Divider()
                .padding(.vertical, 4)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                    .padding(.top, 2)

                Text("运营建议：本周搜索流量占比提升明显，建议优化圈子关键词和简介，提升曝光转化率。")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.71, green: 0.37, blue: 0.09))
            }
            .padding(10)
            .background(Color.orange.opacity(0.08))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 新成员行
private struct NewMemberRow: View {
    let member: NewMember

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                RemoteAvatarView(urlString: member.avatar)
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )

                if member.status == .new {
                    NewBadgeView()
                        .offset(x: 4, y: -4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(member.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(member.tag)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppConstants.Colors.primaryGreen.opacity(0.08))
                        .cornerRadius(6)
                }

                Text(member.intro)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10))
                        Text("来自: \(member.source)")
                            .font(.system(size: 10))
                        if let inviter = member.inviter {
                            Text("@\(inviter)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppConstants.Colors.primaryGreen)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.06))
                    .cornerRadius(999)
                    .foregroundColor(.secondary)

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: {
                            // 欢迎/打招呼
                        }) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppConstants.Colors.primaryGreen)
                                .padding(6)
                                .background(AppConstants.Colors.primaryGreen.opacity(0.12))
                                .clipShape(Circle())
                        }

                        Button(action: {
                            // 更多操作
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(6)
                                .background(Color.gray.opacity(0.08))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.top, 6)
            }

            Text(member.joinTime)
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - 新成员 “NEW” 徽标
private struct NewBadgeView: View {
    @State private var animate: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.25))
                .frame(width: animate ? 18 : 10, height: animate ? 18 : 10)
                .opacity(animate ? 0 : 1)
            Circle()
                .fill(AppConstants.Colors.primaryGreen)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        .onAppear {
            withAnimation(
                .easeOut(duration: 1.2)
                    .repeatForever(autoreverses: false)
            ) {
                animate = true
            }
        }
    }
}

// MARK: - 柱状图视图
struct GrowthBarChart: View {
    let data: [GrowthDataPoint]

    var body: some View {
        GeometryReader { geometry in
            let maxHeight = geometry.size.height

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(data) { item in
                    VStack(spacing: 6) {
                        Text("\(item.count)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        RoundedRectangle(cornerRadius: 999)
                            .fill(AppConstants.Colors.primaryGreen.opacity(item.isHighlight ? 0.9 : 0.4))
                            .frame(width: 10, height: maxHeight * item.heightFactor)

                        Text(item.day)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }
}

// MARK: - 数据模型
struct GrowthDataPoint: Identifiable {
    let id = UUID()
    let day: String
    let count: Int
    let heightFactor: CGFloat

    var isHighlight: Bool {
        count >= 24
    }
}

struct NewMember: Identifiable {
    enum Status {
        case new
        case normal
    }

    let id: Int
    let name: String
    let avatar: String
    let joinTime: String
    let source: String
    let inviter: String?
    let tag: String
    let status: Status
    let intro: String
}

struct SourceStat: Identifiable {
    let id = UUID()
    let label: String
    let percent: Int
    let color: Color
}

// MARK: - 预览
#Preview {
    NavigationStack {
        NewMembersView()
    }
}

