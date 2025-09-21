# 青禾计划 - 社区话题标签API文档 (iOS对接版)

## 概述

社区话题标签系统为iOS应用提供完整的标签管理功能，包括标签浏览、搜索、热门推荐和帖子筛选等功能。基于服务器实际API测试验证。

**API基础地址**: `https://api.qinghejihua.com.cn`

## 认证

所有API请求需要在请求头中包含JWT Token（部分接口支持可选认证）：

```
Authorization: Bearer <your_jwt_token>
```

## 核心API接口

### 1. 获取所有标签

**接口**: `GET /api/v1/community/tags`

**描述**: 获取系统中所有可用的话题标签，支持搜索和分页

**认证**: 可选

**请求参数**:
- `limit` (可选): 返回数量限制，默认50，最大100
- `search` (可选): 搜索关键词，支持标签名称模糊搜索

**请求示例**:
```
GET /api/v1/community/tags?limit=20&search=学习
```

**响应格式**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "学习",
      "description": "学习相关的话题和讨论",
      "color": "#FF6B6B",
      "icon": "📚",
      "postCount": "0",
      "createdAt": "2025-08-17 08:44:53"
    },
    {
      "id": 2,
      "name": "生活",
      "description": "日常生活分享和经验",
      "color": "#4ECDC4",
      "icon": "🏠",
      "postCount": "0",
      "createdAt": "2025-08-17 08:44:53"
    }
  ]
}
```

### 2. 获取热门标签

**接口**: `GET /api/v1/community/tags/popular`

**描述**: 获取最近一段时间内最热门的标签，按帖子数量和用户参与度排序

**认证**: 可选

**请求参数**:
- `limit` (可选): 返回数量限制，默认20
- `days` (可选): 统计天数，默认30天

**请求示例**:
```
GET /api/v1/community/tags/popular?limit=10&days=7
```

**响应格式**:
```json
{
  "success": true,
  "data": [
    {
      "id": 9,
      "name": "读书",
      "description": "读书心得和书籍推荐",
      "color": "#8D6E63",
      "icon": "📖",
      "postCount": "0",
      "userCount": "0"
    }
  ],
  "meta": {
    "limit": 10,
    "days": 7
  }
}
```

### 3. 获取标签建议

**接口**: `GET /api/v1/community/tags/suggestions`

**描述**: 根据输入内容获取标签建议，用于发帖时的标签自动补全

**认证**: 可选

**请求参数**:
- `query` (必填): 搜索查询词
- `limit` (可选): 返回数量限制，默认10

**请求示例**:
```
GET /api/v1/community/tags/suggestions?query=学&limit=5
```

**响应格式**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "学习",
      "description": "学习相关的话题和讨论",
      "color": "#FF6B6B",
      "icon": "📚",
      "postCount": "15"
    }
  ]
}
```

**注意**: 当query为空时，返回空数组

### 4. 获取用户常用标签

**接口**: `GET /api/v1/community/tags/user-frequent`

**描述**: 获取当前用户最常使用的标签，按使用频率排序

**认证**: 必须提供JWT Token

**请求参数**:
- `limit` (可选): 返回数量限制，默认15

**请求示例**:
```
GET /api/v1/community/tags/user-frequent?limit=10
Authorization: Bearer <jwt_token>
```

**响应格式**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "学习",
      "description": "学习相关的话题和讨论",
      "color": "#FF6B6B",
      "icon": "📚",
      "usageCount": "5",
      "lastUsed": "2025-01-15T10:30:00.000Z"
    }
  ]
}
```

### 5. 获取标签下的帖子

**接口**: `GET /api/v1/community/tags/{tagName}/posts`

**描述**: 获取指定标签下的所有帖子，支持多种排序方式

**认证**: 可选

**请求参数**:
- `tagName` (路径参数): 标签名称，支持中文和带#号的标签
- `page` (可选): 页码，默认1
- `limit` (可选): 每页数量，默认20
- `sortBy` (可选): 排序方式，可选值：
  - `latest`: 最新发布 (默认)
  - `hot`: 热度排序
  - `popular`: 受欢迎程度

**请求示例**:
```
GET /api/v1/community/tags/学习/posts?page=1&limit=10&sortBy=hot
GET /api/v1/community/tags/%23学习/posts  // URL编码的#学习
```

**响应格式**:
```json
{
  "success": true,
  "data": {
    "tagName": "学习",
    "items": [],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": "0",
      "totalPages": 0,
      "hasNext": false,
      "hasPrev": false
    }
  }
}
```

## 数据结构说明

### 标签对象 (Tag)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Number | 标签唯一ID |
| name | String | 标签名称 |
| description | String | 标签描述 |
| color | String | 标签颜色 (十六进制) |
| icon | String | 标签图标 (Emoji或图标名) |
| postCount | String | 使用该标签的帖子数量 |
| userCount | String | 使用该标签的用户数量 (仅热门标签) |
| usageCount | String | 用户使用次数 (仅用户常用标签) |
| lastUsed | String | 最后使用时间 (仅用户常用标签) |
| createdAt | String | 标签创建时间 |

## 错误处理

### 常见错误码

| 状态码 | 错误类型 | 说明 |
|--------|----------|------|
| 400 | Bad Request | 请求参数错误 |
| 401 | Unauthorized | 未提供或无效的JWT Token |
| 404 | Not Found | 标签或资源未找到 |
| 500 | Internal Server Error | 服务器内部错误 |

### 错误响应格式

```json
{
  "success": false,
  "message": "标签名称不能为空"
}
```

## 实际测试结果

基于服务器实际测试，以下是API的真实表现：

### 1. 可用标签数据
当前系统中包含以下预设标签：
- 学习 (#FF6B6B, 📚)
- 生活 (#4ECDC4, 🏠) 
- 旅行 (#66BB6A, ✈️)
- 工作 (#78909C, 💼)
- 电影 (#5C6BC0, 🎬)
- 音乐 (#AB47BC, 🎵)
- 读书 (#8D6E63, 📖)

### 2. 注意事项
- 所有标签的 `postCount` 当前为 "0"
- 标签建议API需要非空query参数
- 中文标签名在URL中需要正确编码
- 用户常用标签需要JWT认证

## iOS Swift 集成示例

### 1. 数据模型定义

```swift
// 标签模型
struct Tag: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let color: String
    let icon: String
    let postCount: String
    let userCount: String?
    let usageCount: String?
    let lastUsed: String?
    let createdAt: String

    // 计算属性：转换颜色
    var uiColor: UIColor {
        return UIColor(hex: color) ?? .systemBlue
    }

    // 计算属性：格式化帖子数量
    var formattedPostCount: String {
        let count = Int(postCount) ?? 0
        if count >= 1000 {
            return "\(count/1000)k"
        }
        return postCount
    }
}

// 标签响应模型
struct TagsResponse: Codable {
    let success: Bool
    let data: [Tag]
    let meta: TagsMeta?
}

struct TagsMeta: Codable {
    let limit: Int
    let days: Int?
}

// 标签帖子响应模型
struct TagPostsResponse: Codable {
    let success: Bool
    let data: TagPostsData
}

struct TagPostsData: Codable {
    let tagName: String
    let items: [Post]
    let pagination: Pagination
}

struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: String
    let totalPages: Int
    let hasNext: Bool
    let hasPrev: Bool
}
```

### 2. API服务类

```swift
class TagsAPIService {
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1/community"
    private let session = URLSession.shared

    // 获取所有标签
    func getAllTags(limit: Int = 50, search: String? = nil) async throws -> [Tag] {
        var components = URLComponents(string: "\(baseURL)/tags")!
        var queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]

        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        components.queryItems = queryItems

        let request = URLRequest(url: components.url!)
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(TagsResponse.self, from: data)

        guard response.success else {
            throw APIError.requestFailed
        }

        return response.data
    }

    // 获取热门标签
    func getPopularTags(limit: Int = 20, days: Int = 30) async throws -> [Tag] {
        var components = URLComponents(string: "\(baseURL)/tags/popular")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "days", value: "\(days)")
        ]

        let request = URLRequest(url: components.url!)
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(TagsResponse.self, from: data)

        guard response.success else {
            throw APIError.requestFailed
        }

        return response.data
    }

    // 获取标签建议
    func getTagSuggestions(query: String, limit: Int = 10) async throws -> [Tag] {
        guard !query.isEmpty else { return [] }

        var components = URLComponents(string: "\(baseURL)/tags/suggestions")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        let request = URLRequest(url: components.url!)
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(TagsResponse.self, from: data)

        guard response.success else {
            throw APIError.requestFailed
        }

        return response.data
    }

    // 获取用户常用标签
    func getUserFrequentTags(limit: Int = 15) async throws -> [Tag] {
        var components = URLComponents(string: "\(baseURL)/tags/user-frequent")!
        components.queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(AuthManager.shared.token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(TagsResponse.self, from: data)

        guard response.success else {
            throw APIError.requestFailed
        }

        return response.data
    }

    // 获取标签下的帖子
    func getTagPosts(tagName: String, page: Int = 1, limit: Int = 20, sortBy: String = "latest") async throws -> TagPostsData {
        let encodedTagName = tagName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tagName

        var components = URLComponents(string: "\(baseURL)/tags/\(encodedTagName)/posts")!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sortBy", value: sortBy)
        ]

        let request = URLRequest(url: components.url!)
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(TagPostsResponse.self, from: data)

        guard response.success else {
            throw APIError.requestFailed
        }

        return response.data
    }
}

enum APIError: Error {
    case requestFailed
    case invalidResponse
    case networkError
}
```

### 3. SwiftUI视图示例

```swift
// 标签选择视图
struct TagSelectionView: View {
    @StateObject private var viewModel = TagSelectionViewModel()
    @State private var searchText = ""
    let onTagSelected: (Tag) -> Void

    var body: some View {
        NavigationView {
            VStack {
                // 搜索栏
                SearchBar(text: $searchText, onSearchButtonClicked: {
                    Task {
                        await viewModel.searchTags(query: searchText)
                    }
                })

                // 热门标签
                if searchText.isEmpty {
                    VStack(alignment: .leading) {
                        Text("热门标签")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(viewModel.popularTags) { tag in
                                    TagChip(tag: tag) {
                                        onTagSelected(tag)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // 标签列表
                List(viewModel.tags) { tag in
                    TagRow(tag: tag) {
                        onTagSelected(tag)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("选择标签")
            .task {
                await viewModel.loadInitialData()
            }
        }
    }
}

// 标签芯片组件
struct TagChip: View {
    let tag: Tag
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(tag.icon)
                    .font(.caption)
                Text(tag.name)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(tag.formattedPostCount)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(tag.uiColor.opacity(0.1))
            .foregroundColor(tag.uiColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(tag.uiColor.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// 标签行组件
struct TagRow: View {
    let tag: Tag
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // 标签图标
                Text(tag.icon)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(tag.uiColor.opacity(0.1))
                    .foregroundColor(tag.uiColor)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tag.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(tag.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(tag.formattedPostCount)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text("帖子")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

### 4. ViewModel示例

```swift
@MainActor
class TagSelectionViewModel: ObservableObject {
    @Published var tags: [Tag] = []
    @Published var popularTags: [Tag] = []
    @Published var isLoading = false

    private let apiService = TagsAPIService()

    func loadInitialData() async {
        isLoading = true

        async let allTags = apiService.getAllTags(limit: 50)
        async let popularTags = apiService.getPopularTags(limit: 10)

        do {
            let (tags, popular) = try await (allTags, popularTags)
            self.tags = tags
            self.popularTags = popular
        } catch {
            print("加载标签数据失败: \(error)")
        }

        isLoading = false
    }

    func searchTags(query: String) async {
        guard !query.isEmpty else {
            await loadInitialData()
            return
        }

        do {
            let suggestions = try await apiService.getTagSuggestions(query: query)
            self.tags = suggestions
        } catch {
            print("搜索标签失败: \(error)")
        }
    }
}
```

## 使用建议

### 1. 标签显示优化
- 使用标签的 `color` 字段设置UI颜色主题
- 优先显示 `icon` 字段的Emoji图标
- 对于大数量的 `postCount`，建议格式化显示（如1.2k）

### 2. 搜索体验优化
- 实现搜索防抖，避免频繁请求
- 缓存热门标签，减少网络请求
- 支持最近使用标签的本地缓存

### 3. 性能优化
- 使用分页加载标签下的帖子
- 实现标签数据的本地缓存
- 对于用户常用标签，可以预加载

### 4. 用户体验
- 支持标签的多选功能
- 提供标签的快速输入和自动补全
- 显示标签的使用统计信息

---

**文档版本**: v1.0
**最后更新**: 2025-01-18
**基于服务器**: 123.57.205.94
**联系方式**: 如有问题请联系后端开发团队
