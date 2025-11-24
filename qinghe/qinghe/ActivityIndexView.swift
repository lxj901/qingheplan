import SwiftUI

/// 圈子活跃指数页面
struct ActivityIndexView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var activePeriod: ActivePeriod = .sevenDays
    @State private var showContributionLeaderboard = false

    enum ActivePeriod {
        case sevenDays
        case thirtyDays
    }

    // 模拟数据（与前端示例保持一致）
    private let weeklyData: [Double] = [40, 65, 55, 80, 72, 90, 98]
    private let radarItems: [RadarItem] = [
        RadarItem(label: "内容度", value: 85, icon: "bolt.fill", color: .yellow, bgColor: Color.yellow.opacity(0.1)),
        RadarItem(label: "互动数", value: 92, icon: "bubble.left.and.bubble.right.fill", color: .blue, bgColor: Color.blue.opacity(0.08)),
        RadarItem(label: "增长力", value: 68, icon: "chart.line.uptrend.xyaxis", color: .green, bgColor: Color.green.opacity(0.08)),
        RadarItem(label: "留存率", value: 75, icon: "person.2.fill", color: .purple, bgColor: Color.purple.opacity(0.08)),
        RadarItem(label: "消费力", value: 50, icon: "eye.fill", color: .pink, bgColor: Color.pink.opacity(0.08))
    ]
    private let topUsers: [TopUser] = [
        TopUser(id: 1, name: "森系生活", score: 982, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Forest"),
        TopUser(id: 2, name: "露营达人", score: 875, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Camp"),
        TopUser(id: 3, name: "植物研究所", score: 840, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Plant")
    ]

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.97, blue: 0.96)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        coreIndexCard
                        trendCard
                        dimensionCard
                        contributionCard
                        footerTip
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showContributionLeaderboard) {
            ContributionLeaderboardView()
        }
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

            Text("活跃指数")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                // 预留分享动作
            }) {
                Image(systemName: "square.and.arrow.up")
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
                .ignoresSafeArea(edges: .top) // 让导航栏背景延伸到状态栏区域
        )
    }

    // MARK: - 核心指数卡片
    private var coreIndexCard: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.64, blue: 0.49), Color(red: 0.05, green: 0.46, blue: 0.52)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 180, height: 180)
                .offset(x: 80, y: -80)
                .blur(radius: 20)

            Circle()
                .fill(Color.green.opacity(0.25))
                .frame(width: 140, height: 140)
                .offset(x: -80, y: 80)
                .blur(radius: 18)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 6) {
                    Text("当前指数")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.9))

                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.7))
                }

                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text("98.2")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                        Text("+2.4%")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(Color(red: 0.74, green: 0.93, blue: 0.84))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(10)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.25))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.75, green: 0.94, blue: 0.83), .white],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * 0.98)
                            .shadow(color: .white.opacity(0.5), radius: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("低")
                    Spacer()
                    Text("中")
                    Spacer()
                    Text("高")
                    Spacer()
                    Text("极高")
                        .foregroundColor(.white)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.8))
            }
            .padding(20)
        }
        .cornerRadius(32)
        .shadow(color: Color.green.opacity(0.25), radius: 18, x: 0, y: 10)
    }

    // MARK: - 趋势分析卡片
    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                        .font(.system(size: 16))
                    Text("趋势分析")
                        .font(.system(size: 15, weight: .bold))
                }

                Spacer()

                HStack(spacing: 4) {
                    periodButton(title: "近7天", period: .sevenDays)
                    periodButton(title: "近30天", period: .thirtyDays)
                }
                .padding(4)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(20)
            }

            ActivityTrendChart(data: weeklyData)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                    .padding(.top, 2)

                Text("本周活跃度持续走高，主要由「周末摄影打卡」活动带动。")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(AppConstants.Colors.primaryGreen.opacity(0.06))
            .cornerRadius(14)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private func periodButton(title: String, period: ActivePeriod) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                activePeriod = period
            }
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(activePeriod == period ? AppConstants.Colors.primaryGreen : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Group {
                        if activePeriod == period {
                            Color.white
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        } else {
                            Color.clear
                        }
                    }
                )
                .cornerRadius(999)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 维度分析
    private var dimensionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("维度分析")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Text("超过 85% 同类圈子")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                ForEach(radarItems, id: \.label) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(item.bgColor)
                                        .frame(width: 26, height: 26)

                                    Image(systemName: item.icon)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(item.color)
                                }

                                Text(item.label)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            Text("\(item.value)")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.primary)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.12))

                                Capsule()
                                    .fill(item.label == "消费力" ? Color.pink.opacity(0.8) : AppConstants.Colors.primaryGreen)
                                    .frame(width: geometry.size.width * CGFloat(item.value) / 100.0)
                            }
                        }
                        .frame(height: 8)

                        if item.value < 60 {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 10))
                                Text("指数偏低，建议发起投票或抽奖")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.pink)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    // MARK: - 活跃贡献榜
    private var contributionCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("活跃贡献榜")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Button {
                    showContributionLeaderboard = true
                } label: {
                    HStack(spacing: 4) {
                        Text("查看全部")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.06)),
                alignment: .bottom
            )

            VStack(spacing: 0) {
                ForEach(Array(topUsers.enumerated()), id: \.1.id) { index, user in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 18, weight: .bold))
                            .italic()
                            .foregroundColor(rankColor(index: index))
                            .frame(width: 28)

                        ZStack(alignment: .topTrailing) {
                            RemoteAvatarView(urlString: user.avatar)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())

                            if index == 0 {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.yellow)
                                    .offset(x: 4, y: -4)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)
                            Text("贡献活跃值 \(user.score)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("No.\(index + 1)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppConstants.Colors.primaryGreen.opacity(0.08))
                            .cornerRadius(999)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white)

                    if index != topUsers.count - 1 {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private func rankColor(index: Int) -> Color {
        switch index {
        case 0:
            return .yellow
        case 1:
            return .gray
        default:
            return .orange
        }
    }

    // MARK: - 底部提示
    private var footerTip: some View {
        Text("数据每日凌晨 02:00 更新")
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }
}

// MARK: - 趋势图表视图
struct ActivityTrendChart: View {
    let data: [Double]
    @State private var animatePulse = false

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                let size = geometry.size
                let maxValue = data.max() ?? 1
                let minValue = data.min() ?? 0
                let range = max(maxValue - minValue, 1)

                let points: [CGPoint] = data.enumerated().map { index, value in
                    let x = size.width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                    let normalized = (value - minValue) / range
                    let y = size.height * (1 - CGFloat(normalized))
                    return CGPoint(x: x, y: y)
                }

                ZStack {
                    if !points.isEmpty {
                        // 面积填充
                        Path { path in
                            guard let first = points.first, let last = points.last else { return }
                            path.move(to: CGPoint(x: first.x, y: size.height))
                            path.addLine(to: first)
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                            path.addLine(to: CGPoint(x: last.x, y: size.height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppConstants.Colors.primaryGreen.opacity(0.25),
                                    AppConstants.Colors.primaryGreen.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // 折线
                        Path { path in
                            guard let first = points.first else { return }
                            path.move(to: first)
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                        .stroke(
                            AppConstants.Colors.primaryGreen,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )

                        // 中间数据点
                        ForEach(Array(points.dropLast().enumerated()), id: \.0) { _, point in
                            Circle()
                                .fill(Color.white)
                                .overlay(
                                    Circle()
                                        .stroke(AppConstants.Colors.primaryGreen, lineWidth: 1)
                                )
                                .frame(width: 6, height: 6)
                                .position(point)
                        }

                        // 最后一个闪烁点
                        if let lastPoint = points.last {
                            Circle()
                                .fill(AppConstants.Colors.primaryGreen.opacity(0.2))
                                .frame(width: animatePulse ? 24 : 8, height: animatePulse ? 24 : 8)
                                .position(lastPoint)
                                .opacity(animatePulse ? 0 : 1)
                                .animation(
                                    .easeOut(duration: 1.0)
                                        .repeatForever(autoreverses: false),
                                    value: animatePulse
                                )

                            Circle()
                                .fill(Color.white)
                                .overlay(
                                    Circle()
                                        .stroke(AppConstants.Colors.primaryGreen, lineWidth: 2)
                                )
                                .frame(width: 10, height: 10)
                                .position(lastPoint)
                        }
                    }
                }
            }
            .frame(height: 130)

            HStack {
                Text("11-14")
                Spacer()
                Text("11-16")
                Spacer()
                Text("11-18")
                Spacer()
                Text("今天")
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
        }
        .onAppear {
            animatePulse = true
        }
    }
}

// MARK: - 远程头像视图
struct RemoteAvatarView: View {
    let urlString: String

    var body: some View {
        if let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(.secondary)
                @unknown default:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(.secondary)
                }
            }
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFill()
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 数据模型
struct RadarItem {
    let label: String
    let value: Int
    let icon: String
    let color: Color
    let bgColor: Color
}

struct TopUser: Identifiable {
    let id: Int
    let name: String
    let score: Int
    let avatar: String
}

// MARK: - 预览
#Preview {
    NavigationStack {
        ActivityIndexView()
    }
}
