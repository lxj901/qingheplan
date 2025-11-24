import Foundation

// MARK: - 标签相关模型
struct PopularTag: Codable, Identifiable {
    let id = UUID()
    let tag: String
    let count: Int
    let trending: Bool

    enum CodingKeys: String, CodingKey {
        case tag, count, trending
    }
}

struct UserTag: Codable, Identifiable {
    let id = UUID()
    let tag: String
    let count: Int
    let lastUsed: String?

    enum CodingKeys: String, CodingKey {
        case tag, count
        case lastUsed = "last_used"
    }
}

struct TagSuggestion: Codable, Identifiable {
    let id = UUID()
    let tag: String
    let relevance: Double
    let category: String?

    enum CodingKeys: String, CodingKey {
        case tag, relevance, category
    }
}

// 后端标签DTO（简化版本，匹配实际API返回）
struct TagDTO: Codable {
    let tag: String
    let count: Int

    private enum CodingKeys: String, CodingKey {
        case tag, trend, count
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // tag 字段兼容 "tag" 或 "trend" 两种字段名
        if let tagValue = try? container.decode(String.self, forKey: .tag) {
            tag = tagValue
        } else if let trendValue = try? container.decode(String.self, forKey: .trend) {
            tag = trendValue
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.tag,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Neither 'tag' nor 'trend' key found"
                )
            )
        }

        // count 字段兼容字符串或数字
        if let countInt = try? container.decode(Int.self, forKey: .count) {
            count = countInt
        } else if let countString = try? container.decode(String.self, forKey: .count) {
            count = Int(countString) ?? 0
        } else {
            count = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tag, forKey: .tag)
        try container.encode(count, forKey: .count)
    }
}

// 通用标签列表响应
private struct TagListResponse: Codable {
    let success: Bool
    let data: [TagDTO]?
    let message: String?
    let meta: TagListMeta?
}

private struct TagListMeta: Codable {
    let limit: Int?
    let days: Int?
}


// MARK: - API 响应模型
struct TagsResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
}

struct PopularTagsData: Codable {
    let tags: [PopularTag]
    let total: Int
}

struct UserTagsData: Codable {
    let tags: [UserTag]
    let total: Int
}

struct TagSuggestionsData: Codable {
    let suggestions: [TagSuggestion]
    let total: Int
}

// MARK: - 标签 API 服务
class TagsAPIService: ObservableObject {
    static let shared = TagsAPIService()

    // 统一走全局 NetworkManager，自动带上 baseURL 与认证头
    private let networkManager = NetworkManager.shared
    private let session = URLSession.shared

    private init() {}

    // MARK: - 获取热门标签（真实API）
    func getPopularTags(limit: Int = 20) async throws -> [PopularTag] {
        let parameters: [String: Any] = ["limit": min(limit, 50)]
        let response: TagListResponse = try await networkManager.get(
            endpoint: "/community/tags/popular",
            parameters: parameters,
            headers: nil,
            responseType: TagListResponse.self
        )
        guard response.success, let items = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取热门标签失败")
        }
        // 转为 UI 使用的 PopularTag 模型
        let mapped = items.enumerated().map { idx, t in
            // 简单规则：前3个标记为 trending
            return PopularTag(tag: t.tag, count: t.count, trending: idx < 3)
        }
        return mapped
    }
    // MARK: - 获取全部标签（支持搜索）
    func getAllTags(limit: Int = 50, search: String? = nil) async throws -> [TagDTO] {
        var params: [String: Any] = ["limit": min(limit, 100)]
        if let q = search, !q.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            params["search"] = q
        }
        let response: TagListResponse = try await networkManager.get(
            endpoint: "/community/tags",
            parameters: params,
            headers: nil,
            responseType: TagListResponse.self
        )
        guard response.success, let items = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取标签失败")
        }
        return items
    }


    // MARK: - 获取用户常用标签（真实API，需登录）
    func getUserTags(limit: Int = 10) async throws -> [UserTag] {
        let parameters: [String: Any] = ["limit": min(limit, 50)]
        let response: TagListResponse = try await networkManager.get(
            endpoint: "/community/tags/user-frequent",
            parameters: parameters,
            headers: nil,
            responseType: TagListResponse.self
        )
        guard response.success, let items = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取用户常用标签失败")
        }
        return items.map { t in
            return UserTag(tag: t.tag, count: t.count, lastUsed: nil)
        }
    }

    // MARK: - 搜索标签建议（真实API）
    func searchTagSuggestions(query: String, limit: Int = 10) async throws -> [TagSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let parameters: [String: Any] = [
            "query": trimmed,
            "limit": min(limit, 20)
        ]
        let response: TagListResponse = try await networkManager.get(
            endpoint: "/community/tags/suggestions",
            parameters: parameters,
            headers: nil,
            responseType: TagListResponse.self
        )
        guard response.success, let items = response.data else {
            // 按文档：当query为空时返回空数组；其他失败抛错
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取标签建议失败")
        }
        return items.prefix(limit).enumerated().map { idx, t in
            TagSuggestion(
                tag: t.tag,
                relevance: 1.0 - Double(idx) * 0.05,
                category: nil // 后端没有返回 category 字段
            )
        }
    }

    // MARK: - 私有辅助方法
    private func getCategoryForTag(_ tag: String) -> String {
        switch tag {
        case "健身", "跑步", "运动", "瑜伽", "游泳", "骑行", "徒步":
            return "运动"
        case "美食", "咖啡", "茶", "烘焙", "料理", "甜品":
            return "美食"
        case "旅行", "日本", "韩国", "欧洲", "美国":
            return "旅行"
        case "摄影", "风景", "人像", "街拍", "夜景":
            return "摄影"
        case "读书", "小说", "散文", "诗歌":
            return "阅读"
        case "音乐", "电影", "游戏":
            return "娱乐"
        case "学习", "技术", "编程", "设计":
            return "学习"
        default:
            return "其他"
        }
    }
}

// MARK: - API 配置
struct APIConfig {
    static let baseURL = "https://api.qinghe.com"
    static let isDebugMode = true
}
