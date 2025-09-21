import Foundation

/// 计划管理服务类，处理所有计划相关的API请求
class PlanService {
    static let shared = PlanService()
    
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    // MARK: - 计划管理功能
    
    /// 获取单个计划
    /// - Parameter id: 计划ID
    /// - Returns: 计划详情
    func getPlan(id: Int) async throws -> PlanNew {
        print("🌐 获取计划请求: ID=\(id)")
        
        let response = try await networkManager.get(
            endpoint: "\(APIEndpoints.plans)/\(id)",
            responseType: PlanResponseNew.self
        )
        
        if response.success, let data = response.data {
            print("✅ 获取计划成功: ID=\(id)")
            return data.plan
        } else {
            print("❌ 获取计划失败: \(response.message)")
            throw APIError.serverError(response.message)
        }
    }
    
    /// 创建计划
    /// - Parameters:
    ///   - title: 计划标题
    ///   - description: 计划描述
    ///   - category: 计划分类
    ///   - priority: 优先级
    ///   - startTime: 开始时间（ISO 8601）
    ///   - endTime: 结束时间（ISO 8601）
    /// - Returns: 创建的计划信息
    func createPlan(
        title: String,
        description: String? = nil,
        category: String? = nil,
        priority: String? = nil,
        startTime: String? = nil,
        endTime: String? = nil
    ) async throws -> PlanNew {
        print("🌐 创建计划请求: \(title)")
        
        var parameters: [String: Any] = [
            "title": title
        ]
        
        if let description = description { parameters["description"] = description }
        if let category = category { parameters["category"] = category }
        if let priority = priority { parameters["priority"] = priority }
        if let startTime = startTime { parameters["startTime"] = startTime }
        if let endTime = endTime { parameters["endTime"] = endTime }
        
        let response = try await networkManager.post(
            endpoint: APIEndpoints.plans,
            parameters: parameters,
            responseType: PlanResponseNew.self
        )
        
        if response.success, let data = response.data {
            print("✅ 创建计划成功: \(response.message)")
            return data.plan
        } else {
            print("❌ 创建计划失败: \(response.message)")
            throw NSError(domain: "PlanService", code: 400, userInfo: [NSLocalizedDescriptionKey: "创建计划失败"])
        }
    }
    
    /// 获取计划列表
    /// - Parameters:
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 计划列表和分页信息
    func getPlans(page: Int = 1, limit: Int = 10) async throws -> SimplePlanListData {
        print("🌐 获取计划列表")

        let parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]

        let response = try await networkManager.get(
            endpoint: APIEndpoints.plans,
            parameters: parameters,
            responseType: PlanListServerResponse.self
        )

        if response.success {
            print("✅ 获取计划列表成功")

            // 将服务器返回的 PlanNew 转换为 Plan
            let plans = response.data.plans.map { planNew in
                Plan(
                    title: planNew.title,
                    description: planNew.description,
                    category: planNew.category,
                    startDate: planNew.startDate,
                    endDate: planNew.endDate,
                    isActive: planNew.isActive,
                    progress: planNew.progress,
                    status: planNew.status,
                    reminderTime: nil
                )
            }

            // 转换分页信息格式
            return SimplePlanListData(
                plans: plans,
                totalCount: response.data.pagination.totalPlans,
                currentPage: response.data.pagination.currentPage,
                totalPages: response.data.pagination.totalPages
            )
        } else {
            print("❌ 获取计划列表失败: \(response.displayMessage)")
            throw NSError(domain: "PlanService", code: 400, userInfo: [NSLocalizedDescriptionKey: "获取计划列表失败"])
        }
    }
    
    /// 更新计划
    /// - Parameters:
    ///   - planId: 计划ID
    ///   - title: 新标题
    ///   - description: 新描述
    ///   - category: 新分类
    ///   - priority: 新优先级
    ///   - status: 新状态
    /// - Returns: 更新后的计划信息
    func updatePlan(
        planId: Int,
        title: String? = nil,
        description: String? = nil,
        category: String? = nil,
        priority: String? = nil,
        status: String? = nil
    ) async throws -> PlanNew {
        print("🌐 更新计划请求: \(planId)")
        
        var parameters: [String: Any] = [:]
        
        if let title = title { parameters["title"] = title }
        if let description = description { parameters["description"] = description }
        if let category = category { parameters["category"] = category }
        if let priority = priority { parameters["priority"] = priority }
        if let status = status { parameters["status"] = status }
        
        let response = try await networkManager.put(
            endpoint: "\(APIEndpoints.plans)/\(planId)",
            parameters: parameters,
            responseType: PlanUpdateResponseNew.self
        )
        
        if response.success {
            print("✅ 更新计划成功: \(response.message)")
            return response.data!.plan
        } else {
            print("❌ 更新计划失败: \(response.message)")
            throw NSError(domain: "PlanService", code: 400, userInfo: [NSLocalizedDescriptionKey: "更新计划失败"])
        }
    }
    
    /// 删除计划
    /// - Parameter planId: 计划ID
    func deletePlan(planId: Int) async throws {
        print("🌐 删除计划请求: \(planId)")
        
        let response = try await networkManager.delete(
            endpoint: "\(APIEndpoints.plans)/\(planId)",
            responseType: ServerAPIResponse<EmptyData>.self
        )
        
        if response.success {
            print("✅ 删除计划成功: \(response.displayMessage)")
        } else {
            print("❌ 删除计划失败: \(response.displayMessage)")
            throw NSError(domain: "PlanService", code: 400, userInfo: [NSLocalizedDescriptionKey: "删除计划失败"])
        }
    }
    
    /// 获取计划统计信息
    /// - Returns: 计划统计数据
    func getPlanStatistics() async throws -> PlanStatisticsNew {
        print("🌐 获取计划统计")

        let response = try await networkManager.get(
            endpoint: "\(APIEndpoints.plans)/statistics",
            responseType: PlanStatisticsResponseNew.self
        )

        if response.success, let data = response.data {
            print("✅ 获取计划统计成功")
            return data.statistics
        } else {
            print("❌ 获取计划统计失败: \(response.message)")
            throw APIError.serverError(response.message)
        }
    }
    
    // MARK: - 便捷方法
    
    /// 创建计划的便捷方法
    func createPlan(_ request: PlanRequestNew) async throws -> PlanNew {
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // 使用 ISO 8601 格式发送包含时间的 startTime/endTime
        // 注意：后端API不支持reminderTime字段，所以不发送该字段
        // 提醒时间将在前端本地处理
        return try await createPlan(
            title: request.title,
            description: request.description,
            category: request.category,
            priority: nil,
            startTime: iso8601Formatter.string(from: request.startDate),
            endTime: iso8601Formatter.string(from: request.endDate)
        )
    }
    
    /// 标记计划为完成
    func completePlan(planId: Int) async throws -> PlanNew {
        return try await updatePlan(planId: planId, status: "completed")
    }
    
    /// 标记计划为进行中
    func startPlan(planId: Int) async throws -> PlanNew {
        return try await updatePlan(planId: planId, status: "in_progress")
    }
    
    /// 暂停计划
    func pausePlan(planId: Int) async throws -> PlanNew {
        return try await updatePlan(planId: planId, status: "paused")
    }
}

// MARK: - 计划请求模型扩展
extension PlanRequestNew {
    /// 从字典创建计划请求
    static func from(dict: [String: Any]) -> PlanRequestNew? {
        guard let title = dict["title"] as? String else { return nil }

        let description = dict["description"] as? String ?? ""
        let category = dict["category"] as? String ?? "其他"
        let goals = dict["goals"] as? [String] ?? []

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startDate = (dict["startDate"] as? String).flatMap { dateFormatter.date(from: $0) } ?? Date()

        // 根据预估时间计算结束时间，如果没有预估时间则默认30天
        let endDate: Date
        if let endDateString = dict["endDate"] as? String,
           let parsedEndDate = dateFormatter.date(from: endDateString) {
            endDate = parsedEndDate
        } else if let estimatedMinutes = dict["estimatedTime"] as? Int {
            // 根据预估时间计算结束时间
            let estimatedTimeInSeconds = TimeInterval(estimatedMinutes * 60)
            endDate = startDate.addingTimeInterval(estimatedTimeInSeconds)
        } else {
            // 默认30天
            endDate = Date().addingTimeInterval(86400 * 30)
        }

        return PlanRequestNew(
            title: title,
            description: description,
            category: category,
            startDate: startDate,
            endDate: endDate,
            goals: goals,
            reminderTime: nil
        )
    }
}

// MARK: - 响应模型

struct PlanResponseNew: Codable {
    let status: String
    let data: PlanDataNew?

    var success: Bool {
        return status == "success"
    }

    var message: String {
        return success ? "获取成功" : "获取失败"
    }
}

struct PlanDataNew: Codable {
    let plan: PlanNew
}

struct PlanListResponseNew: Codable {
    let status: String
    let data: PlanListDataNew?

    var success: Bool {
        return status == "success"
    }

    var message: String {
        return success ? "获取成功" : "获取失败"
    }
}

struct PlanListDataNew: Codable {
    let plans: [PlanNew]
    let pagination: PlanPaginationInfo
}

struct PlanCreateResponseNew: Codable {
    let status: String
    let message: String
    let data: PlanCreateDataNew?

    var success: Bool {
        return status == "success"
    }
}

struct PlanCreateDataNew: Codable {
    let plan: PlanNew
}

struct PlanUpdateResponseNew: Codable {
    let status: String
    let message: String
    let data: PlanUpdateDataNew?

    var success: Bool {
        return status == "success"
    }
}

struct PlanUpdateDataNew: Codable {
    let plan: PlanNew
}

struct PlanDeleteResponseNew: Codable {
    let status: String
    let message: String

    var success: Bool {
        return status == "success"
    }
}

struct PlanPaginationInfo: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalPlans: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
}

struct PlanStatisticsResponseNew: Codable {
    let status: String
    let data: PlanStatisticsDataNew?

    var success: Bool {
        return status == "success"
    }

    var message: String {
        return success ? "获取成功" : "获取失败"
    }
}

struct PlanStatisticsDataNew: Codable {
    let statistics: PlanStatisticsNew
}
