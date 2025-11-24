import SwiftUI

// MARK: - 数据模型

private enum LeaderboardPeriod: String, CaseIterable, Identifiable {
    case weekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: return "周榜"
        case .monthly: return "月榜"
        }
    }

    var badgeText: String {
        switch self {
        case .weekly: return "Weekly Best"
        case .monthly: return "Monthly Best"
        }
    }
}

private enum LeaderboardContentType {
    case video
    case image
    case article
}

private struct LeaderboardItem: Identifiable {
    let id: Int
    let rank: Int
    let title: String
    let author: String
    let imageURL: String
    let type: LeaderboardContentType
    let score: Double
    let views: String
    let trend: Int
}

// MARK: - 示例数据（与前端保持一致）

private enum ContentLeaderboardMockData {
    static let weekly: [LeaderboardItem] = [
        LeaderboardItem(
            id: 1,
            rank: 1,
            title: "秋日露营指南：如何用最少的装备拍出大片？",
            author: "山野观察员",
            imageURL: "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
            type: .image,
            score: 9.9,
            views: "12.5k",
            trend: 1
        ),
        LeaderboardItem(
            id: 2,
            rank: 2,
            title: "沉浸式雨天徒步，白噪音治愈系列",
            author: "ForestLife",
            imageURL: "https://images.unsplash.com/photo-1519681393784-d120267933ba?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
            type: .video,
            score: 9.7,
            views: "8.2k",
            trend: 0
        ),
        LeaderboardItem(
            id: 3,
            rank: 3,
            title: "中医养生：入秋后的饮食禁忌清单",
            author: "本草纲目",
            imageURL: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
            type: .article,
            score: 9.5,
            views: "6.8k",
            trend: 2
        ),
        LeaderboardItem(
            id: 4,
            rank: 4,
            title: "我的极简书桌改造计划 (附清单)",
            author: "整理收纳师",
            imageURL: "https://images.unsplash.com/photo-1493934558415-9d19f0b2b4d2?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
            type: .image,
            score: 9.3,
            views: "5.4k",
            trend: 1
        ),
        LeaderboardItem(
            id: 5,
            rank: 5,
            title: "早起打卡第100天，身体发生了什么变化？",
            author: "自律狂人",
            imageURL: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
            type: .article,
            score: 9.1,
            views: "4.9k",
            trend: -1
        ),
        LeaderboardItem(
            id: 6,
            rank: 6,
            title: "周末去哪儿：城市周边的隐秘森林",
            author: "探险家",
            imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
            type: .image,
            score: 8.9,
            views: "4.2k",
            trend: 3
        ),
        LeaderboardItem(
            id: 7,
            rank: 7,
            title: "胶片摄影入门：如何选择第一台相机",
            author: "FilmLover",
            imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
            type: .article,
            score: 8.8,
            views: "3.5k",
            trend: 0
        )
    ]

    // Demo：月榜暂时复用周榜数据，后续可替换为接口数据
    static let monthly: [LeaderboardItem] = weekly
}

// MARK: - 主页面

struct ContentLeaderboardView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var period: LeaderboardPeriod = .weekly
    @State private var isLoading = false
    @State private var hasScrolled = false

    private var items: [LeaderboardItem] {
        switch period {
        case .weekly: return ContentLeaderboardMockData.weekly
        case .monthly: return ContentLeaderboardMockData.monthly
        }
    }

    private var top1: LeaderboardItem? {
        items.indices.contains(0) ? items[0] : nil
    }

    private var top2: LeaderboardItem? {
        items.indices.contains(1) ? items[1] : nil
    }

    private var top3: LeaderboardItem? {
        items.indices.contains(2) ? items[2] : nil
    }

    private var restItems: [LeaderboardItem] {
        Array(items.dropFirst(3))
    }

    var body: some View {
        ZStack(alignment: .top) {
            cinematicBackground

            VStack(spacing: 0) {
                navBar

                ScrollView(showsIndicators: false) {
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: LeaderboardScrollOffsetKey.self,
                                value: geo.frame(in: .named("LeaderboardScroll")).minY
                            )
                    }
                    .frame(height: 0)

                    VStack(spacing: 0) {
                        headerSection
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                        podiumSection
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 16)

                        listSection
                    }
                    .padding(.bottom, 24)
                }
                .coordinateSpace(name: "LeaderboardScroll")
                .onPreferenceChange(LeaderboardScrollOffsetKey.self) { value in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hasScrolled = value < -50
                    }
                }
            }
        }
        .background(Color.leaderboardBackground.ignoresSafeArea())
    }

    // MARK: 顶部背景（深绿渐变 + 高光），贴近设计图

    private var cinematicBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#01211A"),
                    Color(hex: "#064E3B"),
                    Color.leaderboardBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color.white.opacity(0.08))
                .blur(radius: 80)
                .frame(width: 340, height: 240)
                .offset(y: -40)

            Circle()
                .fill(Color(hex: "#34D399").opacity(0.25))
                .blur(radius: 90)
                .frame(width: 260, height: 200)
                .offset(y: -20)
        }
        .ignoresSafeArea()
    }

    // MARK: 导航栏

    private var navBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(hasScrolled ? Color(.systemGray6) : Color.white.opacity(0.16))
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("优质内容榜")
                .font(.system(size: 14, weight: .bold))
                .opacity(hasScrolled ? 1 : 0)
                .offset(y: hasScrolled ? 0 : 4)

            Spacer()

            Button {
                // 分享占位
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(hasScrolled ? Color(.systemGray6) : Color.white.opacity(0.16))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .foregroundColor(hasScrolled ? .primary : .white)
        .background(
            Group {
                if hasScrolled {
                    Color.white.opacity(0.9)
                        .overlay(
                            Divider()
                                .opacity(0.7),
                            alignment: .bottom
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                } else {
                    Color.clear
                }
            }
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: 头部标题 + 周 / 月切换

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部黄色 WEEKLY BEST / MONTHLY BEST 徽章
            Text(period.badgeText)
                .font(.system(size: 10, weight: .black))
                .textCase(.uppercase)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: "#FCD34D"))
                .foregroundColor(Color(hex: "#78350F"))
                .cornerRadius(999)
                .shadow(color: Color(hex: "#FCD34D").opacity(0.4), radius: 8, x: 0, y: 4)

            // 标题在左，周榜 / 月榜切换在右，整体竖直居中对齐
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("内容风向标")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.45), radius: 10, x: 0, y: 4)

                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#FCD34D"))

                        Text("发现社区最值得读的好内容")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#D1FAE5").opacity(0.9))
                    }
                }

                Spacer()

                periodToggle
            }

            // 中间的皇冠图标（仅保留这一处），紧挨标题组下方
            HStack {
                Spacer()
                Image(systemName: "crown.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "#FCD34D"))
                    .shadow(color: Color(hex: "#FCD34D").opacity(0.6), radius: 12, x: 0, y: 4)
                Spacer()
            }
            .padding(.top, 6)
        }
    }

    private var periodToggle: some View {
        ZStack {
            Capsule()
                .fill(Color.black.opacity(0.28))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )

            HStack(spacing: 2) {
                ForEach(LeaderboardPeriod.allCases) { option in
                    Button {
                        guard period != option else { return }

                        period = option
                        isLoading = true

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                isLoading = false
                            }
                        }
                    } label: {
                        Text(option.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(
                                period == option ? Color(hex: "#064E3B") : Color.white.opacity(0.8)
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                Group {
                                    if period == option {
                                        Capsule()
                                            .fill(Color.white)
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
        }
        .frame(width: 146, height: 40) // 按照设计要求的整体尺寸
    }

    // MARK: 顶部 3D 悬浮领奖台

    private var podiumSection: some View {
        ZStack {
            let sideWidth: CGFloat = 140
            let centerWidth: CGFloat = 190

            if let item2 = top2 {
                PodiumSideCard(item: item2, isLeft: true, width: sideWidth)
                    .offset(x: -90, y: 30)
            }

            if let item3 = top3 {
                PodiumSideCard(item: item3, isLeft: false, width: sideWidth)
                    .offset(x: 90, y: 30)
            }

            if let item1 = top1 {
                PodiumCenterCard(item: item1, width: centerWidth)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 240)
    }

    // MARK: 列表区域

    private var listSection: some View {
        VStack(spacing: 0) {
            // 列表头
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "rosette")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#059669"))

                    Text("精选榜单")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#064E3B"))
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 12))
                    Text("筛选内容")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.8))
                .foregroundColor(Color(hex: "#047857").opacity(0.7))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // 列表内容
            if isLoading {
                SkeletonListView()
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(restItems) { item in
                        GlassRowView(item: item)
                    }

                    Button {
                        // 预留：查看更多
                    } label: {
                        HStack(spacing: 4) {
                            Text("查看完整 100 名")
                            Image(systemName: "chevron.down")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#059669"))
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - 顶部领奖台卡片（固定宽高，避免图片加载撑宽）

private struct PodiumCenterCard: View {
    let item: LeaderboardItem
    let width: CGFloat

    var body: some View {
        let height = width * 4 / 3

        ZStack(alignment: .bottomLeading) {
            // 图片填满卡片区域，不改变卡片自身尺寸
            Group {
                if let url = URL(string: item.imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Color.gray.opacity(0.3)
                        }
                    }
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: width, height: height)
            .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.9), Color.black.opacity(0.15), Color.clear],
                startPoint: .bottom,
                endPoint: .top
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "flame.fill")
                                .foregroundColor(Color(hex: "#F97316"))
                                .font(.system(size: 11, weight: .bold))
                        )

                    Text("Top Pick")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#FCD34D"))
                }

                Text(item.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)

                    Text("质量分")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.9))

                    Text(String(format: "%.1f", item.score))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(item.views) 阅读")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 16)
        }
        .frame(width: width, height: height)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "#FCD34D").opacity(0.6), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.55), radius: 26, x: 0, y: 18)
        .padding(.top, 24)
    }
}

private struct PodiumSideCard: View {
    let item: LeaderboardItem
    let isLeft: Bool
    let width: CGFloat

    var body: some View {
        let height = width * 4 / 3

        ZStack(alignment: .bottomLeading) {
            Group {
                if let url = URL(string: item.imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Color.gray.opacity(0.3)
                        }
                    }
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: width, height: height)
            .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.9), Color.clear],
                startPoint: .bottom,
                endPoint: .top
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.author)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#E5E7EB"))
                    .lineLimit(1)

                Text(item.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            .padding(10)
        }
        .frame(width: width, height: height)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .overlay(
            rankBadge,
            alignment: isLeft ? .topLeading : .topTrailing
        )
        .scaleEffect(0.94)
        .offset(x: isLeft ? 6 : -6, y: 14)
        .rotation3DEffect(
            .degrees(isLeft ? 8 : -8),
            axis: (x: 0, y: 1, z: 0),
            anchor: isLeft ? .bottomTrailing : .bottomLeading,
            perspective: 0.9
        )
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 14)
    }

    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.2))

            Text("\(item.rank)")
                .font(.system(size: 16, weight: .black, design: .serif))
                .italic()
                .foregroundColor(.white)
        }
        .frame(width: 28, height: 28)
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .offset(x: isLeft ? -8 : 8, y: -8)
    }
}

// MARK: - Glass 列表行

private struct GlassRowView: View {
    let item: LeaderboardItem

    var body: some View {
        HStack(spacing: 12) {
            // 排名列
            VStack(spacing: 4) {
                Text(String(format: "%02d", item.rank))
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .italic()
                    .foregroundColor(Color.gray.opacity(0.4))

                if item.trend > 0 {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#F97373"))
                } else if item.trend == 0 {
                    Text("-")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.gray.opacity(0.4))
                }
            }
            .frame(width: 34)

            // 封面
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let url = URL(string: item.imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            default:
                                Color.gray.opacity(0.2)
                            }
                        }
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(width: 96, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                TypeDot(type: item.type)
                    .offset(x: -4, y: -4)
            }

            // 文本内容
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))
                    .lineLimit(2)

                HStack {
                    Text(item.author)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text(String(format: "%.1f", item.score))
                    }
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .foregroundColor(Color(hex: "#10B981"))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 类型圆形标签（视频 / 图文 / 文章）

private struct TypeDot: View {
    let type: LeaderboardContentType

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)

            Image(systemName: iconName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 22, height: 22)
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: backgroundColor.opacity(0.5), radius: 4, x: 0, y: 2)
    }

    private var backgroundColor: Color {
        switch type {
        case .video: return Color(hex: "#E11D48")
        case .image: return Color(hex: "#2563EB")
        case .article: return Color(hex: "#059669")
        }
    }

    private var iconName: String {
        switch type {
        case .video: return "play.fill"
        case .image: return "photo"
        case .article: return "doc.text"
        }
    }
}

// MARK: - 骨架屏

private struct SkeletonListView: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { _ in
                SkeletonRow()
            }
        }
    }
}

private struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 120, height: 10)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 50)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.7))
        )
    }
}

// MARK: - Scroll 偏移量

private struct LeaderboardScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - 颜色扩展

extension Color {
    static let leaderboardBackground = Color(hex: "#F2F5F4")
}

// MARK: - 预览

#Preview {
    NavigationStack {
        ContentLeaderboardView()
    }
}
