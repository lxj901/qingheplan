import SwiftUI
import Charts
import UIKit

/// 数据中心视图 - 全新设计
struct DataCenterView: View {
    @StateObject private var viewModel = DataCenterViewModel()
    @State private var selectedTimeRange: TimeRange = .sevenDays
    @State private var activeMetric: MetricType = .views
    @Environment(\.dismiss) private var dismiss

    enum TimeRange: String, CaseIterable {
        case sevenDays = "近7天"
        case thirtyDays = "近30天"
        case custom = "自定义"

        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .custom: return 7
            }
        }
    }

    enum MetricType {
        case views, fans, profile, interaction
    }

    var body: some View {
        ZStack {
            Color(red: 0.965, green: 0.969, blue: 0.976)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部导航栏
                topNavigationBar

                // 主滚动区域
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 1. 核心指标概览
                        coreMetricsSection

                        // 2. 作品表现
                        videoPerformanceSection

                        // 3. 粉丝画像
                        audienceProfileSection

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadStatistics(days: selectedTimeRange.days)
            viewModel.loadAudienceAnalysis(days: selectedTimeRange.days)
        }
    }

    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        VStack(spacing: 0) {
            navigationHeader
            timeRangeSelector
                .padding(.bottom, 8)
        }
        .background(Color.white.opacity(0.9))
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 0.5)
                .offset(y: 1),
            alignment: .bottom
        )
    }

    private var navigationHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
            }

            Spacer()

            Text("数据分析")
                .font(.system(size: 18, weight: .bold))

            Spacer()

            Button(action: {}) {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    private var timeRangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                timeRangeButton(for: range)
            }
        }
        .padding(4)
        .background(Color(red: 0.94, green: 0.94, blue: 0.94))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    private func timeRangeButton(for range: TimeRange) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTimeRange = range
                viewModel.loadStatistics(days: range.days)
                viewModel.loadAudienceAnalysis(days: range.days)
            }
        }) {
            Text(range.rawValue)
                .font(.system(size: 12, weight: selectedTimeRange == range ? .semibold : .regular))
                .foregroundColor(selectedTimeRange == range ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    Group {
                        if selectedTimeRange == range {
                            Color.white
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        } else {
                            Color.clear
                        }
                    }
                )
                .cornerRadius(10)
        }
    }

    // MARK: - 核心指标概览
    private var coreMetricsSection: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("核心指标")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.6))

                Spacer()

                Text("数据更新至 12:00")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)

            // 指标卡片网格
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(
                    title: "总播放量",
                    value: formatNumber(viewModel.statistics?.overview.totalViews ?? 0),
                    trend: "+12%",
                    icon: "eye.fill",
                    isActive: activeMetric == .views,
                    action: { activeMetric = .views }
                )

                MetricCard(
                    title: "净增粉丝",
                    value: "2,345",
                    trend: "+5.2%",
                    icon: "person.2.fill",
                    isActive: activeMetric == .fans,
                    action: { activeMetric = .fans }
                )

                MetricCard(
                    title: "主页访问",
                    value: "45.2k",
                    trend: "-1.2%",
                    icon: "chart.line.uptrend.xyaxis",
                    isNegative: true,
                    isActive: activeMetric == .profile,
                    action: { activeMetric = .profile }
                )

                MetricCard(
                    title: "互动总量",
                    value: formatNumber(viewModel.statistics?.overview.totalLikes ?? 0),
                    trend: "+8.4%",
                    icon: "heart.fill",
                    isActive: activeMetric == .interaction,
                    action: { activeMetric = .interaction }
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)

            // 趋势图表
            trendChart
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 2)
    }

    // 趋势图表
    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 0) {
            chartContent

            // X轴日期
            HStack {
                Spacer().frame(width: 30)
                HStack {
                    ForEach(["11.14", "11.16", "11.18", "11.20"], id: \.self) { date in
                        Text(date)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.6))
                        if date != "11.20" {
                            Spacer()
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .cornerRadius(12)
    }

    // 图表内容
    private var chartContent: some View {
        ZStack(alignment: .topLeading) {
            yAxisLabels
            mainChart
        }
    }

    // Y轴刻度
    private var yAxisLabels: some View {
        VStack(spacing: 0) {
            ForEach(["200k", "100k", "50k", "0"], id: \.self) { label in
                HStack {
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.4))
                    Spacer()
                }
                if label != "0" {
                    Spacer()
                }
            }
        }
        .frame(height: 192)
    }

    // 主图表
    private var mainChart: some View {
        Group {
            if viewModel.statistics?.overview != nil {
                Chart {
                    ForEach(viewModel.mockChartData, id: \.date) { item in
                        LineMark(
                            x: .value("日期", item.date),
                            y: .value("数值", item.value)
                        )
                        .foregroundStyle(Color(red: 0.06, green: 0.73, blue: 0.51))
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                        AreaMark(
                            x: .value("日期", item.date),
                            y: .value("数值", item.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                    colors: [
                                        Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.2),
                                        Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 192)
                .padding(.leading, 30)
            } else {
                ProgressView()
                    .frame(height: 192)
                    .padding(.leading, 30)
            }
        }
    }

    // MARK: - 作品表现区域
    private var videoPerformanceSection: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("近期作品表现")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Text("按播放量")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)

            // 作品列表
            VStack(spacing: 16) {
                VideoPerformanceItem(
                    title: "沉浸式整理我的书桌 | 极简主义生活",
                    date: "昨天 18:30",
                    views: "45.2w",
                    likes: "3.4w",
                    ctr: "12.5%",
                    playRate: "68%",
                    score: 92
                )

                VideoPerformanceItem(
                    title: "Vlog 03: 这里的秋天像画一样",
                    date: "11月18日",
                    views: "28.8w",
                    likes: "1.2w",
                    ctr: "8.2%",
                    playRate: "45%",
                    score: 78
                )
            }
            .padding(.horizontal, 16)

            // 查看全部按钮
            NavigationLink(destination: WorksListView().asSubView()) {
                HStack(spacing: 4) {
                    Text("查看全部作品")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 2)
    }

    // MARK: - 粉丝画像区域
    private var audienceProfileSection: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text("粉丝画像")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)

            // 性别分布
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: 8, height: 8)
                        Text("男性 35%")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.pink.opacity(0.6))
                            .frame(width: 8, height: 8)
                        Text("女性 65%")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                // 性别分布条
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: UIScreen.main.bounds.width * 0.35 - 32)
                    Rectangle()
                        .fill(Color.pink.opacity(0.6))
                }
                .frame(height: 12)
                .cornerRadius(6)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }

            // 活跃时间分布
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("活跃时间分布")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // 活跃时间柱状图
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach([20, 35, 45, 30, 60, 90, 100, 85, 50, 40, 25, 15], id: \.self) { height in
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(height == 100 ? Color(red: 0.4, green: 0.87, blue: 0.65) : Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.15))
                                .frame(height: CGFloat(height) * 0.8)
                                .cornerRadius(2, corners: [.topLeft, .topRight])
                        }
                    }
                }
                .frame(height: 96)
                .padding(.horizontal, 16)

                // X轴标签
                HStack {
                    Text("0点")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.4))
                    Spacer()
                    Text("12点")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.4))
                    Spacer()
                    Text("24点")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 2)
    }

    // MARK: - 辅助方法
    private func formatNumber(_ number: Int) -> String {
        if number >= 10000 {
            return String(format: "%.1fw", Double(number) / 10000.0)
        } else if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

// MARK: - 子组件

/// 指标卡片组件
struct MetricCard: View {
    let title: String
    let value: String
    let trend: String
    let icon: String
    var isNegative: Bool = false
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // 标题和图标
                HStack {
                    Text(title)
                        .font(.system(size: 12))
                        .foregroundColor(isActive ? Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.8) : .secondary)

                    Spacer()

                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(isActive ? Color(red: 0.06, green: 0.73, blue: 0.51) : .secondary.opacity(0.6))
                        .padding(4)
                        .background(isActive ? Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.15) : Color.secondary.opacity(0.08))
                        .cornerRadius(6)
                }
                .padding(.bottom, 8)

                // 数值
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)

                // 趋势
                HStack(spacing: 2) {
                    Image(systemName: isNegative ? "arrow.down.right" : "arrow.up.right")
                        .font(.system(size: 10))
                    Text(trend)
                        .font(.system(size: 10))
                }
                .foregroundColor(isNegative ? .green : .red)
            }
            .padding(12)
            .background(isActive ? Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.05) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 视频表现项组件
struct VideoPerformanceItem: View {
    let title: String
    let date: String
    let views: String
    let likes: String
    let ctr: String
    let playRate: String
    let score: Int

    var body: some View {
        NavigationLink(destination: SingleWorkAnalysisView().asSubView()) {
            contentView
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var contentView: some View {
        HStack(spacing: 12) {
            // 封面图
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 128)
                    .cornerRadius(8)

                // 播放量标签
                HStack(spacing: 2) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 8))
                    Text(views)
                        .font(.system(size: 9))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.5))
                .cornerRadius(4)
                .padding(4)

                // 评分角标
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(score)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .padding(4)
                    }
                }
            }
            .frame(width: 96, height: 128)

            // 数据详情
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .padding(.bottom, 4)

                Text(date)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)

                Spacer()

                // 数据网格
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        DataCell(label: "点赞", value: likes)
                        DataCell(label: "点击率", value: ctr)
                    }
                    HStack(spacing: 8) {
                        DataCell(label: "完播率", value: playRate, isHighlight: true)
                        Button(action: {}) {
                            HStack(spacing: 2) {
                                Text("详情")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8))
                                    .foregroundColor(.orange)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(8)
                .background(Color(red: 0.97, green: 0.98, blue: 0.98))
                .cornerRadius(8)
            }
        }
        .padding(.bottom, 16)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 0.5)
                .padding(.top, 160),
            alignment: .bottom
        )
    }
}

/// 数据单元格组件
struct DataCell: View {
    let label: String
    let value: String
    var isHighlight: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isHighlight ? Color(red: 0.06, green: 0.73, blue: 0.51) : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 数据中心ViewModel
class DataCenterViewModel: ObservableObject {
    @Published var statistics: CreatorStatisticsData?
    @Published var audienceAnalysis: AudienceAnalysisData?
    @Published var isLoading: Bool = false

    // 模拟图表数据
    var mockChartData: [ChartDataPoint] {
        [
            ChartDataPoint(date: "11.14", value: 80000),
            ChartDataPoint(date: "11.15", value: 75000),
            ChartDataPoint(date: "11.16", value: 60000),
            ChartDataPoint(date: "11.17", value: 65000),
            ChartDataPoint(date: "11.18", value: 40000),
            ChartDataPoint(date: "11.19", value: 45000),
            ChartDataPoint(date: "11.20", value: 20000)
        ]
    }

    func loadStatistics(days: Int) {
        isLoading = true
        Task {
            do {
                let stats = try await CreatorAPIService.shared.fetchStatistics(days: days)
                await MainActor.run {
                    self.statistics = stats
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("❌ 加载统计数据失败: \(error)")
            }
        }
    }

    func loadAudienceAnalysis(days: Int) {
        Task {
            do {
                let analysis = try await CreatorAPIService.shared.fetchAudienceAnalysis(days: days)
                await MainActor.run {
                    self.audienceAnalysis = analysis
                }
            } catch {
                print("❌ 加载用户画像失败: \(error)")
            }
        }
    }

    var genderPairs: [(String, Double)] {
        guard let a = audienceAnalysis else { return [] }
        return a.gender.compactMap { ($0.gender == "male" ? "男" : "女", parsePercent($0.percentage)) }
    }

    var agePairs: [(String, Double)] {
        guard let a = audienceAnalysis else { return [] }
        return a.age.compactMap { ($0.range, parsePercent($0.percentage)) }
    }

    var locationPairs: [(String, Double)] {
        guard let a = audienceAnalysis else { return [] }
        return a.location.compactMap { ($0.location, parsePercent($0.percentage)) }
    }

    private func parsePercent(_ text: String) -> Double {
        let cleaned = text.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned) ?? 0
    }
}

// MARK: - 图表数据模型
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: String
    let value: Double
}

// MARK: - 预览
#Preview {
    NavigationStack {
        DataCenterView()
    }
}
