import Foundation

// MARK: - 打卡服务
class CheckinService: ObservableObject {
    static let shared = CheckinService()
    
    private let baseURL = APIConfig.baseURL
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - 获取当前连续打卡天数
    func getCurrentStreakDays() async -> Int {
        // 模拟网络请求
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 返回模拟数据
        return Int.random(in: 0...30) // 随机返回0-30天的连续打卡
    }
    
    // MARK: - 获取打卡统计数据
    func getCheckinStats() async throws -> CheckinStatistics {
        // 模拟网络请求
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
        
        // 返回模拟数据
        return CheckinStatistics(
            totalDays: 45,
            consecutiveDays: 7,
            currentStreak: 7,
            longestStreak: 15,
            thisMonthDays: 12,
            lastCheckinDate: "2024-01-20",
            timeAnalysis: TimeAnalysis(
                morningCount: 15,
                afternoonCount: 20,
                eveningCount: 8,
                nightCount: 2,
                riskLevel: "low",
                suggestions: ["建议保持规律的运动时间", "早晨运动有助于提高一天的精神状态"]
            )
        )
    }
    
    // MARK: - 执行打卡
    func performCheckin(note: String? = nil, location: String? = nil, latitude: Double? = nil, longitude: Double? = nil) async throws -> CheckinAPIRecord {
        // 模拟网络请求
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒

        // 模拟打卡成功
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: now)
        
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: now)
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestampString = formatter.string(from: now)
        
        return CheckinAPIRecord(
            id: Int.random(in: 1000...9999),
            userId: 1,
            date: dateString,
            time: timeString,
            deviceInfo: "iPhone",
            ipAddress: "192.168.1.1",
            locationLatitude: latitude,
            locationLongitude: longitude,
            locationAddress: location,
            note: note,
            mood: "happy",
            challenges: nil,
            createdAt: timestampString,
            updatedAt: timestampString
        )
    }
    
    // MARK: - 获取打卡历史
    func getCheckinHistory(page: Int = 1, limit: Int = 20) async throws -> [CheckinAPIRecord] {
        // 模拟网络请求
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 生成模拟历史数据
        var history: [CheckinAPIRecord] = []
        let calendar = Calendar.current
        
        for i in 0..<limit {
            let dayOffset = (page - 1) * limit + i
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: date)
            
            // 随机生成打卡时间
            let hour = Int.random(in: 7...10)
            let minute = Int.random(in: 0...59)
            let timeString = String(format: "%02d:%02d:00", hour, minute)
            
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestampString = formatter.string(from: date)
            
            let record = CheckinAPIRecord(
                id: 1000 + dayOffset,
                userId: 1,
                date: dateString,
                time: timeString,
                deviceInfo: "iPhone",
                ipAddress: "192.168.1.1",
                locationLatitude: nil,
                locationLongitude: nil,
                locationAddress: nil,
                note: i % 3 == 0 ? "今天心情不错！" : nil,
                mood: ["happy", "normal", "excited"].randomElement(),
                challenges: nil,
                createdAt: timestampString,
                updatedAt: timestampString
            )
            
            history.append(record)
        }
        
        return history
    }
    
    // MARK: - 检查今日是否已打卡
    func checkTodayCheckin() async throws -> CheckinAPIRecord? {
        // 模拟网络请求
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        // 随机决定是否已打卡
        let hasCheckedIn = Bool.random()
        
        if hasCheckedIn {
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: now)
            
            let hour = Int.random(in: 7...10)
            let minute = Int.random(in: 0...59)
            let timeString = String(format: "%02d:%02d:00", hour, minute)
            
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestampString = formatter.string(from: now)
            
            return CheckinAPIRecord(
                id: 9999,
                userId: 1,
                date: dateString,
                time: timeString,
                deviceInfo: "iPhone",
                ipAddress: "192.168.1.1",
                locationLatitude: nil,
                locationLongitude: nil,
                locationAddress: nil,
                note: "今天的打卡",
                mood: "happy",
                challenges: nil,
                createdAt: timestampString,
                updatedAt: timestampString
            )
        }
        
        return nil
    }

    // MARK: - 执行打卡（RecordCenterViewModel 需要的方法）
    func checkin(
        note: String? = nil,
        location: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        mood: String? = nil,
        challenges: [String]? = nil
    ) async throws -> ServerAPIResponse<CheckinAPIRecord> {
        let record = try await performCheckin(
            note: note,
            location: location,
            latitude: latitude,
            longitude: longitude
        )

        return ServerAPIResponse(
            success: true,
            message: "打卡成功",
            data: record,
            error: nil
        )
    }

    // MARK: - 获取统计数据
    func getStatistics() async throws -> ServerAPIResponse<CheckinStatistics> {
        let stats = try await getCheckinStats()

        return ServerAPIResponse(
            success: true,
            message: "获取统计数据成功",
            data: stats,
            error: nil
        )
    }

    // MARK: - 获取今日状态
    func getTodayStatus() async throws -> ServerAPIResponse<CheckinAPIRecord?> {
        let todayRecord = try await checkTodayCheckin()

        return ServerAPIResponse(
            success: true,
            message: "获取今日状态成功",
            data: todayRecord,
            error: nil
        )
    }
}

// MARK: - 打卡统计数据模型
struct CheckinStatistics: Codable {
    let totalDays: Int
    let consecutiveDays: Int
    let currentStreak: Int
    let longestStreak: Int
    let thisMonthDays: Int
    let lastCheckinDate: String?
    let timeAnalysis: TimeAnalysis
    let heatmapData: [HeatmapData]?

    // 普通初始化器
    init(totalDays: Int, consecutiveDays: Int, currentStreak: Int, longestStreak: Int, thisMonthDays: Int, lastCheckinDate: String?, timeAnalysis: TimeAnalysis, heatmapData: [HeatmapData]? = nil) {
        self.totalDays = totalDays
        self.consecutiveDays = consecutiveDays
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.thisMonthDays = thisMonthDays
        self.lastCheckinDate = lastCheckinDate
        self.timeAnalysis = timeAnalysis
        self.heatmapData = heatmapData
    }

    // 自定义解码器来处理服务器返回的不同字段名
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        totalDays = try container.decode(Int.self, forKey: .totalDays)
        thisMonthDays = try container.decode(Int.self, forKey: .thisMonthDays)
        timeAnalysis = try container.decode(TimeAnalysis.self, forKey: .timeAnalysis)
        lastCheckinDate = try container.decodeIfPresent(String.self, forKey: .lastCheckinDate)
        heatmapData = try container.decodeIfPresent([HeatmapData].self, forKey: .heatmapData)

        // 处理 consecutiveDays 和 currentStreak 字段：服务器返回 consecutiveDays，客户端期望 currentStreak
        if let consecutive = try? container.decodeIfPresent(Int.self, forKey: .consecutiveDays) {
            consecutiveDays = consecutive
            currentStreak = consecutive  // 两个字段保持一致
        } else if let current = try? container.decodeIfPresent(Int.self, forKey: .currentStreak) {
            currentStreak = current
            consecutiveDays = current  // 两个字段保持一致
        } else {
            consecutiveDays = 0
            currentStreak = 0
        }

        // longestStreak 字段处理
        longestStreak = try container.decodeIfPresent(Int.self, forKey: .longestStreak) ?? consecutiveDays
    }

    enum CodingKeys: String, CodingKey {
        case totalDays = "totalDays"
        case consecutiveDays = "consecutiveDays"
        case currentStreak = "currentStreak"
        case longestStreak = "longestStreak"
        case thisMonthDays = "thisMonthDays"
        case lastCheckinDate = "lastCheckinDate"
        case timeAnalysis = "timeAnalysis"
        case heatmapData = "heatmapData"
    }
}


