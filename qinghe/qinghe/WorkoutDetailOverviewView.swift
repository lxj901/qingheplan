import SwiftUI
import Charts

/// 运动详情 - 概览页面
/// 这是最重要的页面，展示运动的核心信息和亮点
struct WorkoutDetailOverviewView: View {
    let workout: QingheWorkout
    @State private var animateNumbers = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // 英雄数据区域
                heroMetricsSection
                
                // 运动亮点
                highlightsSection
                
                // 配速概览图表
                paceOverviewChart
                
                // 快速统计
                quickStatsSection
                
                // AI智能洞察
                insightsSection
                
                // 历史对比
                historicalComparisonSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // 为底部标签栏留空间
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                animateNumbers = true
            }
        }
    }
    
    // MARK: - 英雄数据区域
    private var heroMetricsSection: some View {
        VStack(spacing: 20) {
            // 运动类型和状态
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        // 运动类型图标
                        ZStack {
                            Circle()
                                .fill(workoutTypeColor)
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: workoutTypeIcon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workoutTypeName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(formattedDate)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // 完成状态徽章
                completionBadge
            }
            
            // 核心三大指标
            HStack(spacing: 0) {
                heroMetric(
                    value: animateNumbers ? workout.basicMetrics.totalDistance : 0,
                    unit: "公里",
                    label: "距离",
                    color: .green,
                    isFirst: true
                )
                
                divider
                
                heroMetric(
                    value: animateNumbers ? Double(workout.duration) : 0,
                    unit: "",
                    label: "时间",
                    color: .blue,
                    isTime: true
                )
                
                divider
                
                heroMetric(
                    value: animateNumbers ? Double(workout.basicMetrics.calories) : 0,
                    unit: "千卡",
                    label: "卡路里", 
                    color: .red,
                    isLast: true
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // 英雄指标项
    private func heroMetric(value: Double, unit: String, label: String, color: Color, isFirst: Bool = false, isLast: Bool = false, isTime: Bool = false) -> some View {
        VStack(spacing: 8) {
            // 数字显示
            HStack(alignment: .bottom, spacing: 4) {
                if isTime {
                    Text(formatDuration(Int(value)))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                } else {
                    Text(String(format: value < 10 ? "%.2f" : "%.1f", value))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                }
            }
            
            // 标签
            Text(label.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
    
    // 分隔线
    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 1, height: 40)
    }
    
    // 完成状态徽章
    private var completionBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
            
            Text("已完成")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.1))
        )
    }
    
    // MARK: - 运动亮点
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("运动亮点", icon: "star.fill", color: .orange)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                let avgPace = workout.basicMetrics.averagePace
                if avgPace > 0 {
                    let minutes = Int(avgPace)
                    let seconds = Int((avgPace - Double(minutes)) * 60)
                    let paceString = String(format: "%d:%02d", minutes, seconds)
                    highlightCard(
                        title: "平均配速",
                        value: paceString,
                        subtitle: "稳定表现",
                        icon: "speedometer",
                        color: .blue
                    )
                }
                
                // 最高速度数据暂时不可用
                highlightCard(
                    title: "最高速度",
                    value: "N/A",
                    subtitle: "冲刺瞬间",
                    icon: "bolt.fill",
                    color: .yellow
                )
                
                // 注意：QingheWorkout 只有 basicMetrics，没有 advancedMetrics
                // 如果需要心率数据，需要从其他地方获取或者修改数据模型
                // 暂时注释掉这部分代码
                /*
                if let avgHeartRate = workout.advancedMetrics?.averageHeartRate {
                    highlightCard(
                        title: "平均心率",
                        value: "\(avgHeartRate) bpm",
                        subtitle: "有氧运动",
                        icon: "heart.fill",
                        color: .red
                    )
                }
                */
                
                if let elevationGain = workout.advancedMetrics?.elevationGain, elevationGain > 0 {
                    highlightCard(
                        title: "爬升高度",
                        value: String(format: "%.0f m", elevationGain),
                        subtitle: "征服高度",
                        icon: "mountain.2.fill",
                        color: .green
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // 亮点卡片
    private func highlightCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 配速概览图表
    private var paceOverviewChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("配速概览", icon: "chart.xyaxis.line", color: .blue)
            
            // 简化的配速图表
            Chart {
                // 这里应该是真实的配速数据
                // 现在用示例数据
                ForEach(0..<20, id: \.self) { index in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Pace", Double.random(in: 4.5...6.0))
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .frame(height: 120)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            
            // 图表说明
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                    Text("配速")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("全程配速变化")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - 快速统计
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("快速统计", icon: "chart.bar.fill", color: .purple)
            
            VStack(spacing: 12) {
                quickStatRow("总步数", value: workout.basicMetrics.totalSteps.formatted(), icon: "figure.walk")
                quickStatRow("平均步频", value: "N/A", icon: "metronome")
                quickStatRow("运动时长", value: formatDuration(workout.duration), icon: "clock")
                quickStatRow("开始时间", value: formatTime(workout.startTime), icon: "clock.badge.checkmark")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // 快速统计行
    private func quickStatRow(_ title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - AI智能洞察
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("智能洞察", icon: "brain.head.profile", color: .indigo)
            
            VStack(spacing: 12) {
                insightCard(
                    title: "表现分析",
                    content: "本次跑步配速稳定，心率控制良好，建议保持当前训练强度。",
                    type: .positive
                )
                
                insightCard(
                    title: "改进建议", 
                    content: "可以尝试在中段增加一些间歇训练，提升最大摄氧量。",
                    type: .suggestion
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // 洞察卡片
    private func insightCard(title: String, content: String, type: InsightType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(type.color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(type.color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(content)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(type.color.opacity(0.05))
        )
    }
    
    // MARK: - 历史对比
    private var historicalComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("历史对比", icon: "chart.line.uptrend.xyaxis", color: .green)
            
            HStack(spacing: 16) {
                comparisonCard(
                    title: "vs 上次",
                    value: "+0.2km",
                    change: .improved,
                    subtitle: "距离提升"
                )
                
                comparisonCard(
                    title: "vs 平均",
                    value: "-1:23",
                    change: .improved,
                    subtitle: "配速更快"
                )
                
                comparisonCard(
                    title: "vs 最佳",
                    value: "+2:45",
                    change: .declined,
                    subtitle: "仍有提升空间"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // 对比卡片
    private func comparisonCard(title: String, value: String, change: ChangeType, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Image(systemName: change.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(change.color)
                
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(change.color)
            }
            
            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(change.color.opacity(0.1))
        )
    }
    
    // MARK: - 辅助组件
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    // MARK: - 计算属性
    private var workoutTypeColor: Color {
        switch workout.workoutType.lowercased() {
        case "running": return .green
        case "cycling": return .orange
        case "walking": return .blue
        case "hiking": return .purple
        default: return .blue
        }
    }
    
    private var workoutTypeIcon: String {
        switch workout.workoutType.lowercased() {
        case "running": return "figure.run"
        case "cycling": return "bicycle"
        case "walking": return "figure.walk"
        case "hiking": return "figure.hiking"
        default: return "figure.walk"
        }
    }
    
    private var workoutTypeName: String {
        switch workout.workoutType.lowercased() {
        case "running": return "户外跑步"
        case "cycling": return "户外骑行"
        case "walking": return "户外步行"
        case "hiking": return "户外徒步"
        default: return "户外运动"
        }
    }
    
    private var formattedDate: String {
        // 这里应该格式化真实的日期
        return "2024年7月13日 06:30"
    }
    
    // MARK: - 辅助方法
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    private func formatTime(_ dateString: String) -> String {
        // 这里应该解析和格式化真实的时间
        return "06:30"
    }
}

// MARK: - 支持类型
enum InsightType {
    case positive
    case suggestion
    case warning
    
    var icon: String {
        switch self {
        case .positive: return "checkmark.circle.fill"
        case .suggestion: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .suggestion: return .blue
        case .warning: return .orange
        }
    }
}

enum ChangeType {
    case improved
    case declined
    case same
    
    var icon: String {
        switch self {
        case .improved: return "arrow.up.right"
        case .declined: return "arrow.down.right"
        case .same: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .improved: return .green
        case .declined: return .red
        case .same: return .secondary
        }
    }
}

// MARK: - 预览
struct WorkoutDetailOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutDetailOverviewView(workout: sampleWorkout)
        }
    }
    
    static var sampleWorkout: QingheWorkout {
        // 创建示例数据
        QingheWorkout(
            workoutId: 1,
            workoutType: "running",
            startTime: "2024-07-13T06:30:00Z",
            endTime: "2024-07-13T07:15:00Z",
            duration: 2700, // 45分钟
            basicMetrics: WorkoutBasicMetrics(
                totalDistance: 8.5,
                totalSteps: 12000,
                calories: 450,
                averagePace: 5.3, // 5分18秒 = 5.3分钟
                maxSpeed: 11.3 // 约11.3 km/h
            ),
            advancedMetrics: WorkoutAdvancedMetrics(
                averageHeartRate: 145,
                maxHeartRate: 165,
                averageCadence: 180,
                elevationGain: 85.0,
                elevationLoss: 72.0
            ),
            notes: "晨跑训练"
        )
    }

}