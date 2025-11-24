import SwiftUI

// MARK: - AI题库统计页面
struct AIQuestionStatsView: View {
    let stats: QuestionStats
    @Environment(\.dismiss) private var dismiss
    
    // 背景渐变色
    private let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 245/255, green: 242/255, blue: 237/255),
            Color(red: 239/255, green: 235/255, blue: 224/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            // 背景
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // 导航栏
                navigationBar

                // 内容区域
                ScrollView {
                    VStack(spacing: 16) {
                        // 总体统计卡片
                        overallStatsCard

                        // 正确率圆环
                        accuracyRingCard

                        // 详细统计
                        detailStatsCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
        }
        // 隐藏系统导航栏，避免出现大标题造成的顶部额外高度
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack(spacing: 12) {
            // 返回按钮
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                    Text("返回")
                        .font(.system(size: 15))
                }
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.6))
                )
            }

            Spacer()

            // 标题
            Text("答题统计")
                .font(AppFont.kangxi(size: 20))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

            Spacer()

            // 占位
            Color.clear.frame(width: 70)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .frame(height: 44)
        .background(Color.white.opacity(0.3))
    }
    
    // MARK: - Overall Stats Card
    private var overallStatsCard: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                
                Text("总体表现")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                
                Spacer()
            }
            
            // 统计数据
            HStack(spacing: 0) {
                statColumn(
                    title: "总题数",
                    value: "\(stats.totalAttempts)",
                    color: Color(red: 0.2, green: 0.55, blue: 0.45)
                )
                
                Divider()
                    .frame(height: 60)
                
                statColumn(
                    title: "正确数",
                    value: "\(stats.correctCount)",
                    color: Color(red: 0.2, green: 0.7, blue: 0.4)
                )
                
                Divider()
                    .frame(height: 60)
                
                statColumn(
                    title: "错误数",
                    value: "\(stats.totalAttempts - stats.correctCount)",
                    color: Color(red: 0.9, green: 0.3, blue: 0.3)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
    
    private func statColumn(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Color.gray)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Accuracy Ring Card
    private var accuracyRingCard: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                
                Text("正确率")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                
                Spacer()
            }
            
            // 圆环图
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 180, height: 180)
                
                // 进度圆环
                Circle()
                    .trim(from: 0, to: stats.accuracyRate / 100)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.7, blue: 0.4),
                                Color(red: 0.2, green: 0.55, blue: 0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                
                // 中心文字
                VStack(spacing: 4) {
                    Text(stats.displayAccuracyRate)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.4))
                    
                    Text("正确率")
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray)
                }
            }
            .padding(.vertical, 20)
            
            // 评价
            Text(getAccuracyComment())
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
    
    // MARK: - Detail Stats Card
    private var detailStatsCard: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                
                Text("详细数据")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                
                Spacer()
            }
            
            // 数据行
            detailRow(
                icon: "star.fill",
                title: "平均分",
                value: stats.displayAvgScore,
                color: Color(red: 0.9, green: 0.6, blue: 0.2)
            )
            
            Divider()
            
            detailRow(
                icon: "clock.fill",
                title: "平均用时",
                value: stats.displayAvgTime,
                color: Color(red: 0.6, green: 0.4, blue: 0.8)
            )
            
            Divider()
            
            detailRow(
                icon: "checkmark.circle.fill",
                title: "正确率",
                value: stats.displayAccuracyRate,
                color: Color(red: 0.2, green: 0.7, blue: 0.4)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
    
    private func detailRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            // 图标
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)
            
            // 标题
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            
            Spacer()
            
            // 数值
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
    }
    
    // MARK: - Helper Methods
    private func getAccuracyComment() -> String {
        let rate = stats.accuracyRate
        
        if rate >= 90 {
            return "优秀！继续保持这样的学习状态"
        } else if rate >= 80 {
            return "良好！再接再厉，争取更好的成绩"
        } else if rate >= 70 {
            return "中等，还有提升空间，加油！"
        } else if rate >= 60 {
            return "及格，需要加强练习和理解"
        } else {
            return "需要更多练习，建议复习相关内容"
        }
    }
}

// MARK: - Preview
#Preview {
    AIQuestionStatsView(stats: QuestionStats.mockStats)
}
