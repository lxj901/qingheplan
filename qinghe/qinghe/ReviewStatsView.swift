//
//  ReviewStatsView.swift
//  qinghe
//
//  Created by Augment Agent on 2025-10-20.
//  复习统计页面

import SwiftUI
import Charts

struct ReviewStatsView: View {
    let stats: ReviewStats
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(red: 245/255, green: 242/255, blue: 237/255),
                    Color(red: 239/255, green: 235/255, blue: 224/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 内容区域（监听滚动偏移以驱动导航栏透明度）
                ScrollView {
                    VStack(spacing: 20) {
                        // 本周复习情况
                        weeklyReviewSection

                        // 复习数据汇总
                        statsOverviewSection

                        // 艾宾浩斯遗忘曲线
                        forgettingCurveSection

                        // 质量评分分布
                        qualityDistributionSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                    // 监听顶部内容相对滚动坐标的偏移
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ReviewStatsScrollOffsetKey.self,
                                value: proxy.frame(in: .named("reviewStatsScroll")).minY
                            )
                        }
                    )
                }
                .coordinateSpace(name: "reviewStatsScroll")
                .onPreferenceChange(ReviewStatsScrollOffsetKey.self) { value in
                    scrollOffset = value
                }
            }
        }
        // 将自定义导航栏作为安全区顶部插入，避免被父布局拉伸；同时根据滚动产生渐隐/渐显
        .safeAreaInset(edge: .top) { navigationBar(opacity: navOpacity) }
        // 隐藏系统导航栏，避免出现大标题造成的顶部额外高度
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: - Navigation Bar
    private func navigationBar(opacity: Double) -> some View {
        HStack(spacing: 12) {
            // 返回按钮
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                    Text("返回")
                        .font(.system(size: 15))
                }
                .foregroundColor(Color(red: 51/255, green: 140/255, blue: 115/255))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.6))
                )
            }

            Spacer()

            // 标题
            Text("复习统计")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))

            Spacer()

            // 占位
            Color.clear
                .frame(width: 70)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(.ultraThinMaterial.opacity(opacity))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.08 * opacity))
                .frame(height: 0.5)
        }
    }

    // 根据滚动距离计算导航栏透明度（上滑 8pt 起显，约 24pt 完全不透明）
    private var navOpacity: Double {
        let shown = max(0, min(1, Double((-(scrollOffset) - 8) / 24)))
        return shown
    }
    
    // MARK: - Weekly Review Section
    private var weeklyReviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 51/255, green: 140/255, blue: 115/255))
                
                Text("本周复习情况")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                
                Spacer()
                
                Text("共 \(stats.weeklyTotal) 次")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
            }
            
            // 柱状图
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(stats.weeklyReviews.enumerated()), id: \.offset) { index, count in
                        BarMark(
                            x: .value("Day", weekdayName(index)),
                            y: .value("Count", count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 51/255, green: 140/255, blue: 115/255),
                                    Color(red: 41/255, green: 120/255, blue: 95/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                // iOS 16 以下的简化版本
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(Array(stats.weeklyReviews.enumerated()), id: \.offset) { index, count in
                        VStack(spacing: 4) {
                            // 柱子
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 51/255, green: 140/255, blue: 115/255),
                                            Color(red: 41/255, green: 120/255, blue: 95/255)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: barHeight(count))
                            
                            // 星期标签
                            Text(weekdayName(index))
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Stats Overview Section
    private var statsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 139/255, green: 97/255, blue: 57/255))
                
                Text("复习数据")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            }
            
            // 数据卡片
            HStack(spacing: 12) {
                // 总复习次数
                ReviewStatCard(
                    icon: "arrow.clockwise",
                    title: "总复习次数",
                    value: "\(stats.totalReviews)",
                    color: Color(red: 51/255, green: 140/255, blue: 115/255)
                )

                // 平均质量
                ReviewStatCard(
                    icon: "star.fill",
                    title: "平均质量",
                    value: String(format: "%.1f", stats.averageQuality),
                    color: Color(red: 255/255, green: 200/255, blue: 50/255)
                )

                // 连续天数
                ReviewStatCard(
                    icon: "flame.fill",
                    title: "连续天数",
                    value: "\(stats.consecutiveDays)",
                    color: Color(red: 220/255, green: 100/255, blue: 80/255)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Forgetting Curve Section
    private var forgettingCurveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 100/255, green: 120/255, blue: 140/255))
                
                Text("艾宾浩斯遗忘曲线")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            }
            
            // 曲线图
            ForgettingCurveChart()
                .frame(height: 200)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Quality Distribution Section
    private var qualityDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 255/255, green: 200/255, blue: 50/255))
                
                Text("质量评分分布")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            }
            
            // 评分分布
            VStack(spacing: 12) {
                ForEach(Array(ReviewQuality.allCases.reversed().enumerated()), id: \.offset) { index, quality in
                    QualityDistributionBar(
                        quality: quality,
                        count: stats.qualityDistribution[quality.rawValue - 1],
                        total: stats.totalReviews
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Methods
    private func weekdayName(_ index: Int) -> String {
        let weekdays = ["一", "二", "三", "四", "五", "六", "日"]
        return weekdays[index]
    }
    
    private func barHeight(_ count: Int) -> CGFloat {
        let maxCount = stats.maxDailyReviews
        guard maxCount > 0 else { return 20 }
        let ratio = CGFloat(count) / CGFloat(maxCount)
        return max(20, ratio * 160)
    }
}

// MARK: - 滚动偏移监听 Key
private struct ReviewStatsScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Review Stat Card
struct ReviewStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 120/255, green: 120/255, blue: 120/255))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Quality Distribution Bar
struct QualityDistributionBar: View {
    let quality: ReviewQuality
    let count: Int
    let total: Int
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 星级
            HStack(spacing: 2) {
                ForEach(0..<quality.rawValue, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                }
            }
            .foregroundColor(Color(red: quality.color.red, green: quality.color.green, blue: quality.color.blue))
            .frame(width: 80, alignment: .leading)
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 220/255, green: 220/255, blue: 220/255))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: quality.color.red, green: quality.color.green, blue: quality.color.blue))
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 8)
            
            // 次数
            Text("\(count)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Forgetting Curve Chart
struct ForgettingCurveChart: View {
    // 艾宾浩斯遗忘曲线数据点
    private let curveData: [(day: Int, retention: Double)] = [
        (0, 100),
        (1, 58),
        (2, 44),
        (3, 36),
        (7, 25),
        (14, 22),
        (30, 21)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景网格
                Path { path in
                    for i in 0...4 {
                        let y = geometry.size.height * CGFloat(i) / 4
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(Color(red: 220/255, green: 220/255, blue: 220/255), lineWidth: 1)
                
                // 曲线
                Path { path in
                    for (index, point) in curveData.enumerated() {
                        let x = xPosition(day: point.day, width: geometry.size.width)
                        let y = yPosition(retention: point.retention, height: geometry.size.height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    Color(red: 220/255, green: 100/255, blue: 80/255),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                
                // 数据点
                ForEach(curveData, id: \.day) { point in
                    Circle()
                        .fill(Color(red: 220/255, green: 100/255, blue: 80/255))
                        .frame(width: 8, height: 8)
                        .position(
                            x: xPosition(day: point.day, width: geometry.size.width),
                            y: yPosition(retention: point.retention, height: geometry.size.height)
                        )
                }
                
                // X轴标签
                HStack(spacing: 0) {
                    ForEach([0, 1, 3, 7, 14, 30], id: \.self) { day in
                        Text("\(day)天")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 120/255, green: 120/255, blue: 120/255))
                            .frame(maxWidth: .infinity)
                    }
                }
                .offset(y: geometry.size.height + 15)
            }
        }
    }
    
    private func xPosition(day: Int, width: CGFloat) -> CGFloat {
        let maxDay: CGFloat = 30
        return width * CGFloat(day) / maxDay
    }
    
    private func yPosition(retention: Double, height: CGFloat) -> CGFloat {
        return height * (1 - CGFloat(retention) / 100)
    }
}

#Preview {
    ReviewStatsView(stats: ReviewStats.mockData)
}
