import SwiftUI
import Charts

struct AppUsageAnalysisDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appUsageManager = AppUsageManager.shared
    @State private var selectedTimeRange = 0 // 0: 今日, 1: 本周, 2: 本月
    @State private var selectedCategory = 0 // 0: 全部, 1: 社交, 2: 娱乐, 3: 工作
    
    private let timeRanges = ["今日", "本周", "本月"]
    private let categories = ["全部", "社交", "娱乐", "工作"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 时间范围选择器
                    timeRangeSelector
                    
                    // 总览卡片
                    overviewCards
                    
                    // 使用趋势图表
                    usageTrendChart
                    
                    // 应用分类分析
                    categoryAnalysis
                    
                    // 详细应用列表
                    detailedAppList
                    
                    // AI 洞察和建议
                    aiInsights
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("应用使用分析")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                }
            }
        }
        .onAppear {
            appUsageManager.refreshData()
        }
    }
    
    // MARK: - 时间范围选择器
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间范围")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
            
            HStack(spacing: 0) {
                ForEach(0..<timeRanges.count, id: \.self) { index in
                    Button(action: {
                        selectedTimeRange = index
                    }) {
                        Text(timeRanges[index])
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTimeRange == index ? .white : Color(red: 76/255, green: 175/255, blue: 80/255))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedTimeRange == index ?
                                Color(red: 76/255, green: 175/255, blue: 80/255) :
                                Color.clear
                            )
                            .cornerRadius(selectedTimeRange == index ? 8 : 0)
                    }
                }
            }
            .background(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.1))
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 总览卡片
    private var overviewCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            overviewCard(
                title: "总使用时间",
                value: formatScreenTime(appUsageManager.totalScreenTime),
                icon: "clock.fill",
                color: Color(red: 76/255, green: 175/255, blue: 80/255)
            )
            
            overviewCard(
                title: "应用数量",
                value: "\(appUsageManager.appUsageData.count)",
                icon: "apps.iphone",
                color: Color(red: 255/255, green: 193/255, blue: 7/255)
            )
            
            overviewCard(
                title: "平均使用",
                value: formatAverageUsage(),
                icon: "chart.bar.fill",
                color: Color(red: 255/255, green: 59/255, blue: 48/255)
            )
            
            overviewCard(
                title: "专注度",
                value: "\(calculateFocusScore())%",
                icon: "target",
                color: Color(red: 138/255, green: 43/255, blue: 226/255)
            )
        }
    }
    
    private func overviewCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 使用趋势图表
    private var usageTrendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("使用趋势")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
            
            if #available(iOS 16.0, *) {
                Chart(generateTrendData()) { data in
                    LineMark(
                        x: .value("时间", data.time),
                        y: .value("使用时间", data.usage)
                    )
                    .foregroundStyle(Color(red: 76/255, green: 175/255, blue: 80/255))
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("时间", data.time),
                        y: .value("使用时间", data.usage)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.3),
                                Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                            .font(.system(size: 10))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                            .font(.system(size: 10))
                    }
                }
            } else {
                // iOS 15 兼容性处理
                VStack {
                    Text("趋势图表")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                    
                    Text("需要 iOS 16+ 支持")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(red: 248/255, green: 249/255, blue: 250/255))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 应用分类分析
    private var categoryAnalysis: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("分类分析")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(getCategoryData(), id: \.category) { data in
                    categoryCard(data: data)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    private func categoryCard(data: CategoryData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: data.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(data.color)
                
                Spacer()
                
                Text("\(Int(data.percentage))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(data.color)
            }
            
            Text(data.category)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
            
            Text(formatScreenTime(data.totalTime))
                .font(.system(size: 12))
                .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
        }
        .padding(12)
        .background(data.color.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(data.color.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - 详细应用列表
    private var detailedAppList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("应用详情")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
            
            ForEach(Array(appUsageManager.appUsageData.enumerated()), id: \.element.id) { index, app in
                appDetailRow(app: app, rank: index + 1)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    private func appDetailRow(app: AppUsageData, rank: Int) -> some View {
        HStack(spacing: 12) {
            // 排名
            Text("\(rank)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(getRankColor(rank))
                .frame(width: 24, height: 24)
                .background(getRankColor(rank).opacity(0.1))
                .cornerRadius(12)
            
            // 应用图标
            ZStack {
                Circle()
                    .fill(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: app.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
            }
            
            // 应用信息
            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                
                Text("使用时长")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
            }
            
            Spacer()
            
            // 使用时间和进度条
            VStack(alignment: .trailing, spacing: 4) {
                Text(app.formattedTime)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(app.usageLevel.color)
                
                // 使用进度条
                ProgressView(value: Double(app.usageTime), total: Double(getMaxUsageTime()))
                    .progressViewStyle(LinearProgressViewStyle(tint: app.usageLevel.color))
                    .frame(width: 60)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - AI 洞察和建议
    private var aiInsights: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI 洞察与建议")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
            
            ForEach(generateAIInsights(), id: \.id) { insight in
                insightCard(insight: insight)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    private func insightCard(insight: AppUsageInsight) -> some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(insight.color)
                .frame(width: 32, height: 32)
                .background(insight.color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                
                Text(insight.description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(red: 248/255, green: 249/255, blue: 250/255))
        .cornerRadius(8)
    }

    // MARK: - 辅助方法

    private func formatScreenTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func formatAverageUsage() -> String {
        guard !appUsageManager.appUsageData.isEmpty else { return "0m" }
        let totalMinutes = appUsageManager.appUsageData.reduce(0) { $0 + $1.usageTime }
        let average = totalMinutes / appUsageManager.appUsageData.count
        return "\(average)m"
    }

    private func calculateFocusScore() -> Int {
        // 基于使用时间和应用类型计算专注度分数
        let totalTime = appUsageManager.totalScreenTime
        // let focusApps = ["工作", "学习", "阅读"] // 专注类应用
        // let distractionApps = ["社交", "游戏", "娱乐"] // 分心类应用

        // 简化的专注度计算
        if totalTime < 3600 { // 少于1小时
            return 95
        } else if totalTime < 7200 { // 少于2小时
            return 85
        } else if totalTime < 14400 { // 少于4小时
            return 70
        } else {
            return 50
        }
    }

    private func generateTrendData() -> [TrendData] {
        // 生成模拟的趋势数据
        let hours = ["00", "06", "12", "18", "24"]
        return hours.enumerated().map { index, hour in
            TrendData(
                time: hour,
                usage: Double.random(in: 10...120)
            )
        }
    }

    private func getCategoryData() -> [CategoryData] {
        return [
            CategoryData(
                category: "社交",
                totalTime: 3600,
                percentage: 35.0,
                icon: "message.fill",
                color: Color(red: 255/255, green: 59/255, blue: 48/255)
            ),
            CategoryData(
                category: "娱乐",
                totalTime: 2400,
                percentage: 25.0,
                icon: "play.fill",
                color: Color(red: 255/255, green: 193/255, blue: 7/255)
            ),
            CategoryData(
                category: "工作",
                totalTime: 1800,
                percentage: 20.0,
                icon: "briefcase.fill",
                color: Color(red: 76/255, green: 175/255, blue: 80/255)
            ),
            CategoryData(
                category: "其他",
                totalTime: 1200,
                percentage: 20.0,
                icon: "ellipsis.circle.fill",
                color: Color(red: 138/255, green: 43/255, blue: 226/255)
            )
        ]
    }

    private func getRankColor(_ rank: Int) -> Color {
        switch rank {
        case 1:
            return Color(red: 255/255, green: 215/255, blue: 0/255) // 金色
        case 2:
            return Color(red: 192/255, green: 192/255, blue: 192/255) // 银色
        case 3:
            return Color(red: 205/255, green: 127/255, blue: 50/255) // 铜色
        default:
            return Color(red: 153/255, green: 153/255, blue: 153/255) // 灰色
        }
    }

    private func getMaxUsageTime() -> Int {
        return appUsageManager.appUsageData.map(\.usageTime).max() ?? 120
    }

    private func generateAIInsights() -> [AppUsageInsight] {
        return [
            AppUsageInsight(
                id: UUID(),
                title: "使用习惯良好",
                description: "您今天的应用使用时间控制得很好，保持了良好的数字健康习惯。",
                icon: "checkmark.circle.fill",
                color: Color(red: 76/255, green: 175/255, blue: 80/255)
            ),
            AppUsageInsight(
                id: UUID(),
                title: "专注时间建议",
                description: "建议在工作时间减少社交应用的使用，可以提高专注度和工作效率。",
                icon: "target",
                color: Color(red: 255/255, green: 193/255, blue: 7/255)
            ),
            AppUsageInsight(
                id: UUID(),
                title: "睡前提醒",
                description: "晚上10点后建议减少屏幕使用时间，有助于提高睡眠质量。",
                icon: "moon.fill",
                color: Color(red: 138/255, green: 43/255, blue: 226/255)
            )
        ]
    }
}

// MARK: - 数据模型

struct TrendData: Identifiable {
    let id = UUID()
    let time: String
    let usage: Double
}

struct CategoryData {
    let category: String
    let totalTime: TimeInterval
    let percentage: Double
    let icon: String
    let color: Color
}

struct AppUsageInsight {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let color: Color
}
