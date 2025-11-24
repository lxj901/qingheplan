import SwiftUI
import Foundation

/// 首页视图模型
class HomeViewModel: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var dailyMinutes: Int = 150
    @Published var completionRate: Double = 0.0
    @Published var selectedTab: ProgressTab = .persistence
    @Published var calendarDays: [CalendarDayData] = []
    @Published var currentMotivation: String = ""
    @Published var hasTodayCheckedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var todayCheckinRecord: CheckinAPIRecord?

    private let calendar = Calendar.current
    private let checkinService = CheckinAPIService.shared

    // 每日激励语句数组
    private let motivationQuotes = [
        "每一天的坚持都是迈向更好自己的一步",
        "自律是通往自由的唯一道路",
        "今天的努力是明天成功的基石",
        "坚持不懈，直到成功成为习惯",
        "每个优秀的人都有一段沉默的时光",
        "自律给我自由，坚持成就梦想"
    ]
    
    init() {
        refreshMotivation()
        Task {
            await loadUserData()
        }
    }

    // MARK: - 数据加载
    @MainActor
    private func loadUserData() async {
        isLoading = true

        do {
            // 加载今日签到状态
            await loadTodayCheckinStatus()

            // 加载签到统计
            await loadCheckinStatistics()

            // 生成日历数据
            await generateCalendarData()

        } catch {
            print("❌ 加载用户数据失败: \(error)")
            // 使用默认数据
            currentStreak = 0
            dailyMinutes = 150
            completionRate = 0.0
        }

        isLoading = false
    }

    // MARK: - 加载今日签到状态
    @MainActor
    private func loadTodayCheckinStatus() async {
        do {
            let todayStatus = try await checkinService.getTodayCheckinStatus()
            hasTodayCheckedIn = todayStatus.hasCheckedIn
            todayCheckinRecord = todayStatus.checkin
            print("✅ 今日签到状态: \(hasTodayCheckedIn)")
        } catch {
            print("❌ 获取今日签到状态失败: \(error)")
            hasTodayCheckedIn = false
            todayCheckinRecord = nil
        }
    }

    // MARK: - 加载签到统计
    @MainActor
    private func loadCheckinStatistics() async {
        do {
            let statistics = try await checkinService.getCheckinStatistics()
            currentStreak = statistics.consecutiveDays
            // 可以根据需要更新其他统计数据
            print("✅ 签到统计加载成功: 连续\(currentStreak)天")
        } catch {
            print("❌ 获取签到统计失败: \(error)")
            currentStreak = 0
        }
    }
    
    // MARK: - 生成日历数据
    @MainActor
    private func generateCalendarData() async {
        let today = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
        let endOfMonth = calendar.dateInterval(of: .month, for: today)?.end ?? today

        var days: [CalendarDayData] = []
        var currentDate = startOfMonth

        // 获取本月的签到记录
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startDateString = dateFormatter.string(from: startOfMonth)
        let endDateString = dateFormatter.string(from: endOfMonth)

        var checkinRecords: [CheckinAPIRecord] = []

        do {
            let response = try await checkinService.getCheckinRecords(
                page: 1,
                limit: 50,
                startDate: startDateString,
                endDate: endDateString
            )
            checkinRecords = response.checkins
        } catch {
            print("❌ 获取签到记录失败: \(error)")
        }

        // 只生成本月的天数
        while currentDate < endOfMonth {
            let isToday = calendar.isDate(currentDate, inSameDayAs: today)
            let currentDateString = dateFormatter.string(from: currentDate)

            // 检查当前日期是否有签到记录
            let hasCheckin = checkinRecords.contains { record in
                record.date == currentDateString
            }

            let checkinRecord = checkinRecords.first { record in
                record.date == currentDateString
            }

            days.append(CalendarDayData(
                date: currentDate,
                isCurrentMonth: true, // 只显示当月，所以都是true
                isToday: isToday,
                hasCheckin: hasCheckin,
                checkinRecord: convertAPIRecordToCheckinRecord(checkinRecord)
            ))

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        self.calendarDays = days
    }

    // MARK: - 转换API记录为本地记录
    private func convertAPIRecordToCheckinRecord(_ apiRecord: CheckinAPIRecord?) -> CheckinRecord? {
        guard let apiRecord = apiRecord else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: apiRecord.date) ?? Date()

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let time = timeFormatter.date(from: apiRecord.time) ?? Date()

        // 合并日期和时间
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second

        let timestamp = calendar.date(from: combinedComponents) ?? Date()

        return CheckinRecord(
            date: date,
            timestamp: timestamp,
            mood: CheckinMood(rawValue: apiRecord.mood ?? "good") ?? .good,
            note: apiRecord.note,
            location: apiRecord.locationAddress,
            weather: nil
        )
    }
    
    // MARK: - 生成模拟打卡数据
    private func generateMockCheckinData(for date: Date) -> Bool {
        let today = Date()
        let daysDifference = calendar.dateComponents([.day], from: date, to: today).day ?? 0

        // 今天之后的日期不显示打卡
        if daysDifference < 0 {
            return false
        }

        // 模拟打卡数据：根据设计图，1-12号已打卡，13号之后未打卡
        let dayOfMonth = calendar.component(.day, from: date)
        let currentDay = calendar.component(.day, from: today)

        // 如果是当前日期之前且是本月前12天，显示已打卡
        if dayOfMonth <= 12 && dayOfMonth < currentDay {
            return true
        }

        return false
    }
    
    // MARK: - 更新选中的标签
    func updateSelectedTab(_ tab: ProgressTab) {
        selectedTab = tab
        // 这里可以根据不同的标签加载不同的数据
    }
    
    // MARK: - 刷新激励语
    func refreshMotivation() {
        currentMotivation = motivationQuotes.randomElement() ?? motivationQuotes[0]
    }

    // MARK: - 执行签到
    @MainActor
    func performCheckin(note: String? = nil, mood: String? = nil) async -> Bool {
        guard !hasTodayCheckedIn else {
            print("⚠️ 今天已经签到过了")
            return false
        }

        isLoading = true

        do {
            let checkinRecord = try await checkinService.checkin(
                note: note,
                mood: mood,
                challenges: nil,
                location: nil
            )

            // 更新本地状态
            hasTodayCheckedIn = true
            todayCheckinRecord = checkinRecord

            // 重新加载数据
            await loadCheckinStatistics()
            await generateCalendarData()

            print("✅ 签到成功")
            isLoading = false
            return true

        } catch {
            print("❌ 签到失败: \(error)")
            isLoading = false
            return false
        }
    }

    // MARK: - 刷新数据
    @MainActor
    func refreshData() async {
        await loadUserData()
        refreshMotivation()
    }

    // MARK: - 同步刷新数据（用于兼容现有代码）
    func refreshDataSync() {
        Task {
            await refreshData()
        }
    }
}

// MARK: - 进度标签枚举
enum ProgressTab: CaseIterable {
    case persistence
    case exercise
    case sleep

    var title: String {
        switch self {
        case .persistence:
            return "坚持"
        case .exercise:
            return "运动"
        case .sleep:
            return "睡眠"
        }
    }
}
