import Foundation

class CreatorAPIService {
    static let shared = CreatorAPIService()

    private let networkManager = NetworkManager.shared
    private let authManager = AuthManager.shared

    private enum Endpoint {
        static let worksOverview = "/creator/works/overview"
        static let works = "/creator/works"
        static let statistics = "/creator/statistics"
        static let audienceAnalysis = "/creator/audience-analysis"
        static let activities = "/creator/activities"
        static let activitiesHot = "/creator/activities/hot"
        static let activitiesParticipated = "/creator/activities/participated"
        static let collections = "/creator/collections"
    }

    struct WorksListData: Codable {
        let works: [Work]
        let pagination: SimplePagination
    }

    struct ActivitiesListData: Codable {
        let activities: [Activity]
        let pagination: SimplePagination?
    }

    struct CollectionsListData: Codable {
        let collections: [CollectionItem]
        let pagination: SimplePagination
    }

    struct CollectionItem: Codable, Identifiable {
        let id: String
        let type: String
        let title: String
        let description: String?
        let coverImage: String?
        let postsCount: Int?
        let worksCount: Int?
        let viewsCount: Int?
        let likesCount: Int?
        let subscribersCount: Int?
        let status: String
        let visibility: String
        let createdAt: String
    }

    struct SimplePagination: Codable {
        let total: Int
        let page: Int
        let limit: Int
        let totalPages: Int
    }

    private init() {}

    func fetchWorksOverview() async throws -> CreatorWorksOverview {
        let headers = authManager.getAuthHeader()
        let response: APIResponse<CreatorWorksOverview> = try await networkManager.get(
            endpoint: Endpoint.worksOverview,
            headers: headers,
            responseType: APIResponse<CreatorWorksOverview>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取作品概览失败")
        }
        return data
    }

    func fetchStatistics(days: Int = 7) async throws -> CreatorStatisticsData {
        let parameters: [String: Any] = ["days": days]
        let headers = authManager.getAuthHeader()
        let response: APIResponse<CreatorStatisticsData> = try await networkManager.get(
            endpoint: Endpoint.statistics,
            parameters: parameters,
            headers: headers,
            responseType: APIResponse<CreatorStatisticsData>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取统计数据失败")
        }
        return data
    }

    func fetchAudienceAnalysis(days: Int = 7, postId: String? = nil) async throws -> AudienceAnalysisData {
        var parameters: [String: Any] = ["days": days]
        if let postId = postId { parameters["postId"] = postId }
        let headers = authManager.getAuthHeader()
        let response: APIResponse<AudienceAnalysisData> = try await networkManager.get(
            endpoint: Endpoint.audienceAnalysis,
            parameters: parameters,
            headers: headers,
            responseType: APIResponse<AudienceAnalysisData>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取用户画像失败")
        }
        return data
    }

    func fetchWorks(status: String = "all", page: Int = 1, limit: Int = 20, sortBy: String = "createdAt", sortOrder: String = "DESC") async throws -> [Work] {
        let parameters: [String: Any] = [
            "status": status,
            "page": page,
            "limit": limit,
            "sortBy": sortBy,
            "sortOrder": sortOrder
        ]
        let headers = authManager.getAuthHeader()
        let response: APIResponse<WorksListData> = try await networkManager.get(
            endpoint: Endpoint.works,
            parameters: parameters,
            headers: headers,
            responseType: APIResponse<WorksListData>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取作品列表失败")
        }
        return data.works
    }

    func fetchActivities(category: String? = nil, status: String = "ongoing", page: Int = 1, limit: Int = 20) async throws -> [Activity] {
        var parameters: [String: Any] = [
            "status": status,
            "page": page,
            "limit": limit
        ]
        if let category = category { parameters["category"] = category }
        let headers = authManager.getAuthHeader()
        let response: APIResponse<ActivitiesListData> = try await networkManager.get(
            endpoint: Endpoint.activities,
            parameters: parameters,
            headers: headers,
            responseType: APIResponse<ActivitiesListData>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取活动列表失败")
        }
        return data.activities
    }

    func fetchParticipatedActivities(page: Int = 1, limit: Int = 20) async throws -> [Activity] {
        let parameters: [String: Any] = ["page": page, "limit": limit]
        let headers = authManager.getAuthHeader()
        let response: APIResponse<ActivitiesListData> = try await networkManager.get(
            endpoint: Endpoint.activitiesParticipated,
            parameters: parameters,
            headers: headers,
            responseType: APIResponse<ActivitiesListData>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取参与活动失败")
        }
        return data.activities
    }

    // MARK: - 专栏/合集管理

    /// 创建专栏/合集
    func createCollection(request: CreateCollectionRequest) async throws -> CollectionItem {
        let headers = authManager.getAuthHeader()
        let response: APIResponse<CollectionItem> = try await networkManager.post(
            endpoint: Endpoint.collections,
            parameters: try request.toDictionary(),
            headers: headers,
            responseType: APIResponse<CollectionItem>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "创建失败")
        }
        return data
    }

    /// 获取专栏/合集列表
    func fetchCollections(type: String? = nil, page: Int = 1, limit: Int = 20) async throws -> [CollectionItem] {
        var parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        if let type = type {
            parameters["type"] = type
        }
        let headers = authManager.getAuthHeader()
        let response: APIResponse<CollectionsListData> = try await networkManager.get(
            endpoint: Endpoint.collections,
            parameters: parameters,
            headers: headers,
            responseType: APIResponse<CollectionsListData>.self
        )
        guard response.success, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取列表失败")
        }
        return data.collections
    }
}

// MARK: - 请求数据模型

/// 创建专栏/合集请求
struct CreateCollectionRequest: Codable {
    let type: String
    let title: String
    let description: String?
    let coverImage: String?
    let visibility: String?

    func toDictionary() throws -> [String: Any] {
        var dict: [String: Any] = [
            "type": type,
            "title": title
        ]
        if let description = description {
            dict["description"] = description
        }
        if let coverImage = coverImage {
            dict["coverImage"] = coverImage
        }
        if let visibility = visibility {
            dict["visibility"] = visibility
        }
        return dict
    }
}

