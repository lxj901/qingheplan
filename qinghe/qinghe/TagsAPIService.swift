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

// 后端标签DTO（与服务器返回一致）
struct TagDTO: Codable {
    let id: Int
    let name: String
    let description: String?
    let color: String?
    let icon: String?
    let postCount: String?
    let userCount: String?
    let usageCount: String?
    let lastUsed: String?
    let createdAt: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, description, color, icon, postCount, userCount, usageCount, lastUsed, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        // 计数字段兼容字符串或数字
        if let s = try? container.decode(String.self, forKey: .postCount) {
            postCount = s
        } else if let i = try? container.decode(Int.self, forKey: .postCount) {
            postCount = String(i)
        } else {
            postCount = nil
        }
        if let s = try? container.decode(String.self, forKey: .userCount) {
            userCount = s
        } else if let i = try? container.decode(Int.self, forKey: .userCount) {
            userCount = String(i)
        } else {
            userCount = nil
        }
        if let s = try? container.decode(String.self, forKey: .usageCount) {
            usageCount = s
        } else if let i = try? container.decode(Int.self, forKey: .usageCount) {
            usageCount = String(i)
        } else {
            usageCount = nil
        }
        lastUsed = try container.decodeIfPresent(String.self, forKey: .lastUsed)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
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
            let count = Int(t.userCount ?? t.postCount ?? "0") ?? 0
            // 简单规则：前3个标记为 trending
            return PopularTag(tag: t.name, count: count, trending: idx < 3)
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
            let count = Int(t.usageCount ?? t.postCount ?? "0") ?? 0
            return UserTag(tag: t.name, count: count, lastUsed: t.lastUsed)
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
                tag: t.name,
                relevance: 1.0 - Double(idx) * 0.05,
                category: t.icon // 临时把 icon 放在 category 字段里占位（UI未使用）
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
