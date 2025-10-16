import SwiftUI
import Charts

/// 功过格统计视图 - 展示统计数据和趋势
struct MeritStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MeritViewModel()
    @State private var statisticsDays: Int = 30
    @State private var statisticsData: MeritStatisticsData?
    @State private var isLoading = false
    @State private var showingError = false

    private let dayOptions = [7, 30, 90, 365]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 时间段选择器
                periodSelector
                
                if isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if let stats = statisticsData {
                    // 总览卡片
                    overviewCard(stats.overview)

                    // 分类统计
                    categoryBreakdown(stats.categoryStats)

                    // 连续打卡
                    streaksCard(stats.streaks)
                } else {
                    emptyState
                }
            }
            .padding()
        }
        .background(ModernDesignSystem.Colors.paperIvory.ignoresSafeArea())
        .navigationTitle("功过统计")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light) // 功过统计页面不适配深色模式
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadStatistics()
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "加载失败")
        }
    }
    
    // MARK: - 视图组件
    
    private var periodSelector: some View {
        Picker("时间段", selection: $statisticsDays) {
            ForEach(dayOptions, id: \.self) { days in
                Text("\(days)天").tag(days)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: statisticsDays) { newValue in
            loadStatistics()
        }
    }
    
    private func overviewCard(_ overview: StatisticsOverview) -> some View {
        VStack(spacing: 16) {
            Text("总览")
                .font(AppFont.kangxi(size: 20))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                statBox(
                    title: "功德",
                    value: "\(overview.totalMeritPoints)",
                    subtitle: "\(overview.totalMeritRecords)次",
                    color: ModernDesignSystem.Colors.primaryGreen
                )
                
                statBox(
                    title: "过失",
                    value: "\(overview.totalDemeritPoints)",
                    subtitle: "\(overview.totalDemeritRecords)次",
                    color: ModernDesignSystem.Colors.errorRed
                )
                
                statBox(
                    title: "净分",
                    value: "\(overview.netScore)",
                    subtitle: "总计",
                    color: overview.netScore >= 0 ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.errorRed
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
        )
    }
    
    private func statBox(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func trendsChart(_ trends: TrendsData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("趋势")
                .font(AppFont.kangxi(size: 20))
            
            Chart {
                ForEach(trends.weeklyData, id: \.week) { point in
                    LineMark(
                        x: .value("周期", point.week),
                        y: .value("功德", point.meritPoints)
                    )
                    .foregroundStyle(ModernDesignSystem.Colors.primaryGreen)
                    .symbol(Circle())
                    
                    LineMark(
                        x: .value("周期", point.week),
                        y: .value("过失", point.demeritPoints)
                    )
                    .foregroundStyle(ModernDesignSystem.Colors.errorRed)
                    .symbol(Circle())
                }
            }
            .frame(height: 200)
            .chartLegend(position: .bottom)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
        )
    }
    
    private func categoryBreakdown(_ categoryStats: CategoryStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("分类统计")
                .font(AppFont.kangxi(size: 20))
            
            VStack(spacing: 12) {
                Text("功德分类")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(categoryStats.merits, id: \.category) { stat in
                    categoryRow(
                        title: stat.category,
                        count: stat.count,
                        points: stat.totalPoints,
                        percentage: stat.percentage,
                        color: ModernDesignSystem.Colors.primaryGreen
                    )
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            VStack(spacing: 12) {
                Text("过失分类")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(categoryStats.demerits, id: \.category) { stat in
                    categoryRow(
                        title: stat.category,
                        count: stat.count,
                        points: stat.totalPoints,
                        percentage: stat.percentage,
                        color: ModernDesignSystem.Colors.errorRed
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
        )
    }
    
    private func categoryRow(title: String, count: Int, points: Int, percentage: Double, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text("\(count)次 · \(points)分")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.1f%%", percentage))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.1))
        )
    }
    
    private func streaksCard(_ streaks: StreaksData) -> some View {
        VStack(spacing: 16) {
            Text("连续记录")
                .font(AppFont.kangxi(size: 20))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("\(streaks.currentStreak)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                    Text("当前连续")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 60)
                
                VStack(spacing: 8) {
                    Text("\(streaks.longestStreak)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(ModernDesignSystem.Colors.accentGold)
                    Text("最长连续")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("暂无统计数据")
                .font(.system(size: 16, weight: .semibold))
            
            Text("开始记录功过，查看你的修行轨迹")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
    }
    
    // MARK: - 数据加载
    
    private func loadStatistics() {
        isLoading = true
        
        Task {
            do {
                let response = try await MeritService.shared.getStatistics(period: statisticsDays)
                
                await MainActor.run {
                    statisticsData = response.data
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showingError = true
                    print("❌ 加载统计数据失败: \(error)")
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func formatChartDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM/dd"
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

#Preview {
    NavigationStack {
        MeritStatisticsView()
    }
}

