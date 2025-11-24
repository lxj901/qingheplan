import SwiftUI
import Foundation

// MARK: - 日历日期数据模型
struct CalendarDayData: Identifiable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let hasCheckin: Bool
    let checkinRecord: CheckinRecord?

    var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
}

// MARK: - 日历打卡记录模型
struct CalendarCheckinRecord: Identifiable {
    let id = UUID()
    let date: Date
    let mood: CheckinMood
    let note: String?
    let time: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - 打卡记录模型
struct CheckinRecord: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let timestamp: Date
    let mood: CheckinMood
    let note: String?
    let location: String?
    let weather: String?

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - API 响应模型

/// 打卡API响应基础结构
struct CheckinAPIResponse<T: Codable>: Codable {
    let status: String
    let message: String?
    let data: T?
}

/// 打卡记录API模型
struct CheckinAPIRecord: Codable {
    let id: Int
    let userId: Int
    let date: String
    let time: String
    let deviceInfo: String?
    let ipAddress: String?
    let locationLatitude: Double?
    let locationLongitude: Double?
    let locationAddress: String?
    let note: String?
    let mood: String?
    let challenges: String?
    let createdAt: String
    let updatedAt: String

    // 普通初始化器
    init(id: Int, userId: Int, date: String, time: String, deviceInfo: String?, ipAddress: String?, locationLatitude: Double?, locationLongitude: Double?, locationAddress: String?, note: String?, mood: String?, challenges: String?, createdAt: String, updatedAt: String) {
        self.id = id
        self.userId = userId
        self.date = date
        self.time = time
        self.deviceInfo = deviceInfo
        self.ipAddress = ipAddress
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.locationAddress = locationAddress
        self.note = note
        self.mood = mood
        self.challenges = challenges
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // 自定义解码逻辑处理坐标字段
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        date = try container.decode(String.self, forKey: .date)
        time = try container.decode(String.self, forKey: .time)
        deviceInfo = try container.decodeIfPresent(String.self, forKey: .deviceInfo)
        ipAddress = try container.decodeIfPresent(String.self, forKey: .ipAddress)
        locationAddress = try container.decodeIfPresent(String.self, forKey: .locationAddress)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        mood = try container.decodeIfPresent(String.self, forKey: .mood)
        challenges = try container.decodeIfPresent(String.self, forKey: .challenges)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // 处理locationLatitude：可能是字符串、数字或null
        if let latString = try? container.decodeIfPresent(String.self, forKey: .locationLatitude) {
            locationLatitude = Double(latString)
        } else {
            locationLatitude = try container.decodeIfPresent(Double.self, forKey: .locationLatitude)
        }
        
        // 处理locationLongitude：可能是字符串、数字或null
        if let lngString = try? container.decodeIfPresent(String.self, forKey: .locationLongitude) {
            locationLongitude = Double(lngString)
        } else {
            locationLongitude = try container.decodeIfPresent(Double.self, forKey: .locationLongitude)
        }
    }
    
    // CodingKeys枚举
    private enum CodingKeys: String, CodingKey {
        case id, userId, date, time, deviceInfo, ipAddress
        case locationLatitude, locationLongitude, locationAddress
        case note, mood, challenges, createdAt, updatedAt
    }
}

/// 打卡请求参数
struct CheckinRequest: Codable {
    let deviceInfo: String?
    let location: CheckinLocation?
    let note: String?
    let mood: String?
    let challenges: String?
}

/// 位置信息
struct CheckinLocation: Codable {
    let latitude: Double
    let longitude: Double
    let address: String
}

/// 打卡响应数据
struct CheckinResponseData: Codable {
    let checkin: CheckinAPIRecord
}

/// 今日签到状态响应
struct TodayCheckinResponse: Codable {
    let hasCheckedIn: Bool
    let checkin: CheckinAPIRecord?
}



/// 热力图数据
struct HeatmapData: Codable {
    let date: String
    let time: String
    let value: Int?
}

/// 时间分析数据
struct TimeAnalysis: Codable {
    let morningCount: Int
    let afternoonCount: Int
    let eveningCount: Int
    let nightCount: Int
    let riskLevel: String
    let suggestions: [String]?  // 设为可选，因为服务器可能不返回此字段

    // 提供默认的 suggestions 值
    var safeSuggestions: [String] {
        return suggestions ?? []
    }
}

/// 签到记录列表响应
struct CheckinListResponse: Codable {
    let checkins: [CheckinAPIRecord]
    let pagination: PaginationInfo
}

// PaginationInfo 已移动到 CommunityModels.swift 中以避免重复定义

// MARK: - 打卡心情枚举
enum CheckinMood: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case normal = "normal"
    case bad = "bad"
    case terrible = "terrible"
    
    var emoji: String {
        switch self {
        case .excellent: return "😄"
        case .good: return "😊"
        case .normal: return "😐"
        case .bad: return "😔"
        case .terrible: return "😢"
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "非常棒"
        case .good: return "很好"
        case .normal: return "一般"
        case .bad: return "不好"
        case .terrible: return "很糟"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return ModernDesignSystem.Colors.successGreen
        case .good: return ModernDesignSystem.Colors.primaryGreenLight
        case .normal: return ModernDesignSystem.Colors.accentBlue
        case .bad: return ModernDesignSystem.Colors.warningOrange
        case .terrible: return ModernDesignSystem.Colors.errorRed
        }
    }

    var score: Double {
        switch self {
        case .excellent: return 5.0
        case .good: return 4.0
        case .normal: return 3.0
        case .bad: return 2.0
        case .terrible: return 1.0
        }
    }
}

// MARK: - 月度统计数据
struct MonthlyStats: Codable {
    let month: Date
    let totalDays: Int
    let checkedInDays: Int
    let currentStreak: Int
    let longestStreak: Int
    let averageMood: Double
    let checkinRecords: [CheckinRecord]
    
    var checkinRate: Double {
        guard totalDays > 0 else { return 0 }
        return Double(checkedInDays) / Double(totalDays)
    }
    
    var checkinRatePercentage: String {
        return String(format: "%.0f%%", checkinRate * 100)
    }
}

// MARK: - 数据洞察
struct CheckinInsight {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let value: String
    let trend: InsightTrend
}

enum InsightTrend {
    case up, down, stable
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return ModernDesignSystem.Colors.successGreen
        case .down: return ModernDesignSystem.Colors.errorRed
        case .stable: return ModernDesignSystem.Colors.textSecondary
        }
    }
}

// MARK: - 打卡日历视图模型
@MainActor
class CheckinCalendarViewModel: ObservableObject {
    @Published var monthlyStats: MonthlyStats?
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var hasTodayCheckedIn: Bool = false
    @Published var checkinRecords: [CheckinRecord] = []
    @Published var insights: [CheckinInsight] = []
    @Published var isLoading: Bool = false

    // 完整版需要的新属性
    @Published var monthlyCompletionRate: Double = 0.0
    @Published var monthlyCheckinCount: Int = 0
    @Published var calendarDays: [CalendarDayData] = []

    private let calendar = Calendar.current
    
    init() {
        // 初始化一些模拟数据
        generateMockData()
    }
    
    // MARK: - 加载月度数据
    func loadMonthData(for date: Date) async {
        isLoading = true
        
        // 模拟网络请求延迟
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // 生成模拟数据
        generateMockData(for: date)
        
        isLoading = false
    }
    
    // MARK: - 检查今日是否已打卡
    func checkTodayCheckin() {
        let today = Date()
        hasTodayCheckedIn = checkinRecords.contains { record in
            calendar.isDate(record.date, inSameDayAs: today)
        }
    }
    
    // MARK: - 获取指定日期的打卡记录
    func getCheckinRecord(for date: Date) -> CheckinRecord? {
        return checkinRecords.first { record in
            calendar.isDate(record.date, inSameDayAs: date)
        }
    }

    // MARK: - 检查指定日期是否有打卡记录
    func hasCheckinForDate(_ date: Date) -> Bool {
        return getCheckinRecord(for: date) != nil
    }
    
    // MARK: - 生成数据洞察
    private func generateInsights() {
        insights = [
            CheckinInsight(
                title: "打卡趋势",
                description: "本月打卡率较上月提升了15%",
                icon: "chart.line.uptrend.xyaxis",
                color: ModernDesignSystem.Colors.successGreen,
                value: "+15%",
                trend: .up
            ),
            CheckinInsight(
                title: "最佳时段",
                description: "你通常在早上8-9点打卡效果最好",
                icon: "clock.fill",
                color: ModernDesignSystem.Colors.accentBlue,
                value: "8-9点",
                trend: .stable
            ),
            CheckinInsight(
                title: "心情指数",
                description: "本周平均心情指数为4.2分",
                icon: "heart.fill",
                color: ModernDesignSystem.Colors.accentOrange,
                value: "4.2分",
                trend: .up
            )
        ]
    }
    
    // MARK: - 生成模拟数据
    private func generateMockData(for date: Date = Date()) {
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date
        
        var records: [CheckinRecord] = []
        var currentDate = startOfMonth
        var streak = 0
        var maxStreak = 0
        var tempStreak = 0
        
        while currentDate <= endOfMonth {
            // 80% 概率有打卡记录
            if Double.random(in: 0...1) < 0.8 {
                let record = CheckinRecord(
                    date: currentDate,
                    timestamp: currentDate.addingTimeInterval(Double.random(in: 28800...32400)), // 8-9点
                    mood: CheckinMood.allCases.randomElement() ?? .good,
                    note: ["今天状态不错", "继续加油", "感觉很棒", nil].randomElement() ?? nil,
                    location: "家",
                    weather: "晴"
                )
                records.append(record)
                tempStreak += 1
                maxStreak = max(maxStreak, tempStreak)
            } else {
                tempStreak = 0
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // 计算当前连续天数
        let today = Date()
        var checkDate = today
        while records.first(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }) != nil {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        self.checkinRecords = records.sorted { $0.date > $1.date }
        self.currentStreak = streak
        self.longestStreak = maxStreak

        // 更新新属性
        let totalDays = calendar.dateComponents([.day], from: startOfMonth, to: endOfMonth).day ?? 0
        self.monthlyCheckinCount = records.count
        self.monthlyCompletionRate = totalDays > 0 ? Double(records.count) / Double(totalDays) * 100.0 : 0.0

        // 生成日历数据
        generateCalendarDays(for: date, records: records)

        checkTodayCheckin()
        generateInsights()

        // 生成月度统计
        self.monthlyStats = MonthlyStats(
            month: date,
            totalDays: totalDays,
            checkedInDays: records.count,
            currentStreak: streak,
            longestStreak: maxStreak,
            averageMood: 4.2,
            checkinRecords: records
        )
    }

    // MARK: - 生成日历数据
    private func generateCalendarDays(for date: Date, records: [CheckinRecord]) {
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let _ = calendar.dateInterval(of: .month, for: date)?.end ?? date
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth

        var days: [CalendarDayData] = []
        var currentDate = startOfWeek
        let today = Date()

        // 生成6周的日期数据
        for _ in 0..<42 {
            let isCurrentMonth = calendar.isDate(currentDate, equalTo: date, toGranularity: .month)
            let isToday = calendar.isDate(currentDate, inSameDayAs: today)
            let checkinRecord = records.first { calendar.isDate($0.date, inSameDayAs: currentDate) }
            let hasCheckin = checkinRecord != nil

            let dayData = CalendarDayData(
                date: currentDate,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                hasCheckin: hasCheckin,
                checkinRecord: checkinRecord
            )

            days.append(dayData)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        self.calendarDays = days
    }
}
