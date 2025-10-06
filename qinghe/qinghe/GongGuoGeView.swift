import SwiftUI
import UIKit

/// 了凡四训功过格 - 初始页面（米色背景 + 滚动后显示导航栏）
struct GongGuoGeView: View {
    @StateObject private var viewModel = MeritViewModel()
    @State private var scrollOffset: CGFloat = 0
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date? = nil
    @State private var showingError = false
    // 由弹出式编辑改为导航推入新页面

    private var navOpacity: Double {
        let shown = max(0, min(1, Double((-scrollOffset - 10) / 30)))
        return shown
    }
    
    // 从 ViewModel 获取数据的计算属性
    private var monthScores: [Date: DailyScore] {
        viewModel.dailyScores
    }
    
    private var dayRecords: [Date: [MeritRecord]] {
        viewModel.dayRecords
    }

    var body: some View {
        ZStack(alignment: .top) {
            ModernDesignSystem.Colors.paperIvory
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 滚动监听器 - 使用与 HealthAssistantView 相同的实现方式
                    Color.clear
                        .frame(height: 1)
                        .background(
                            GeometryReader { g in
                                let y = g.frame(in: .named("gongguogeScroll")).minY
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: y)
                                    .onChange(of: y) { oldValue, newValue in
                                        // 直接在这里更新状态
                                        DispatchQueue.main.async {
                                            scrollOffset = newValue
                                        }
                                    }
                            }
                        )

                    // 月份头部（切换） - 移除了额外的顶部间距
                    monthHeader
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // 星期标题
                    weekHeader
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    // 月历网格
                    monthGrid
                        .padding(.horizontal, 12)
                        .padding(.top, 2)

                    // 当日记录（空态或列表）
                    dayDetailSection
                        .padding(.horizontal, 16)

                    // 占位，保证可滚动触发顶部栏渐入
                    Color.clear.frame(height: 480)
                }
            }
            .coordinateSpace(name: "gongguogeScroll")
            .onAppear {
                let cal = Calendar.current
                if cal.isDate(Date(), equalTo: currentMonth, toGranularity: .month) {
                    selectedDate = Date()
                } else {
                    selectedDate = startOfMonth(currentMonth)
                }
                
                // 加载当月数据
                Task {
                    await viewModel.loadMonthlyRecords(for: currentMonth)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: ModernDesignSystem.Colors.primaryGreen))
                    }
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "未知错误")
            }
            .onChange(of: viewModel.errorMessage) { oldValue, newValue in
                showingError = newValue != nil
            }

            // 顶部导航栏（默认透明，滚动后出现）
            topNavigationBar(opacity: navOpacity)
        }
        .toolbar(.hidden, for: .navigationBar)
        .asRootView()
        // 移除 sheet 弹出编辑器，改为由 NavigationLink 推入
    }
}

private extension GongGuoGeView {
    // MARK: - 数据模型
    typealias DailyScore = MeritViewModel.DailyScore

    // MARK: - 日期工具
    func startOfMonth(_ date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? date
    }

    func daysInMonth(_ date: Date) -> Int {
        Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    func firstWeekdayOfMonth(_ date: Date) -> Int { // 1=周日 ... 7=周六
        Calendar.current.component(.weekday, from: startOfMonth(date))
    }

    func addMonths(_ date: Date, _ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: date) ?? date
    }

    func monthTitle(_ date: Date) -> String {
        let df = DateFormatter(); df.locale = Locale(identifier: "zh_CN"); df.dateFormat = "yyyy年M月"; return df.string(from: date)
    }

    var isInCurrentMonth: (Date) -> Bool {
        let cal = Calendar.current
        let m = cal.component(.month, from: currentMonth)
        let y = cal.component(.year, from: currentMonth)
        return { d in cal.component(.month, from: d) == m && cal.component(.year, from: d) == y }
    }

    var gridDates: [Date] {
        let cal = Calendar.current
        let first = startOfMonth(currentMonth)
        let days = daysInMonth(currentMonth)
        let firstWeekday = firstWeekdayOfMonth(currentMonth) // 1..7 (周日=1)
        let leading = firstWeekday - 1

        let prev = addMonths(currentMonth, -1)
        let prevDays = daysInMonth(prev)

        var arr: [Date] = []
        if leading > 0 {
            for i in stride(from: leading - 1, through: 0, by: -1) {
                let day = prevDays - i
                if let d = cal.date(bySetting: .day, value: day, of: startOfMonth(prev)) { arr.append(d) }
            }
        }
        for d in 1...days {
            if let dd = cal.date(bySetting: .day, value: d, of: first) { arr.append(dd) }
        }
        let trailing = 42 - arr.count
        if trailing > 0 {
            let next = addMonths(currentMonth, 1)
            for d in 1...trailing {
                if let nd = cal.date(bySetting: .day, value: d, of: startOfMonth(next)) { arr.append(nd) }
            }
        }
        return arr
    }

    // MARK: - 视图片段
    var monthHeader: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentMonth = addMonths(currentMonth, -1)
                    selectedDate = startOfMonth(currentMonth)
                }
                Task {
                    await viewModel.loadMonthlyRecords(for: currentMonth)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.black.opacity(0.06)))
            }

            Spacer()

            Text(monthTitle(currentMonth))
                .font(AppFont.kangxi(size: 22))
                .foregroundColor(.primary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentMonth = addMonths(currentMonth, 1)
                    selectedDate = startOfMonth(currentMonth)
                }
                Task {
                    await viewModel.loadMonthlyRecords(for: currentMonth)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.black.opacity(0.06)))
            }
        }
    }

    var weekHeader: some View {
        let names = ["日","一","二","三","四","五","六"]
        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                Text(names[i])
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
            ForEach(Array(gridCells.enumerated()), id: \.offset) { _, cell in
                if let d = cell {
                    dayCell(date: d)
                } else {
                    placeholderCell
                }
            }
        }
    }

    // 仅保留当月的日期；前导位置用空占位补齐，不再显示下月天数
    var gridCells: [Date?] {
        let first = startOfMonth(currentMonth)
        let days = daysInMonth(currentMonth)
        let leading = firstWeekdayOfMonth(currentMonth) - 1 // 0..6
        var arr: [Date?] = Array(repeating: nil, count: max(0, leading))
        for d in 1...days {
            if let date = Calendar.current.date(bySetting: .day, value: d, of: first) {
                arr.append(date)
            }
        }
        return arr
    }

    func dayCell(date: Date) -> some View {
        let day = Calendar.current.component(.day, from: date)
        let score = monthScores[date]
        let isTodayFlag = isToday(date)
        let isSelected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
        
        // 判断是否有功过记录
        let hasScore = score != nil && (score!.merit > 0 || score!.demerit > 0)

        return VStack(alignment: .center, spacing: 3) {
            // 日期行
            HStack(spacing: 4) {
                Text("\(day)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isTodayFlag ? ModernDesignSystem.Colors.primaryGreen : .primary)

                if isTodayFlag {
                    Circle()
                        .fill(ModernDesignSystem.Colors.primaryGreen)
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.top, 2)

            // 功过标签 - 垂直排列以节省空间
            VStack(spacing: 3) {
                if let s = score, s.merit > 0 {
                    Text("功+\(s.merit)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(ModernDesignSystem.Colors.primaryGreen.opacity(0.15)))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                if let s = score, s.demerit > 0 {
                    Text("过-\(s.demerit)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(ModernDesignSystem.Colors.errorRed)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(ModernDesignSystem.Colors.errorRed.opacity(0.15)))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .frame(height: hasScore ? 72 : 64)  // 有记录时增加高度
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
        )
        .overlay(
            Group {
                if isTodayFlag {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(ModernDesignSystem.Colors.primaryGreen.opacity(0.9), lineWidth: 1.2)
                }
                if isSelected && !isTodayFlag {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(ModernDesignSystem.Colors.accentGold.opacity(0.8), lineWidth: 1.1)
                }
            }
        )
        .contentShape(Rectangle())
        .onTapGesture { selectedDate = date }
    }

    var placeholderCell: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 64)
    }

    // 今日判断
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    // MARK: - 当日记录区域（空态/列表）
    var dayDetailSection: some View {
        let baseDate = selectedDate ?? startOfMonth(currentMonth)
        // 为避免时间成分影响，以起始日统一 key
        let normalized = Calendar.current.startOfDay(for: baseDate)
        let items = viewModel.getRecordsForDate(normalized)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("当日记录")
                    .font(AppFont.kangxi(size: 20))
                    .foregroundColor(.primary)
                Spacer()
                Text(dateString(normalized))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                NavigationLink {
                    GongGuoRecordEditorView(
                        date: normalized,
                        viewModel: viewModel
                    )
                    .asSubView()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                }
            }

            if items.isEmpty {
                // 空状态
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("今日暂无记录")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("将善事与过失记入功过格，日结月汇一目了然")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 0.6)
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(items) { record in
                        recordRow(record)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteRecord(id: record.id)
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }
    
    func recordRow(_ record: MeritRecord) -> some View {
        HStack(spacing: 12) {
            Text(record.type == "merit" ? "功" : "过")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle().fill(record.type == "merit" ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.errorRed)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Text(record.type == "merit" ? "加分" : "减分")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text((record.type == "merit" ? "+" : "-") + "\(record.points)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(record.type == "merit" ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.errorRed)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
        )
    }

    func dateString(_ date: Date) -> String {
        let df = DateFormatter(); df.locale = Locale(identifier: "zh_CN"); df.dateFormat = "yyyy-MM-dd"; return df.string(from: date)
    }

    // 已移除“本月汇总”卡片与通用玻璃卡片，专注日历主体
    var safeTopInset: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.safeAreaInsets.top) ?? 0
    }

    func topNavigationBar(opacity: Double) -> some View {
        VStack(spacing: 0) {
            // 顶部安全区填充（随透明度淡入）
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(opacity)
                .frame(height: safeTopInset)

            ZStack {
                // 居中的标题
                Text("功过格")
                    .font(AppFont.kangxi(size: 20))
                    .foregroundColor(.primary)
                    .opacity(opacity)

                // 右侧统计按钮
                HStack {
                    Spacer()
                    NavigationLink {
                        MeritStatisticsView()
                            .asSubView()
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .opacity(opacity)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial.opacity(opacity))
            .overlay(
                Rectangle()
                    .fill(ModernDesignSystem.Colors.borderLight)
                    .frame(height: 0.5)
                    .opacity(opacity)
                , alignment: .bottom
            )
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    NavigationStack {
        GongGuoGeView()
    }
}
