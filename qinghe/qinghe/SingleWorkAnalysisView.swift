import SwiftUI

/// 单个作品数据分析视图
struct SingleWorkAnalysisView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var timeRange = "7d"
    
    var body: some View {
        ZStack {
            // 背景色
            Color(red: 0.965, green: 0.969, blue: 0.976)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                topNavigationBar
                
                // 主滚动区域
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. 作品概览卡片
                        workOverviewCard
                        
                        // 2. 核心数据 Grid
                        coreDataGrid
                        
                        // 3. AI 诊断建议
                        aiDiagnosisCard
                        
                        // 4. 流量漏斗分析
                        trafficFunnelCard
                        
                        // 5. 完播率曲线
                        completionRateCard
                        
                        // 6. 流量来源
                        trafficSourceCard
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("作品数据分析")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 占位,保持标题居中
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.8))
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 0.5),
                alignment: .bottom
            )
        }
    }
    
    // MARK: - 作品概览卡片
    private var workOverviewCard: some View {
        HStack(spacing: 12) {
            // 封面
            ZStack {
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1616486338812-3dadae4b4f9d?auto=format&fit=crop&w=300&q=80")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 80, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 80, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .opacity(0.8)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("沉浸式整理我的书桌 | 极简主义生活 Vlog #03")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text("发布于 2024-11-20 18:30")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.6))
                        
                        Text("公开可见")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppConstants.Colors.primaryGreen.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // 综合评分
                HStack(alignment: .bottom, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("92")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                        Text("分")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    
                    Text("超越 95% 同类作品")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - 核心数据 Grid
    private var coreDataGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            StatBox(label: "播放量", value: "45.2w", trend: "+12%", isDown: false, icon: "play.fill")
            StatBox(label: "点赞", value: "3.4w", trend: "+5%", isDown: false, icon: "heart.fill")
            StatBox(label: "评论", value: "1,205", trend: "-2%", isDown: true, icon: "message.fill")
            StatBox(label: "收藏", value: "8,902", trend: "+8%", isDown: false, icon: "star.fill")
        }
    }

    // MARK: - AI 诊断建议卡片
    private var aiDiagnosisCard: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [Color(red: 0.93, green: 0.94, blue: 1.0), Color(red: 0.93, green: 0.96, blue: 1.0)],
                startPoint: .leading,
                endPoint: .trailing
            )

            // 装饰图标
            Image(systemName: "bolt.fill")
                .font(.system(size: 100))
                .foregroundColor(Color.indigo.opacity(0.1))
                .rotationEffect(.degrees(12))
                .offset(x: 60, y: 30)

            HStack(alignment: .top, spacing: 12) {
                // 图标
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.indigo)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("作品表现优异")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.4))

                    Text("完播率极高，平台正在加大推荐力度。评论区互动活跃，建议置顶神评引导关注。")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.4).opacity(0.7))
                        .lineSpacing(4)
                }

                Spacer()
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.indigo.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - 流量漏斗分析卡片
    private var trafficFunnelCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("流量转化漏斗")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "questionmark.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.3))
            }

            VStack(spacing: 4) {
                FunnelRow(label: "作品曝光", value: "89.5w", percent: "100%", width: 1.0, color: Color.gray.opacity(0.1), textColor: .secondary)

                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 16)
                    .frame(maxWidth: .infinity)

                FunnelRow(label: "播放次数", value: "45.2w", percent: "50.5%", width: 0.8, color: Color.blue.opacity(0.1), textColor: .blue)

                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 16)
                    .frame(maxWidth: .infinity)

                FunnelRow(label: "互动 (赞评藏)", value: "5.6w", percent: "12.3%", width: 0.6, color: Color.indigo.opacity(0.1), textColor: .indigo)

                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 16)
                    .frame(maxWidth: .infinity)

                FunnelRow(label: "转粉人数", value: "892", percent: "0.2%", width: 0.4, color: AppConstants.Colors.primaryGreen.opacity(0.1), textColor: AppConstants.Colors.primaryGreen, isGoal: true)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - 完播率曲线卡片
    private var completionRateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("观众留存率 (完播率)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text("5秒完播率")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("68%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                    Text("· 优于均值")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }

            // 模拟曲线图
            ZStack(alignment: .bottomLeading) {
                // 辅助线
                Rectangle()
                    .fill(Color.gray.opacity(0.05))
                    .frame(height: 1)
                    .offset(y: -60)

                // 曲线区域 (使用渐变模拟)
                LinearGradient(
                    colors: [AppConstants.Colors.primaryGreen.opacity(0.2), AppConstants.Colors.primaryGreen.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
                .mask(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 150))
                        path.addCurve(
                            to: CGPoint(x: 300, y: 140),
                            control1: CGPoint(x: 100, y: 130),
                            control2: CGPoint(x: 200, y: 135)
                        )
                        path.addLine(to: CGPoint(x: 300, y: 160))
                        path.addLine(to: CGPoint(x: 0, y: 160))
                        path.closeSubpath()
                    }
                )

                // 流失点标注
                VStack(spacing: 2) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)

                    Text("流失点 (3s)")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                }
                .offset(x: 40, y: -110)
            }
            .frame(height: 160)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1),
                alignment: .leading
            )
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1),
                alignment: .bottom
            )

            HStack {
                Text("00:00")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.3))

                Spacer()

                Text("01:30")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.3))

                Spacer()

                Text("03:00")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.3))
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - 流量来源卡片
    private var trafficSourceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("流量来源")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                SourceItem(label: "推荐页", percent: "65%", value: 0.65, color: AppConstants.Colors.primaryGreen)
                SourceItem(label: "搜索", percent: "20%", value: 0.20, color: .blue)
                SourceItem(label: "个人主页", percent: "10%", value: 0.10, color: .orange)
                SourceItem(label: "其他", percent: "5%", value: 0.05, color: .gray)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - 子组件

/// 统计数据盒子
struct StatBox: View {
    let label: String
    let value: String
    let trend: String
    let isDown: Bool
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.6))

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)

            HStack(spacing: 2) {
                Image(systemName: isDown ? "arrow.down.right" : "arrow.up.right")
                    .font(.system(size: 8))

                Text(trend)
                    .font(.system(size: 9))
            }
            .foregroundColor(isDown ? .secondary.opacity(0.6) : .red)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(isDown ? Color.gray.opacity(0.05) : Color.red.opacity(0.05))
            .cornerRadius(4)

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

/// 漏斗行组件
struct FunnelRow: View {
    let label: String
    let value: String
    let percent: String
    let width: CGFloat
    let color: Color
    let textColor: Color
    var isGoal: Bool = false

    var body: some View {
        ZStack {
            // 背景条
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(width: geometry.size.width * width)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isGoal ? AppConstants.Colors.primaryGreen.opacity(0.2) : Color.clear, lineWidth: 1)
                    )
            }

            // 内容
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary.opacity(0.8))

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(value)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)

                    Text("转化 \(percent)")
                        .font(.system(size: 9))
                        .foregroundColor(textColor)
                }
            }
            .padding(.horizontal, 32)
        }
        .frame(height: 40)
    }
}

/// 流量来源项组件
struct SourceItem: View {
    let label: String
    let percent: String
    let value: CGFloat
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 56, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * value)
                }
            }
            .frame(height: 8)

            Text(percent)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
                .frame(width: 32, alignment: .trailing)
        }
    }
}

#Preview {
    SingleWorkAnalysisView()
}

