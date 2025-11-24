import SwiftUI

/// 现代化打卡日历页面 - 重新设计版本
struct ModernCheckinCalendarView: View {
    @StateObject private var viewModel = CheckinCalendarViewModel()
    @State private var selectedDate: Date = Date()
    @State private var showingDateDetail = false
    @State private var selectedViewMode: CalendarViewMode = .month
    @State private var animateCards = false
    @State private var showingInsights = false
    @State private var headerOpacity: Double = 1.0

    enum CalendarViewMode: String, CaseIterable {
        case week = "周视图"
        case month = "月视图"
        case year = "年视图"

        var icon: String {
            switch self {
            case .week: return "calendar.day.timeline.left"
            case .month: return "calendar"
            case .year: return "calendar.badge.clock"
            }
        }

        var description: String {
            switch self {
            case .week: return "查看本周打卡情况"
            case .month: return "查看本月打卡日历"
            case .year: return "查看年度打卡热力图"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 现代化渐变背景
                modernBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 毛玻璃导航栏
                    modernNavigationBar
                        .background(
                            VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                                .opacity(headerOpacity)
                        )
                        .zIndex(1000)

                    ScrollView {
                        LazyVStack(spacing: ModernDesignSystem.Spacing.xxl) {
                            // 快速统计概览卡片
                            quickStatsSection
                                .padding(.top, ModernDesignSystem.Spacing.lg)

                            // 增强的视图模式选择器
                            enhancedViewModeSelector

                            // 日历主体区域
                            calendarMainSection

                            // 智能数据洞察
                            if showingInsights {
                                enhancedInsightsSection
                            }

                            // 本月打卡记录
                            monthlyRecordsSection
                        }
                        .modernPagePadding()
                        .padding(.bottom, 120)
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            headerOpacity = value > 50 ? 0.95 : 1.0
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .asRootView() // 标记为根视图，显示Tab栏
        .onAppear {
            Task {
                await viewModel.loadMonthData(for: selectedDate)
            }

            // 错开动画效果
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                animateCards = true
            }
        }
        .sheet(isPresented: $showingDateDetail) {
            modernDateDetailSheet
        }

    }
    
    // MARK: - 现代化渐变背景
    private var modernBackground: some View {
        ZStack {
            // 多层渐变背景
            LinearGradient(
                colors: [
                    Color(red: 248/255, green: 250/255, blue: 252/255),
                    Color(red: 241/255, green: 245/255, blue: 249/255),
                    Color(red: 248/255, green: 250/255, blue: 252/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 装饰性几何图形
            GeometryReader { geometry in
                ZStack {
                    // 主装饰圆形 - 绿色
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    ModernDesignSystem.Colors.primaryGreen.opacity(0.08),
                                    ModernDesignSystem.Colors.primaryGreen.opacity(0.02)
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .offset(x: geometry.size.width * 0.75, y: -100)
                        .blur(radius: 1)

                    // 次装饰圆形 - 蓝色
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    ModernDesignSystem.Colors.accentBlue.opacity(0.06),
                                    ModernDesignSystem.Colors.accentBlue.opacity(0.01)
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                        .offset(x: -60, y: geometry.size.height * 0.85)
                        .blur(radius: 1)

                    // 小装饰圆形 - 橙色
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    ModernDesignSystem.Colors.accentOrange.opacity(0.05),
                                    ModernDesignSystem.Colors.accentOrange.opacity(0.01)
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 120, height: 120)
                        .offset(x: geometry.size.width * 0.2, y: geometry.size.height * 0.3)
                        .blur(radius: 0.5)
                }
            }
        }
    }
    
    // MARK: - 毛玻璃导航栏
    private var modernNavigationBar: some View {
        HStack {
            Spacer()

            // 标题和日期 - 增强设计
            VStack(spacing: 3) {
                Text("功过格")
                    .font(ModernDesignSystem.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)

                Text(getCurrentMonthYear())
                    .font(ModernDesignSystem.Typography.caption1)
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(ModernDesignSystem.Colors.primaryGreen.opacity(0.1))
                    )
            }

            Spacer()

            // 洞察按钮
            Button(action: {
                withAnimation(ModernDesignSystem.Animation.springStandard) {
                    showingInsights.toggle()
                }
            }) {
                Image(systemName: showingInsights ? "brain.head.profile.fill" : "brain.head.profile")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(showingInsights ? .white : ModernDesignSystem.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(showingInsights ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.backgroundCard.opacity(0.8))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.pageHorizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - 快速统计概览
    private var quickStatsSection: some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            // 今日状态
            quickStatCard(
                title: "今日状态",
                value: viewModel.hasTodayCheckedIn ? "已打卡" : "未打卡",
                icon: viewModel.hasTodayCheckedIn ? "checkmark.circle.fill" : "circle",
                color: viewModel.hasTodayCheckedIn ? ModernDesignSystem.Colors.successGreen : ModernDesignSystem.Colors.textTertiary,
                progress: viewModel.hasTodayCheckedIn ? 1.0 : 0.0
            )
            
            // 连续天数
            quickStatCard(
                title: "连续天数",
                value: "\(viewModel.currentStreak)",
                icon: "flame.fill",
                color: ModernDesignSystem.Colors.accentOrange,
                progress: min(Double(viewModel.currentStreak) / 30.0, 1.0)
            )
            
            // 本月完成率
            quickStatCard(
                title: "本月完成率",
                value: String(format: "%.0f%%", viewModel.monthlyCompletionRate),
                icon: "chart.pie.fill",
                color: ModernDesignSystem.Colors.accentBlue,
                progress: viewModel.monthlyCompletionRate / 100.0
            )
        }
        .scaleEffect(animateCards ? 1 : 0.8)
        .opacity(animateCards ? 1 : 0)
        .animation(ModernDesignSystem.Animation.springStandard, value: animateCards)
    }
    
    // MARK: - 快速统计卡片
    private func quickStatCard(title: String, value: String, icon: String, color: Color, progress: Double) -> some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            // 图标和进度环
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                // 进度圆环
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, lineWidth: 4)
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(ModernDesignSystem.Animation.springStandard.delay(0.5), value: progress)
                
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // 数值和标题
            VStack(spacing: ModernDesignSystem.Spacing.xs) {
                Text(value)
                    .font(ModernDesignSystem.Typography.subheadline)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(title)
                    .font(ModernDesignSystem.Typography.caption2)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .modernCardPadding()
        .modernCard()
    }
    
    // MARK: - 增强的视图模式选择器
    private var enhancedViewModeSelector: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            // 选择器标题
            HStack {
                Text("视图模式")
                    .font(ModernDesignSystem.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)

                Spacer()

                Text(selectedViewMode.description)
                    .font(ModernDesignSystem.Typography.caption1)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }

            // 卡片式选择器
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(ModernDesignSystem.Animation.springStandard) {
                            selectedViewMode = mode
                        }
                    }) {
                        VStack(spacing: ModernDesignSystem.Spacing.xs) {
                            // 图标
                            ZStack {
                                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.sm)
                                    .fill(selectedViewMode == mode ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.backgroundSecondary)
                                    .frame(width: 40, height: 40)

                                Image(systemName: mode.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(selectedViewMode == mode ? .white : ModernDesignSystem.Colors.textSecondary)
                            }

                            // 标题
                            Text(mode.rawValue)
                                .font(ModernDesignSystem.Typography.caption1)
                                .fontWeight(.medium)
                                .foregroundColor(selectedViewMode == mode ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ModernDesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                                .fill(selectedViewMode == mode ? ModernDesignSystem.Colors.primaryGreen.opacity(0.1) : ModernDesignSystem.Colors.backgroundCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                                        .stroke(selectedViewMode == mode ? ModernDesignSystem.Colors.primaryGreen.opacity(0.3) : ModernDesignSystem.Colors.borderLight, lineWidth: selectedViewMode == mode ? 2 : 1)
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .modernCardPadding()
        .modernCard()
        .scaleEffect(animateCards ? 1 : 0.9)
        .opacity(animateCards ? 1 : 0)
        .animation(ModernDesignSystem.Animation.springStandard.delay(0.15), value: animateCards)
    }
    
    // MARK: - 日历主体区域
    private var calendarMainSection: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.lg) {
            // 月份导航
            monthNavigationHeader
            
            // 日历视图
            VStack {
                switch selectedViewMode {
                case .week:
                    weekCalendarView
                case .month:
                    monthCalendarView
                case .year:
                    yearCalendarView
                }
            }
        }
        .scaleEffect(animateCards ? 1 : 0.9)
        .opacity(animateCards ? 1 : 0)
        .animation(ModernDesignSystem.Animation.springStandard.delay(0.2), value: animateCards)
    }

    // MARK: - 月份导航头部
    private var monthNavigationHeader: some View {
        HStack {
            // 上个月按钮
            Button(action: {
                withAnimation(ModernDesignSystem.Animation.springStandard) {
                    selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    Task {
                        await viewModel.loadMonthData(for: selectedDate)
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(ModernDesignSystem.Colors.primaryGreen.opacity(0.1))
                    )
            }

            Spacer()

            // 当前月份显示
            VStack(spacing: 2) {
                Text(getMonthYear())
                    .font(ModernDesignSystem.Typography.title3)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)

                Text("共\(viewModel.monthlyCheckinCount)天打卡")
                    .font(ModernDesignSystem.Typography.caption1)
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
            }

            Spacer()

            // 下个月按钮
            Button(action: {
                withAnimation(ModernDesignSystem.Animation.springStandard) {
                    selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    Task {
                        await viewModel.loadMonthData(for: selectedDate)
                    }
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(ModernDesignSystem.Colors.primaryGreen.opacity(0.1))
                    )
            }
        }
    }

    // MARK: - 月视图日历
    private var monthCalendarView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // 星期标题行
            HStack(spacing: 0) {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(ModernDesignSystem.Typography.caption1)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 日历网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: ModernDesignSystem.Spacing.xs), count: 7), spacing: ModernDesignSystem.Spacing.xs) {
                ForEach(viewModel.calendarDays, id: \.id) { dayData in
                    modernCalendarDayCell(dayData)
                }
            }
        }
        .modernCardPadding()
        .modernCard()
    }

    // MARK: - 现代化日历日期单元格
    private func modernCalendarDayCell(_ dayData: CalendarDayData) -> some View {
        Button(action: {
            selectedDate = dayData.date
            showingDateDetail = true
        }) {
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .fill(getDayBackgroundColor(dayData))
                    .frame(height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                            .stroke(getDayBorderColor(dayData), lineWidth: dayData.isToday ? 2 : 0)
                    )

                // 日期数字
                Text("\(Calendar.current.component(.day, from: dayData.date))")
                    .font(ModernDesignSystem.Typography.subheadline)
                    .fontWeight(dayData.isToday ? .bold : .medium)
                    .foregroundColor(getDayTextColor(dayData))

                // 打卡标记
                if dayData.hasCheckin {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(dayData.isToday ? ModernDesignSystem.Colors.primaryGreen : .white)
                                .frame(width: 8, height: 8)
                                .offset(x: -4, y: -4)
                        }
                    }
                }

                // 今日呼吸动画效果
                if dayData.isToday && !dayData.hasCheckin {
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                        .stroke(ModernDesignSystem.Colors.primaryGreen.opacity(0.5), lineWidth: 1)
                        .frame(height: 48)
                        .scaleEffect(animateCards ? 1.1 : 1.0)
                        .opacity(animateCards ? 0.5 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: animateCards
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!dayData.isCurrentMonth)
        .scaleEffect(dayData.isCurrentMonth ? 1.0 : 0.8)
        .opacity(dayData.isCurrentMonth ? 1.0 : 0.3)
    }

    // MARK: - 周视图日历
    private var weekCalendarView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            ForEach(getWeekDays(), id: \.self) { date in
                modernWeekDayCell(date)
            }
        }
        .modernCardPadding()
        .modernCard()
    }

    // MARK: - 现代化周视图单元格
    private func modernWeekDayCell(_ date: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(date)
        let hasCheckin = viewModel.hasCheckinForDate(date)

        return HStack(spacing: ModernDesignSystem.Spacing.lg) {
            // 日期信息
            VStack(spacing: ModernDesignSystem.Spacing.xs) {
                Text(formatWeekday(date))
                    .font(ModernDesignSystem.Typography.caption2)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)

                Text("\(Calendar.current.component(.day, from: date))")
                    .font(ModernDesignSystem.Typography.headline)
                    .fontWeight(isToday ? .bold : .semibold)
                    .foregroundColor(isToday ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.textPrimary)
            }
            .frame(width: 50)

            // 打卡状态
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                // 状态指示器
                ZStack {
                    Circle()
                        .fill(hasCheckin ? ModernDesignSystem.Colors.successGreen : ModernDesignSystem.Colors.borderLight)
                        .frame(width: 20, height: 20)

                    if hasCheckin {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // 状态文字
                Text(hasCheckin ? "已打卡" : "未打卡")
                    .font(ModernDesignSystem.Typography.callout)
                    .foregroundColor(hasCheckin ? ModernDesignSystem.Colors.successGreen : ModernDesignSystem.Colors.textSecondary)

                Spacer()

                // 时间
                if hasCheckin {
                    Text("09:30") // 这里应该从数据中获取实际时间
                        .font(ModernDesignSystem.Typography.caption1)
                        .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                }
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.md)
            .padding(.vertical, ModernDesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.sm)
                    .fill(hasCheckin ? ModernDesignSystem.Colors.successGreen.opacity(0.05) : ModernDesignSystem.Colors.backgroundSecondary)
            )
        }
        .padding(.vertical, ModernDesignSystem.Spacing.xs)
    }

    // MARK: - 年视图日历
    private var yearCalendarView: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.lg) {
            Text("年度打卡热力图")
                .font(ModernDesignSystem.Typography.title3)
                .foregroundColor(ModernDesignSystem.Colors.textPrimary)

            // 热力图
            yearHeatmapView

            // 年度统计
            yearStatsView
        }
        .modernCardPadding()
        .modernCard()
    }

    // MARK: - 年度热力图
    private var yearHeatmapView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            // 月份标签
            HStack {
                ForEach(["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"], id: \.self) { month in
                    Text(month)
                        .font(ModernDesignSystem.Typography.caption2)
                        .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 热力图网格（简化版本）
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 12), spacing: 2) {
                ForEach(0..<365, id: \.self) { day in
                    Rectangle()
                        .fill(getHeatmapColor(for: day))
                        .frame(height: 12)
                        .cornerRadius(2)
                }
            }

            // 图例
            HStack {
                Text("少")
                    .font(ModernDesignSystem.Typography.caption2)
                    .foregroundColor(ModernDesignSystem.Colors.textTertiary)

                HStack(spacing: 2) {
                    ForEach(0..<5) { level in
                        Rectangle()
                            .fill(getHeatmapColor(for: level * 73)) // 简化的颜色计算
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                    }
                }

                Text("多")
                    .font(ModernDesignSystem.Typography.caption2)
                    .foregroundColor(ModernDesignSystem.Colors.textTertiary)

                Spacer()
            }
        }
    }

    // MARK: - 年度统计
    private var yearStatsView: some View {
        HStack(spacing: ModernDesignSystem.Spacing.lg) {
            yearStatItem(title: "总打卡天数", value: "268", color: ModernDesignSystem.Colors.primaryGreen)
            yearStatItem(title: "最长连续", value: "45", color: ModernDesignSystem.Colors.accentOrange)
            yearStatItem(title: "完成率", value: "73%", color: ModernDesignSystem.Colors.accentBlue)
        }
    }

    // MARK: - 年度统计项目
    private func yearStatItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: ModernDesignSystem.Spacing.xs) {
            Text(value)
                .font(ModernDesignSystem.Typography.numberMedium)
                .foregroundColor(color)

            Text(title)
                .font(ModernDesignSystem.Typography.caption2)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 增强的数据洞察区域
    private var enhancedInsightsSection: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.lg) {
            // 洞察标题栏
            HStack {
                HStack(spacing: ModernDesignSystem.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(ModernDesignSystem.Colors.primaryGreen.opacity(0.15))
                            .frame(width: 32, height: 32)

                        Image(systemName: "brain.head.profile.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI智能洞察")
                            .font(ModernDesignSystem.Typography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ModernDesignSystem.Colors.textPrimary)

                        Text("基于您的打卡数据分析")
                            .font(ModernDesignSystem.Typography.caption1)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    }
                }

                Spacer()

                Button(action: {
                    withAnimation(ModernDesignSystem.Animation.springStandard) {
                        showingInsights = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                        .background(
                            Circle()
                                .fill(ModernDesignSystem.Colors.backgroundCard)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // 洞察卡片组
            VStack(spacing: ModernDesignSystem.Spacing.md) {
                enhancedInsightCard(
                    title: "本月表现评价",
                    content: getMonthlyPerformanceInsight(),
                    icon: "chart.line.uptrend.xyaxis",
                    color: ModernDesignSystem.Colors.successGreen,
                    progress: viewModel.monthlyCompletionRate / 100.0
                )

                enhancedInsightCard(
                    title: "习惯养成分析",
                    content: getHabitAnalysisInsight(),
                    icon: "brain.head.profile",
                    color: ModernDesignSystem.Colors.accentBlue,
                    progress: min(Double(viewModel.currentStreak) / 21.0, 1.0)
                )

                enhancedInsightCard(
                    title: "个性化建议",
                    content: getPersonalizedSuggestion(),
                    icon: "lightbulb.fill",
                    color: ModernDesignSystem.Colors.accentOrange,
                    progress: 0.8
                )
            }
        }
        .scaleEffect(animateCards ? 1 : 0.9)
        .opacity(animateCards ? 1 : 0)
        .animation(ModernDesignSystem.Animation.springStandard.delay(0.25), value: animateCards)
    }

    // MARK: - 增强的洞察卡片
    private func enhancedInsightCard(title: String, content: String, icon: String, color: Color, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.md) {
            // 标题栏
            HStack {
                HStack(spacing: ModernDesignSystem.Spacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.sm)
                            .fill(color.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(color)
                    }

                    Text(title)
                        .font(ModernDesignSystem.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                }

                Spacer()

                // 进度指示器
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.2), lineWidth: 3)
                        .frame(width: 24, height: 24)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(color, lineWidth: 3)
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(-90))
                        .animation(ModernDesignSystem.Animation.springStandard.delay(0.5), value: progress)
                }
            }

            // 内容
            Text(content)
                .font(ModernDesignSystem.Typography.callout)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            // 进度条
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                HStack {
                    Text("完成度")
                        .font(ModernDesignSystem.Typography.caption2)
                        .foregroundColor(ModernDesignSystem.Colors.textTertiary)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(ModernDesignSystem.Typography.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(0.2))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geometry.size.width * progress, height: 4)
                            .animation(ModernDesignSystem.Animation.springStandard.delay(0.3), value: progress)
                    }
                }
                .frame(height: 4)
            }
        }
        .modernCardPadding()
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.card)
                .fill(
                    LinearGradient(
                        colors: [
                            ModernDesignSystem.Colors.backgroundCard,
                            color.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.card)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.3),
                                    color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - 本月记录区域
    private var monthlyRecordsSection: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.lg) {
            HStack {
                Text("本月记录")
                    .font(ModernDesignSystem.Typography.title3)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)

                Spacer()

                Text("\(viewModel.checkinRecords.count)条记录")
                    .font(ModernDesignSystem.Typography.caption1)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }

            if viewModel.checkinRecords.isEmpty {
                // 空状态
                VStack(spacing: ModernDesignSystem.Spacing.lg) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(ModernDesignSystem.Colors.textTertiary)

                    VStack(spacing: ModernDesignSystem.Spacing.xs) {
                        Text("本月还没有打卡记录")
                            .font(ModernDesignSystem.Typography.subheadline)
                            .foregroundColor(ModernDesignSystem.Colors.textPrimary)

                        Text("开始您的第一次打卡吧")
                            .font(ModernDesignSystem.Typography.callout)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ModernDesignSystem.Spacing.xxxl)
                .modernCardPadding()
                .modernCard()
            } else {
                // 记录列表
                LazyVStack(spacing: ModernDesignSystem.Spacing.md) {
                    ForEach(viewModel.checkinRecords.prefix(5), id: \.id) { record in
                        modernCheckinRecordRow(record)
                    }

                    if viewModel.checkinRecords.count > 5 {
                        Button("查看更多记录") {
                            // 处理查看更多逻辑
                        }
                        .modernButton(style: .tertiary)
                    }
                }
            }
        }
        .scaleEffect(animateCards ? 1 : 0.9)
        .opacity(animateCards ? 1 : 0)
        .animation(ModernDesignSystem.Animation.springStandard.delay(0.4), value: animateCards)
    }

    // MARK: - 现代化打卡记录行
    private func modernCheckinRecordRow(_ record: CheckinRecord) -> some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            // 日期圆形标记
            ZStack {
                Circle()
                    .fill(ModernDesignSystem.Colors.primaryGreen.opacity(0.15))
                    .frame(width: 50, height: 50)

                VStack(spacing: 2) {
                    Text(formatDay(record.date))
                        .font(ModernDesignSystem.Typography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(ModernDesignSystem.Colors.primaryGreen)

                    Text(formatWeekday(record.date))
                        .font(ModernDesignSystem.Typography.caption2)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                }
            }

            // 内容信息
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                HStack {
                    Text("打卡成功")
                        .font(ModernDesignSystem.Typography.subheadline)
                        .foregroundColor(ModernDesignSystem.Colors.textPrimary)

                    Spacer()

                    Text(formatTime(record.date))
                        .font(ModernDesignSystem.Typography.caption1)
                        .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                }

                Text("心情：\(record.mood.description)")
                    .font(ModernDesignSystem.Typography.callout)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)

                if let note = record.note, !note.isEmpty {
                    Text(note)
                        .font(ModernDesignSystem.Typography.callout)
                        .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                        .lineLimit(nil) // 允许多行显示
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true) // 允许垂直扩展
                }
            }

            // 状态图标
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(ModernDesignSystem.Colors.successGreen)
        }
        .modernCardPadding()
        .modernCard()
    }

    // MARK: - 现代化日期详情表单
    private var modernDateDetailSheet: some View {
        NavigationView {
            VStack(spacing: ModernDesignSystem.Spacing.xl) {
                // 日期标题
                VStack(spacing: ModernDesignSystem.Spacing.sm) {
                    Text(formatFullDate(selectedDate))
                        .font(ModernDesignSystem.Typography.title2)
                        .foregroundColor(ModernDesignSystem.Colors.textPrimary)

                    Text(formatWeekday(selectedDate))
                        .font(ModernDesignSystem.Typography.subheadline)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                }

                // 打卡状态
                let hasCheckin = viewModel.hasCheckinForDate(selectedDate)
                VStack(spacing: ModernDesignSystem.Spacing.lg) {
                    // 状态图标
                    ZStack {
                        Circle()
                            .fill(hasCheckin ? ModernDesignSystem.Colors.successGreen.opacity(0.15) : ModernDesignSystem.Colors.borderLight)
                            .frame(width: 100, height: 100)

                        Image(systemName: hasCheckin ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(hasCheckin ? ModernDesignSystem.Colors.successGreen : ModernDesignSystem.Colors.textTertiary)
                    }

                    // 状态文字
                    Text(hasCheckin ? "已完成打卡" : "未打卡")
                        .font(ModernDesignSystem.Typography.title3)
                        .foregroundColor(hasCheckin ? ModernDesignSystem.Colors.successGreen : ModernDesignSystem.Colors.textSecondary)

                    // 操作按钮
                    if !hasCheckin && !isDateInFuture(selectedDate) {
                        Button("补打卡") {
                            // 处理补打卡逻辑
                            showingDateDetail = false
                        }
                        .modernButton(style: .primary)
                    }
                }

                Spacer()
            }
            .modernPagePadding()
            .navigationTitle("日期详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        showingDateDetail = false
                    }
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                }
            }
        }
    }

    // MARK: - 辅助方法
    private func getCurrentMonthYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: selectedDate)
    }

    private func getMonthYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 MM月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: selectedDate)
    }

    private func getWeekDays() -> [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate

        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }

    private func getDayBackgroundColor(_ dayData: CalendarDayData) -> Color {
        if !dayData.isCurrentMonth {
            return Color.clear
        } else if dayData.hasCheckin {
            return ModernDesignSystem.Colors.primaryGreen
        } else if dayData.isToday {
            return ModernDesignSystem.Colors.primaryGreen.opacity(0.1)
        } else {
            return ModernDesignSystem.Colors.backgroundSecondary
        }
    }

    private func getDayBorderColor(_ dayData: CalendarDayData) -> Color {
        if dayData.isToday {
            return ModernDesignSystem.Colors.primaryGreen
        } else {
            return Color.clear
        }
    }

    private func getDayTextColor(_ dayData: CalendarDayData) -> Color {
        if !dayData.isCurrentMonth {
            return ModernDesignSystem.Colors.textDisabled
        } else if dayData.hasCheckin {
            return .white
        } else if dayData.isToday {
            return ModernDesignSystem.Colors.primaryGreen
        } else {
            return ModernDesignSystem.Colors.textPrimary
        }
    }

    private func getHeatmapColor(for day: Int) -> Color {
        // 简化的热力图颜色计算
        let intensity = Double(day % 5) / 4.0
        return ModernDesignSystem.Colors.primaryGreen.opacity(0.2 + intensity * 0.8)
    }

    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }

    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private func isDateInFuture(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.compare(date, to: today, toGranularity: .day) == .orderedDescending
    }

    // MARK: - 智能洞察方法

    /// 获取月度表现洞察
    private func getMonthlyPerformanceInsight() -> String {
        let rate = viewModel.monthlyCompletionRate

        if rate >= 90 {
            return "🎉 您本月的打卡表现非常出色！完成率达到\(String(format: "%.0f", rate))%，远超平均水平。您已经建立了很好的习惯，继续保持这种优秀的状态！"
        } else if rate >= 75 {
            return "👍 您本月的打卡表现良好，完成率为\(String(format: "%.0f", rate))%。距离优秀还有一步之遥，加油冲刺最后几天！"
        } else if rate >= 60 {
            return "💪 您本月的打卡完成率为\(String(format: "%.0f", rate))%，还有提升空间。建议设置提醒，帮助您更好地坚持打卡习惯。"
        } else {
            return "🌱 您本月的打卡完成率为\(String(format: "%.0f", rate))%，习惯养成需要时间。建议从小目标开始，逐步建立稳定的打卡节奏。"
        }
    }

    /// 获取习惯分析洞察
    private func getHabitAnalysisInsight() -> String {
        let streak = viewModel.currentStreak

        if streak >= 21 {
            return "🏆 恭喜！您已经连续打卡\(streak)天，成功养成了稳定的习惯。研究表明，21天是习惯养成的关键期，您已经超越了这个里程碑！"
        } else if streak >= 14 {
            return "🔥 您已经连续打卡\(streak)天，距离21天习惯养成目标还有\(21 - streak)天。坚持就是胜利，您已经走过了最困难的阶段！"
        } else if streak >= 7 {
            return "📈 您已经连续打卡\(streak)天，这是一个很好的开始！第一周是习惯养成的基础期，继续保持这个节奏。"
        } else if streak >= 3 {
            return "🌟 您已经连续打卡\(streak)天，习惯正在形成中。前几天是最关键的，每一天的坚持都很有意义。"
        } else {
            return "🚀 开始建立您的打卡习惯吧！连续性是关键，即使是小小的开始也会带来巨大的改变。今天就是最好的开始！"
        }
    }

    /// 获取个性化建议
    private func getPersonalizedSuggestion() -> String {
        let rate = viewModel.monthlyCompletionRate
        let streak = viewModel.currentStreak

        if rate < 50 {
            return "💡 建议：设置每日提醒，选择固定的打卡时间，比如早上起床后或晚上睡前。固定的时间有助于形成自动化的习惯。"
        } else if streak < 7 {
            return "⏰ 建议：尝试将打卡与现有习惯绑定，比如刷牙后打卡、吃早餐前打卡。这种'习惯叠加'能提高成功率。"
        } else if rate < 80 {
            return "📱 建议：在手机桌面放置打卡应用，减少打卡的步骤。同时可以设置多个提醒时间，确保不会遗忘。"
        } else {
            return "🎯 建议：您的习惯已经很稳定了！可以考虑设定更高的目标，或者帮助朋友一起养成好习惯，互相监督和鼓励。"
        }
    }
}



// MARK: - 辅助组件

/// 毛玻璃效果
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

// MARK: - 预览
struct ModernCheckinCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        ModernCheckinCalendarView()
    }
}
 
