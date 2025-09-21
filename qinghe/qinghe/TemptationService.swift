import Foundation

/// 诱惑记录服务类，处理所有诱惑相关的API请求
class TemptationService {
    static let shared = TemptationService()
    
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    // MARK: - 诱惑记录功能
    
    /// 获取单个诱惑记录
    /// - Parameter id: 诱惑记录ID
    /// - Returns: 诱惑记录详情
    func getTemptation(id: Int) async throws -> TemptationNew {
        print("🌐 获取诱惑记录请求: ID=\(id)")
        
        // 尝试从列表中查找指定ID的记录
        let temptationsList = try await getTemptations(page: 1, limit: 100)
        
        if let temptation = temptationsList.temptations.first(where: { $0.id == id }) {
            print("✅ 获取诱惑记录成功: ID=\(id)")
            return temptation
        } else {
            print("❌ 获取诱惑记录失败: 未找到ID=\(id)的记录")
            throw APIError.serverError("未找到指定的诱惑记录")
        }
    }
    
    /// 创建诱惑记录
    /// - Parameters:
    ///   - type: 诱惑类型
    ///   - intensity: 强度 (1-10)
    ///   - result: 抵抗结果
    ///   - note: 备注
    ///   - strategies: 抵抗策略
    /// - Returns: 创建的诱惑记录
    func createTemptation(
        type: String,
        intensity: Int,
        result: String,
        note: String? = nil,
        strategies: [String]? = nil
    ) async throws -> TemptationNew {
        print("🌐 创建诱惑记录请求: \(type)")
        
        var parameters: [String: Any] = [
            "type": type,
            "intensity": intensity,
            "result": result
        ]
        
        if let note = note { parameters["note"] = note }
        if let strategies = strategies { parameters["strategies"] = strategies }
        
        let response = try await networkManager.post(
            endpoint: APIEndpoints.temptations,
            parameters: parameters,
            responseType: TemptationResponseNew.self
        )

        if response.success, let data = response.data {
            print("✅ 创建诱惑记录成功: \(response.message)")
            return data.temptation
        } else {
            print("❌ 创建诱惑记录失败: \(response.message)")
            throw NSError(domain: "TemptationService", code: 400, userInfo: [NSLocalizedDescriptionKey: "记录诱惑失败"])
        }
    }
    
    /// 获取诱惑记录列表
    /// - Parameters:
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 诱惑记录列表和分页信息
    func getTemptations(page: Int = 1, limit: Int = 10) async throws -> TemptationListData {
        print("🌐 获取诱惑记录列表")
        
        let parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        
        let response = try await networkManager.get(
            endpoint: APIEndpoints.temptations,
            parameters: parameters,
            responseType: TemptationListResponse.self
        )
        
        if response.success {
            print("✅ 获取诱惑记录列表成功")
            // 转换服务器返回的分页信息格式
            let pagination = TemptationPagination(
                currentPage: response.data.pagination.currentPage,
                totalPages: response.data.pagination.totalPages,
                totalTemptations: response.data.pagination.totalTemptations,
                hasNextPage: response.data.pagination.hasNextPage,
                hasPrevPage: response.data.pagination.hasPrevPage
            )
            return TemptationListData(temptations: response.data.temptations, pagination: pagination)
        } else {
            print("❌ 获取诱惑记录列表失败: \(response.message ?? "未知错误")")
            throw NSError(domain: "TemptationService", code: 400, userInfo: [NSLocalizedDescriptionKey: "获取诱惑记录列表失败"])
        }
    }
    
    /// 获取诱惑统计信息
    /// - Returns: 诱惑统计数据
    func getTemptationStatistics() async throws -> TemptationStatistics {
        print("🌐 获取诱惑统计")
        
        let response = try await networkManager.get(
            endpoint: "\(APIEndpoints.temptations)/statistics",
            responseType: TemptationStatisticsResponse.self
        )
        
        if response.success {
            print("✅ 获取诱惑统计成功")
            return response.data
        } else {
            print("❌ 获取诱惑统计失败: \(response.message)")
            throw NSError(domain: "TemptationService", code: 400, userInfo: [NSLocalizedDescriptionKey: "获取诱惑统计失败"])
        }
    }
    
    /// 删除诱惑记录
    /// - Parameter temptationId: 诱惑记录ID
    func deleteTemptation(temptationId: Int) async throws {
        print("🌐 删除诱惑记录请求: \(temptationId)")
        
        let response = try await networkManager.delete(
            endpoint: "\(APIEndpoints.temptations)/\(temptationId)",
            responseType: ServerAPIResponse<EmptyData>.self
        )

        if response.success {
            print("✅ 删除诱惑记录成功: \(response.displayMessage)")
        } else {
            print("❌ 删除诱惑记录失败: \(response.displayMessage)")
            throw NSError(domain: "TemptationService", code: 400, userInfo: [NSLocalizedDescriptionKey: "删除诱惑记录失败"])
        }
    }
    
    // MARK: - 便捷方法
    
    /// 创建诱惑记录的便捷方法
    func createTemptation(_ request: TemptationRequestNew) async throws -> TemptationNew {
        return try await createTemptation(
            type: request.type,
            intensity: request.intensity,
            result: request.result,
            note: request.note,
            strategies: request.strategies
        )
    }
    
    /// 记录成功抵抗诱惑
    func recordResistance(
        type: String,
        intensity: Int,
        strategies: [String]? = nil,
        note: String? = nil
    ) async throws -> TemptationNew {
        return try await createTemptation(
            type: type,
            intensity: intensity,
            result: "已抵抗住",
            note: note,
            strategies: strategies
        )
    }
    
    /// 记录未能抵抗诱惑
    func recordFailure(
        type: String,
        intensity: Int,
        note: String? = nil
    ) async throws -> TemptationNew {
        return try await createTemptation(
            type: type,
            intensity: intensity,
            result: "未抵抗住",
            note: note
        )
    }
    
    /// 记录抽烟诱惑
    func recordSmokingTemptation(
        intensity: Int,
        resisted: Bool,
        strategies: [String]? = nil,
        note: String? = nil
    ) async throws -> TemptationNew {
        return try await createTemptation(
            type: "抽烟",
            intensity: intensity,
            result: resisted ? "已抵抗住" : "未抵抗住",
            note: note,
            strategies: strategies
        )
    }
    
    /// 记录喝酒诱惑
    func recordDrinkingTemptation(
        intensity: Int,
        resisted: Bool,
        strategies: [String]? = nil,
        note: String? = nil
    ) async throws -> TemptationNew {
        return try await createTemptation(
            type: "喝酒",
            intensity: intensity,
            result: resisted ? "已抵抗住" : "未抵抗住",
            note: note,
            strategies: strategies
        )
    }
    
    /// 记录熬夜诱惑
    func recordStayingUpLateTemptation(
        intensity: Int,
        resisted: Bool,
        strategies: [String]? = nil,
        note: String? = nil
    ) async throws -> TemptationNew {
        return try await createTemptation(
            type: "熬夜",
            intensity: intensity,
            result: resisted ? "已抵抗住" : "未抵抗住",
            note: note,
            strategies: strategies
        )
    }
    
    /// 记录刷手机诱惑
    func recordPhoneScrollingTemptation(
        intensity: Int,
        resisted: Bool,
        strategies: [String]? = nil,
        note: String? = nil
    ) async throws -> TemptationNew {
        return try await createTemptation(
            type: "刷手机",
            intensity: intensity,
            result: resisted ? "已抵抗住" : "未抵抗住",
            note: note,
            strategies: strategies
        )
    }
    
    /// 获取最近的诱惑记录
    func getRecentTemptations(limit: Int = 5) async throws -> [TemptationNew] {
        let data = try await getTemptations(page: 1, limit: limit)
        return data.temptations
    }
    
    /// 获取特定类型的诱惑记录
    func getTemptationsByType(_ type: String, limit: Int = 10) async throws -> [TemptationNew] {
        // 注意：这里假设后端支持按类型筛选，如果不支持需要在客户端过滤
        let data = try await getTemptations(page: 1, limit: limit)
        return data.temptations.filter { $0.type == type }
    }
    
    /// 获取抵抗成功的记录
    func getSuccessfulResistances(limit: Int = 10) async throws -> [TemptationNew] {
        let data = try await getTemptations(page: 1, limit: limit)
        return data.temptations.filter { $0.resisted }
    }
    
    // MARK: - 缓存管理
    
    /// 缓存诱惑统计数据
    func cacheTemptationStats(_ stats: TemptationStatistics) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(stats) {
            UserDefaults.standard.set(data, forKey: "cached_temptation_stats")
            print("📦 诱惑统计数据已缓存")
        }
    }
    
    /// 获取缓存的诱惑统计数据
    func getCachedTemptationStats() -> TemptationStatistics? {
        guard let data = UserDefaults.standard.data(forKey: "cached_temptation_stats") else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(TemptationStatistics.self, from: data)
    }
    
    /// 清除缓存数据
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "cached_temptation_stats")
        print("🧹 诱惑服务缓存已清除")
    }
}

// MARK: - 诱惑请求模型扩展
extension TemptationRequestNew {
    /// 从字典创建诱惑请求
    static func from(dict: [String: Any]) -> TemptationRequestNew? {
        guard let type = dict["type"] as? String,
              let intensity = dict["intensity"] as? Int,
              let result = dict["result"] as? String else { return nil }
        
        return TemptationRequestNew(
            type: type,
            intensity: intensity,
            result: result,
            note: dict["note"] as? String,
            strategies: dict["strategies"] as? [String],
            recordTime: dict["recordTime"] as? String
        )
    }
}

// MARK: - 诱惑类型辅助方法
extension TemptationService {
    /// 获取所有支持的诱惑类型
    static var supportedTemptationTypes: [String] {
        return ["抽烟", "喝酒", "熬夜", "刷手机", "垃圾食品", "购物", "游戏", "社交媒体"]
    }
    
    /// 验证诱惑类型是否有效
    static func isValidTemptationType(_ type: String) -> Bool {
        return supportedTemptationTypes.contains(type)
    }
    
    /// 验证强度值是否有效
    static func isValidIntensity(_ intensity: Int) -> Bool {
        return intensity >= 1 && intensity <= 10
    }
    
    /// 验证抵抗结果是否有效
    static func isValidResult(_ result: String) -> Bool {
        return result == "已抵抗住" || result == "未抵抗住"
    }
    
    /// 更新诱惑记录
    func updateTemptation(
        temptationId: Int,
        type: String,
        intensity: Int,
        result: String,
        note: String? = nil,
        strategies: [String]? = nil
    ) async throws -> TemptationNew {
        let endpoint = "\(APIEndpoints.temptations)/\(temptationId)"
        
        let requestBody: [String: Any] = [
            "type": type,
            "intensity": intensity,
            "result": result,
            "note": note ?? "",
            "strategies": strategies ?? []
        ]
        
        let response = try await networkManager.put(
            endpoint: endpoint,
            parameters: requestBody,
            responseType: TemptationUpdateResponseNew.self
        )
        
        if response.success, let data = response.data {
            return data.temptation
        } else {
            throw APIError.serverError(response.message)
        }
    }
}

// MARK: - 响应模型
// 所有响应模型已在 AdditionalTypes.swift 中定义，这里不重复定义
