# 白噪音 API 文档

## 基础信息

- **基础 URL**: `https://api.qinghejihua.com.cn`
- **API 前缀**: `/api/v1`
- **响应格式**: JSON
- **字符编码**: UTF-8

## 通用响应格式

### 成功响应
```json
{
  "success": true,
  "data": { ... }
}
```

### 错误响应
```json
{
  "success": false,
  "message": "错误信息",
  "error": "详细错误描述"
}
```

## API 端点

### 1. 获取白噪音列表

获取白噪音列表，支持分页、筛选、排序和搜索。

**请求**
```
GET /api/v1/white-noise
```

**查询参数**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| category | string | 否 | - | 分类筛选（见分类列表） |
| page | integer | 否 | 1 | 页码 |
| limit | integer | 否 | 20 | 每页数量 |
| sort | string | 否 | created_at | 排序字段：created_at, play_count, like_count, title, duration |
| order | string | 否 | DESC | 排序方向：ASC, DESC |
| search | string | 否 | - | 搜索关键词（搜索标题、描述、标签） |

**响应示例**
```json
{
  "success": true,
  "data": {
    "list": [
      {
        "id": 1,
        "title": "丛林夜晚的溪水",
        "category": "四季-冬",
        "duration": 218,
        "audioUrl": "http://qinghe-uploads.oss-cn-beijing.aliyuncs.com/white-noise/audio/四季-冬/1759991028444_ce8b94ba.mp3",
        "coverUrl": "http://qinghe-uploads.oss-cn-beijing.aliyuncs.com/white-noise/covers/四季-冬/1759991028575_f2a15d2a.jpg",
        "playCount": 0,
        "likeCount": 0,
        "tags": null,
        "description": "",
        "format": "mp3",
        "createdAt": "2025-10-09T03:50:28.000Z"
      }
    ],
    "pagination": {
      "total": 162,
      "page": 1,
      "limit": 20,
      "pages": 9
    }
  }
}
```

**iOS 示例代码**
```swift
func getWhiteNoiseList(category: String? = nil, page: Int = 1, limit: Int = 20) {
    var components = URLComponents(string: "https://api.qinghejihua.com.cn/api/v1/white-noise")!

    var queryItems: [URLQueryItem] = [
        URLQueryItem(name: "page", value: String(page)),
        URLQueryItem(name: "limit", value: String(limit))
    ]

    if let category = category {
        queryItems.append(URLQueryItem(name: "category", value: category))
    }

    components.queryItems = queryItems

    URLSession.shared.dataTask(with: components.url!) { data, response, error in
        // 处理响应
    }.resume()
}
```

---

### 2. 获取白噪音详情

获取指定白噪音的详细信息。

**请求**
```
GET /api/v1/white-noise/:id
```

**路径参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | integer | 是 | 白噪音 ID |

**响应示例**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "丛林夜晚的溪水",
    "category": "四季-冬",
    "duration": 218,
    "audioUrl": "http://qinghe-uploads.oss-cn-beijing.aliyuncs.com/white-noise/audio/四季-冬/1759991028444_ce8b94ba.mp3",
    "coverUrl": "http://qinghe-uploads.oss-cn-beijing.aliyuncs.com/white-noise/covers/四季-冬/1759991028575_f2a15d2a.jpg",
    "playCount": 0,
    "likeCount": 0,
    "tags": null,
    "description": "",
    "format": "mp3",
    "fileSize": 5242880,
    "createdAt": "2025-10-09T03:50:28.000Z",
    "updatedAt": "2025-10-09T03:50:28.000Z"
  }
}
```

**iOS 示例代码**
```swift
func getWhiteNoiseDetail(id: Int) {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/white-noise/\(id)")!

    URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data else { return }
        // 解析 JSON 响应
    }.resume()
}
```

---

### 3. 获取分类列表

获取所有白噪音分类及统计信息。

**请求**
```
GET /api/v1/white-noise/categories
```

**响应示例**
```json
{
  "success": true,
  "data": [
    {
      "category": "四季-冬",
      "name": "冬季自然声音",
      "count": 15,
      "totalPlays": 0
    },
    {
      "category": "四季-夏",
      "name": "夏季自然声音",
      "count": 15,
      "totalPlays": 0
    },
    {
      "category": "四季-春",
      "name": "春季自然声音",
      "count": 15,
      "totalPlays": 0
    },
    {
      "category": "四季-秋",
      "name": "秋季自然声音",
      "count": 13,
      "totalPlays": 0
    },
    {
      "category": "时钟-午间",
      "name": "午间休憩",
      "count": 15,
      "totalPlays": 0
    },
    {
      "category": "时钟-夜晚",
      "name": "夜晚安眠",
      "count": 15,
      "totalPlays": 0
    },
    {
      "category": "时钟-清晨",
      "name": "清晨时光",
      "count": 15,
      "totalPlays": 0
    },
    {
      "category": "时钟-黎明",
      "name": "黎明时分",
      "count": 15,
      "totalPlays": 0
    },
    {
      "category": "自然声音",
      "name": "纯净自然",
      "count": 15,
      "totalPlays": 0
    },
    {
      "category": "音乐旋律",
      "name": "轻柔旋律",
      "count": 13,
      "totalPlays": 0
    },
    {
      "category": "首页",
      "name": "精选推荐",
      "count": 16,
      "totalPlays": 0
    }
  ]
}
```

**iOS 示例代码**
```swift
struct Category: Codable {
    let category: String
    let name: String
    let count: Int
    let totalPlays: Int
}

func getCategories() {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/white-noise/categories")!

    URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data else { return }

        if let response = try? JSONDecoder().decode(APIResponse<[Category]>.self, from: data) {
            // 使用分类数据
            print(response.data)
        }
    }.resume()
}
```

---

### 4. 获取热门白噪音

获取播放量和点赞量最高的白噪音列表。

**请求**
```
GET /api/v1/white-noise/popular
```

**查询参数**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| limit | integer | 否 | 10 | 返回数量 |
| category | string | 否 | - | 指定分类 |

**响应示例**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "丛林夜晚的溪水",
      "category": "四季-冬",
      "duration": 218,
      "audioUrl": "http://qinghe-uploads.oss-cn-beijing.aliyuncs.com/white-noise/audio/四季-冬/1759991028444_ce8b94ba.mp3",
      "coverUrl": "http://qinghe-uploads.oss-cn-beijing.aliyuncs.com/white-noise/covers/四季-冬/1759991028575_f2a15d2a.jpg",
      "playCount": 100,
      "likeCount": 50,
      "tags": null,
      "description": ""
    }
  ]
}
```

**iOS 示例代码**
```swift
func getPopularWhiteNoise(limit: Int = 10, category: String? = nil) {
    var components = URLComponents(string: "https://api.qinghejihua.com.cn/api/v1/white-noise/popular")!

    var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
    if let category = category {
        queryItems.append(URLQueryItem(name: "category", value: category))
    }
    components.queryItems = queryItems

    URLSession.shared.dataTask(with: components.url!) { data, response, error in
        // 处理响应
    }.resume()
}
```

---

### 5. 搜索白噪音

根据关键词搜索白噪音。

**请求**
```
GET /api/v1/white-noise/search
```

**查询参数**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| q | string | 是 | - | 搜索关键词 |
| page | integer | 否 | 1 | 页码 |
| limit | integer | 否 | 20 | 每页数量 |

**响应示例**
```json
{
  "success": true,
  "data": {
    "keyword": "雨",
    "list": [
      {
        "id": 9,
        "title": "池塘里的小雨",
        "category": "四季-冬",
        "duration": 116,
        "audioUrl": "http://qinghe-uploads.oss-cn-beijing.aliyuncs.com/white-noise/audio/四季-冬/1759991029297_00e74225.mp3",
        "coverUrl": "http://qinghe-uploads.oss-cn-beijing.aliyuncs.com/white-noise/covers/四季-冬/1759991029403_cc6f6fa9.jpg",
        "playCount": 0,
        "likeCount": 0,
        "tags": null,
        "description": ""
      }
    ],
    "pagination": {
      "total": 8,
      "page": 1,
      "limit": 20,
      "pages": 1
    }
  }
}
```

**iOS 示例代码**
```swift
func searchWhiteNoise(keyword: String, page: Int = 1) {
    var components = URLComponents(string: "https://api.qinghejihua.com.cn/api/v1/white-noise/search")!
    components.queryItems = [
        URLQueryItem(name: "q", value: keyword),
        URLQueryItem(name: "page", value: String(page))
    ]

    URLSession.shared.dataTask(with: components.url!) { data, response, error in
        // 处理搜索结果
    }.resume()
}
```

---

### 6. 记录播放

记录白噪音播放次数。

**请求**
```
POST /api/v1/white-noise/:id/play
```

**路径参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | integer | 是 | 白噪音 ID |

**响应示例**
```json
{
  "success": true,
  "message": "播放记录成功",
  "data": {
    "id": 1,
    "playCount": 101
  }
}
```

**iOS 示例代码**
```swift
func recordPlay(id: Int) {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/white-noise/\(id)/play")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    URLSession.shared.dataTask(with: request) { data, response, error in
        // 处理响应
    }.resume()
}
```

---

### 7. 获取推荐白噪音

获取推荐的白噪音列表。

**请求**
```
GET /api/v1/white-noise/recommendations
```

**查询参数**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| limit | integer | 否 | 6 | 返回数量 |

**响应示例**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "丛林夜晚的溪水",
      "category": "四季-冬",
      "duration": 218,
      "audioUrl": "http://qinghe-uploads.oss-cn-beijing.aliyuncs.com/white-noise/audio/四季-冬/1759991028444_ce8b94ba.mp3",
      "coverUrl": "http://qinghe-uploads.oss-cn-beijing.aliyuncs.com/white-noise/covers/四季-冬/1759991028575_f2a15d2a.jpg",
      "playCount": 100,
      "likeCount": 50,
      "tags": null,
      "description": ""
    }
  ]
}
```

**iOS 示例代码**
```swift
func getRecommendations(limit: Int = 6) {
    var components = URLComponents(string: "https://api.qinghejihua.com.cn/api/v1/white-noise/recommendations")!
    components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]

    URLSession.shared.dataTask(with: components.url!) { data, response, error in
        // 处理推荐数据
    }.resume()
}
```

---

### 8. 获取统计信息

获取白噪音的统计信息，包括数据库统计和存储统计。

**请求**
```
GET /api/v1/white-noise/stats
```

**响应示例**
```json
{
  "success": true,
  "data": {
    "database": {
      "totalCount": 162,
      "totalPlays": 1000,
      "totalLikes": 500,
      "categories": [
        {
          "category": "四季-冬",
          "count": "15"
        }
      ]
    },
    "storage": {
      "totalSize": 850000000,
      "totalFiles": 324,
      "audioFiles": 162,
      "coverFiles": 162
    }
  }
}
```

**iOS 示例代码**
```swift
func getStats() {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/white-noise/stats")!

    URLSession.shared.dataTask(with: url) { data, response, error in
        // 处理统计数据
    }.resume()
}
```

---

## 数据模型

### WhiteNoise 对象

| 字段 | 类型 | 说明 |
|------|------|------|
| id | integer | 白噪音 ID |
| title | string | 标题 |
| category | string | 分类（见分类列表） |
| duration | integer | 时长（秒） |
| audioUrl | string | 音频文件 URL (MP3 格式) |
| coverUrl | string | 封面图片 URL (JPG 格式) |
| playCount | integer | 播放次数 |
| likeCount | integer | 点赞次数 |
| tags | array | 标签数组（可为 null） |
| description | string | 描述 |
| format | string | 音频格式（默认 "mp3"） |
| fileSize | integer | 文件大小（字节） |
| createdAt | string | 创建时间（ISO 8601 格式） |
| updatedAt | string | 更新时间（ISO 8601 格式） |

### 分类列表

| 分类代码 | 分类名称 | 说明 |
|---------|---------|------|
| 四季-春 | 春季自然声音 | 15 条 |
| 四季-夏 | 夏季自然声音 | 15 条 |
| 四季-秋 | 秋季自然声音 | 13 条 |
| 四季-冬 | 冬季自然声音 | 15 条 |
| 时钟-清晨 | 清晨时光 | 15 条 |
| 时钟-黎明 | 黎明时分 | 15 条 |
| 时钟-午间 | 午间休憩 | 15 条 |
| 时钟-夜晚 | 夜晚安眠 | 15 条 |
| 自然声音 | 纯净自然 | 15 条 |
| 音乐旋律 | 轻柔旋律 | 13 条 |
| 首页 | 精选推荐 | 16 条 |

---

## 错误码

| HTTP 状态码 | 说明 |
|------------|------|
| 200 | 请求成功 |
| 400 | 请求参数错误 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

---

## 完整 iOS 集成示例

```swift
import Foundation

// MARK: - API 响应模型
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
    let message: String?
}

// MARK: - 白噪音数据模型
struct WhiteNoise: Codable {
    let id: Int
    let title: String
    let category: String
    let duration: Int
    let audioUrl: String
    let coverUrl: String
    let playCount: Int
    let likeCount: Int
    let tags: [String]?
    let description: String
    let format: String
    let fileSize: Int?
    let createdAt: String
    let updatedAt: String?
}

// MARK: - 分页数据模型
struct PaginatedResponse<T: Codable>: Codable {
    let list: [T]
    let pagination: Pagination
}

struct Pagination: Codable {
    let total: Int
    let page: Int
    let limit: Int
    let pages: Int
}

// MARK: - 白噪音 API 服务
class WhiteNoiseAPIService {
    static let shared = WhiteNoiseAPIService()
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1"

    // 获取白噪音列表
    func getWhiteNoiseList(
        category: String? = nil,
        page: Int = 1,
        limit: Int = 20,
        completion: @escaping (Result<PaginatedResponse<WhiteNoise>, Error>) -> Void
    ) {
        var components = URLComponents(string: "\(baseURL)/white-noise")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }

        components.queryItems = queryItems

        performRequest(url: components.url!, completion: completion)
    }

    // 获取白噪音详情
    func getWhiteNoiseDetail(
        id: Int,
        completion: @escaping (Result<WhiteNoise, Error>) -> Void
    ) {
        let url = URL(string: "\(baseURL)/white-noise/\(id)")!
        performRequest(url: url, completion: completion)
    }

    // 记录播放
    func recordPlay(
        id: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let url = URL(string: "\(baseURL)/white-noise/\(id)/play")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }.resume()
    }

    // 通用请求方法
    private func performRequest<T: Codable>(
        url: URL,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1)))
                return
            }

            do {
                let apiResponse = try JSONDecoder().decode(APIResponse<T>.self, from: data)
                completion(.success(apiResponse.data))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - 使用示例
class WhiteNoiseViewController: UIViewController {

    func loadWhiteNoiseList() {
        WhiteNoiseAPIService.shared.getWhiteNoiseList(category: "四季-春", page: 1) { result in
            switch result {
            case .success(let paginatedResponse):
                DispatchQueue.main.async {
                    // 更新 UI
                    print("获取到 \(paginatedResponse.list.count) 条白噪音")
                    print("总共 \(paginatedResponse.pagination.total) 条")
                }
            case .failure(let error):
                print("加载失败: \(error)")
            }
        }
    }

    func playWhiteNoise(id: Int) {
        // 获取详情
        WhiteNoiseAPIService.shared.getWhiteNoiseDetail(id: id) { result in
            switch result {
            case .success(let whiteNoise):
                // 播放音频
                self.playAudio(url: whiteNoise.audioUrl)

                // 记录播放
                WhiteNoiseAPIService.shared.recordPlay(id: id) { _ in }

            case .failure(let error):
                print("获取详情失败: \(error)")
            }
        }
    }

    private func playAudio(url: String) {
        // 使用 AVPlayer 播放音频
        // 实现音频播放逻辑
    }
}
```

---

## 注意事项

1. **URL 编码**: 中文分类名称需要进行 URL 编码
2. **音频格式**: 所有音频文件均为 MP3 格式
3. **封面图片**: 所有封面图片均为 JPG 格式
4. **OSS 存储**: 音频和封面文件存储在阿里云 OSS (qinghe-uploads bucket)
5. **时间格式**: 所有时间字段使用 ISO 8601 格式（UTC 时间）
6. **播放记录**: 建议在音频播放开始时调用播放记录接口
7. **缓存策略**: 建议缓存分类列表和热门推荐数据
8. **错误处理**: 所有接口都可能返回 500 错误，需要做好错误处理

---

## 更新日志

- **2025-10-09**: 初始版本，包含 8 个 API 端点，162 条白噪音数据
