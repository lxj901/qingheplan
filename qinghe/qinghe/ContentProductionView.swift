import SwiftUI

/// 内容产出页面
struct ContentProductionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var timeRange: TimeRange = .week
    @State private var showLeaderboard = false

    enum TimeRange {
        case week
        case month
    }

    // 发帖趋势数据
    private let trendData: [Double] = [12, 18, 15, 25, 22, 38, 30]

    // 热门话题（左列为主色标签，右列为描边标签）
    private let topics: [ContentTopic] = [
        ContentTopic(id: 1, name: "周末去露营", count: 342, isHot: true, size: .large, style: .primary),
        ContentTopic(id: 2, name: "阳台种菜", count: 128, isHot: false, size: .small, style: .outline),
        ContentTopic(id: 3, name: "徒步路线分享", count: 215, isHot: true, size: .medium, style: .teal),
        ContentTopic(id: 4, name: "胶片摄影", count: 89, isHot: false, size: .xSmall, style: .outline),
        ContentTopic(id: 5, name: "每日穿搭", count: 156, isHot: false, size: .small, style: .orange)
    ]

    // 优质内容榜
    private let topContents: [TopContentItem] = [
        TopContentItem(
            id: 1,
            title: "整理了一份新手露营装备清单，防坑必看！⛺️",
            author: "山野观察员",
            coverStyle: .color(Color(red: 0.75, green: 0.93, blue: 0.82)),
            type: .image,
            views: "2.4k",
            likes: 342,
            comments: 56,
            score: 9.8
        ),
        TopContentItem(
            id: 2,
            title: "沉浸式雨天徒步，听声音就很治愈...",
            author: "ForestLife",
            coverStyle: .color(Color(red: 0.15, green: 0.17, blue: 0.21)),
            type: .video,
            views: "1.8k",
            likes: 289,
            comments: 82,
            score: 9.5
        ),
        TopContentItem(
            id: 3,
            title: "关于在这个城市租房的一些避雷经验",
            author: "漂泊者",
            coverStyle: .none,
            type: .text,
            views: "980",
            likes: 124,
            comments: 230,
            score: 8.9
        )
    ]

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.97, blue: 0.96)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        coreBoardSection
                        trendSection
                        topicsSection
                        topContentSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showLeaderboard) {
            ContentLeaderboardView()
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

            Text("内容产出")
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
                .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - 核心看板
    private var coreBoardSection: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.64, blue: 0.62), Color(red: 0.09, green: 0.63, blue: 0.50)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 简单的波纹装饰
            VStack(spacing: 0) {
                Spacer()
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 40)
                    .offset(y: 10)
                    .blur(radius: 16)
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 14))
                        Text("本周发帖量")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color.white.opacity(0.9))

                    Text("156")
                        .font(.system(size: 34, weight: .black))
                        .foregroundColor(.white)

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("互动率")
                                .font(.system(size: 10))
                                .foregroundColor(Color.white.opacity(0.8))
                            Text("4.8%")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("优质贴")
                                .font(.system(size: 10))
                                .foregroundColor(Color.white.opacity(0.8))
                            Text("12篇")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.9))
                        )

                    Text("+12% 环比")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.9))
                }
            }
            .padding(18)
        }
        .cornerRadius(32)
        .shadow(color: Color(red: 0.0, green: 0.24, blue: 0.19).opacity(0.5), radius: 18, x: 0, y: 10)
    }

    // MARK: - 产出趋势 & 内容成分
    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                    Text("产出趋势")
                        .font(.system(size: 15, weight: .bold))
                }

                Spacer()

                HStack(spacing: 4) {
                    timeRangeButton(title: "周", range: .week)
                    timeRangeButton(title: "月", range: .month)
                }
                .padding(4)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
            }

            ContentAreaChart(data: trendData)
                .frame(height: 120)

            VStack(alignment: .leading, spacing: 8) {
                Text("内容成分分析")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)

                // 合成进度条
                HStack(spacing: 0) {
                    Capsule()
                        .fill(AppConstants.Colors.primaryGreen)
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .leading) { EmptyView() }
                        .frame(width: nil)
                        .layoutPriority(55)

                    Capsule()
                        .fill(Color(red: 0.11, green: 0.74, blue: 0.70))
                        .frame(maxWidth: .infinity)
                        .layoutPriority(30)

                    Capsule()
                        .fill(Color.orange)
                        .frame(maxWidth: .infinity)
                        .layoutPriority(15)
                }
                .frame(height: 10)
                .clipShape(Capsule())
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                )

                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(AppConstants.Colors.primaryGreen).frame(width: 6, height: 6)
                        Text("图文 55%")
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color(red: 0.11, green: 0.74, blue: 0.70)).frame(width: 6, height: 6)
                        Text("视频 30%")
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.orange).frame(width: 6, height: 6)
                        Text("纯文 15%")
                    }
                }
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private func timeRangeButton(title: String, range: TimeRange) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                timeRange = range
            }
        } label: {
            Text(title)
                .font(.system(size: 11, weight: timeRange == range ? .bold : .regular))
                .foregroundColor(timeRange == range ? AppConstants.Colors.primaryGreen : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Group {
                        if timeRange == range {
                            Color.white
                                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
                        } else {
                            Color.clear
                        }
                    }
                )
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 热门话题云
    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "number")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                    Text("热门话题")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                Text("近7天热度")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .top, spacing: 12) {
                // 左列：主色标签（实心背景）
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(topics.filter { $0.style != .outline }) { topic in
                        TopicTagView(topic: topic)
                    }
                }

                // 右列：描边浅色标签
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(topics.filter { $0.style == .outline }) { topic in
                        TopicTagView(topic: topic)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - 优质内容榜
    private var topContentSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("优质内容榜")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    // 预留筛选动作
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color.gray.opacity(0.06))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.05))
                    .frame(height: 1),
                alignment: .bottom
            )

            VStack(spacing: 0) {
                ForEach(Array(topContents.enumerated()), id: \.1.id) { index, item in
                    TopContentRow(item: item, rank: index + 1)
                        .background(Color.white)

                    if index != topContents.count - 1 {
                        Divider()
                            .padding(.leading, 60)
                            .background(Color.gray.opacity(0.05))
                    }
                }
            }

            Button {
                showLeaderboard = true
            } label: {
                Text("查看完整榜单")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppConstants.Colors.primaryGreen.opacity(0.06))
            }
        }
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 面积图视图
struct ContentAreaChart: View {
    let data: [Double]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let maxValue = data.max() ?? 1
            let normalizedPoints: [CGPoint] = data.enumerated().map { index, value in
                let x = size.width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                let y = size.height * (1 - CGFloat(value / maxValue) * 0.8)
                return CGPoint(x: x, y: y)
            }

            ZStack {
                if !normalizedPoints.isEmpty {
                    // 填充区域
                    Path { path in
                        guard let first = normalizedPoints.first, let last = normalizedPoints.last else { return }
                        path.move(to: CGPoint(x: first.x, y: size.height))
                        path.addLine(to: first)
                        for point in normalizedPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: last.x, y: size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                AppConstants.Colors.primaryGreen.opacity(0.3),
                                AppConstants.Colors.primaryGreen.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // 折线
                    Path { path in
                        guard let first = normalizedPoints.first else { return }
                        path.move(to: first)
                        for point in normalizedPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(
                        AppConstants.Colors.primaryGreen,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )

                    // 高亮点 & 提示
                    if let highlightPoint = normalizedPoints.dropLast().last {
                        Circle()
                            .fill(Color.white)
                            .overlay(
                                Circle()
                                    .stroke(AppConstants.Colors.primaryGreen, lineWidth: 2)
                            )
                            .frame(width: 8, height: 8)
                            .position(highlightPoint)

                        // 浮动 Tip
                        VStack(spacing: 4) {
                            Text("38篇")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.85))
                                .cornerRadius(8)

                            TrianglePointer()
                                .fill(Color.black.opacity(0.85))
                                .frame(width: 8, height: 4)
                        }
                        .position(
                            x: min(highlightPoint.x + 36, size.width - 30),
                            y: max(highlightPoint.y - 24, 10)
                        )
                    }
                }
            }
        }
    }
}

// 小三角指示器
private struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 话题 Tag
private struct TopicTagView: View {
    let topic: ContentTopic

    var body: some View {
        HStack(spacing: 4) {
            Text("#\(topic.name)")
                .font(topic.font)
                .fontWeight(.bold)

            if topic.isHot {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
            }

            Text("\(topic.count)")
                .font(.system(size: 10))
                .opacity(0.6)
                .padding(.leading, 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(topic.background)
        .foregroundColor(topic.foreground)
        .overlay(
            topic.borderColor.map { color in
                RoundedRectangle(cornerRadius: topic.cornerRadius)
                    .stroke(color, lineWidth: 1)
            }
        )
        .cornerRadius(topic.cornerRadius)
    }
}

// MARK: - 优质内容行
private struct TopContentRow: View {
    let item: TopContentItem
    let rank: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 排名
            Text("\(rank)")
                .font(.system(size: 14, weight: .bold))
                .italic()
                .foregroundColor(rankColor)
                .frame(width: 24, alignment: .leading)
                .padding(.top, 4)

            // 封面
            ZStack {
                switch item.coverStyle {
                case .color(let color):
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color)
                case .none:
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.gray.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )

                    // 纯文字内容的占位图标
                    if item.type == .text {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.gray.opacity(0.6))
                    }
                }

                if item.type == .video {
                    Color.black.opacity(0.3)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 26, height: 26)

                        TrianglePointer()
                            .rotation(Angle(degrees: 90))
                            .fill(Color.black)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .frame(width: 72, height: 72)

            // 文字内容
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(item.author)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 3, height: 3)

                    Text("质量分 \(String(format: "%.1f", item.score))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                }

                HStack {
                    HStack(spacing: 8) {
                        Label(item.views, systemImage: "eye")
                        Label("\(item.likes)", systemImage: "heart")
                        Label("\(item.comments)", systemImage: "bubble.right")
                    }
                    .labelStyle(CompactLabelStyle())
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                    Spacer()

                    Button(action: {
                        // 更多操作
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color.gray.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var rankColor: Color {
        rank <= 3 ? .orange : .gray.opacity(0.4)
    }
}

// 紧凑 Label 样式（图标 + 小号文字）
private struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
                .font(.system(size: 9))
            configuration.title
        }
    }
}

// MARK: - 数据模型
struct ContentTopic: Identifiable {
    enum Size {
        case xSmall, small, medium, large
    }

    enum Style {
        case primary
        case outline
        case teal
        case orange
    }

    let id: Int
    let name: String
    let count: Int
    let isHot: Bool
    let size: Size
    let style: Style
}

extension ContentTopic {
    var font: Font {
        switch size {
        case .xSmall: return .system(size: 10)
        case .small: return .system(size: 12)
        case .medium: return .system(size: 14)
        case .large: return .system(size: 16)
        }
    }

    var background: Color {
        switch style {
        case .primary:
            return Color(red: 0.88, green: 0.96, blue: 0.91)
        case .outline:
            return Color.white
        case .teal:
            return Color(red: 0.90, green: 0.96, blue: 0.96)
        case .orange:
            return Color(red: 1.0, green: 0.95, blue: 0.90)
        }
    }

    var foreground: Color {
        switch style {
        case .primary:
            return Color(red: 0.06, green: 0.51, blue: 0.34)
        case .outline:
            return Color.gray
        case .teal:
            return Color(red: 0.09, green: 0.54, blue: 0.55)
        case .orange:
            return Color(red: 0.87, green: 0.44, blue: 0.14)
        }
    }

    var borderColor: Color? {
        switch style {
        case .outline:
            return Color.gray.opacity(0.2)
        default:
            return nil
        }
    }

    var cornerRadius: CGFloat { 999 }
}

struct TopContentItem: Identifiable {
    enum CoverStyle {
        case color(Color)
        case none
    }

    enum ContentType {
        case image
        case video
        case text
    }

    let id: Int
    let title: String
    let author: String
    let coverStyle: CoverStyle
    let type: ContentType
    let views: String
    let likes: Int
    let comments: Int
    let score: Double
}

// MARK: - 预览
#Preview {
    NavigationStack {
        ContentProductionView()
    }
}
