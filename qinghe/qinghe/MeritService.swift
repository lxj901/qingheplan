//
//  MeritService.swift
//  qinghe
//
//  Created by AI Assistant on 2025-01-15.
//  功过格服务层 - 基于《了凡四训》功过格系统
//

import Foundation

// MARK: - 功过记录服务
class MeritService {
    static let shared = MeritService()
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    // MARK: - 功过记录管理
    
    /// 创建功过记录
    /// - Parameter request: 创建请求
    /// - Returns: 创建的记录
    func createRecord(_ request: CreateMeritRequest) async throws -> MeritRecord {
        print("🌐 创建功过记录请求: \(request.type) - \(request.title)")
        
        let requestBody: [String: Any] = [
            "type": request.type,
            "title": request.title,
            "points": request.points,
            "category": request.category ?? "",
            "note": request.note ?? "",
            "recordedAt": request.recordedAt ?? ISO8601DateFormatter().string(from: Date())
        ]
        
        let response = try await networkManager.post(
            endpoint: APIEndpoints.merits,
            parameters: requestBody,
            responseType: MeritResponse.self
        )
        
        if response.success, let data = response.data {
            print("✅ 创建功过记录成功: ID=\(data.record.id)")
            return data.record
        } else {
            let errorMessage = response.message ?? "创建功过记录失败"
            print("❌ 创建功过记录失败: \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
    }
    
    /// 获取功过记录列表
    /// - Parameters:
    ///   - page: 页码
    ///   - limit: 每页数量
    ///   - type: 类型筛选（可选）
    ///   - category: 分类筛选（可选）
    ///   - startDate: 开始日期（可选）
    ///   - endDate: 结束日期（可选）
    /// - Returns: 记录列表响应
    func getRecords(
        page: Int = 1,
        limit: Int = 20,
        type: String? = nil,
        category: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil
    ) async throws -> MeritListResponse {
        print("🌐 获取功过记录列表请求: page=\(page), limit=\(limit)")
        
        var parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        
        if let type = type {
            parameters["type"] = type
        }
        if let category = category {
            parameters["category"] = category
        }
        if let startDate = startDate {
            parameters["startDate"] = startDate
        }
        if let endDate = endDate {
            parameters["endDate"] = endDate
        }
        
        let response = try await networkManager.get(
            endpoint: APIEndpoints.merits,
            parameters: parameters,
            responseType: MeritListResponse.self
        )
        
        if response.success, let data = response.data {
            print("✅ 获取功过记录列表成功: 共\(data.records.count)条记录")
            return response
        } else {
            let errorMessage = response.message ?? "获取功过记录列表失败"
            print("❌ 获取功过记录列表失败: \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
    }
    
    /// 获取某日的功过记录
    /// - Parameter date: 日期（YYYY-MM-DD）
    /// - Returns: 每日记录响应
    func getDailyRecords(date: String) async throws -> DailyRecordsResponse {
        print("🌐 获取每日功过记录请求: date=\(date)")
        
        let parameters: [String: Any] = ["date": date]
        
        let response = try await networkManager.get(
            endpoint: APIEndpoints.meritsDaily,
            parameters: parameters,
            responseType: DailyRecordsResponse.self
        )
        
        if response.success, let data = response.data {
            print("✅ 获取每日记录成功: 功\(data.summary.meritCount)条, 过\(data.summary.demeritCount)条")
            return response
        } else {
            let errorMessage = response.message ?? "获取每日记录失败"
            print("❌ 获取每日记录失败: \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
    }
    
    /// 获取月度汇总
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份
    /// - Returns: 月度汇总响应
    func getMonthlyRecords(year: Int, month: Int) async throws -> MonthlyRecordsResponse {
        print("🌐 获取月度功过汇总请求: \(year)-\(month)")
        
        let parameters: [String: Any] = [
            "year": year,
            "month": month
        ]
        
        let response = try await networkManager.get(
            endpoint: APIEndpoints.meritsMonthly,
            parameters: parameters,
            responseType: MonthlyRecordsResponse.self
        )
        
        if response.success, let data = response.data {
            print("✅ 获取月度汇总成功: 净得分=\(data.summary.netScore)")
            return response
        } else {
            let errorMessage = response.message ?? "获取月度汇总失败"
            print("❌ 获取月度汇总失败: \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
    }
    
    /// 获取功过统计
    /// - Parameters:
    ///   - period: 统计天数
    ///   - startDate: 开始日期（可选）
    ///   - endDate: 结束日期（可选）
    /// - Returns: 统计响应
    func getStatistics(
        period: Int = 30,
        startDate: String? = nil,
        endDate: String? = nil
    ) async throws -> MeritStatisticsResponse {
        print("🌐 获取功过统计请求: period=\(period)")
        
        var parameters: [String: Any] = ["period": period]
        
        if let startDate = startDate {
            parameters["startDate"] = startDate
        }
        if let endDate = endDate {
            parameters["endDate"] = endDate
        }
        
        let response = try await networkManager.get(
            endpoint: APIEndpoints.meritsStatistics,
            parameters: parameters,
            responseType: MeritStatisticsResponse.self
        )
        
        if response.success {
            print("✅ 获取功过统计成功")
            return response
        } else {
            let errorMessage = response.message ?? "获取功过统计失败"
            print("❌ 获取功过统计失败: \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
    }
    
    /// 获取单个功过记录
    /// - Parameter id: 记录ID
    /// - Returns: 记录详情
    func getRecord(id: Int) async throws -> MeritRecord {
        print("🌐 获取功过记录详情请求: id=\(id)")
        
        let response = try await networkManager.get(
            endpoint: "\(APIEndpoints.merits)/\(id)",
            parameters: nil,
            responseType: MeritResponse.self
        )
        
        if response.success, let data = response.data {
            print("✅ 获取记录详情成功")
            return data.record
        } else {
            let errorMessage = response.message ?? "获取记录详情失败"
            print("❌ 获取记录详情失败: \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
    }
    
    /// 更新功过记录
    /// - Parameters:
    ///   - id: 记录ID
    ///   - request: 更新请求
    /// - Returns: 更新后的记录
    func updateRecord(id: Int, _ request: UpdateMeritRequest) async throws -> MeritRecord {
        print("🌐 更新功过记录请求: id=\(id)")
        
        var requestBody: [String: Any] = [:]
        
        if let title = request.title {
            requestBody["title"] = title
        }
        if let points = request.points {
            requestBody["points"] = points
        }
        if let note = request.note {
            requestBody["note"] = note
        }
        if let recordedAt = request.recordedAt {
            requestBody["recordedAt"] = recordedAt
        }
        
        let response = try await networkManager.put(
            endpoint: "\(APIEndpoints.merits)/\(id)",
            parameters: requestBody,
            responseType: MeritResponse.self
        )
        
        if response.success, let data = response.data {
            print("✅ 更新功过记录成功")
            return data.record
        } else {
            let errorMessage = response.message ?? "更新功过记录失败"
            print("❌ 更新功过记录失败: \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
    }
    
    /// 删除功过记录
    /// - Parameter id: 记录ID
    func deleteRecord(id: Int) async throws {
        print("🌐 删除功过记录请求: id=\(id)")
        
        let response = try await networkManager.delete(
            endpoint: "\(APIEndpoints.merits)/\(id)",
            parameters: nil,
            responseType: BaseResponse.self
        )
        
        if response.success {
            print("✅ 删除功过记录成功")
        } else {
            let errorMessage = response.message ?? "未知错误"
            print("❌ 删除功过记录失败: \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
    }
    
    // MARK: - 标准条目库
    
    /// 获取标准条目列表
    /// - Parameters:
    ///   - type: 类型筛选（可选）
    ///   - category: 分类筛选（可选）
    ///   - search: 搜索关键词（可选）
    /// - Returns: 标准条目响应
    func getStandardItems(
        type: String? = nil,
        category: String? = nil,
        search: String? = nil
    ) async throws -> StandardItemsResponse {
        print("🌐 获取标准条目列表请求")
        
        var parameters: [String: Any] = [:]
        
        if let type = type {
            parameters["type"] = type
        }
        if let category = category {
            parameters["category"] = category
        }
        if let search = search {
            parameters["search"] = search
        }
        
        let response = try await networkManager.get(
            endpoint: APIEndpoints.meritsStandard,
            parameters: parameters,
            responseType: StandardItemsResponse.self
        )
        
        if response.success {
            print("✅ 获取标准条目列表成功")
            return response
        } else {
            let errorMessage = response.message ?? "获取标准条目列表失败"
            print("❌ 获取标准条目列表失败: \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
    }
    
    /// 获取分类列表
    /// - Returns: 分类列表响应
    func getCategories() async throws -> CategoriesResponse {
        print("🌐 获取分类列表请求")
        
        let response = try await networkManager.get(
            endpoint: APIEndpoints.meritsCategories,
            parameters: nil,
            responseType: CategoriesResponse.self
        )
        
        if response.success {
            print("✅ 获取分类列表成功")
            return response
        } else {
            let errorMessage = response.message ?? "获取分类列表失败"
            print("❌ 获取分类列表失败: \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
    }
    
    // MARK: - 排行榜
    
    /// 获取功过排行榜
    /// - Parameters:
    ///   - period: 时间周期
    ///   - limit: 返回数量
    /// - Returns: 排行榜响应
    func getLeaderboard(period: String = "month", limit: Int = 20) async throws -> LeaderboardResponse {
        print("🌐 获取功过排行榜请求: period=\(period)")
        
        let parameters: [String: Any] = [
            "period": period,
            "limit": limit
        ]
        
        let response = try await networkManager.get(
            endpoint: APIEndpoints.meritsLeaderboard,
            parameters: parameters,
            responseType: LeaderboardResponse.self
        )
        
        if response.success {
            print("✅ 获取排行榜成功")
            return response
        } else {
            let errorMessage = response.message ?? "获取排行榜失败"
            print("❌ 获取排行榜失败: \(errorMessage)")
            throw APIError.serverError(errorMessage)
        }
    }
}

// MARK: - 数据模型

/// 功过记录
struct MeritRecord: Codable, Identifiable {
    let id: Int
    let userId: Int
    let type: String  // "merit" 或 "demerit"
    let title: String
    let points: Int
    let category: String?
    let note: String?
    let recordedAt: String
    let createdAt: String
    let updatedAt: String
}

/// 创建功过记录请求
struct CreateMeritRequest: Codable {
    let type: String
    let title: String
    let points: Int
    let category: String?
    let note: String?
    let recordedAt: String?
}

/// 更新功过记录请求
struct UpdateMeritRequest: Codable {
    let title: String?
    let points: Int?
    let note: String?
    let recordedAt: String?
}

/// 功过记录响应
struct MeritResponse: Codable {
    let status: String
    let message: String?
    let data: MeritData?
    
    var success: Bool {
        status == "success"
    }
}

struct MeritData: Codable {
    let record: MeritRecord
}

/// 功过记录列表响应
struct MeritListResponse: Codable {
    let status: String
    let message: String?
    let data: MeritListData?
    
    var success: Bool {
        status == "success"
    }
}

struct MeritListData: Codable {
    let records: [MeritRecord]
    let pagination: MeritPagination
}

struct MeritPagination: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalRecords: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
    let limit: Int
}

/// 每日记录响应
struct DailyRecordsResponse: Codable {
    let status: String
    let message: String?
    let data: DailyRecordsData?
    
    var success: Bool {
        status == "success"
    }
}

struct DailyRecordsData: Codable {
    let date: String
    let summary: DailySummary
    let records: [MeritRecord]
}

struct DailySummary: Codable {
    let meritCount: Int
    let demeritCount: Int
    let totalMeritPoints: Int
    let totalDemeritPoints: Int
    let netScore: Int
}

/// 月度汇总响应
struct MonthlyRecordsResponse: Codable {
    let status: String
    let message: String?
    let data: MonthlyRecordsData?
    
    var success: Bool {
        status == "success"
    }
}

struct MonthlyRecordsData: Codable {
    let year: Int
    let month: Int
    let summary: MonthlySummary
    let dailyScores: [DailyScore]
    let categoryDistribution: CategoryDistribution
}

struct MonthlySummary: Codable {
    let totalMeritRecords: Int
    let totalDemeritRecords: Int
    let totalMeritPoints: Int
    let totalDemeritPoints: Int
    let netScore: Int
    let recordDays: Int
}

struct DailyScore: Codable {
    let date: String
    let meritPoints: Int
    let demeritPoints: Int
    let netScore: Int
    let recordCount: Int
}

struct CategoryDistribution: Codable {
    let merits: [String: Int]
    let demerits: [String: Int]
}

/// 功过统计响应
struct MeritStatisticsResponse: Codable {
    let status: String
    let message: String?
    let data: MeritStatisticsData?
    
    var success: Bool {
        status == "success"
    }
}

struct MeritStatisticsData: Codable {
    let period: MeritStatisticsPeriod
    let overview: StatisticsOverview
    let categoryStats: CategoryStats
    let trends: TrendsData
    let streaks: StreaksData
}

struct MeritStatisticsPeriod: Codable {
    let startDate: String
    let endDate: String
    let days: Int
}

struct StatisticsOverview: Codable {
    let totalMeritRecords: Int
    let totalDemeritRecords: Int
    let totalMeritPoints: Int
    let totalDemeritPoints: Int
    let netScore: Int
    let averageDailyNetScore: Double
    let recordDays: Int
    let recordRate: Double
    
    enum CodingKeys: String, CodingKey {
        case totalMeritRecords, totalDemeritRecords, totalMeritPoints, totalDemeritPoints
        case netScore, averageDailyNetScore, recordDays, recordRate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalMeritRecords = try container.decode(Int.self, forKey: .totalMeritRecords)
        totalDemeritRecords = try container.decode(Int.self, forKey: .totalDemeritRecords)
        totalMeritPoints = try container.decode(Int.self, forKey: .totalMeritPoints)
        totalDemeritPoints = try container.decode(Int.self, forKey: .totalDemeritPoints)
        netScore = try container.decode(Int.self, forKey: .netScore)
        averageDailyNetScore = try container.decode(Double.self, forKey: .averageDailyNetScore)
        recordDays = try container.decode(Int.self, forKey: .recordDays)
        
        // 处理 recordRate 可能是字符串的情况
        if let recordRateString = try? container.decode(String.self, forKey: .recordRate) {
            recordRate = Double(recordRateString) ?? 0.0
        } else {
            recordRate = try container.decode(Double.self, forKey: .recordRate)
        }
    }
}

struct CategoryStats: Codable {
    let merits: [CategoryStat]
    let demerits: [CategoryStat]
}

struct CategoryStat: Codable {
    let category: String
    let count: Int
    let totalPoints: Int
    let percentage: Double
    
    enum CodingKeys: String, CodingKey {
        case category, count, totalPoints, percentage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decode(String.self, forKey: .category)
        count = try container.decode(Int.self, forKey: .count)
        totalPoints = try container.decode(Int.self, forKey: .totalPoints)
        
        // 处理 percentage 可能是字符串的情况
        if let percentageString = try? container.decode(String.self, forKey: .percentage) {
            percentage = Double(percentageString) ?? 0.0
        } else {
            percentage = try container.decode(Double.self, forKey: .percentage)
        }
    }
}

struct TrendsData: Codable {
    let weeklyData: [WeeklyData]
    let improvement: ImprovementData
}

struct WeeklyData: Codable {
    let week: String
    let meritPoints: Int
    let demeritPoints: Int
    let netScore: Int
}

struct ImprovementData: Codable {
    let direction: String
    let percentage: Double
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case direction, percentage, message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        direction = try container.decode(String.self, forKey: .direction)
        message = try container.decode(String.self, forKey: .message)
        
        // 处理 percentage 可能是字符串或整数的情况
        if let percentageInt = try? container.decode(Int.self, forKey: .percentage) {
            percentage = Double(percentageInt)
        } else if let percentageString = try? container.decode(String.self, forKey: .percentage) {
            percentage = Double(percentageString) ?? 0.0
        } else {
            percentage = try container.decode(Double.self, forKey: .percentage)
        }
    }
}

struct StreaksData: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let message: String
}

/// 标准条目响应
struct StandardItemsResponse: Codable {
    let status: String
    let message: String?
    let data: StandardItemsData?
    
    var success: Bool {
        status == "success"
    }
}

struct StandardItemsData: Codable {
    let merits: [StandardItem]
    let demerits: [StandardItem]
    let categories: StandardCategories
}

struct StandardItem: Codable, Identifiable {
    var id: String { title }
    let title: String
    let category: String
    let points: Int
    let description: String
}

struct StandardCategories: Codable {
    let merits: [String]
    let demerits: [String]
}

/// 分类列表响应
struct CategoriesResponse: Codable {
    let status: String
    let message: String?
    let data: CategoriesData?
    
    var success: Bool {
        status == "success"
    }
}

struct CategoriesData: Codable {
    let merits: [CategoryInfo]
    let demerits: [CategoryInfo]
}

struct CategoryInfo: Codable, Identifiable {
    var id: String { name }
    let name: String
    let description: String
    let standardPoints: Int
    let itemCount: Int
}

/// 排行榜响应
struct LeaderboardResponse: Codable {
    let status: String
    let message: String?
    let data: LeaderboardData?
    
    var success: Bool {
        status == "success"
    }
}

struct LeaderboardData: Codable {
    let period: String
    let periodLabel: String
    let myRank: UserRank
    let leaderboard: [UserRank]
}

struct UserRank: Codable, Identifiable {
    let rank: Int
    let userId: Int
    let nickname: String
    let avatar: String?
    let netScore: Int
    let meritPoints: Int
    let demeritPoints: Int
    let recordDays: Int
    
    var id: Int { userId }
}

