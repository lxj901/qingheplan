import Foundation
import UIKit

/// 打卡API服务类
class CheckinAPIService {
    static let shared = CheckinAPIService()
    
    private let networkManager = NetworkManager.shared
    private let authManager = AuthManager.shared
    
    private init() {}
    
    // MARK: - API 端点
    private enum Endpoint {
        static let checkins = "/checkins"
        static let todayCheckin = "/checkins/today"
        static let statistics = "/checkins/statistics"
        static let history = "/checkins/history"
        static let analysis = "/checkins/analysis"
    }
    
    // MARK: - 用户签到
    
    /// 执行签到
    /// - Parameters:
    ///   - note: 签到备注
    ///   - mood: 心情描述
    ///   - challenges: 挑战描述
    ///   - location: 位置信息（可选）
    /// - Returns: 签到记录
    func checkin(
        note: String? = nil,
        mood: String? = nil,
        challenges: String? = nil,
        location: CheckinLocation? = nil
    ) async throws -> CheckinAPIRecord {
        
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        // 获取设备信息
        let deviceInfo = getDeviceInfo()
        
        let request = CheckinRequest(
            deviceInfo: deviceInfo,
            location: location,
            note: note,
            mood: mood,
            challenges: challenges
        )
        
        let parameters = try request.toDictionary()
        
        let response: CheckinAPIResponse<CheckinResponseData> = try await networkManager.post(
            endpoint: Endpoint.checkins,
            parameters: parameters,
            headers: authHeaders,
            responseType: CheckinAPIResponse<CheckinResponseData>.self
        )
        
        guard let data = response.data else {
            throw NetworkManager.NetworkError.noData
        }
        
        return data.checkin
    }
    
    // MARK: - 获取今日签到状态
    
    /// 检查今日是否已签到
    /// - Returns: 今日签到状态
    func getTodayCheckinStatus() async throws -> TodayCheckinResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        let response: CheckinAPIResponse<TodayCheckinResponse> = try await networkManager.get(
            endpoint: Endpoint.todayCheckin,
            headers: authHeaders,
            responseType: CheckinAPIResponse<TodayCheckinResponse>.self
        )
        
        guard let data = response.data else {
            throw NetworkManager.NetworkError.noData
        }
        
        return data
    }
    
    // MARK: - 获取签到统计
    
    /// 获取签到统计信息
    /// - Returns: 签到统计数据
    func getCheckinStatistics() async throws -> CheckinStatistics {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        let response: CheckinAPIResponse<CheckinStatistics> = try await networkManager.get(
            endpoint: Endpoint.statistics,
            headers: authHeaders,
            responseType: CheckinAPIResponse<CheckinStatistics>.self
        )
        
        guard let data = response.data else {
            throw NetworkManager.NetworkError.noData
        }
        
        return data
    }
    
    // MARK: - 获取签到记录
    
    /// 获取签到记录列表
    /// - Parameters:
    ///   - page: 页码
    ///   - limit: 每页记录数
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 签到记录列表
    func getCheckinRecords(
        page: Int = 1,
        limit: Int = 10,
        startDate: String? = nil,
        endDate: String? = nil
    ) async throws -> CheckinListResponse {
        
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        var parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        
        if let startDate = startDate {
            parameters["startDate"] = startDate
        }
        
        if let endDate = endDate {
            parameters["endDate"] = endDate
        }
        
        let response: CheckinAPIResponse<CheckinListResponse> = try await networkManager.get(
            endpoint: Endpoint.checkins,
            parameters: parameters,
            headers: authHeaders,
            responseType: CheckinAPIResponse<CheckinListResponse>.self
        )
        
        guard let data = response.data else {
            throw NetworkManager.NetworkError.noData
        }
        
        return data
    }
    
    // MARK: - 获取分析数据
    
    /// 获取签到分析数据
    /// - Parameters:
    ///   - type: 分析类型
    ///   - year: 年份
    ///   - month: 月份
    /// - Returns: 分析数据
    func getCheckinAnalysis(
        type: String? = nil,
        year: Int? = nil,
        month: Int? = nil
    ) async throws -> [HeatmapData] {
        
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        var parameters: [String: Any] = [:]
        
        if let type = type {
            parameters["type"] = type
        }
        
        if let year = year {
            parameters["year"] = year
        }
        
        if let month = month {
            parameters["month"] = month
        }
        
        struct AnalysisResponse: Codable {
            let heatmapData: [HeatmapData]
        }
        
        let response: CheckinAPIResponse<AnalysisResponse> = try await networkManager.get(
            endpoint: Endpoint.analysis,
            parameters: parameters,
            headers: authHeaders,
            responseType: CheckinAPIResponse<AnalysisResponse>.self
        )
        
        guard let data = response.data else {
            throw NetworkManager.NetworkError.noData
        }
        
        return data.heatmapData
    }
    
    // MARK: - 辅助方法
    
    /// 获取设备信息
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        let model = device.model
        let systemName = device.systemName
        let systemVersion = device.systemVersion
        
        return "\(model) \(systemName) \(systemVersion)"
    }
}

// MARK: - Codable 扩展

extension Encodable {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"])
        }
        return dictionary
    }
}
