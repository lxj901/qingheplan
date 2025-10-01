import Foundation

// MARK: - 健康报告管理器
class HealthReportManager: ObservableObject {
    static let shared = HealthReportManager()
    
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1/health"
    private let networkManager = NetworkManager.shared
    
    @Published var availableReportDates: Set<Date> = []
    @Published var currentHealthReport: HealthReportData?
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    
    private init() {}
    
    // MARK: - 获取可用报告日期列表
    func loadAvailableReportDates() async {
        print("🚀 开始加载可用报告日期列表...")
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            print("📡 正在请求 /health/report/dates 接口...")
            let response: ReportDatesResponse = try await networkManager.request(
                endpoint: "/health/report/dates",
                method: .GET,
                responseType: ReportDatesResponse.self
            )
            
            print("📡 API响应: success=\(response.success), code=\(response.code), msg=\(response.msg)")
            
            if response.success {
                print("📅 API返回的报告日期数据: total=\(response.data.total), dates count=\(response.data.dates.count)")
                
                let dates = Set(response.data.dates.compactMap { reportDate in
                    print("📅 处理日期记录: date=\(reportDate.date), type=\(reportDate.type), generatedAt=\(reportDate.generatedAt)")
                    let parsedDate = parseDate(reportDate.date)
                    if let date = parsedDate {
                        print("✅ 解析成功: \(formatDateForAPI(date))")
                    } else {
                        print("❌ 解析失败: \(reportDate.date)")
                    }
                    return parsedDate
                })
                
                await MainActor.run {
                    self.availableReportDates = dates
                    self.lastUpdateTime = Date()
                    self.isLoading = false
                    print("📅 最终可用日期集合 (\(dates.count)个): \(dates.map { formatDateForAPI($0) }.sorted())")
                }
            } else {
                print("❌ API请求失败: \(response.msg)")
                throw NetworkManager.NetworkError.serverMessage(response.msg)
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            print("❌ 获取报告日期失败: \(error)")
        }
    }
    
    // MARK: - 按日期获取健康报告
    func getHealthReport(for date: Date) async -> HealthReportData? {
        let dateString = formatDateForAPI(date)
        
        do {
            let response: HealthReportResponse = try await networkManager.request(
                endpoint: "/health/report/date/\(dateString)",
                method: .GET,
                responseType: HealthReportResponse.self
            )
            
            if response.success {
                await MainActor.run {
                    self.currentHealthReport = response.data
                }
                return response.data
            } else {
                throw NetworkManager.NetworkError.serverMessage(response.msg)
            }
        } catch {
            print("获取健康报告失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 生成新的健康报告
    func generateHealthReport() async -> HealthReportData? {
        print("🚀 开始生成健康报告...")
        
        await MainActor.run {
            isLoading = true
        }
        
        // 🔧 乐观更新：立即添加今天的日期到可用日期集合
        let today = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current // 确保使用本地时区
        let todayStart = calendar.startOfDay(for: today)
        
        print("🔄 HealthReportManager 乐观更新日期: \(formatDateForAPI(todayStart))")
        await optimisticallyAddReportDate(todayStart)
        
        do {
            let parameters = ["reportType": "comprehensive"]
            print("📡 正在调用生成报告API...")
            let response: HealthReportResponse = try await networkManager.request(
                endpoint: "/health/report/generate",
                method: .POST,
                parameters: parameters,
                responseType: HealthReportResponse.self
            )
            
            print("📡 生成报告API响应: success=\(response.success), code=\(response.code)")
            
            if response.success {
                await MainActor.run {
                    self.currentHealthReport = response.data
                    self.isLoading = false
                }
                
                // 🔧 确认报告生成成功，验证并更新数据
                if let reportData = response.data {
                    await confirmReportDate(todayStart, reportId: reportData.reportId)
                }
                
                // 生成报告后重新加载可用日期（保持与后端同步）
                await loadAvailableReportDates()
                
                print("✅ 健康报告生成成功: \(response.data?.reportId ?? "unknown")")
                return response.data
            } else {
                // 🔧 生成失败，回滚乐观更新
                await rollbackOptimisticUpdate(todayStart)
                throw NetworkManager.NetworkError.serverMessage(response.msg)
            }
        } catch {
            // 🔧 异常情况，回滚乐观更新
            await rollbackOptimisticUpdate(todayStart)
            
            await MainActor.run {
                self.isLoading = false
            }
            print("❌ 生成健康报告失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 乐观更新相关方法
    
    /// 乐观更新：立即在日历上标记指定日期有报告
    func optimisticallyAddReportDate(_ date: Date) async {
        await MainActor.run {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            let dayStart = calendar.startOfDay(for: date)
            
            // 如果该日期还没有报告，添加到集合中
            if !self.availableReportDates.contains(dayStart) {
                self.availableReportDates.insert(dayStart)
                print("🔄 乐观更新：添加日期 \(formatDateForAPI(dayStart)) 到可用日期集合")
            }
        }
    }
    
    /// 确认报告日期：验证报告生成成功后的数据
    func confirmReportDate(_ date: Date, reportId: String) async {
        await MainActor.run {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            let dayStart = calendar.startOfDay(for: date)
            
            // 确保该日期在可用日期集合中
            if !self.availableReportDates.contains(dayStart) {
                self.availableReportDates.insert(dayStart)
            }
            
            print("✅ 确认报告日期: \(formatDateForAPI(dayStart)), reportId: \(reportId)")
        }
    }
    
    /// 回滚乐观更新：当报告生成失败时移除之前乐观添加的日期
    func rollbackOptimisticUpdate(_ date: Date) async {
        await MainActor.run {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            let dayStart = calendar.startOfDay(for: date)
            
            // 只有当该日期在后端真的不存在时才移除
            // 这里我们简单地移除，实际项目中可以做更精确的检查
            self.availableReportDates.remove(dayStart)
            print("🔄 回滚乐观更新：移除日期 \(formatDateForAPI(dayStart))")
        }
    }
    
    // MARK: - 获取日期范围内的报告
    func getReportsInRange(start: Date, end: Date) async -> [ReportSummary] {
        let startString = formatDateForAPI(start)
        let endString = formatDateForAPI(end)
        
        do {
            let response: ReportRangeResponse = try await networkManager.request(
                endpoint: "/health/report/range?start=\(startString)&end=\(endString)",
                method: .GET,
                responseType: ReportRangeResponse.self
            )
            
            if response.success {
                return response.data.reports
            } else {
                throw NetworkManager.NetworkError.serverMessage(response.msg)
            }
        } catch {
            print("获取报告范围失败: \(error)")
            return []
        }
    }
    
    // MARK: - 辅助方法
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        // 首先尝试解析 ISO8601 格式（API返回的完整时间戳）
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // 如果失败，尝试不带毫秒的 ISO8601 格式
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // 最后尝试简单的日期格式 (yyyy-MM-dd)
        let simpleDateFormatter = DateFormatter()
        simpleDateFormatter.dateFormat = "yyyy-MM-dd"
        simpleDateFormatter.timeZone = TimeZone.current // 统一与UI/hasReport的本地时区
        if let date = simpleDateFormatter.date(from: dateString) {
            return date
        }
        
        print("⚠️ 无法解析日期格式: \(dateString)")
        return nil
    }
    
    // MARK: - 计算下次更新日期
    func getNextReportDate() -> Date {
        guard let lastReportDate = availableReportDates.max() else {
            return Date()
        }
        return Calendar.current.date(byAdding: .day, value: 3, to: lastReportDate) ?? Date()
    }
    
    // MARK: - 检查日期是否有报告
    func hasReport(for date: Date) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let dayStart = calendar.startOfDay(for: date)
        
        let result = availableReportDates.contains { availableDate in
            let isMatch = calendar.isDate(availableDate, inSameDayAs: dayStart)
            if isMatch {
                print("📅 找到匹配日期: \(formatDateForAPI(availableDate)) == \(formatDateForAPI(dayStart))")
            }
            return isMatch
        }
        
        if !result {
            print("📅 未找到报告: \(formatDateForAPI(dayStart)), 可用日期: \(availableReportDates.map { formatDateForAPI($0) }.sorted())")
        }
        
        return result
    }
}

// MARK: - 数据模型定义
struct HealthReportResponse: Codable {
    let code: Int
    let success: Bool
    let msg: String
    let data: HealthReportData?
}

struct HealthReportData: Codable {
    let reportId: String
    let reportType: String
    let generatedAt: String
    let nextUpdateSuggested: String?
    let userInfo: UserInfo?
    let healthOverview: HealthOverview
    let detailedAnalysis: DetailedAnalysis?
    let recommendations: Recommendations?
    let healthTrends: HealthTrends?
    let riskAssessment: [RiskAssessment]?
}

struct UserInfo: Codable {
    let userId: Int
    let username: String
}

struct HealthOverview: Codable {
    let overallScore: Int
    let healthLevel: String
    let primaryConstitution: String?
    let currentSolarTerm: String?
}

struct DetailedAnalysis: Codable {
    let constitution: DetailedConstitutionAnalysis?
    let workoutSummary: HealthReportWorkoutSummary?
    let sleepSummary: SleepSummary?
    let healthMetrics: HealthMetrics?
    let fiveElements: FiveElements?
}

struct HealthMetrics: Codable {
    let bmi: String?
    let constitution: Int?
    let exercise: String?
    let sleep: String?
}

struct FiveElements: Codable {
    // 暂时留空，可以根据实际API响应添加字段
}

struct BasicConstitutionAnalysis: Codable {
    let hasAnalysis: Bool
    let primaryConstitution: String
    let confidence: Double
}

struct HealthReportWorkoutSummary: Codable {
    let totalWorkouts: Int
    let weeklyWorkouts: Int
    let average3DayWorkouts: Int
    let lastWorkoutDate: String?
}

struct SleepSummary: Codable {
    let totalSessions: Int
    let weeklySessions: Int
    let average3DaySessions: Int
    let averageSleepDuration: Double
    let lastSleepDate: String?
}

struct ConstitutionInfo: Codable {
    let characteristics: [String]?
    let description: String
    let element: String?
    let healthLevel: String?
    let name: String
    let englishName: String?
    let organs: [String]?
    let season: String?
}

struct ConstitutionRanking: Codable {
    let info: ConstitutionInfo
    let name: String
    let score: Int
}

struct ConstitutionRecommendations: Codable {
    let diet: [String]
    let emotional: [String]
    let exercise: [String]
    let lifestyle: [String]
}

struct SeasonalAdvice: Codable {
    let autumn: String
    let spring: String
    let summer: String
    let winter: String
}

struct AnalysisReport: Codable {
    let primaryConstitution: ConstitutionInfo
    let recommendations: ConstitutionRecommendations
    let riskFactors: [String]
    let seasonalAdvice: SeasonalAdvice
    let secondaryConstitution: ConstitutionInfo
    let summary: String
}

struct DetailedConstitutionAnalysis: Codable {
    let analysisReport: AnalysisReport?
    let analyzedAt: String?
    let confidence: Double
    let constitutionRanking: [ConstitutionRanking]?
    let constitutionScores: [String: Int]?
    let hasAnalysis: Int?
    let primaryConstitution: String?
    let secondaryConstitution: String?

    private enum CodingKeys: String, CodingKey {
        case analysisReport, analyzedAt, confidence, constitutionRanking, constitutionScores, hasAnalysis, primaryConstitution, secondaryConstitution
    }

    init(analysisReport: AnalysisReport?, analyzedAt: String?, confidence: Double, constitutionRanking: [ConstitutionRanking]?, constitutionScores: [String: Int]? = nil, hasAnalysis: Int? = nil, primaryConstitution: String? = nil, secondaryConstitution: String? = nil) {
        self.analysisReport = analysisReport
        self.analyzedAt = analyzedAt
        self.confidence = confidence
        self.constitutionRanking = constitutionRanking
        self.constitutionScores = constitutionScores
        self.hasAnalysis = hasAnalysis
        self.primaryConstitution = primaryConstitution
        self.secondaryConstitution = secondaryConstitution
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.analysisReport = try container.decodeIfPresent(AnalysisReport.self, forKey: .analysisReport)
        self.analyzedAt = try container.decodeIfPresent(String.self, forKey: .analyzedAt)
        self.constitutionScores = try container.decodeIfPresent([String: Int].self, forKey: .constitutionScores)
        self.primaryConstitution = try container.decodeIfPresent(String.self, forKey: .primaryConstitution)
        self.secondaryConstitution = try container.decodeIfPresent(String.self, forKey: .secondaryConstitution)
        
        // hasAnalysis可能是Int或Bool，统一处理为Int
        if let intVal = try? container.decode(Int.self, forKey: .hasAnalysis) {
            self.hasAnalysis = intVal
        } else if let boolVal = try? container.decode(Bool.self, forKey: .hasAnalysis) {
            self.hasAnalysis = boolVal ? 1 : 0
        } else {
            self.hasAnalysis = nil
        }
        
        // 兼容字符串或数字两种格式的confidence
        if let doubleVal = try? container.decode(Double.self, forKey: .confidence) {
            self.confidence = doubleVal
        } else if let stringVal = try? container.decode(String.self, forKey: .confidence), let doubleVal = Double(stringVal) {
            self.confidence = doubleVal
        } else {
            // 缺省兜底
            self.confidence = 0.5
        }
        
        // constitutionRanking字段可能不存在，使用可选解析
        self.constitutionRanking = try container.decodeIfPresent([ConstitutionRanking].self, forKey: .constitutionRanking)
    }
}

struct Recommendations: Codable {
    let priority: String
    let constitution: ConstitutionRecommendations?
    let lifestyle: [String]?
    let immediate: [String]?
    let longTerm: [String]?
}

struct HealthTrends: Codable {
    let exercise: String
    let sleep: String
    let overall: String
}

struct RiskAssessment: Codable {
    let level: String
    let factor: String
    let advice: String
}

// MARK: - 报告日期列表相关模型
struct ReportDatesResponse: Codable {
    let code: Int
    let success: Bool
    let msg: String
    let data: ReportDatesData
}

struct ReportDatesData: Codable {
    let total: Int
    let dates: [ReportDate]
}

struct ReportDate: Codable {
    let date: String
    let type: String
    let generatedAt: String
}

// MARK: - 日期范围报告相关模型
struct ReportRangeResponse: Codable {
    let code: Int
    let success: Bool
    let msg: String
    let data: ReportRangeData
}

struct ReportRangeData: Codable {
    let start: String
    let end: String
    let total: Int
    let reports: [ReportSummary]
}

struct ReportSummary: Codable {
    let id: Int
    let reportDate: String
    let reportType: String
    let reportId: String
    let healthOverview: HealthOverview
    let generatedAt: String
    let nextUpdateSuggested: String?
}