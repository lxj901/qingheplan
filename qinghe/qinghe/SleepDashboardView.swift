import SwiftUI


struct SleepDashboardView: View {
    @StateObject private var sleepManager = SleepDataManager.shared
    @State private var showSleepTracking = false
    @State private var showSleepRecords = false
    @State private var showSleepInsights = false

    @State private var animateCards = false
    @State private var currentTime = Date()
    @State private var fixedDate = Date()

    @State private var pulseAnimation = false
    @State private var starAnimation = false


    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 动态背景
                dynamicBackground

                ScrollViewReader { scrollProxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            // 顶部导航区域（返回按钮、标题和时间在同一水平位置）
                            topNavigationSection
                                .padding(.top, 20)

                            // 主要睡眠状态卡片
                            heroSleepCard
                                .padding(.top, 30)

                            // 快速操作面板
                            quickActionsPanel
                                .padding(.top, 25)
                                .padding(.bottom, 120)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // 上传状态Toast
                if let message = sleepManager.uploadStatusMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Image(systemName: message.contains("✅") ? "checkmark.circle.fill" : "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                            
                            Text(message)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(message.contains("✅") ? Color.green : Color.blue)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: sleepManager.uploadStatusMessage)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            fixedDate = Date() // 固定日期，不再更新
            Task {
                await sleepManager.loadSleepHistory()
                await sleepManager.loadAudioFiles()

                // 添加调试信息
                print("🔍 睡眠管理页面数据状态:")
                print("   - 睡眠记录数量: \(sleepManager.sleepRecords.count)")
                print("   - 最新睡眠记录: \(sleepManager.lastSleepRecord?.formattedSleepDuration ?? "无")")
                print("   - 音频文件数量: \(sleepManager.currentSessionAudioCount)")

                if let lastRecord = sleepManager.lastSleepRecord {
                    let efficiencyText = lastRecord.sleepEfficiency.isFinite ? "\(Int(lastRecord.sleepEfficiency))%" : "无效"
                    print("   - 最新记录详情: 时长=\(lastRecord.formattedSleepDuration), 效率=\(efficiencyText), 评分=\(lastRecord.sleepQualityScore)")
                }
            }
            withAnimation(.easeOut(duration: 0.8)) {
                animateCards = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
                starAnimation = true
            }

            // UI修复测试已移除
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .fullScreenCover(isPresented: $showSleepTracking) {
            SleepTrackingView()
        }
        .fullScreenCover(isPresented: $showSleepRecords) {
            SleepRecordsView()
        }
        .fullScreenCover(isPresented: $showSleepInsights) {
            SleepInsightsView()
        }


    }

    // MARK: - 动态背景

    private var dynamicBackground: some View {
        ZStack {
            // 深度渐变背景
            RadialGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.25),
                    Color(red: 0.05, green: 0.08, blue: 0.18),
                    Color(red: 0.02, green: 0.05, blue: 0.12)
                ],
                center: .topTrailing,
                startRadius: 100,
                endRadius: 800
            )
            .ignoresSafeArea()

            // 动态光晕效果
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .position(x: UIScreen.main.bounds.width * 0.8, y: 100)
                .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                .opacity(pulseAnimation ? 0.6 : 0.3)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: pulseAnimation)

            // 星空粒子效果
            ForEach(0..<30, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.2...0.8)))
                    .frame(width: CGFloat.random(in: 1...4))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height * 0.7)
                    )
                    .scaleEffect(starAnimation ? 1.0 : 0.5)
                    .opacity(starAnimation ? 1.0 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 1.5...3.0))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: starAnimation
                    )
            }
        }
    }

    // MARK: - 顶部导航区域

    private var topNavigationSection: some View {
        HStack(alignment: .center, spacing: 16) {
            // 返回按钮（有动画）
            Button(action: {
                // 返回到首页
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.dismiss(animated: true)
                }
            }) {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(animateCards ? 1.0 : 0.0)
            .offset(y: animateCards ? 0 : -20)
            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animateCards)

            // 中间区域：问候语和睡眠管理标题（有动画）
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                HStack(spacing: 6) {
                    Text("睡眠管理")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.6, green: 0.8, blue: 1.0))
                        .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
                }
            }
            .opacity(animateCards ? 1.0 : 0.0)
            .offset(y: animateCards ? 0 : -20)
            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animateCards)

            Spacer()

            // 右侧：时间和日期模块（固定显示，无动画）
            VStack(alignment: .trailing, spacing: 2) {
                Text(currentTime, style: .time)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(fixedDate, formatter: dateFormatter)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - 主要睡眠状态卡片

    private var heroSleepCard: some View {
        VStack(spacing: 0) {
            // 顶部状态指示
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("昨晚睡眠")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text(sleepStatusText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(sleepStatusColor)
                }

                Spacer()

                Button(action: {
                    showSleepRecords = true
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            // 睡眠质量环形图
            ZStack {
                // 外层装饰圆环
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 20)
                    .frame(width: 200, height: 200)

                // 背景圆环
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 160, height: 160)

                // 进度圆环
                Circle()
                    .trim(from: 0, to: animateCards ? CGFloat(sleepManager.lastSleepRecord?.sleepQualityScore ?? 0) / 100.0 : 0)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(red: 0.3, green: 0.5, blue: 1.0),
                                Color(red: 0.5, green: 0.3, blue: 1.0),
                                Color(red: 0.7, green: 0.5, blue: 1.0),
                                Color(red: 0.9, green: 0.7, blue: 1.0)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 2.0).delay(0.5), value: animateCards)

                // 中心内容
                VStack(spacing: 6) {
                    Image(systemName: sleepQualityIcon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .scaleEffect(animateCards ? 1.0 : 0.8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.8), value: animateCards)

                    Text("\(sleepManager.lastSleepRecord?.sleepQualityScore ?? 0)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 1.0).delay(1.0), value: animateCards)

                    Text("睡眠质量")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.top, 20)

            // 睡眠指标网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                sleepMetricCard(
                    icon: "moon.zzz.fill",
                    value: sleepManager.lastSleepRecord?.formattedSleepDuration ?? "0h 0m",
                    label: "睡眠时长",
                    color: Color(red: 0.4, green: 0.6, blue: 1.0),
                    delay: 0.3
                )

                sleepMetricCard(
                    icon: "percent",
                    value: "\(Int((sleepManager.lastSleepRecord?.sleepEfficiency ?? 0.0) * 100))%",
                    label: "睡眠效率",
                    color: Color(red: 0.6, green: 0.8, blue: 1.0),
                    delay: 0.4
                )

                sleepMetricCard(
                    icon: "clock.fill",
                    value: sleepManager.lastSleepRecord?.formattedWakeTime ?? "--:--",
                    label: "起床时间",
                    color: Color(red: 0.8, green: 0.6, blue: 1.0),
                    delay: 0.5
                )
            }
            .padding(.top, 30)
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .opacity(animateCards ? 1.0 : 0.0)
        .scaleEffect(animateCards ? 1.0 : 0.9)
        .offset(y: animateCards ? 0 : 40)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animateCards)
    }

    private func sleepMetricCard(icon: String, value: String, label: String, color: Color, delay: Double) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .opacity(animateCards ? 1.0 : 0.0)
        .scaleEffect(animateCards ? 1.0 : 0.8)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateCards)
    }






    // MARK: - 快速操作面板

    private var quickActionsPanel: some View {
        VStack(spacing: 16) {
            HStack {
                Text("快速操作")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            HStack(spacing: 12) {
                quickActionCard(
                    icon: "play.circle.fill",
                    title: "开始追踪",
                    subtitle: "记录今晚睡眠",
                    color: Color(red: 0.4, green: 0.8, blue: 0.6),
                    delay: 0.2
                ) {
                    showSleepTracking = true
                }
                
                quickActionCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "睡眠分析",
                    subtitle: "查看详细数据",
                    color: Color(red: 0.6, green: 0.4, blue: 1.0),
                    delay: 0.3
                ) {
                    showSleepInsights = true
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(animateCards ? 1.0 : 0.0)
        .offset(y: animateCards ? 0 : 30)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.0), value: animateCards)
    }

    private func quickActionCard(icon: String, title: String, subtitle: String, color: Color, delay: Double, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )

                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(animateCards ? 1.0 : 0.0)
        .scaleEffect(animateCards ? 1.0 : 0.8)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateCards)
    }



    // MARK: - 辅助方法和计算属性



    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12:
            return "早上好"
        case 12..<17:
            return "下午好"
        case 17..<22:
            return "晚上好"
        default:
            return "夜深了"
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }

    private var sleepQualityIcon: String {
        guard let score = sleepManager.lastSleepRecord?.sleepQualityScore else {
            return "moon.fill"
        }

        switch score {
        case 90...100:
            return "moon.stars.fill"
        case 70..<90:
            return "moon.zzz.fill"
        case 50..<70:
            return "moon.fill"
        default:
            return "moon.circle"
        }
    }

    private var sleepStatusText: String {
        guard let record = sleepManager.lastSleepRecord else {
            return "暂无数据"
        }

        let quality = record.sleepQualityScore
        switch quality {
        case 90...100:
            return "睡眠质量优秀"
        case 80..<90:
            return "睡眠质量良好"
        case 70..<80:
            return "睡眠质量一般"
        case 60..<70:
            return "睡眠质量较差"
        default:
            return "睡眠质量需要改善"
        }
    }

    private var sleepStatusColor: Color {
        guard let record = sleepManager.lastSleepRecord else {
            return .white.opacity(0.6)
        }

        let quality = record.sleepQualityScore
        switch quality {
        case 80...100:
            return Color(red: 0.4, green: 0.8, blue: 0.6)
        case 60..<80:
            return Color(red: 1.0, green: 0.8, blue: 0.4)
        default:
            return Color(red: 1.0, green: 0.6, blue: 0.4)
        }
    }
}

#Preview {
    NavigationView {
        SleepDashboardView()
    }
}