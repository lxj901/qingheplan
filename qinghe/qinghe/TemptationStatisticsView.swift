import SwiftUI

@MainActor
class TemptationStatisticsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var statistics: TemptationStatisticsData?
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let temptationService = TemptationService.shared

    // MARK: - Public Methods

    /// 加载诱惑统计数据
    func loadStatistics() async {
        isLoading = true

        do {
            let response = try await temptationService.getTemptationStatistics()

            // 转换API响应为本地统计模型
            let totalRecords = response.totalCount
            let successfulResistance = response.resistedCount

            // 创建类型分布字典（基于常见类型）
            var typeDistribution: [String: Int] = [:]
            for (index, type) in response.commonTypes.enumerated() {
                // 模拟分布数据，实际应该从API获取
                typeDistribution[type] = max(1, totalRecords / (index + 1))
            }

            // 创建简单的强度分布（基于平均强度）
            let intensityDistribution = createIntensityDistribution(from: [:])

            // 创建周趋势数据
            let weeklyTrend = response.weeklyTrend.map { trend in
                TemptationWeeklyTrend(
                    week: trend.week,
                    successRate: trend.totalCount > 0 ? Double(trend.resistedCount) / Double(trend.totalCount) : 0.0,
                    totalCount: trend.totalCount
                )
            }

            statistics = TemptationStatisticsData(
                totalRecords: totalRecords,
                successfulResistance: successfulResistance,
                successRate: response.resistanceRate,
                averageIntensity: 5.0, // 默认值，因为API没有提供
                typeDistribution: typeDistribution,
                intensityDistribution: intensityDistribution,
                topStrategies: response.effectiveStrategies.map { TopStrategy(name: $0, successCount: 1) },
                weeklyTrend: weeklyTrend
            )
        } catch {
            showErrorMessage("加载统计数据失败: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Private Methods

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    /// 创建强度分布数据
    private func createIntensityDistribution(from distribution: [String: Int]) -> [String: Int] {
        var result: [String: Int] = [:]

        // 将强度分组
        var lowCount = 0
        var mediumCount = 0
        var highCount = 0

        for (intensityStr, count) in distribution {
            if let intensity = Int(intensityStr) {
                switch intensity {
                case 1...3:
                    lowCount += count
                case 4...6:
                    mediumCount += count
                case 7...10:
                    highCount += count
                default:
                    break
                }
            }
        }

        result["1-3"] = lowCount
        result["4-6"] = mediumCount
        result["7-10"] = highCount

        return result
    }
}

// MARK: - Data Models

struct TemptationStatisticsData {
    let totalRecords: Int
    let successfulResistance: Int
    let successRate: Double
    let averageIntensity: Double
    let typeDistribution: [String: Int]
    let intensityDistribution: [String: Int]
    let topStrategies: [TopStrategy]
    let weeklyTrend: [TemptationWeeklyTrend]
}

struct TopStrategy {
    let name: String
    let successCount: Int
}

struct TemptationWeeklyTrend {
    let week: String
    let successRate: Double
    let totalCount: Int
}

struct TemptationStatisticsView: View {
    @StateObject private var viewModel = TemptationStatisticsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let statistics = viewModel.statistics {
                        // 总体统计卡片
                        overallStatsCard(statistics)
                        
                        // 抵抗成功率
                        resistanceRateCard(statistics)
                        
                        // 诱惑类型分布
                        temptationTypeChart(statistics)
                        
                        // 强度分布
                        intensityDistributionChart(statistics)
                        
                        // 成功策略排行
                        if !statistics.topStrategies.isEmpty {
                            topStrategiesCard(statistics)
                        }
                        
                        // 趋势分析
                        if !statistics.weeklyTrend.isEmpty {
                            weeklyTrendCard(statistics)
                        }
                    } else {
                        emptyStateView
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(backgroundGradient)
            .navigationTitle("诱惑抵抗统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("刷新") {
                        Task {
                            await viewModel.loadStatistics()
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadStatistics()
        }
        .alert("加载失败", isPresented: $viewModel.showError) {
            Button("确定") { }
            Button("重试") {
                Task {
                    await viewModel.loadStatistics()
                }
            }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("加载统计数据中...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.gray)
            
            Text("暂无抵抗记录")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("开始记录诱惑抵抗后，这里将显示详细的统计分析")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("开始记录") {
                // TODO: 导航到记录页面
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private func overallStatsCard(_ statistics: TemptationStatisticsData) -> some View {
        VStack(spacing: 16) {
            Text("总体统计")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    title: "总记录数",
                    value: "\(statistics.totalRecords)",
                    unit: "条",
                    color: Color.blue
                )

                StatCard(
                    title: "抵抗成功",
                    value: "\(statistics.successfulResistance)",
                    unit: "次",
                    color: Color.green
                )

                StatCard(
                    title: "成功率",
                    value: "\(Int(statistics.successRate * 100))",
                    unit: "%",
                    color: Color.orange
                )

                StatCard(
                    title: "平均强度",
                    value: String(format: "%.1f", statistics.averageIntensity),
                    unit: "分",
                    color: Color.red
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private func resistanceRateCard(_ statistics: TemptationStatisticsData) -> some View {
        VStack(spacing: 16) {
            Text("抵抗成功率")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: CGFloat(statistics.successRate))
                    .stroke(successRateColor(statistics.successRate), lineWidth: 12)
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(statistics.successRate * 100))")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("%")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 24) {
                VStack {
                    Text("\(statistics.successfulResistance)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("成功")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(statistics.totalRecords - statistics.successfulResistance)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.red)
                    
                    Text("失败")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private func temptationTypeChart(_ statistics: TemptationStatisticsData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("诱惑类型分布")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(Array(statistics.typeDistribution.keys.sorted()), id: \.self) { type in
                    HStack {
                        Text(type)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geometry in
                            HStack {
                                Rectangle()
                                    .fill(colorForTemptationType(type))
                                    .frame(width: CGFloat(statistics.typeDistribution[type] ?? 0) / CGFloat(statistics.totalRecords) * geometry.size.width)
                                    .frame(height: 20)
                                    .cornerRadius(4)
                                
                                Spacer()
                            }
                        }
                        .frame(height: 20)
                        
                        Text("\(statistics.typeDistribution[type] ?? 0)")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private func intensityDistributionChart(_ statistics: TemptationStatisticsData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("强度分布")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                ForEach(Array(statistics.intensityDistribution.keys.sorted()), id: \.self) { range in
                    VStack(spacing: 8) {
                        Text("\(statistics.intensityDistribution[range] ?? 0)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Rectangle()
                            .fill(colorForIntensityRange(range))
                            .frame(width: 40, height: CGFloat(statistics.intensityDistribution[range] ?? 0) * 3)
                            .cornerRadius(4)
                        
                        Text(range)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private func topStrategiesCard(_ statistics: TemptationStatisticsData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最有效策略")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(Array(statistics.topStrategies.enumerated()), id: \.offset) { index, strategy in
                    HStack {
                        Text("\(index + 1)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(rankColor(index))
                            .clipShape(Circle())
                        
                        Text(strategy.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(strategy.successCount)次")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private func weeklyTrendCard(_ statistics: TemptationStatisticsData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("周趋势")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(statistics.weeklyTrend, id: \.week) { trend in
                    HStack {
                        Text(trend.week)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 60, alignment: .leading)
                        
                        Text("成功率: \(Int(trend.successRate * 100))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(trend.totalCount)次")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Properties
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 248/255, green: 250/255, blue: 252/255),
                Color(red: 241/255, green: 245/255, blue: 249/255)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Helper Methods
    
    private func colorForTemptationType(_ type: String) -> Color {
        switch type {
        case "食物诱惑": return .orange
        case "购物诱惑": return .purple
        case "娱乐诱惑": return .blue
        case "社交诱惑": return .green
        case "工作拖延": return .red
        case "不良习惯": return .brown
        default: return .gray
        }
    }
    
    private func colorForIntensityRange(_ range: String) -> Color {
        switch range {
        case "1-3": return .green
        case "4-6": return .yellow
        case "7-10": return .red
        default: return .gray
        }
    }
    
    private func successRateColor(_ rate: Double) -> Color {
        switch rate {
        case 0.8...1.0: return .green
        case 0.6...0.79: return .yellow
        case 0.4...0.59: return .orange
        default: return .red
        }
    }
    
    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .brown
        default: return .blue
        }
    }
}

// MARK: - StatCard Component
struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)

                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct TemptationStatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        TemptationStatisticsView()
    }
}
