import Foundation

/// 情绪记录服务类，处理所有情绪相关的API请求
class EmotionService {
    static let shared = EmotionService()
    
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    // MARK: - 情绪记录功能
    
    /// 获取单个情绪记录
    /// - Parameter id: 情绪记录ID
    /// - Returns: 情绪记录详情
    func getEmotion(id: Int) async throws -> EmotionNew {
        print("🌐 获取情绪记录请求: ID=\(id)")
        
        // 尝试从列表中查找指定ID的记录
        let emotionsList = try await getEmotions(page: 1, limit: 100)
        
        if let emotion = emotionsList.data?.emotions.first(where: { $0.id == id }) {
            print("✅ 获取情绪记录成功: ID=\(id)")
            return emotion
        } else {
            print("❌ 获取情绪记录失败: 未找到ID=\(id)的记录")
            throw APIError.serverError("未找到指定的情绪记录")
        }
    }
    
    /// 获取情绪记录列表
    /// - Parameters:
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 情绪记录列表响应
    func getEmotions(page: Int = 1, limit: Int = 20) async throws -> EmotionListResponseNew {
        print("🌐 获取情绪记录列表请求: page=\(page), limit=\(limit)")
        
        let parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        
        let response = try await networkManager.get(
            endpoint: APIEndpoints.emotions,
            parameters: parameters,
            responseType: EmotionListResponseNew.self
        )
        
        if response.success, let data = response.data {
            print("✅ 获取情绪记录列表成功: 共\(data.emotions.count)条记录")
            return response
        } else {
            print("❌ 获取情绪记录列表失败: \(response.message)")
            throw APIError.serverError(response.message)
        }
    }
    
    /// 创建情绪记录
    func createEmotion(_ request: EmotionRequestNew) async throws -> EmotionNew {
        print("🌐 创建情绪记录请求")
        
        let requestBody: [String: Any] = [
            "type": request.type,
            "intensity": request.intensity,
            "trigger": request.trigger ?? "",
            "note": request.note ?? "",
            "tags": request.tags ?? []
        ]
        
        let response = try await networkManager.post(
            endpoint: APIEndpoints.emotions,
            parameters: requestBody,
            responseType: EmotionCreateResponseNew.self
        )
        
        if response.success, let data = response.data {
            print("✅ 创建情绪记录成功")
            return data.emotion
        } else {
            print("❌ 创建情绪记录失败: \(response.message)")
            throw APIError.serverError(response.message)
        }
    }
    
    /// 更新情绪记录
    func updateEmotion(
        emotionId: Int,
        type: String,
        intensity: Int,
        trigger: String? = nil,
        note: String? = nil,
        strategies: [String]? = nil
    ) async throws -> EmotionNew {
        let endpoint = "\(APIEndpoints.emotions)/\(emotionId)"
        
        let requestBody: [String: Any] = [
            "type": type,
            "intensity": intensity,
            "trigger": trigger ?? "",
            "note": note ?? "",
            "tags": strategies ?? []
        ]
        
        let response = try await networkManager.put(
            endpoint: endpoint,
            parameters: requestBody,
            responseType: EmotionUpdateResponseNew.self
        )
        
        if response.success, let data = response.data {
            return data.emotion
        } else {
            throw APIError.serverError(response.message)
        }
    }
    
    /// 删除情绪记录
    func deleteEmotion(id: Int) async throws {
        print("🌐 删除情绪记录请求: ID=\(id)")
        
        let endpoint = "\(APIEndpoints.emotions)/\(id)"
        
        let response = try await networkManager.delete(
            endpoint: endpoint,
            responseType: EmotionDeleteResponseNew.self
        )
        
        if response.success {
            print("✅ 删除情绪记录成功: ID=\(id)")
        } else {
            print("❌ 删除情绪记录失败: \(response.message)")
            throw APIError.serverError(response.message)
        }
    }

    // MARK: - 获取情绪统计数据
    func getEmotionStatistics() async throws -> EmotionStatisticsData {
        // 模拟网络请求
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒

        // 模拟统计数据
        let typeStats = [
            EmotionTypeStats(id: "happy", name: "开心", total: 15, percentage: 30.0),
            EmotionTypeStats(id: "sad", name: "难过", total: 10, percentage: 20.0),
            EmotionTypeStats(id: "angry", name: "愤怒", total: 8, percentage: 16.0),
            EmotionTypeStats(id: "anxious", name: "焦虑", total: 12, percentage: 24.0),
            EmotionTypeStats(id: "calm", name: "平静", total: 5, percentage: 10.0)
        ]

        return EmotionStatisticsData(
            totalEmotions: 50,
            averageIntensity: 6.5,
            mostCommonEmotion: "开心",
            typeStats: typeStats,
            weeklyTrend: [5, 8, 6, 9, 7, 10, 5],
            monthlyAverage: 7.2
        )
    }
}

// MARK: - 响应模型

struct EmotionListResponseNew: Codable {
    let status: String
    let data: EmotionListDataNew?

    var success: Bool {
        return status == "success"
    }

    var message: String {
        return success ? "获取成功" : "获取失败"
    }

    // 为了兼容 RecordCenterViewModel，添加直接访问属性
    var emotions: [EmotionNew] {
        return data?.emotions ?? []
    }

    var pagination: EmotionPaginationInfo {
        return data?.pagination ?? EmotionPaginationInfo(
            currentPage: 1,
            totalPages: 1,
            totalEmotions: 0,
            hasNextPage: false,
            hasPrevPage: false
        )
    }
}



struct EmotionListDataNew: Codable {
    let emotions: [EmotionNew]
    let pagination: EmotionPaginationInfo
}

struct EmotionCreateResponseNew: Codable {
    let status: String
    let message: String
    let data: EmotionCreateDataNew?

    var success: Bool {
        return status == "success"
    }
}

struct EmotionCreateDataNew: Codable {
    let emotion: EmotionNew
}

struct EmotionUpdateResponseNew: Codable {
    let status: String
    let message: String
    let data: EmotionUpdateDataNew?

    var success: Bool {
        return status == "success"
    }
}

struct EmotionUpdateDataNew: Codable {
    let emotion: EmotionNew
}

struct EmotionDeleteResponseNew: Codable {
    let status: String
    let message: String

    var success: Bool {
        return status == "success"
    }
}

// EmotionRequestNew 已在 AdditionalTypes.swift 中定义，这里不重复定义

struct EmotionPaginationInfo: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalEmotions: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
}
