import SwiftUI

/// 活跃贡献榜 - 全部榜单页面
struct ContributionLeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var period: Period = .weekly

    enum Period {
        case weekly
        case monthly
    }

    // 榜单数据模型
    struct LeaderboardEntry: Identifiable {
        enum Trend {
            case up
            case down
            case same
        }

        let id: Int
        let name: String
        let score: Int
        let avatar: String
        let trend: Trend
        let trendValue: Int
    }

    struct MyRankInfo {
        let rank: Int
        let name: String
        let score: Int
        let avatar: String
        let trend: LeaderboardEntry.Trend
        let trendValue: Int
    }

    // MARK: - 模拟数据

    private let weeklyData: [LeaderboardEntry] = [
        LeaderboardEntry(id: 1, name: "森系生活", score: 982, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Forest", trend: .up, trendValue: 2),
        LeaderboardEntry(id: 2, name: "露营达人", score: 875, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Camp", trend: .same, trendValue: 0),
        LeaderboardEntry(id: 3, name: "植物研究所", score: 840, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Plant", trend: .down, trendValue: 1),
        LeaderboardEntry(id: 4, name: "山谷里的风", score: 765, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Wind", trend: .up, trendValue: 5),
        LeaderboardEntry(id: 5, name: "周末去野餐", score: 720, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Picnic", trend: .up, trendValue: 12),
        LeaderboardEntry(id: 6, name: "Moss", score: 690, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Moss", trend: .same, trendValue: 0),
        LeaderboardEntry(id: 7, name: "小松鼠", score: 650, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Squirrel", trend: .down, trendValue: 3),
        LeaderboardEntry(id: 8, name: "云端漫步", score: 610, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Cloud", trend: .up, trendValue: 1),
        LeaderboardEntry(id: 9, name: "DeepBlue", score: 580, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Blue", trend: .same, trendValue: 0),
        LeaderboardEntry(id: 10, name: "早安", score: 550, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Morning", trend: .down, trendValue: 2)
    ]

    private let monthlyData: [LeaderboardEntry] = [
        LeaderboardEntry(id: 2, name: "露营达人", score: 3400, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Camp", trend: .up, trendValue: 1),
        LeaderboardEntry(id: 1, name: "森系生活", score: 3200, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Forest", trend: .down, trendValue: 1),
        LeaderboardEntry(id: 3, name: "植物研究所", score: 2900, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Plant", trend: .same, trendValue: 0),
        LeaderboardEntry(id: 4, name: "山谷里的风", score: 2600, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Wind", trend: .up, trendValue: 3),
        LeaderboardEntry(id: 5, name: "周末去野餐", score: 2450, avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Picnic", trend: .up, trendValue: 6)
    ]

    private let myRank = MyRankInfo(
        rank: 12,
        name: "我",
        score: 420,
        avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Me",
        trend: .up,
        trendValue: 4
    )

    // 当前榜单
    private var currentList: [LeaderboardEntry] {
        period == .weekly ? weeklyData : monthlyData
    }

    private var top3: [LeaderboardEntry] {
        Array(currentList.prefix(3))
    }

    private var rest: [LeaderboardEntry] {
        Array(currentList.dropFirst(3))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 顶部渐变背景
            LinearGradient(
                colors: [AppConstants.Colors.primaryGreen, Color(red: 0.94, green: 0.97, blue: 0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                periodTabs
                podiumSection
                listSection
            }

            myRankBar
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }

    // MARK: - 顶部导航栏
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                    )
            }

            Spacer()

            Text("活跃贡献榜")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Button(action: {
                // TODO: 分享榜单
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - 周榜 / 月榜切换
    private var periodTabs: some View {
        HStack {
            Spacer()
            HStack(spacing: 0) {
                periodButton(title: "周榜", target: .weekly)
                periodButton(title: "月榜", target: .monthly)
            }
            .padding(4)
            .background(Color.black.opacity(0.25))
            .cornerRadius(999)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private func periodButton(title: String, target: Period) -> some View {
        let isActive = period == target
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                period = target
            }
        }) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
                .background(isActive ? Color.white : Color.clear)
                .foregroundColor(isActive ? AppConstants.Colors.primaryGreen : Color.white.opacity(0.8))
                .cornerRadius(999)
                .shadow(color: isActive ? Color.black.opacity(0.2) : .clear, radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 前三名领奖台
    private var podiumSection: some View {
        HStack(alignment: .bottom, spacing: 16) {
            if top3.count >= 2 {
                podiumItem(entry: top3[1], rankLabel: "NO.2", rankColor: .gray, isCenter: false)
                    .offset(y: 12)
            }

            if let first = top3.first {
                podiumItem(entry: first, rankLabel: "NO.1", rankColor: .yellow, isCenter: true)
                    .offset(y: -4)
            }

            if top3.count >= 3 {
                podiumItem(entry: top3[2], rankLabel: "NO.3", rankColor: .orange, isCenter: false)
                    .offset(y: 12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
        .padding(.bottom, 16)
    }

    private func podiumItem(entry: LeaderboardEntry, rankLabel: String, rankColor: Color, isCenter: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                if isCenter {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.yellow)
                        .offset(y: -34)
                        .shadow(color: Color.yellow.opacity(0.6), radius: 6, x: 0, y: 4)
                }

                VStack(spacing: 6) {
                    ZStack(alignment: .bottom) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: isCenter ? 76 : 64, height: isCenter ? 76 : 64)
                            .overlay(
                                Circle()
                                    .stroke(rankColor.opacity(isCenter ? 0.8 : 0.6), lineWidth: isCenter ? 4 : 2)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: isCenter ? 10 : 6, x: 0, y: 4)

                        RemoteAvatarView(urlString: entry.avatar)
                            .clipShape(Circle())
                            .frame(width: isCenter ? 72 : 60, height: isCenter ? 72 : 60)
                    }

                    Text(entry.name)
                        .font(.system(size: isCenter ? 14 : 13, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: isCenter ? 84 : 72)
                        .lineLimit(1)

                    Text("\(entry.score)")
                        .font(.system(size: isCenter ? 14 : 12, weight: .black))
                        .foregroundColor(isCenter ? .yellow : AppConstants.Colors.primaryGreen)
                }
            }
        }
    }

    // MARK: - 榜单列表
    private var listSection: some View {
        VStack(spacing: 0) {
            // 白色背景容器
            VStack(spacing: 12) {
                HStack {
                    Text("排名 / 用户")
                    Spacer()
                    Text("活跃值")
                }
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(Array(rest.enumerated()), id: \.element.id) { index, user in
                            rowView(for: user, index: index + 4)
                        }
                    }
                    .padding(.bottom, 80) // 留出底部「我的排名」空间
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: -4)
            )
        }
    }

    private func rowView(for user: LeaderboardEntry, index: Int) -> some View {
        HStack {
            HStack(spacing: 10) {
                Text("\(index)")
                    .font(.system(size: 13, weight: .bold))
                    .italic()
                    .foregroundColor(.secondary)
                    .frame(width: 24, alignment: .center)

                ZStack(alignment: .bottomTrailing) {
                    RemoteAvatarView(urlString: user.avatar)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )

                    if index <= 6 {
                        Circle()
                            .fill(AppConstants.Colors.primaryGreen)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .offset(x: 2, y: 2)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    trendView(user.trend, value: user.trendValue)
                }
            }

            Spacer()

            Text("\(user.score)")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(AppConstants.Colors.primaryGreen)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }

    // MARK: - 我的排名底部栏
    private var myRankBar: some View {
        VStack {
            Divider()
                .background(Color.gray.opacity(0.2))

            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Text("\(myRank.rank)")
                        .font(.system(size: 13, weight: .bold))
                        .italic()
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                        .frame(width: 24, alignment: .center)

                    RemoteAvatarView(urlString: myRank.avatar)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(AppConstants.Colors.primaryGreen.opacity(0.3), lineWidth: 2)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(myRank.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)

                            Text("我")
                                .font(.system(size: 10))
                                .foregroundColor(AppConstants.Colors.primaryGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppConstants.Colors.primaryGreen.opacity(0.12))
                                .cornerRadius(6)
                        }

                        trendView(myRank.trend, value: myRank.trendValue)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(myRank.score)")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                    Text("距上一名差 15 分")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - 趋势视图
    @ViewBuilder
    private func trendView(_ trend: LeaderboardEntry.Trend, value: Int) -> some View {
        switch trend {
        case .up:
            HStack(spacing: 2) {
                Image(systemName: "arrow.up.right")
                Text("\(value)")
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.red)

        case .down:
            HStack(spacing: 2) {
                Image(systemName: "arrow.down.right")
                Text("\(value)")
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(AppConstants.Colors.primaryGreen)

        case .same:
            HStack(spacing: 2) {
                Image(systemName: "minus")
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - 预览
#Preview {
    NavigationStack {
        ContributionLeaderboardView()
    }
}

