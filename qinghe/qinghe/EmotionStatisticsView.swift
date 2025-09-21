import SwiftUI
import Charts
import Charts

struct EmotionStatisticsView: View {
    @StateObject private var viewModel = EmotionStatisticsViewModel()
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
                        
                        // 情绪分布图表
                        emotionDistributionChart(statistics)
                        
                        // 强度分布图表
                        intensityDistributionChart(statistics)
                        
                        // 趋势图表
                        if !statistics.weeklyTrend.isEmpty {
                            weeklyTrendChart(statistics)
                        }
                        
                        // 健康评分
                        healthScoreCard(statistics)
                    } else {
                        emptyStateView
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(backgroundGradient)
            .navigationTitle("情绪统计")
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
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.gray)
            
            Text("暂无统计数据")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("开始记录情绪后，这里将显示详细的统计分析")
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
            .background(Color.blue)
            .cornerRadius(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private func overallStatsCard(_ statistics: EmotionStatisticsData) -> some View {
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
                    color: .blue
                )

                StatCard(
                    title: "平均强度",
                    value: String(format: "%.1f", statistics.averageIntensity),
                    unit: "分",
                    color: .green
                )

                StatCard(
                    title: "健康评分",
                    value: "\(statistics.healthScore)",
                    unit: "分",
                    color: .red
                )

                StatCard(
                    title: "记录天数",
                    value: "\(statistics.weeklyTrend.count)",
                    unit: "天",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private func emotionDistributionChart(_ statistics: EmotionStatisticsData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("情绪分布")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(statistics.emotionDistribution.keys.sorted()), id: \.self) { emotion in
                        BarMark(
                            x: .value("情绪", emotion),
                            y: .value("次数", statistics.emotionDistribution[emotion] ?? 0)
                        )
                        .foregroundStyle(colorForEmotion(emotion))
                    }
                }
                .frame(height: 200)
            } else {
                // iOS 15 及以下版本的替代方案
                VStack(spacing: 8) {
                    ForEach(Array(statistics.emotionDistribution.keys.sorted()), id: \.self) { emotion in
                        HStack {
                            Text(emotion)
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 60, alignment: .leading)
                            
                            GeometryReader { geometry in
                                HStack {
                                    Rectangle()
                                        .fill(colorForEmotion(emotion))
                                        .frame(width: CGFloat(statistics.emotionDistribution[emotion] ?? 0) / CGFloat(statistics.totalRecords) * geometry.size.width)
                                        .frame(height: 20)
                                        .cornerRadius(4)
                                    
                                    Spacer()
                                }
                            }
                            .frame(height: 20)
                            
                            Text("\(statistics.emotionDistribution[emotion] ?? 0)")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private func intensityDistributionChart(_ statistics: EmotionStatisticsData) -> some View {
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
    
    @available(iOS 16.0, *)
    private func weeklyTrendChart(_ statistics: EmotionStatisticsData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("周趋势")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Chart {
                ForEach(Array(statistics.weeklyTrend.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("周", "第\(index + 1)周"),
                        y: .value("平均强度", value)
                    )
                    .foregroundStyle(.blue)

                    PointMark(
                        x: .value("周", "第\(index + 1)周"),
                        y: .value("平均强度", value)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 150)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private func healthScoreCard(_ statistics: EmotionStatisticsData) -> some View {
        VStack(spacing: 16) {
            Text("情绪健康评分")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(statistics.healthScore) / 100)
                    .stroke(healthScoreColor(statistics.healthScore), lineWidth: 8)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(statistics.healthScore)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("分")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Text(healthScoreDescription(statistics.healthScore))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
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
    
    private func colorForEmotion(_ emotion: String) -> Color {
        switch emotion {
        case "开心": return .yellow
        case "难过": return .blue
        case "愤怒": return .red
        case "焦虑": return .orange
        case "平静": return .green
        case "兴奋": return .purple
        case "疲惫": return .gray
        case "困惑": return .brown
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
    
    private func healthScoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60...79: return .yellow
        case 40...59: return .orange
        default: return .red
        }
    }
    
    private func healthScoreDescription(_ score: Int) -> String {
        switch score {
        case 80...100: return "情绪状态良好，继续保持积极的心态"
        case 60...79: return "情绪状态一般，建议多关注情绪管理"
        case 40...59: return "情绪波动较大，建议寻求专业帮助"
        default: return "情绪状态需要关注，建议及时调整"
        }
    }
}

// MARK: - Supporting Views



// MARK: - Preview
struct EmotionStatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionStatisticsView()
    }
}
