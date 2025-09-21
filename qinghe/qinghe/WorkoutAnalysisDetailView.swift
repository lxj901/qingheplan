import SwiftUI
import Charts

/// 运动分析详细页面
struct WorkoutAnalysisDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var homePageViewModel = HomePageViewModel()
    @State private var selectedTimeRange = 0 // 0: 本周, 1: 本月, 2: 本年
    @State private var selectedDataType = 0 // 0: 运动时长, 1: 卡路里, 2: 次数
    @State private var animateCharts = false
    @State private var currentDateOffset = 0 // 用于时期导航
    @State private var selectedWorkoutForDetail: WorkoutHistoryItem? // 用于导航到运动详情页面

    // 新增：API数据状态
    @State private var workoutHistoryData: [WorkoutHistoryItem] = []
    @State private var isLoadingHistory = false
    @State private var statisticsData: WorkoutStatisticsData?

    // 分页相关状态
    @State private var currentPage = 1
    @State private var hasMoreHistory = true
    @State private var isLoadingMoreHistory = false
    private let pageSize = 10

    // 新增：图表数据状态
    @State private var chartData: [HomeWorkoutData] = []

    private let timeRanges = ["本周", "本月", "本年"]
    private let dataTypes = ["运动时长", "卡路里", "次数"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                Color(hex: "f9f9f9")
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 24) {
                        // 时间范围选择器
                        timeRangeSelector
                            .padding(.horizontal, 20)

                        // 运动数据图表展示
                        workoutDataImageView
                            .padding(.horizontal, 20)

                        // 运动历史模块
                        workoutHistorySection
                            .padding(.horizontal, 20)

                        // 底部间距
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 10)
                }
            }
            .navigationTitle("运动记录")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("返回")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadAllWorkoutData()
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
                    animateCharts = true
                }
            }
        }
        .fullScreenCover(item: $selectedWorkoutForDetail) { workout in
            WorkoutDetailView(workoutHistoryItem: workout)
        }
        .asSubView()
    }
    
    // MARK: - 时间范围选择器
    private var timeRangeSelector: some View {
        VStack(spacing: 16) {
            HStack {
                Text("数据范围")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))

                Spacer()
            }

            Picker("数据范围", selection: $selectedTimeRange) {
                ForEach(0..<timeRanges.count, id: \.self) { index in
                    Text(timeRanges[index]).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedTimeRange) {
                // 当选择改变时重新加载数据
                Task {
                    await loadAllWorkoutData()
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 运动数据图表展示
    private var workoutDataImageView: some View {
        VStack(spacing: 0) {
            // 占位图片区域，模拟设计图的样式
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

                VStack(spacing: 16) {
                    // 顶部时间范围显示
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentDateOffset -= 1
                            }
                            Task {
                                await homePageViewModel.loadWorkoutAnalysisData()
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(width: 32, height: 32)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Text(getCurrentDateRangeText())
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))

                        Spacer()

                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentDateOffset += 1
                            }
                            Task {
                                await homePageViewModel.loadWorkoutAnalysisData()
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(width: 32, height: 32)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // 图表区域占位
                    VStack(spacing: 12) {
                        // 累积数据标签（可点击切换数据类型）
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    selectedDataType = (selectedDataType + 1) % dataTypes.count
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Text("累积数据")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(getDataTypeColor())

                                    Text("(\(dataTypes[selectedDataType]))")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(getDataTypeColor().opacity(0.8))

                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 12))
                                        .foregroundColor(getDataTypeColor())
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(getDataTypeColor().opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)

                        // 现代化运动数据图表
                        VStack(spacing: 0) {
                            if #available(iOS 16.0, *) {
                                Chart {
                                    ForEach(chartData, id: \.id) { data in
                                        BarMark(
                                            x: .value("日期", data.date),
                                            y: .value(getCurrentDataTypeLabel(), animateCharts ? getCurrentDataValue(data) : 0)
                                        )
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [getDataTypeColor(), getDataTypeColor().opacity(0.6)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .cornerRadius(6)
                                    }
                                }
                                .frame(height: 200)
                                .chartYAxis {
                                    AxisMarks(position: .leading) { value in
                                        AxisValueLabel {
                                            if let intValue = value.as(Int.self) {
                                                Text("\(intValue)\(getCurrentDataUnit())")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks { value in
                                        AxisValueLabel {
                                            if let stringValue = value.as(String.self) {
                                                Text(stringValue)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: selectedDataType)
                            } else {
                                // iOS 15 兼容性处理
                                HStack(alignment: .bottom, spacing: 12) {
                                    ForEach(chartData, id: \.id) { data in
                                        VStack(spacing: 8) {
                                            Rectangle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [getDataTypeColor(), getDataTypeColor().opacity(0.6)],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .frame(width: 28, height: animateCharts ? CGFloat(getCurrentDataValue(data)) * 2 : 0)
                                                .cornerRadius(6)
                                                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animateCharts)

                                            Text(data.date)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .frame(height: 200)
                            }
                        }
                        .padding(.horizontal, 20)

                        // 现代化交互式数据卡片
                        modernDataMetricsCards
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
    }
    

    
    // MARK: - 辅助方法
    
    private func getTimeRangeText() -> String {
        switch selectedTimeRange {
        case 0: return "最近7天"
        case 1: return "最近30天"
        case 2: return "最近365天"
        default: return "最近7天"
        }
    }

    private func getCurrentDateRangeText() -> String {
        let calendar = Calendar.current
        let today = Date()

        switch selectedTimeRange {
        case 0: // 本周
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
            let adjustedStart = calendar.date(byAdding: .weekOfYear, value: currentDateOffset, to: startOfWeek) ?? startOfWeek
            let adjustedEnd = calendar.date(byAdding: .day, value: 6, to: adjustedStart) ?? adjustedStart

            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return "\(formatter.string(from: adjustedStart))～\(formatter.string(from: adjustedEnd))"

        case 1: // 本月
            let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
            let adjustedStart = calendar.date(byAdding: .month, value: currentDateOffset, to: startOfMonth) ?? startOfMonth
            let adjustedEnd = calendar.date(byAdding: .month, value: 1, to: adjustedStart) ?? adjustedStart
            let endOfMonth = calendar.date(byAdding: .day, value: -1, to: adjustedEnd) ?? adjustedStart

            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return "\(formatter.string(from: adjustedStart))～\(formatter.string(from: endOfMonth))"

        case 2: // 本年
            let startOfYear = calendar.dateInterval(of: .year, for: today)?.start ?? today
            let adjustedStart = calendar.date(byAdding: .year, value: currentDateOffset, to: startOfYear) ?? startOfYear
            let adjustedEnd = calendar.date(byAdding: .year, value: 1, to: adjustedStart) ?? adjustedStart
            let endOfYear = calendar.date(byAdding: .day, value: -1, to: adjustedEnd) ?? adjustedStart

            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return "\(formatter.string(from: adjustedStart))～\(formatter.string(from: endOfYear))"

        default:
            return "1月1日～12月31日"
        }
    }

    // MARK: - 现代化数据指标卡片
    private var modernDataMetricsCards: some View {
        HStack(spacing: 0) {
            // 运动时长卡片
            modernDataCard(
                title: "运动时长",
                value: getTotalDuration(),
                icon: "clock.fill",
                isSelected: selectedDataType == 0,
                color: Color(red: 76/255, green: 175/255, blue: 80/255)
            ) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    selectedDataType = 0
                }
            }

            // 卡路里卡片
            modernDataCard(
                title: "卡路里",
                value: getTotalCalories(),
                icon: "flame.fill",
                isSelected: selectedDataType == 1,
                color: Color(red: 255/255, green: 149/255, blue: 0/255)
            ) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    selectedDataType = 1
                }
            }

            // 运动次数卡片
            modernDataCard(
                title: "次数",
                value: getTotalWorkouts(),
                icon: "target",
                isSelected: selectedDataType == 2,
                color: Color(red: 0/255, green: 122/255, blue: 255/255)
            ) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    selectedDataType = 2
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - 现代化数据卡片组件
    private func modernDataCard(
        title: String,
        value: String,
        icon: String,
        isSelected: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? color : .gray)

                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isSelected ? color : .gray)
                }

                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? color : Color(red: 51/255, green: 51/255, blue: 51/255))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1.5)
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 数据辅助方法
    private func getCurrentDataTypeLabel() -> String {
        return dataTypes[selectedDataType]
    }

    private func getDataTypeColor() -> Color {
        switch selectedDataType {
        case 0: return Color(red: 76/255, green: 175/255, blue: 80/255) // 运动时长 - 绿色
        case 1: return Color(red: 255/255, green: 149/255, blue: 0/255) // 卡路里 - 橙色
        case 2: return Color(red: 0/255, green: 122/255, blue: 255/255) // 次数 - 蓝色
        default: return Color(red: 76/255, green: 175/255, blue: 80/255)
        }
    }

    private func getCurrentDataUnit() -> String {
        switch selectedDataType {
        case 0: return "分"
        case 1: return "千卡"
        case 2: return "次"
        default: return "分"
        }
    }

    private func getCurrentDataValue(_ data: HomeWorkoutData) -> Double {
        switch selectedDataType {
        case 0: return Double(data.duration)
        case 1: return Double(data.calories)
        case 2: return data.hasWorkout ? 1.0 : 0.0 // 运动次数：有运动为1，无运动为0
        default: return Double(data.duration)
        }
    }

    private func getTotalDuration() -> String {
        if let stats = statisticsData {
            let totalMinutes = stats.effectiveStatistics.totalDuration / 60
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return "\(hours)小时\(minutes)分"
        } else {
            // 后备：使用图表数据
            let totalMinutes = chartData.reduce(0) { $0 + $1.duration }
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return "\(hours)小时\(minutes)分"
        }
    }

    private func getTotalCalories() -> String {
        if let stats = statisticsData {
            return "\(stats.effectiveStatistics.totalCalories)千卡"
        } else {
            // 后备：使用图表数据
            let total = chartData.reduce(0) { $0 + $1.calories }
            return "\(total)千卡"
        }
    }

    private func getTotalWorkouts() -> String {
        if let stats = statisticsData {
            return "\(stats.effectiveStatistics.totalWorkouts)次"
        } else {
            // 后备：使用图表数据
            let total = chartData.filter { $0.hasWorkout }.count
            return "\(total)次"
        }
    }

    // MARK: - 运动历史模块
    private var workoutHistorySection: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text("运动历史")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // 运动历史列表
            VStack(spacing: 0) {
                ForEach(getWorkoutHistoryData(), id: \.id) { workout in
                    workoutHistoryRow(workout)

                    if workout.id != getWorkoutHistoryData().last?.id {
                        Divider()
                            .padding(.leading, 68) // 对齐图标后的位置
                    }
                }

                // 加载更多按钮或加载指示器
                if hasMoreHistory {
                    if isLoadingMoreHistory {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("加载中...")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 16)
                    } else {
                        Button(action: {
                            Task {
                                await loadMoreWorkoutHistory()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 16))
                                Text("加载更多")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - 运动历史行
    private func workoutHistoryRow(_ workout: WorkoutHistoryItem) -> some View {
        HStack(spacing: 16) {
            // 运动类型图标
            ZStack {
                Circle()
                    .fill(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: getWorkoutIcon(workout.type))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
            }

            // 运动信息
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.type)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))

                HStack(spacing: 4) {
                    Text("\(workout.duration)分钟")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))

                    Text("•")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))

                    Text(workout.date)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))

                    Spacer()
                }
            }

            Spacer()

            // 卡路里和箭头
            HStack(spacing: 8) {
                Text("\(workout.calories)千卡")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 204/255, green: 204/255, blue: 204/255))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            // 点击跳转到运动详情
            selectedWorkoutForDetail = workout
        }
    }

    // MARK: - 获取运动历史数据
    private func getWorkoutHistoryData() -> [WorkoutHistoryItem] {
        return workoutHistoryData
    }

    // MARK: - 加载所有运动数据
    private func loadAllWorkoutData() async {
        await homePageViewModel.loadWorkoutAnalysisData()
        await loadWorkoutHistory()
        await loadWorkoutStatistics()
        await generateChartData()
    }

    // MARK: - 生成图表数据
    private func generateChartData() async {
        await MainActor.run {
            switch selectedTimeRange {
            case 0: // 本周
                chartData = generateWeeklyChartData()
            case 1: // 本月
                chartData = generateMonthlyChartData()
            case 2: // 本年
                chartData = generateYearlyChartData()
            default:
                chartData = generateWeeklyChartData()
            }
        }
    }

    // 生成本周图表数据（周一到周日）
    private func generateWeeklyChartData() -> [HomeWorkoutData] {
        // 使用现有的周数据
        return homePageViewModel.weeklyWorkoutData
    }

    // 生成本月图表数据（显示日期数字）
    private func generateMonthlyChartData() -> [HomeWorkoutData] {
        // 基于实际的运动历史数据生成月度图表
        return generateChartDataFromWorkoutHistory(timeRange: .month)
    }

    // 生成本年图表数据（显示月份）
    private func generateYearlyChartData() -> [HomeWorkoutData] {
        // 基于实际的运动历史数据生成年度图表
        return generateChartDataFromWorkoutHistory(timeRange: .year)
    }

    // 时间范围枚举
    private enum ChartTimeRange {
        case week, month, year
    }

    // 基于实际运动历史数据生成图表数据
    private func generateChartDataFromWorkoutHistory(timeRange: ChartTimeRange) -> [HomeWorkoutData] {
        let calendar = Calendar.current
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        print("📊 开始生成图表数据，时间范围: \(timeRange)")
        print("📊 运动历史数据总数: \(workoutHistoryData.count)")

        // 创建日期到运动数据的映射
        var workoutDataMap: [String: (duration: Int, calories: Int, distance: Double, count: Int)] = [:]

        // 处理运动历史数据
        for workout in workoutHistoryData {
            print("📊 处理运动记录: \(workout.date) - \(workout.type) - \(workout.duration)分钟")
            // 解析运动日期
            if let workoutDate = parseWorkoutDate(workout.date) {
                let dateKey = dateFormatter.string(from: workoutDate)
                print("📊 日期解析成功: \(workout.date) -> \(dateKey)")

                // 累加同一天的运动数据
                if var existingData = workoutDataMap[dateKey] {
                    existingData.duration += workout.duration
                    existingData.calories += workout.calories
                    existingData.count += 1
                    workoutDataMap[dateKey] = existingData
                    print("📊 累加到现有日期 \(dateKey): \(existingData.duration)分钟")
                } else {
                    workoutDataMap[dateKey] = (
                        duration: workout.duration,
                        calories: workout.calories,
                        distance: 0.0, // 运动历史中没有距离数据
                        count: 1
                    )
                    print("📊 新增日期 \(dateKey): \(workout.duration)分钟")
                }
            } else {
                print("❌ 日期解析失败: \(workout.date)")
            }
        }

        print("📊 日期映射完成，共 \(workoutDataMap.count) 个日期有数据:")
        for (date, data) in workoutDataMap.sorted(by: { $0.key < $1.key }) {
            print("  \(date): \(data.duration)分钟, \(data.calories)卡路里, \(data.count)次")
        }

        var chartData: [HomeWorkoutData] = []

        switch timeRange {
        case .week:
            // 本周数据：使用现有的周数据
            return homePageViewModel.weeklyWorkoutData

        case .month:
            // 本月数据：只显示有运动数据的日期
            let monthInterval = calendar.dateInterval(of: .month, for: today)!
            let startOfMonth = monthInterval.start
            let endOfMonth = monthInterval.end

            print("📊 生成本月数据，时间范围: \(startOfMonth) 到 \(endOfMonth)")

            // 遍历本月的每一天
            var currentDate = startOfMonth
            while currentDate < endOfMonth {
                let dateKey = dateFormatter.string(from: currentDate)

                // 只有当天有运动数据时才添加到图表
                if let workoutData = workoutDataMap[dateKey] {
                    let day = calendar.component(.day, from: currentDate)
                    let chartItem = HomeWorkoutData(
                        date: "\(day)",
                        duration: workoutData.duration,
                        type: getWorkoutTypeFromHistory(for: dateKey),
                        calories: workoutData.calories,
                        distance: workoutData.distance
                    )
                    chartData.append(chartItem)
                    print("📊 添加本月数据: \(day)日 - \(workoutData.duration)分钟")
                }

                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }

            print("📊 本月图表数据生成完成，共 \(chartData.count) 天有数据")

        case .year:
            // 本年数据：按月聚合，只显示有运动数据的月份
            let yearInterval = calendar.dateInterval(of: .year, for: today)!
            let startOfYear = yearInterval.start

            print("📊 生成本年数据，年份: \(calendar.component(.year, from: today))")

            // 创建月份到运动数据的映射
            var monthlyDataMap: [Int: (duration: Int, calories: Int, distance: Double, count: Int)] = [:]

            for (dateKey, workoutData) in workoutDataMap {
                if let date = dateFormatter.date(from: dateKey),
                   calendar.isDate(date, equalTo: today, toGranularity: .year) {
                    let month = calendar.component(.month, from: date)

                    print("📊 处理年度数据: \(dateKey) -> \(month)月, \(workoutData.duration)分钟")

                    if var existingData = monthlyDataMap[month] {
                        existingData.duration += workoutData.duration
                        existingData.calories += workoutData.calories
                        existingData.count += workoutData.count
                        monthlyDataMap[month] = existingData
                        print("📊 累加到 \(month)月: \(existingData.duration)分钟")
                    } else {
                        monthlyDataMap[month] = workoutData
                        print("📊 新增 \(month)月: \(workoutData.duration)分钟")
                    }
                }
            }

            print("📊 月度数据聚合完成，共 \(monthlyDataMap.count) 个月有数据:")
            for (month, data) in monthlyDataMap.sorted(by: { $0.key < $1.key }) {
                print("  \(month)月: \(data.duration)分钟, \(data.calories)卡路里, \(data.count)次")
            }

            // 只添加有数据的月份
            for month in 1...12 {
                if let monthData = monthlyDataMap[month] {
                    let chartItem = HomeWorkoutData(
                        date: "\(month)月",
                        duration: monthData.duration,
                        type: "运动",
                        calories: monthData.calories,
                        distance: monthData.distance
                    )
                    chartData.append(chartItem)
                    print("📊 添加年度图表数据: \(month)月 - \(monthData.duration)分钟")
                }
            }

            print("📊 本年图表数据生成完成，共 \(chartData.count) 个月有数据")
        }

        return chartData
    }

    // 解析运动日期
    private func parseWorkoutDate(_ dateString: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd HH:mm:ss",  // API返回格式：2025-09-16 12:34:18
            "yyyy-MM-dd HH:mm",     // 标准格式
            "MM月dd日 HH:mm",       // 中文格式
            "yyyy-MM-dd",           // 日期格式
            "MM月dd日"              // 中文日期格式
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "zh_CN")
            if let date = formatter.date(from: dateString) {
                print("📅 成功解析日期: \(dateString) -> \(date)")
                return date
            }
        }

        print("❌ 无法解析日期格式: \(dateString)")
        return nil
    }

    // 从历史数据中获取运动类型
    private func getWorkoutTypeFromHistory(for dateKey: String) -> String {
        for workout in workoutHistoryData {
            if let workoutDate = parseWorkoutDate(workout.date) {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if formatter.string(from: workoutDate) == dateKey {
                    return workout.type
                }
            }
        }
        return "运动"
    }



    // MARK: - 加载运动历史记录
    private func loadWorkoutHistory() async {
        isLoadingHistory = true
        currentPage = 1 // 重置页码

        do {
            // 根据选择的时间范围获取日期过滤参数
            let (startDate, endDate) = getTimeRangeFilter()

            // 根据时间范围调整获取的数据量
            let limitSize = getLimitForTimeRange()

            // 获取运动记录列表
            let workouts = try await NewWorkoutAPIService.shared.getWorkouts(
                page: currentPage,
                limit: limitSize,
                startDate: startDate,
                endDate: endDate,
                sortBy: "startTime",
                sortOrder: "desc"
            )

            // 转换为WorkoutHistoryItem格式
            let historyItems = workouts.map { workout in
                WorkoutHistoryItem(
                    id: UUID(),
                    workoutId: workout.workoutId, // 添加workoutId
                    type: convertWorkoutTypeToDisplayName(workout.workoutType),
                    duration: workout.duration / 60, // 转换为分钟
                    date: formatDateForDisplay(workout.startTime),
                    calories: workout.basicMetrics.calories,
                    source: "青禾计划"
                )
            }

            await MainActor.run {
                self.workoutHistoryData = historyItems
                self.hasMoreHistory = workouts.count >= pageSize
                self.isLoadingHistory = false
            }

        } catch {
            print("❌ 加载运动历史失败: \(error)")

            // 如果API调用失败，使用模拟数据
            await MainActor.run {
                self.workoutHistoryData = getMockWorkoutHistory()
                self.hasMoreHistory = false
                self.isLoadingHistory = false
            }
        }
    }

    // MARK: - 加载更多运动历史记录
    private func loadMoreWorkoutHistory() async {
        guard !isLoadingMoreHistory && hasMoreHistory else { return }

        isLoadingMoreHistory = true
        currentPage += 1

        do {
            // 根据选择的时间范围获取日期过滤参数
            let (startDate, endDate) = getTimeRangeFilter()

            // 获取更多运动记录
            let workouts = try await NewWorkoutAPIService.shared.getWorkouts(
                page: currentPage,
                limit: pageSize,
                startDate: startDate,
                endDate: endDate,
                sortBy: "startTime",
                sortOrder: "desc"
            )

            // 转换为WorkoutHistoryItem格式
            let historyItems = workouts.map { workout in
                WorkoutHistoryItem(
                    id: UUID(),
                    workoutId: workout.workoutId, // 添加workoutId
                    type: convertWorkoutTypeToDisplayName(workout.workoutType),
                    duration: workout.duration / 60, // 转换为分钟
                    date: formatDateForDisplay(workout.startTime),
                    calories: workout.basicMetrics.calories,
                    source: "青禾计划"
                )
            }

            await MainActor.run {
                self.workoutHistoryData.append(contentsOf: historyItems)
                self.hasMoreHistory = workouts.count >= pageSize
                self.isLoadingMoreHistory = false
            }

        } catch {
            print("❌ 加载更多运动历史失败: \(error)")

            await MainActor.run {
                self.currentPage -= 1 // 回退页码
                self.isLoadingMoreHistory = false
            }
        }
    }

    // MARK: - 加载运动统计数据
    private func loadWorkoutStatistics() async {
        do {
            let period = getCurrentPeriod()
            let stats = try await NewWorkoutAPIService.shared.getWorkoutStatistics(period: period)

            await MainActor.run {
                self.statisticsData = stats
            }

        } catch {
            print("❌ 加载运动统计数据失败: \(error)")
        }
    }

    // MARK: - 辅助方法
    private func getCurrentPeriod() -> String {
        switch selectedTimeRange {
        case 0: return "week"
        case 1: return "month"
        case 2: return "year"
        default: return "week"
        }
    }

    // 根据时间范围获取合适的数据量限制
    private func getLimitForTimeRange() -> Int {
        switch selectedTimeRange {
        case 0: return 50   // 本周：50条记录足够
        case 1: return 200  // 本月：200条记录
        case 2: return 1000 // 本年：1000条记录
        default: return 50
        }
    }

    // MARK: - 获取时间范围过滤参数
    private func getTimeRangeFilter() -> (startDate: String?, endDate: String?) {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        switch selectedTimeRange {
        case 0: // 本周
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
            return (formatter.string(from: startOfWeek), formatter.string(from: endOfWeek))

        case 1: // 本月
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
            return (formatter.string(from: startOfMonth), formatter.string(from: endOfMonth))

        case 2: // 本年
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let endOfYear = calendar.dateInterval(of: .year, for: now)?.end ?? now
            return (formatter.string(from: startOfYear), formatter.string(from: endOfYear))

        default:
            return (nil, nil)
        }
    }

    private func convertWorkoutTypeToDisplayName(_ type: String) -> String {
        switch type {
        case "running": return "跑步"
        case "walking": return "步行"
        case "cycling": return "骑行"
        case "swimming": return "游泳"
        case "yoga": return "瑜伽"
        case "strength": return "力量训练"
        case "hiking": return "徒步"
        default: return "运动"
        }
    }

    private func formatDateForDisplay(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "M月d日"
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    private func getMockWorkoutHistory() -> [WorkoutHistoryItem] {
        return [
            WorkoutHistoryItem(
                id: UUID(),
                workoutId: nil, // 模拟数据没有真实的workoutId
                type: "户外步行",
                duration: 19,
                date: "7月21日",
                calories: 59,
                source: "Keep"
            ),
            WorkoutHistoryItem(
                id: UUID(),
                workoutId: nil,
                type: "户外步行",
                duration: 37,
                date: "7月21日",
                calories: 102,
                source: "Keep"
            ),
            WorkoutHistoryItem(
                id: UUID(),
                workoutId: nil,
                type: "户外步行",
                duration: 38,
                date: "7月21日",
                calories: 105,
                source: "Keep"
            ),
            WorkoutHistoryItem(
                id: UUID(),
                workoutId: nil,
                type: "户外步行",
                duration: 19,
                date: "7月20日",
                calories: 56,
                source: "Keep"
            )
        ]
    }

    // MARK: - 获取运动类型图标
    private func getWorkoutIcon(_ type: String) -> String {
        switch type {
        case "户外步行", "步行":
            return "figure.walk"
        case "跑步", "户外跑步":
            return "figure.run"
        case "骑行", "户外骑行":
            return "bicycle"
        case "游泳":
            return "figure.pool.swim"
        case "瑜伽":
            return "figure.yoga"
        case "力量训练":
            return "dumbbell"
        default:
            return "figure.walk"
        }
    }
}

// MARK: - 数据模型
struct WorkoutTypeData {
    let type: String
    let count: Int
    let percentage: Double
    let icon: String
    let color: Color
}

struct AIWorkoutInsight {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - 运动历史数据模型
struct WorkoutHistoryItem: Identifiable {
    let id: UUID
    let workoutId: Int? // 添加workoutId字段
    let type: String
    let duration: Int // 分钟
    let date: String
    let calories: Int
    let source: String
}
