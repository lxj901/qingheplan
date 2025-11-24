import SwiftUI

struct SleepInsightsView: View {
    @ObservedObject private var sleepManager = SleepDataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedInsightType: SleepInsightType?
    @State private var selectedTab: InsightTab = .overview
    @State private var showingDetailView = false

    // 本地数据状态
    @State private var isLoadingData = false

    enum InsightTab: String, CaseIterable {
        case overview = "概览"
        case personalized = "个性化"
        case improvement = "改善建议"

        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .personalized: return "person.crop.circle.fill"
            case .improvement: return "lightbulb.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            // 简化的背景 - 提高性能
            Color(red: 0.08, green: 0.12, blue: 0.25)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 自定义顶部导航栏
                customNavigationBar

                // 分段控制器
                segmentedControl

                // 主要内容区域 - 使用条件渲染替代TabView提高性能
                Group {
                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .personalized:
                        personalizedContent
                    case .improvement:
                        improvementContent
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadLocalSleepInsights()
        }
    }

    // MARK: - UI 组件

    private var customNavigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("返回")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
            }

            Spacer()

            Text("睡眠建议")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            // 占位符保持平衡
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                Text("返回")
                    .font(.system(size: 16, weight: .medium))
            }
            .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 15)
    }

    private var segmentedControl: some View {
        HStack(spacing: 4) {
            ForEach(InsightTab.allCases, id: \.self) { tab in
                Button(action: {
                    if selectedTab != tab {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTab = tab
                        }
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: .medium))

                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedTab == tab ? Color.white.opacity(0.15) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle()) // 提高性能
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.1))
        )
        .padding(.horizontal, 20)
    }

    // MARK: - 内容页面

    private var overviewContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 24, pinnedViews: []) {
                // 加载状态
                if isLoadingData {
                    loadingView
                        .id("loading-view")
                } else {
                    // 睡眠健康评估卡片
                    sleepHealthOverviewCard
                        .id("health-card")

                    // 快速洞察卡片
                    quickInsightsGrid
                        .id("insights-grid")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
        .scrollContentBackground(.hidden)
        .refreshable {
            loadLocalSleepInsights()
        }
    }

    private var personalizedContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16, pinnedViews: []) {
                // 个性化建议列表
                personalizedInsightsSection
                    .id("personalized-insights")
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
        .scrollContentBackground(.hidden)
    }

    private var improvementContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16, pinnedViews: []) {
                // 睡眠改善建议
                sleepImprovementTipsSection
                    .id("improvement-tips")
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - 睡眠健康概览卡片
    
    private var sleepHealthOverviewCard: some View {
        VStack(spacing: 18) {
            sleepHealthHeader
            sleepHealthMetrics
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    private var sleepHealthHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("睡眠健康评估")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("基于最近7天的睡眠数据")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            if let localStatistics = sleepManager.sleepStatistics {
                VStack(spacing: 2) {
                    Text("\(Int(localStatistics.averageSleepQuality))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("总分")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.15))
                )
            }
        }
    }

    private var sleepHealthMetrics: some View {
        Group {
            if let localStatistics = sleepManager.sleepStatistics {
                // 使用本地数据的健康指标网格
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        optimizedHealthMetricCard(
                            title: "睡眠时长",
                            value: formatDuration(localStatistics.averageSleepDuration),
                            score: calculateDurationScore(localStatistics.averageSleepDuration),
                            icon: "moon.zzz.fill",
                            color: Color(red: 0.4, green: 0.6, blue: 1.0)
                        )

                        optimizedHealthMetricCard(
                            title: "睡眠质量",
                            value: "\(Int(localStatistics.averageSleepQuality))分",
                            score: Int(localStatistics.averageSleepQuality),
                            icon: "heart.fill",
                            color: Color(red: 0.8, green: 0.4, blue: 0.9)
                        )
                    }

                    HStack(spacing: 12) {
                        optimizedHealthMetricCard(
                            title: "睡眠效率",
                            value: "\(Int(localStatistics.averageSleepEfficiency * 100))%",
                            score: Int(localStatistics.averageSleepEfficiency * 100),
                            icon: "gauge.high",
                            color: Color(red: 0.2, green: 0.8, blue: 0.6)
                        )

                        optimizedHealthMetricCard(
                            title: "作息规律",
                            value: String(format: "%.2f分", localStatistics.consistencyScore),
                            score: Int(localStatistics.consistencyScore),
                            icon: "clock.fill",
                            color: Color(red: 1.0, green: 0.6, blue: 0.4)
                        )
                    }
                }
            } else {
                emptyStateView
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.6))

            VStack(spacing: 8) {
                Text("开始您的睡眠之旅")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("记录睡眠数据，获得个性化的健康建议")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 120)
    }
    
    // MARK: - 个性化建议列表
    
    private var personalizedInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                
                Text("个性化建议")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(generatePersonalizedInsights()) { insight in
                    insightCard(insight)
                }
            }
        }
    }
    
    private func insightCard(_ insight: SleepInsight) -> some View {
        HStack(spacing: 12) {
            // 优先级指示器
            RoundedRectangle(cornerRadius: 2)
                .fill(insight.priority.color)
                .frame(width: 4)
            
            // 图标
            Image(systemName: insight.type.icon)
                .font(.system(size: 20))
                .foregroundColor(insight.priority.color)
                .frame(width: 32)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(insight.message ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)
            }
            
            Spacer()
            
            // 可操作指示器
            if insight.actionable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onTapGesture {
            if insight.actionable {
                selectedInsightType = insight.type
            }
        }
    }

    private var quickInsightsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                quickInsightCard(
                    title: "最佳就寝时间",
                    value: getBestBedtime(),
                    subtitle: "基于您的作息分析",
                    icon: "moon.fill",
                    color: Color(red: 0.4, green: 0.6, blue: 1.0)
                )

                quickInsightCard(
                    title: "睡眠债务",
                    value: getSleepDebt(),
                    subtitle: "本周累计不足",
                    icon: "clock.badge.exclamationmark",
                    color: Color(red: 1.0, green: 0.6, blue: 0.4)
                )
            }

            HStack(spacing: 12) {
                quickInsightCard(
                    title: "深度睡眠",
                    value: getDeepSleepPercentage(),
                    subtitle: "占总睡眠时间",
                    icon: "brain.head.profile",
                    color: Color(red: 0.6, green: 0.4, blue: 0.9)
                )

                quickInsightCard(
                    title: "睡眠环境",
                    value: getSleepEnvironmentQuality(),
                    subtitle: "基于环境数据评估",
                    icon: "thermometer.medium",
                    color: Color(red: 0.2, green: 0.8, blue: 0.6)
                )
            }
        }
    }
    
    // MARK: - 睡眠改善建议
    
    private var sleepImprovementTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                
                Text("睡眠改善小贴士")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(sleepImprovementTips, id: \.title) { tip in
                    tipCard(tip)
                }
            }
        }
    }
    
    private func tipCard(_ tip: SleepTip) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tip.icon)
                .font(.system(size: 16))
                .foregroundColor(tip.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(tip.description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - 辅助方法和数据
    
    private func calculateOverallHealthScore(_ statistics: SleepStatistics) -> Int {
        let durationScore = calculateDurationScore(statistics.averageSleepDuration)
        let qualityScore = Int(statistics.averageSleepQuality)
        let efficiencyScore = Int(statistics.averageSleepEfficiency * 100)
        let consistencyScore = statistics.consistencyScore

        return (durationScore + qualityScore + efficiencyScore + Int(consistencyScore)) / 4
    }
    
    private func calculateDurationScore(_ duration: TimeInterval) -> Int {
        let hours = duration / 3600
        if hours >= 7 && hours <= 9 {
            return 100
        } else if hours >= 6 && hours < 7 {
            return 80
        } else if hours >= 5 && hours < 6 {
            return 60
        } else {
            return 40
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100:
            return Color.green
        case 60..<80:
            return Color.orange
        default:
            return Color.red
        }
    }
    
    private func scoreDescription(_ score: Int) -> String {
        switch score {
        case 90...100:
            return "优秀"
        case 80..<90:
            return "良好"
        case 70..<80:
            return "一般"
        case 60..<70:
            return "较差"
        default:
            return "需要改善"
        }
    }
    
    private func generatePersonalizedInsights() -> [SleepInsight] {
        // 基于本地数据生成个性化建议
        var insights: [SleepInsight] = []

        // 使用本地统计数据生成建议
        if let localStatistics = sleepManager.sleepStatistics {
            // 睡眠时长建议
            if localStatistics.averageSleepDuration < 7 * 3600 {
                insights.append(SleepInsight(
                    type: .sleepDuration,
                    title: "增加睡眠时间",
                    message: "您的平均睡眠时间不足7小时，建议提前30分钟上床",
                    description: "您的平均睡眠时间不足7小时，建议提前30分钟上床",
                    priority: .high,
                    actionable: true,
                    createdAt: Date()
                ))
            }

            // 睡眠效率建议
            if localStatistics.averageSleepEfficiency < 0.85 {
                insights.append(SleepInsight(
                    type: .sleepQuality,
                    title: "提高睡眠效率",
                    message: "尝试改善睡眠环境，减少夜间觉醒次数",
                    description: "尝试改善睡眠环境，减少夜间觉醒次数",
                    priority: .medium,
                    actionable: true,
                    createdAt: Date()
                ))
            }

            // 作息规律建议
            if localStatistics.consistencyScore < 70 {
                insights.append(SleepInsight(
                    type: .bedtimeConsistency,
                    title: "保持作息规律",
                    message: "每天在相同时间上床睡觉，有助于调节生物钟",
                    description: "每天在相同时间上床睡觉，有助于调节生物钟",
                    priority: .medium,
                    actionable: true,
                    createdAt: Date()
                ))
            }

            // 睡眠质量建议
            if localStatistics.averageSleepQuality < 80 {
                insights.append(SleepInsight(
                    type: .sleepQuality,
                    title: "改善睡眠质量",
                    message: "建议减少睡前刺激性活动，创造更好的睡眠环境",
                    description: "建议减少睡前刺激性活动，创造更好的睡眠环境",
                    priority: .medium,
                    actionable: true,
                    createdAt: Date()
                ))
            }
        } else if let lastRecord = sleepManager.lastSleepRecord {
            // 使用最近的睡眠记录生成建议
            if lastRecord.totalSleepDuration < 7 * 3600 {
                insights.append(SleepInsight(
                    type: .sleepDuration,
                    title: "增加睡眠时间",
                    message: "您的平均睡眠时间不足7小时，建议提前30分钟上床",
                    description: "您的平均睡眠时间不足7小时，建议提前30分钟上床",
                    priority: .high,
                    actionable: true,
                    createdAt: Date()
                ))
            }

            if lastRecord.sleepEfficiency < 85 {
                insights.append(SleepInsight(
                    type: .sleepQuality,
                    title: "提高睡眠效率",
                    message: "当前睡眠效率\(Int(lastRecord.sleepEfficiency))%，建议优化睡眠环境",
                    description: "当前睡眠效率\(Int(lastRecord.sleepEfficiency))%，建议优化睡眠环境",
                    priority: .medium,
                    actionable: true,
                    createdAt: Date()
                ))
            }
        }

        // 如果没有足够的个性化建议，添加默认建议
        if insights.count < 3 {
            let defaultInsights = [
                SleepInsight(
                    type: .sleepEnvironment,
                    title: "优化睡眠环境",
                    message: "保持卧室温度在18-22°C，使用遮光窗帘",
                    description: "保持卧室温度在18-22°C，使用遮光窗帘",
                    priority: .medium,
                    actionable: true,
                    createdAt: Date()
                ),
                SleepInsight(
                    type: .bedtimeConsistency,
                    title: "建立睡前仪式",
                    message: "睡前1小时进行放松活动，如阅读或冥想",
                    description: "睡前1小时进行放松活动，如阅读或冥想",
                    priority: .low,
                    actionable: true,
                    createdAt: Date()
                ),
                SleepInsight(
                    type: .sleepQuality,
                    title: "限制蓝光暴露",
                    message: "睡前2小时减少电子设备使用",
                    description: "睡前2小时减少电子设备使用",
                    priority: .medium,
                    actionable: true,
                    createdAt: Date()
                )
            ]

            let neededCount = 3 - insights.count
            insights.append(contentsOf: Array(defaultInsights.prefix(neededCount)))
        }

        return insights
    }
    
    private var sleepImprovementTips: [SleepTip] {
        var tips: [SleepTip] = []
        
        // 根据本地睡眠统计数据生成个性化建议
        if let localStatistics = sleepManager.sleepStatistics {
            // 睡眠时长建议
            if localStatistics.averageSleepDuration < 7 * 3600 {
                tips.append(SleepTip(
                    title: "延长睡眠时间",
                    description: "您的平均睡眠时间为\(formatDuration(localStatistics.averageSleepDuration))，建议每晚7-9小时",
                    icon: "clock.fill",
                    color: Color(red: 0.4, green: 0.6, blue: 1.0)
                ))
            }
            
            // 睡眠效率建议
            if localStatistics.averageSleepEfficiency < 0.85 {
                tips.append(SleepTip(
                    title: "提高睡眠效率",
                    description: "当前睡眠效率\(Int(localStatistics.averageSleepEfficiency * 100))%，建议优化睡眠环境",
                    icon: "gauge.high",
                    color: Color(red: 0.2, green: 0.8, blue: 0.6)
                ))
            }
            
            // 作息规律建议
            if localStatistics.consistencyScore < 70 {
                tips.append(SleepTip(
                    title: "保持作息规律",
                    description: "作息规律性得分\(String(format: "%.2f", localStatistics.consistencyScore))分，建议固定就寝和起床时间",
                    icon: "calendar",
                    color: Color(red: 1.0, green: 0.6, blue: 0.4)
                ))
            }
            
            // 睡眠质量建议
            if localStatistics.averageSleepQuality < 80 {
                tips.append(SleepTip(
                    title: "改善睡眠质量",
                    description: "睡眠质量\(Int(localStatistics.averageSleepQuality))分，建议减少睡前刺激性活动",
                    icon: "heart.fill",
                    color: Color(red: 0.6, green: 0.4, blue: 0.9)
                ))
            }
        }
        
        // 如果没有本地数据或建议少于4条，添加默认建议
        if tips.count < 4 {
            let defaultTips = [
                SleepTip(
                    title: "优化睡眠环境",
                    description: "保持卧室温度在18-22°C，使用遮光窗帘",
                    icon: "house.fill",
                    color: Color(red: 0.4, green: 0.6, blue: 1.0)
                ),
                SleepTip(
                    title: "建立睡前仪式",
                    description: "睡前1小时进行放松活动，如阅读或冥想",
                    icon: "book.fill",
                    color: Color(red: 0.2, green: 0.8, blue: 0.6)
                ),
                SleepTip(
                    title: "限制蓝光暴露",
                    description: "睡前2小时减少电子设备使用",
                    icon: "iphone",
                    color: Color(red: 1.0, green: 0.6, blue: 0.4)
                ),
                SleepTip(
                    title: "规律运动",
                    description: "定期运动有助于改善睡眠质量",
                    icon: "figure.run",
                    color: Color(red: 0.6, green: 0.4, blue: 0.9)
                )
            ]
            
            // 添加缺少的默认建议
            let neededCount = 4 - tips.count
            tips.append(contentsOf: Array(defaultTips.prefix(neededCount)))
        }
        
        return tips
    }
}

// MARK: - 睡眠小贴士数据模型

struct SleepTip {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - 新增UI组件方法

extension SleepInsightsView {

    private func optimizedHealthMetricCard(title: String, value: String, score: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)

                Spacer()

                Text("\(score)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )
        )
    }

    private func quickInsightCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    // MARK: - 真实数据绑定方法
    
    /// 获取最佳就寝时间（基于本地数据或默认值）
    private func getBestBedtime() -> String {
        if let localStatistics = sleepManager.sleepStatistics {
            // 计算平均就寝时间
            let records = sleepManager.sleepRecords
            if !records.isEmpty {
                let totalSeconds = records.reduce(0) { total, record in
                    let calendar = Calendar.current
                    let bedTime = calendar.dateComponents([.hour, .minute], from: record.bedTime)
                    return total + (bedTime.hour ?? 22) * 3600 + (bedTime.minute ?? 30) * 60
                }
                let averageSeconds = totalSeconds / records.count
                let hours = averageSeconds / 3600
                let minutes = (averageSeconds % 3600) / 60
                return String(format: "%02d:%02d", hours, minutes)
            }
        } else if let lastRecord = sleepManager.lastSleepRecord {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: lastRecord.bedTime)
        }
        return "22:30"
    }
    
    /// 获取睡眠债务信息
    private func getSleepDebt() -> String {
        if let localStatistics = sleepManager.sleepStatistics {
            let averageSleepDuration = localStatistics.averageSleepDuration
            let recommendedSleep: TimeInterval = 8 * 3600 // 推荐8小时睡眠
            
            if averageSleepDuration < recommendedSleep {
                let debt = recommendedSleep - averageSleepDuration
                let hours = Int(debt) / 3600
                let minutes = (Int(debt) % 3600) / 60
                if hours > 0 {
                    return "\(hours)h \(minutes)m"
                } else {
                    return "\(minutes)分钟"
                }
            } else {
                return "无债务"
            }
        }
        return "1.2小时"
    }
    
    /// 获取深度睡眠比例
    private func getDeepSleepPercentage() -> String {
        if let localStatistics = sleepManager.sleepStatistics {
            // 从本地统计数据计算深度睡眠比例
            let records = sleepManager.sleepRecords
            if !records.isEmpty {
                let totalDeepSleep = records.reduce(0.0) { total, record in
                    let deepSleepDuration = record.sleepStages
                        .filter { $0.stage == .deep }
                        .reduce(0) { $0 + $1.duration }
                    return total + deepSleepDuration
                }
                let totalSleep = records.reduce(0.0) { $0 + $1.totalSleepDuration }
                if totalSleep > 0 {
                    let percentage = (totalDeepSleep / totalSleep) * 100
                    return "\(Int(percentage))%"
                }
            }
        } else if let lastRecord = sleepManager.lastSleepRecord {
            let deepSleepDuration = lastRecord.sleepStages
                .filter { $0.stage == .deep }
                .reduce(0) { $0 + $1.duration }
            
            if lastRecord.totalSleepDuration > 0 {
                let percentage = (deepSleepDuration / lastRecord.totalSleepDuration) * 100
                return "\(Int(percentage))%"
            }
        }
        return "23%"
    }
    
    /// 获取睡眠环境质量评估
    private func getSleepEnvironmentQuality() -> String {
        if let localStatistics = sleepManager.sleepStatistics {
            let efficiency = localStatistics.averageSleepEfficiency
            if efficiency >= 0.90 {
                return "优秀"
            } else if efficiency >= 0.80 {
                return "良好"
            } else if efficiency >= 0.70 {
                return "一般"
            } else {
                return "需改善"
            }
        }
        return "良好"
    }

    private func loadLocalSleepInsights() {
        print("🔄 开始加载本地睡眠洞察数据...")
        
        Task {
            // 加载本地睡眠历史数据
            await sleepManager.loadSleepHistory(forceRefresh: true)
        }
        
        print("✅ 本地睡眠洞察数据加载完成")
    }

    // MARK: - 辅助视图

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)

            Text("正在加载睡眠洞察数据...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    SleepInsightsView()
}