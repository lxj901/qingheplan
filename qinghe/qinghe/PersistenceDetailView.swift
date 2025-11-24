import SwiftUI

/// 打卡历史页面 - 显示用户的打卡历史记录
struct PersistenceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PersistenceDetailViewModel()
    @State private var selectedDate = Date()
    @State private var showingMonthPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // 主要内容区域
            VStack(spacing: 0) {
                // 自定义导航栏
                customNavigationBar

                // 月份选择器
                monthSelector

                // 主要内容区域
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.checkinRecords.isEmpty {
                    emptyStateView
                } else {
                    // 打卡历史列表
                    checkinHistoryList
                }

                Spacer() // 让内容向上推，底部统计栏向下推
            }
            .background(Color(.systemGroupedBackground))

            // 底部统计栏 - 固定在屏幕最底部
            bottomStatisticsBar
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingMonthPicker) {
            monthPickerSheet
        }
        .asSubView() // 隐藏底部Tab栏
        .onAppear {
            Task {
                await viewModel.loadCheckinHistory(for: selectedDate)
            }
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            // 返回按钮
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
            }

            Spacer()

            // 标题
            Text("打卡历史")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - 月份选择器
    private var monthSelector: some View {
        Button(action: {
            showingMonthPicker = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)

                Text(formatMonthYear(selectedDate))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)

            Text("加载中...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            // 装饰性背景圆圈
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.1),
                                Color.green.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.15),
                                Color.green.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                // 日历图标
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.green)
            }

            VStack(spacing: 12) {
                Text("本月暂无打卡记录")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text("开始您的第一次打卡\n建立良好的习惯")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            // 装饰性按钮（仅展示用）
            Button(action: {
                // 这里可以添加跳转到首页的逻辑
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .medium))

                    Text("去打卡")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(
                    color: Color.green.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 友好提示区域
    private var checkinStatusTip: some View {
        VStack(spacing: 0) {
            if let tipInfo = getCheckinStatusTip() {
                HStack(spacing: 12) {
                    // 提示图标
                    Image(systemName: tipInfo.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(tipInfo.color)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(tipInfo.color.opacity(0.1))
                        )

                    // 提示文本
                    Text(tipInfo.message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tipInfo.color.opacity(0.05))
                        .stroke(tipInfo.color.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - 打卡历史列表
    private var checkinHistoryList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.checkinRecords, id: \.id) { record in
                    checkinRecordRow(record)
                }
            }
            .padding(.horizontal, 8) // 减少外层边距从16到8
        }
    }

    // MARK: - 打卡记录行
    @ViewBuilder
    private func checkinRecordRow(_ record: CheckinHistoryRecord) -> some View {
        VStack(spacing: 0) {
            // 主卡片内容
            HStack(spacing: 16) {
                // 左侧装饰和日期
                VStack(spacing: 8) {
                    // 圆形装饰点 - 根据是否有打卡记录显示不同颜色
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: record.hasCheckin ? [
                                    Color.green,
                                    Color.green.opacity(0.8)
                                ] : [
                                    Color.gray.opacity(0.5),
                                    Color.gray.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 12, height: 12)
                        .shadow(color: record.hasCheckin ? Color.green.opacity(0.3) : Color.gray.opacity(0.2), radius: 2, x: 0, y: 1)

                    // 连接线 - 根据是否有打卡记录显示不同颜色
                    Rectangle()
                        .fill(record.hasCheckin ? Color.green.opacity(0.3) : Color.gray.opacity(0.2))
                        .frame(width: 2, height: 40)
                }

                // 主要内容区域
                VStack(alignment: .leading, spacing: 12) {
                    // 顶部：日期、星期和时间
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatDate(record.date))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)

                            Text(formatWeekday(record.date))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // 时间标签 - 根据是否有打卡记录显示不同内容
                        if record.hasCheckin {
                            Text(formatTime(record.time!))
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.green.opacity(0.08))
                                )
                        } else {
                            Text("未打卡")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                    }

                    // 底部：签到备注和状态
                    VStack(spacing: 8) {
                        // 签到备注区域 - 根据是否有打卡记录显示不同内容
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: record.hasCheckin ? "note.text" : "xmark.circle")
                                .font(.system(size: 14))
                                .foregroundColor(record.hasCheckin ? (record.note?.isEmpty != false ? .gray : .blue) : .red)
                                .padding(.top, 2) // 与文本顶部对齐

                            VStack(alignment: .leading, spacing: 0) {
                                if record.hasCheckin {
                                    Text(record.note?.isEmpty != false ? "暂无备注" : record.note!)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(record.note?.isEmpty != false ? .secondary : .primary)
                                        .lineLimit(nil) // 允许多行显示
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true) // 允许垂直扩展
                                } else {
                                    Text("未打卡")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.red)
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8) // 增加垂直内边距以适应多行文本
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(record.hasCheckin ? Color(.secondarySystemBackground) : Color.red.opacity(0.1))
                        )

                        // 连续打卡标签（如果有）- 移到备注下方
                        HStack {
                            if record.isConsecutive {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.orange)

                                    Text("连续打卡")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.15))
                                )
                            }

                            // 打卡中断标签（如果有）
                            if record.isInterrupted {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.red)

                                    Text("打卡中断")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.red.opacity(0.15))
                                )
                            }

                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
            .padding(.horizontal, 8) // 减少卡片边距从16到8
            .padding(.vertical, 4)
        }
    }

    // MARK: - 底部统计栏
    private var bottomStatisticsBar: some View {
        VStack(spacing: 0) {
            // 顶部装饰线
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.3),
                            Color.green.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)

            // 统计内容
            HStack(spacing: 0) {
                // 本月打卡次数
                statisticItem(
                    value: viewModel.monthlyCheckinCount,
                    title: "本月打卡",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                // 分隔线
                Rectangle()
                    .fill(Color(.separator).opacity(0.5))
                    .frame(width: 1, height: 24)

                // 本月连续
                statisticItem(
                    value: viewModel.consecutiveDays,
                    title: "本月连续",
                    icon: "flame.fill",
                    color: .orange
                )

                // 分隔线
                Rectangle()
                    .fill(Color(.separator).opacity(0.5))
                    .frame(width: 1, height: 24)

                // 历史最长连续天数
                statisticItem(
                    value: viewModel.totalConsecutiveDays,
                    title: "历史最长",
                    icon: "crown.fill",
                    color: .yellow
                )

                // 分隔线
                Rectangle()
                    .fill(Color(.separator).opacity(0.5))
                    .frame(width: 1, height: 24)

                // 心得数量
                statisticItem(
                    value: viewModel.insightCount,
                    title: "心得",
                    icon: "heart.fill",
                    color: .pink
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 10,
                x: 0,
                y: -5
            )

            // 安全区域底部填充
            Rectangle()
                .fill(Color(.systemBackground))
                .frame(height: 0)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - 统计项目组件
    @ViewBuilder
    private func statisticItem(value: Int, title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) { // 进一步减少间距从6到4
            // 图标
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold)) // 减少图标大小从18到16
                .foregroundColor(color)
                .frame(width: 24, height: 24) // 减少图标背景大小从28到24
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )

            // 数值 - 为本月连续和历史最长添加单位
            if title == "本月连续" || title == "历史最长" {
                HStack(spacing: 2) {
                    Text("\(value)")
                        .font(.system(size: 20, weight: .bold)) // 减少数值字体大小从24到20
                        .foregroundColor(.primary)
                    Text("天")
                        .font(.system(size: 12, weight: .medium)) // 减少单位字体大小从14到12
                        .foregroundColor(.secondary)
                        .offset(y: 1) // 稍微下移对齐
                }
            } else {
                Text("\(value)")
                    .font(.system(size: 20, weight: .bold)) // 减少数值字体大小从24到20
                    .foregroundColor(.primary)
            }

            // 标题
            Text(title)
                .font(.system(size: 11, weight: .medium)) // 减少标题字体大小从12到11
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2) // 减少垂直内边距从4到2
    }

    // MARK: - 月份选择器弹窗
    private var monthPickerSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 当前选中月份显示
                Text(formatMonthYear(selectedDate))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.vertical, 20)

                // 月份列表
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(getAvailableMonths(), id: \.self) { date in
                            Button(action: {
                                selectedDate = date
                                showingMonthPicker = false
                                Task {
                                    await viewModel.loadCheckinHistory(for: date)
                                }
                            }) {
                                HStack {
                                    Text(formatMonthYear(date))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Calendar.current.isDate(date, equalTo: selectedDate, toGranularity: .month) ? .green : .primary)

                                    Spacer()

                                    if Calendar.current.isDate(date, equalTo: selectedDate, toGranularity: .month) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(.systemBackground))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("选择月份")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        showingMonthPicker = false
                    }
                }
            }
        }
    }

    // MARK: - 辅助方法

    /// 格式化月份年份
    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }

    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    /// 格式化星期
    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN") // 设置中文本地化
        formatter.dateFormat = "EEEE" // 使用完整星期名称
        let weekdayString = formatter.string(from: date)
        return "周" + weekdayString.replacingOccurrences(of: "星期", with: "")
    }

    /// 格式化时间
    private func formatTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }



    /// 获取可用月份列表
    private func getAvailableMonths() -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        var months: [Date] = []

        // 生成最近6个月的日期
        for i in 0..<6 {
            if let date = calendar.date(byAdding: .month, value: -i, to: now) {
                months.append(date)
            }
        }

        return months
    }

    // MARK: - 获取打卡状态提示
    private func getCheckinStatusTip() -> CheckinStatusTip? {
        let calendar = Calendar.current
        let today = Date()

        guard !viewModel.checkinRecords.isEmpty else { return nil }

        // 按日期排序（最新的在前）
        let sortedRecords = viewModel.checkinRecords.sorted { $0.date > $1.date }
        let latestRecord = sortedRecords.first!

        let daysDifference = calendar.dateComponents([.day], from: latestRecord.date, to: today).day ?? 0

        if daysDifference == 0 {
            // 今天已打卡
            let consecutiveCount = viewModel.consecutiveDays
            if consecutiveCount >= 2 {
                return CheckinStatusTip(
                    icon: "flame.fill",
                    message: "太棒了！您已连续打卡 \(consecutiveCount) 天，继续保持！",
                    color: .orange
                )
            } else {
                return CheckinStatusTip(
                    icon: "checkmark.circle.fill",
                    message: "今日打卡完成！明天继续加油，开启连续打卡之旅！",
                    color: .green
                )
            }
        } else if daysDifference == 1 {
            // 昨天打卡了，今天还没打卡
            return CheckinStatusTip(
                icon: "clock.fill",
                message: "今天还没有打卡哦，快去完成今日打卡吧！",
                color: .blue
            )
        } else {
            // 超过1天没打卡，但不在这里显示中断提示（在列表中显示）
            return CheckinStatusTip(
                icon: "clock.fill",
                message: "今天还没有打卡哦，快去完成今日打卡吧！",
                color: .blue
            )
        }
    }
}

// MARK: - 打卡历史记录UI模型
struct CheckinHistoryRecord: Identifiable {
    let id = UUID()
    let checkinId: Int? // 真正的打卡记录ID，用于API调用
    let date: Date
    let time: Date? // 修改为可选，支持没有打卡的日期
    let mood: String?
    let note: String?
    let isConsecutive: Bool
    let isInterrupted: Bool // 新增：是否中断了连续打卡

    // 是否有打卡记录
    var hasCheckin: Bool {
        return time != nil
    }
}

// MARK: - 打卡状态提示模型
struct CheckinStatusTip {
    let icon: String
    let message: String
    let color: Color
}

// MARK: - 预览
struct PersistenceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PersistenceDetailView()
    }
}