import SwiftUI
import UIKit

/// 了凡四训功过格 - 初始页面（米色背景 + 滚动后显示导航栏）
struct GongGuoGeView: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var currentMonth: Date = Date()
    @State private var monthScores: [Date: DailyScore] = [:]
    @State private var dayRecords: [Date: [RecordItem]] = [:]
    @State private var selectedDate: Date? = nil
    @State private var showingEditor: Bool = false

    private var navOpacity: Double {
        let shown = max(0, min(1, Double((-scrollOffset - 10) / 30)))
        return shown
    }

    var body: some View {
        ZStack(alignment: .top) {
            ModernDesignSystem.Colors.paperIvory
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 监听滚动偏移（自定义坐标空间）
                    ScrollOffsetReader(coordinateSpace: "gongguogeScroll")

                    // 将日历整体下移一些
                    Color.clear.frame(height: 16)

                    // 月份头部（切换）
                    monthHeader
                        .padding(.horizontal, 16)

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
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .onAppear {
                buildSampleScores(for: currentMonth)
                let cal = Calendar.current
                if cal.isDate(Date(), equalTo: currentMonth, toGranularity: .month) {
                    selectedDate = Date()
                } else {
                    selectedDate = startOfMonth(currentMonth)
                }
            }

            // 顶部导航栏（默认透明，滚动后出现）
            topNavigationBar(opacity: navOpacity)
        }
        .toolbar(.hidden, for: .navigationBar)
        .asRootView()
        .sheet(isPresented: $showingEditor) {
            let date = Calendar.current.startOfDay(for: selectedDate ?? startOfMonth(currentMonth))
            GongGuoRecordEditorView(date: date) { kind, title, points in
                let dayKey = Calendar.current.startOfDay(for: date)
                // 更新明细
                var items = dayRecords[dayKey] ?? []
                let newItem = RecordItem(kind: (kind == .merit ? .merit : .demerit), title: title, points: points)
                items.append(newItem)
                dayRecords[dayKey] = items

                // 更新当日汇总分
                var s = monthScores[dayKey] ?? DailyScore(merit: 0, demerit: 0)
                if kind == .merit { s.merit += points } else { s.demerit += points }
                monthScores[dayKey] = s
            }
        }
    }
}

private extension GongGuoGeView {
    // MARK: - 数据模型
    struct DailyScore { var merit: Int; var demerit: Int }
    struct RecordItem: Identifiable, Hashable {
        enum Kind { case merit, demerit }
        let id = UUID()
        let kind: Kind
        let title: String
        let points: Int
    }

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

    func buildSampleScores(for month: Date) {
        monthScores.removeAll()
        dayRecords.removeAll()
        let cal = Calendar.current
        let days = daysInMonth(month)
        for d in 1...days {
            if let date = cal.date(bySetting: .day, value: d, of: startOfMonth(month)) {
                var m = 0, g = 0
                if d % 7 == 0 { m = 1 }
                if d % 10 == 0 { g = 1 }
                if m > 0 || g > 0 { monthScores[date] = DailyScore(merit: m, demerit: g) }
                var items: [RecordItem] = []
                if m > 0 { items.append(RecordItem(kind: .merit, title: "随手帮人", points: m)) }
                if g > 0 { items.append(RecordItem(kind: .demerit, title: "言辞不敬", points: g)) }
                if !items.isEmpty { dayRecords[date] = items }
            }
        }
    }

    // MARK: - 视图片段
    var monthHeader: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentMonth = addMonths(currentMonth, -1)
                    buildSampleScores(for: currentMonth)
                    selectedDate = startOfMonth(currentMonth)
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
                    buildSampleScores(for: currentMonth)
                    selectedDate = startOfMonth(currentMonth)
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

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("\(day)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isTodayFlag ? ModernDesignSystem.Colors.primaryGreen : .primary)

                if isTodayFlag {
                    Circle()
                        .fill(ModernDesignSystem.Colors.primaryGreen)
                        .frame(width: 6, height: 6)
                }
            }

            HStack(spacing: 4) {
                if let s = score, s.merit > 0 {
                    Text("功 +\(s.merit)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(ModernDesignSystem.Colors.primaryGreen.opacity(0.12)))
                }
                if let s = score, s.demerit > 0 {
                    Text("过 -\(s.demerit)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(ModernDesignSystem.Colors.errorRed)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(ModernDesignSystem.Colors.errorRed.opacity(0.12)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(height: 64)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        let items = dayRecords[normalized] ?? dayRecords[baseDate] ?? []

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("当日记录")
                    .font(AppFont.kangxi(size: 20))
                    .foregroundColor(.primary)
                Spacer()
                Text(dateString(normalized))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Button(action: { showingEditor = true }) {
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
                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            Text(item.kind == .merit ? "功" : "过")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle().fill(item.kind == .merit ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.errorRed)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(item.kind == .merit ? "加分" : "减分")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text((item.kind == .merit ? "+" : "-") + "\(item.points)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(item.kind == .merit ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.errorRed)
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
                }
            }
        }
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

            HStack(spacing: 12) {
                Text("功过格")
                    .font(AppFont.kangxi(size: 20))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 12)
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
