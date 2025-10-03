# 青禾计划 - 视频功能API文档 (iOS集成指南)

**Base URL**: `https://api.qinghejihua.com.cn`

**版本**: v1.0
**更新日期**: 2025-10-02

---

## 目录

1. [认证说明](#认证说明)
2. [视频上传](#1-视频上传)
3. [获取视频列表](#2-获取视频列表)
4. [获取视频详情](#3-获取视频详情)
5. [更新视频信息](#4-更新视频信息)
6. [删除视频](#5-删除视频)
7. [获取视频处理状态](#6-获取视频处理状态)
8. [点赞视频](#7-点赞视频)
9. [取消点赞](#8-取消点赞)
10. [收藏视频](#9-收藏视频)
11. [取消收藏](#10-取消收藏)
12. [视频评论](#11-视频评论)
13. [获取评论列表](#12-获取评论列表)
14. [错误代码说明](#错误代码说明)
15. [Swift示例代码](#swift示例代码)

---

## 认证说明

所有需要认证的接口都需要在请求头中携带JWT Token：

```http
Authorization: Bearer {your_jwt_token}
```

---

## 1. 视频上传

上传视频文件到服务器，系统会自动进行审核和转码处理。

### 接口信息

- **URL**: `/api/v1/videos/upload`
- **Method**: `POST`
- **Content-Type**: `multipart/form-data`
- **认证**: 需要

### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| video | File | 是 | 视频文件（最大1GB） |
| title | String | 是 | 视频标题（1-100字符） |
| description | String | 否 | 视频描述（最多500字符） |
| category | String | 否 | 分类（健康/运动/饮食/心理等） |
| tags | String[] | 否 | 标签数组，JSON字符串格式 |

### 支持的视频格式

- MP4 (推荐)
- MOV (QuickTime)
- AVI
- MPEG
- WebM

### 文件大小限制

- **最大**: 1GB (1024MB)
- **推荐**: 200MB以内，获得更好的上传和处理体验

### 响应示例

```json
{
  "status": "success",
  "data": {
    "videoId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "title": "晨练瑜伽教程",
    "originalUrl": "https://qinghe-uploads.oss-cn-beijing.aliyuncs.com/videos/...",
    "duration": 120.5,
    "size": 52428800,
    "resolution": "1920x1080",
    "status": "draft",
    "transcodeStatus": "pending",
    "moderationStatus": "pending",
    "uploadedAt": "2025-10-02T14:30:00.000Z",
    "message": "视频正在审核中，审核通过后可手动发布"
  }
}
```

### 错误响应

```json
{
  "status": "error",
  "message": "文件大小超过限制",
  "code": "FILE_TOO_LARGE"
}
```

### Swift示例代码

```swift
func uploadVideo(videoURL: URL, title: String, description: String?, category: String?, completion: @escaping (Result<VideoUploadResponse, Error>) -> Void) {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/videos/upload")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()

    // 添加视频文件
    if let videoData = try? Data(contentsOf: videoURL) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"video.mp4\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(videoData)
        body.append("\r\n".data(using: .utf8)!)
    }

    // 添加标题
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n".data(using: .utf8)!)
    body.append(title.data(using: .utf8)!)
    body.append("\r\n".data(using: .utf8)!)

    // 添加描述（可选）
    if let description = description {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"description\"\r\n\r\n".data(using: .utf8)!)
        body.append(description.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
    }

    // 添加分类（可选）
    if let category = category {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        body.append(category.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
    }

    body.append("--\(boundary)--\r\n".data(using: .utf8)!)

    // 配置长超时时间（1GB文件需要）
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 600 // 10分钟
    config.timeoutIntervalForResource = 1200 // 20分钟

    let session = URLSession(configuration: config)
    let task = session.uploadTask(with: request, from: body) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: -1)))
            return
        }

        do {
            let result = try JSONDecoder().decode(VideoUploadResponse.self, from: data)
            completion(.success(result))
        } catch {
            completion(.failure(error))
        }
    }

    // 监听上传进度
    let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
        DispatchQueue.main.async {
            print("上传进度: \(Int(progress.fractionCompleted * 100))%")
            // 更新UI进度条
        }
    }

    task.resume()
}

// 数据模型
struct VideoUploadResponse: Codable {
    let status: String
    let data: VideoData

    struct VideoData: Codable {
        let videoId: String
        let title: String
        let originalUrl: String
        let duration: Double
        let size: Int64
        let resolution: String?
        let status: String
        let transcodeStatus: String
        let moderationStatus: String
        let uploadedAt: String
        let message: String?
    }
}
```

---

## 2. 获取视频列表

获取视频列表，支持分页、筛选和排序。

### 接口信息

- **URL**: `/api/v1/videos`
- **Method**: `GET`
- **认证**: 可选（未登录只能看公开视频）

### 请求参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| page | Int | 否 | 1 | 页码（从1开始） |
| limit | Int | 否 | 20 | 每页数量（1-100） |
| category | String | 否 | - | 分类筛选 |
| userId | String | 否 | - | 用户ID筛选（查看某用户的视频） |
| status | String | 否 | published | 状态筛选（published/draft/private） |
| sort | String | 否 | latest | 排序方式（latest/popular/trending） |

### 响应示例

```json
{
  "status": "success",
  "data": {
    "videos": [
      {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "title": "晨练瑜伽教程",
        "description": "适合初学者的晨练瑜伽",
        "thumbnailUrl": "https://qinghe-uploads.oss-cn-beijing.aliyuncs.com/thumbnails/...",
        "duration": 120.5,
        "resolution": "1920x1080",
        "viewsCount": 1580,
        "likesCount": 156,
        "commentsCount": 23,
        "category": "运动",
        "tags": ["瑜伽", "晨练", "初学者"],
        "status": "published",
        "uploader": {
          "id": "user-123",
          "phone": "138****8001",
          "qingheId": "123456",
          "avatarUrl": "https://..."
        },
        "createdAt": "2025-10-01T08:30:00.000Z",
        "publishedAt": "2025-10-01T09:00:00.000Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 15,
      "totalCount": 289,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

### Swift示例代码

```swift
func getVideoList(page: Int = 1, limit: Int = 20, category: String? = nil, sort: String = "latest", completion: @escaping (Result<VideoListResponse, Error>) -> Void) {
    var components = URLComponents(string: "https://api.qinghejihua.com.cn/api/v1/videos")!
    var queryItems: [URLQueryItem] = [
        URLQueryItem(name: "page", value: "\(page)"),
        URLQueryItem(name: "limit", value: "\(limit)"),
        URLQueryItem(name: "sort", value: sort)
    ]

    if let category = category {
        queryItems.append(URLQueryItem(name: "category", value: category))
    }

    components.queryItems = queryItems

    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"

    // 如果已登录，添加token
    if let token = authToken {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: -1)))
            return
        }

        do {
            let result = try JSONDecoder().decode(VideoListResponse.self, from: data)
            completion(.success(result))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

struct VideoListResponse: Codable {
    let status: String
    let data: VideoListData

    struct VideoListData: Codable {
        let videos: [Video]
        let pagination: Pagination
    }
}

struct Video: Codable {
    let id: String
    let title: String
    let description: String?
    let thumbnailUrl: String
    let duration: Double
    let resolution: String?
    let viewsCount: Int
    let likesCount: Int
    let commentsCount: Int
    let category: String?
    let tags: [String]?
    let status: String
    let uploader: VideoUploader
    let createdAt: String
    let publishedAt: String?
}

struct VideoUploader: Codable {
    let id: String
    let phone: String?
    let qingheId: String?
    let avatarUrl: String?
}

struct Pagination: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalCount: Int
    let hasNext: Bool
    let hasPrev: Bool
}
```

---

## 3. 获取视频详情

获取单个视频的详细信息，包括播放URL、清晰度版本等。

### 接口信息

- **URL**: `/api/v1/videos/:videoId`
- **Method**: `GET`
- **认证**: 可选

### 路径参数

| 参数名 | 类型 | 说明 |
|--------|------|------|
| videoId | String | 视频ID |

### 响应示例

```json
{
  "status": "success",
  "data": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "title": "晨练瑜伽教程",
    "description": "适合初学者的晨练瑜伽课程，每天15分钟，改善体态",
    "thumbnailUrl": "https://qinghe-uploads.oss-cn-beijing.aliyuncs.com/thumbnails/cover.jpg",
    "playUrl": "https://qinghe-uploads.oss-cn-beijing.aliyuncs.com/videos/sd/video.m3u8",
    "versions": {
      "hd": {
        "quality": "1080p",
        "url": "https://qinghe-uploads.oss-cn-beijing.aliyuncs.com/videos/hd/video.m3u8",
        "size": 156789120,
        "bitrate": 5000
      },
      "sd": {
        "quality": "720p",
        "url": "https://qinghe-uploads.oss-cn-beijing.aliyuncs.com/videos/sd/video.m3u8",
        "size": 78394560,
        "bitrate": 2500
      },
      "ld": {
        "quality": "480p",
        "url": "https://qinghe-uploads.oss-cn-beijing.aliyuncs.com/videos/ld/video.m3u8",
        "size": 39197280,
        "bitrate": 1200
      }
    },
    "duration": 120.5,
    "resolution": "1920x1080",
    "viewsCount": 1580,
    "likesCount": 156,
    "commentsCount": 23,
    "favoritesCount": 89,
    "category": "运动",
    "tags": ["瑜伽", "晨练", "初学者"],
    "status": "published",
    "transcodeStatus": "completed",
    "moderationStatus": "approved",
    "uploader": {
      "id": "user-123",
      "phone": "138****8001",
      "qingheId": "123456",
      "avatarUrl": "https://...",
      "nickname": "瑜伽教练小美"
    },
    "isLiked": false,
    "isFavorited": false,
    "canPlay": true,
    "canDownload": false,
    "createdAt": "2025-10-01T08:30:00.000Z",
    "publishedAt": "2025-10-01T09:00:00.000Z"
  }
}
```

### Swift示例代码

```swift
func getVideoDetail(videoId: String, completion: @escaping (Result<VideoDetailResponse, Error>) -> Void) {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/videos/\(videoId)")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    if let token = authToken {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: -1)))
            return
        }

        do {
            let result = try JSONDecoder().decode(VideoDetailResponse.self, from: data)
            completion(.success(result))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

struct VideoDetailResponse: Codable {
    let status: String
    let data: VideoDetail
}

struct VideoDetail: Codable {
    let id: String
    let title: String
    let description: String?
    let thumbnailUrl: String
    let playUrl: String
    let versions: VideoVersions
    let duration: Double
    let resolution: String
    let viewsCount: Int
    let likesCount: Int
    let commentsCount: Int
    let favoritesCount: Int
    let category: String?
    let tags: [String]?
    let status: String
    let transcodeStatus: String
    let moderationStatus: String
    let uploader: VideoUploader
    let isLiked: Bool
    let isFavorited: Bool
    let canPlay: Bool
    let canDownload: Bool
    let createdAt: String
    let publishedAt: String?
}

struct VideoVersions: Codable {
    let hd: VideoVersion?
    let sd: VideoVersion?
    let ld: VideoVersion?
}

struct VideoVersion: Codable {
    let quality: String
    let url: String
    let size: Int64
    let bitrate: Int
}
```

---

## 4. 更新视频信息

更新视频的标题、描述、分类等信息，或手动发布视频。

### 接口信息

- **URL**: `/api/v1/videos/:videoId`
- **Method**: `PUT`
- **Content-Type**: `application/json`
- **认证**: 需要（仅作者可更新）

### 路径参数

| 参数名 | 类型 | 说明 |
|--------|------|------|
| videoId | String | 视频ID |

### 请求体参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| title | String | 否 | 新标题 |
| description | String | 否 | 新描述 |
| category | String | 否 | 新分类 |
| tags | String[] | 否 | 新标签数组 |
| status | String | 否 | 新状态（draft/published/private） |

### 重要说明

**发布视频流程**：
1. 上传视频后，状态为 `draft`，`moderationStatus` 为 `pending`
2. 审核完成后，`moderationStatus` 变为 `approved`，但 `status` 仍为 `draft`
3. 用户需要手动调用此接口，设置 `status=published` 来发布视频
4. 发布后会自动触发转码流程
5. 转码完成后视频可正常播放

### 请求示例

```json
{
  "status": "published"
}
```

### 响应示例

```json
{
  "status": "success",
  "data": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "title": "晨练瑜伽教程",
    "status": "published",
    "transcodeStatus": "processing",
    "message": "视频已发布，正在转码中"
  }
}
```

### 错误响应

```json
{
  "status": "error",
  "message": "视频未通过审核，无法发布",
  "code": "MODERATION_NOT_APPROVED"
}
```

### Swift示例代码

```swift
// 发布视频
func publishVideo(videoId: String, completion: @escaping (Result<UpdateVideoResponse, Error>) -> Void) {
    updateVideo(videoId: videoId, updates: ["status": "published"], completion: completion)
}

// 通用更新方法
func updateVideo(videoId: String, updates: [String: Any], completion: @escaping (Result<UpdateVideoResponse, Error>) -> Void) {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/videos/\(videoId)")!
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: updates)
    } catch {
        completion(.failure(error))
        return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: -1)))
            return
        }

        do {
            let result = try JSONDecoder().decode(UpdateVideoResponse.self, from: data)
            completion(.success(result))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

struct UpdateVideoResponse: Codable {
    let status: String
    let data: UpdatedVideoData

    struct UpdatedVideoData: Codable {
        let id: String
        let title: String
        let status: String
        let transcodeStatus: String
        let message: String?
    }
}
```

---

## 5. 删除视频

删除视频（仅作者可删除）。

### 接口信息

- **URL**: `/api/v1/videos/:videoId`
- **Method**: `DELETE`
- **认证**: 需要

### 响应示例

```json
{
  "status": "success",
  "message": "视频已删除"
}
```

### Swift示例代码

```swift
func deleteVideo(videoId: String, completion: @escaping (Result<Void, Error>) -> Void) {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/videos/\(videoId)")!
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            completion(.success(()))
        } else {
            completion(.failure(NSError(domain: "DeleteFailed", code: -1)))
        }
    }.resume()
}
```

---

## 6. 获取视频处理状态

实时查询视频的审核和转码状态。

### 接口信息

- **URL**: `/api/v1/videos/:videoId/status`
- **Method**: `GET`
- **认证**: 需要

### 响应示例

```json
{
  "status": "success",
  "data": {
    "videoId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "status": "draft",
    "moderationStatus": "approved",
    "moderationResult": {
      "action": "pass",
      "message": "视频审核通过（无风险）",
      "queriedAt": "2025-10-02T14:35:00.000Z"
    },
    "transcodeStatus": "completed",
    "transcodeProgress": 100,
    "transcodeCompletedAt": "2025-10-02T14:40:00.000Z",
    "canPublish": true,
    "canPlay": false,
    "message": "审核已通过，可以发布视频"
  }
}
```

### 状态说明

**moderationStatus (审核状态)**:
- `pending`: 审核中
- `approved`: 已通过
- `rejected`: 已拒绝
- `reviewing`: 人工复审中

**transcodeStatus (转码状态)**:
- `pending`: 等待转码
- `processing`: 转码中
- `completed`: 转码完成
- `failed`: 转码失败

**status (发布状态)**:
- `draft`: 草稿（未发布）
- `published`: 已发布
- `private`: 私密

### Swift示例代码

```swift
func getVideoStatus(videoId: String, completion: @escaping (Result<VideoStatusResponse, Error>) -> Void) {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/videos/\(videoId)/status")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: -1)))
            return
        }

        do {
            let result = try JSONDecoder().decode(VideoStatusResponse.self, from: data)
            completion(.success(result))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

struct VideoStatusResponse: Codable {
    let status: String
    let data: VideoStatus
}

struct VideoStatus: Codable {
    let videoId: String
    let status: String
    let moderationStatus: String
    let moderationResult: ModerationResult?
    let transcodeStatus: String
    let transcodeProgress: Int
    let transcodeCompletedAt: String?
    let canPublish: Bool
    let canPlay: Bool
    let message: String?
}

struct ModerationResult: Codable {
    let action: String
    let message: String
    let queriedAt: String
}
```

---

## 7. 点赞视频

为视频点赞。

### 接口信息

- **URL**: `/api/v1/videos/:videoId/like`
- **Method**: `POST`
- **认证**: 需要

### 响应示例

```json
{
  "status": "success",
  "data": {
    "videoId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "isLiked": true,
    "likesCount": 157
  }
}
```

### Swift示例代码

```swift
func likeVideo(videoId: String, completion: @escaping (Result<LikeResponse, Error>) -> Void) {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/videos/\(videoId)/like")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: -1)))
            return
        }

        do {
            let result = try JSONDecoder().decode(LikeResponse.self, from: data)
            completion(.success(result))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

struct LikeResponse: Codable {
    let status: String
    let data: LikeData

    struct LikeData: Codable {
        let videoId: String
        let isLiked: Bool
        let likesCount: Int
    }
}
```

---

## 8. 取消点赞

取消对视频的点赞。

### 接口信息

- **URL**: `/api/v1/videos/:videoId/like`
- **Method**: `DELETE`
- **认证**: 需要

### 响应示例

```json
{
  "status": "success",
  "data": {
    "videoId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "isLiked": false,
    "likesCount": 156
  }
}
```

---

## 9. 收藏视频

收藏视频到个人收藏夹。

### 接口信息

- **URL**: `/api/v1/videos/:videoId/favorite`
- **Method**: `POST`
- **认证**: 需要

### 响应示例

```json
{
  "status": "success",
  "data": {
    "videoId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "isFavorited": true,
    "favoritesCount": 90
  }
}
```

---

## 10. 取消收藏

取消收藏视频。

### 接口信息

- **URL**: `/api/v1/videos/:videoId/favorite`
- **Method**: `DELETE`
- **认证**: 需要

---

## 11. 视频评论

对视频发表评论。

### 接口信息

- **URL**: `/api/v1/videos/:videoId/comments`
- **Method**: `POST`
- **Content-Type**: `application/json`
- **认证**: 需要

### 请求体参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| content | String | 是 | 评论内容（1-500字符） |
| parentId | String | 否 | 父评论ID（回复评论时提供） |

### 请求示例

```json
{
  "content": "讲解得很清楚，跟着练习后感觉身体轻松多了！"
}
```

### 响应示例

```json
{
  "status": "success",
  "data": {
    "id": "comment-123",
    "videoId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "content": "讲解得很清楚，跟着练习后感觉身体轻松多了！",
    "author": {
      "id": "user-456",
      "qingheId": "654321",
      "avatarUrl": "https://..."
    },
    "createdAt": "2025-10-02T15:00:00.000Z",
    "likesCount": 0
  }
}
```

---

## 12. 获取评论列表

获取视频的评论列表。

### 接口信息

- **URL**: `/api/v1/videos/:videoId/comments`
- **Method**: `GET`
- **认证**: 可选

### 请求参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| page | Int | 否 | 1 | 页码 |
| limit | Int | 否 | 20 | 每页数量 |
| sort | String | 否 | latest | 排序（latest/popular） |

### 响应示例

```json
{
  "status": "success",
  "data": {
    "comments": [
      {
        "id": "comment-123",
        "content": "讲解得很清楚！",
        "author": {
          "id": "user-456",
          "qingheId": "654321",
          "avatarUrl": "https://..."
        },
        "createdAt": "2025-10-02T15:00:00.000Z",
        "likesCount": 5,
        "repliesCount": 2,
        "isLiked": false
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalCount": 45,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

---

## 错误代码说明

| 错误代码 | 说明 |
|---------|------|
| `UNAUTHORIZED` | 未登录或token无效 |
| `FORBIDDEN` | 无权限操作 |
| `FILE_TOO_LARGE` | 文件超过1GB限制 |
| `INVALID_FILE_TYPE` | 不支持的视频格式 |
| `VIDEO_NOT_FOUND` | 视频不存在 |
| `MODERATION_NOT_APPROVED` | 视频未通过审核 |
| `TRANSCODE_FAILED` | 转码失败 |
| `VALIDATION_ERROR` | 参数验证失败 |

---

## Swift示例代码

### 完整的视频服务类

```swift
import Foundation
import AVFoundation

class VideoService {
    static let shared = VideoService()
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1"
    private var authToken: String? {
        // 从UserDefaults或Keychain获取token
        return UserDefaults.standard.string(forKey: "authToken")
    }

    // MARK: - 上传视频

    func uploadVideo(
        videoURL: URL,
        title: String,
        description: String? = nil,
        category: String? = nil,
        tags: [String]? = nil,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (Result<VideoUploadResponse, Error>) -> Void
    ) {
        let url = URL(string: "\(baseURL)/videos/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken ?? "")", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // 添加视频文件
        do {
            let videoData = try Data(contentsOf: videoURL)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"video\"; filename=\"video.mp4\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
            body.append(videoData)
            body.append("\r\n".data(using: .utf8)!)
        } catch {
            completion(.failure(error))
            return
        }

        // 添加其他字段
        let fields: [String: String?] = [
            "title": title,
            "description": description,
            "category": category,
            "tags": tags?.joined(separator: ",")
        ]

        for (key, value) in fields {
            guard let value = value else { continue }
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        // 配置长超时
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 600
        config.timeoutIntervalForResource = 1200

        let session = URLSession(configuration: config)
        let task = session.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(VideoUploadResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }

        // 监听进度
        let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                progressHandler?(progress.fractionCompleted)
            }
        }

        task.resume()
    }

    // MARK: - 获取视频列表

    func getVideoList(
        page: Int = 1,
        limit: Int = 20,
        category: String? = nil,
        userId: String? = nil,
        sort: String = "latest",
        completion: @escaping (Result<VideoListResponse, Error>) -> Void
    ) {
        var components = URLComponents(string: "\(baseURL)/videos")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: sort)
        ]

        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        if let userId = userId {
            queryItems.append(URLQueryItem(name: "userId", value: userId))
        }

        components.queryItems = queryItems

        performRequest(url: components.url!, method: "GET", completion: completion)
    }

    // MARK: - 获取视频详情

    func getVideoDetail(videoId: String, completion: @escaping (Result<VideoDetailResponse, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/videos/\(videoId)")!
        performRequest(url: url, method: "GET", completion: completion)
    }

    // MARK: - 发布视频

    func publishVideo(videoId: String, completion: @escaping (Result<UpdateVideoResponse, Error>) -> Void) {
        updateVideo(videoId: videoId, updates: ["status": "published"], completion: completion)
    }

    // MARK: - 更新视频

    func updateVideo(
        videoId: String,
        updates: [String: Any],
        completion: @escaping (Result<UpdateVideoResponse, Error>) -> Void
    ) {
        let url = URL(string: "\(baseURL)/videos/\(videoId)")!
        performRequest(url: url, method: "PUT", body: updates, completion: completion)
    }

    // MARK: - 删除视频

    func deleteVideo(videoId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/videos/\(videoId)")!
        performRequest(url: url, method: "DELETE") { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - 点赞相关

    func likeVideo(videoId: String, completion: @escaping (Result<LikeResponse, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/videos/\(videoId)/like")!
        performRequest(url: url, method: "POST", completion: completion)
    }

    func unlikeVideo(videoId: String, completion: @escaping (Result<LikeResponse, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/videos/\(videoId)/like")!
        performRequest(url: url, method: "DELETE", completion: completion)
    }

    // MARK: - 收藏相关

    func favoriteVideo(videoId: String, completion: @escaping (Result<FavoriteResponse, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/videos/\(videoId)/favorite")!
        performRequest(url: url, method: "POST", completion: completion)
    }

    func unfavoriteVideo(videoId: String, completion: @escaping (Result<FavoriteResponse, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/videos/\(videoId)/favorite")!
        performRequest(url: url, method: "DELETE", completion: completion)
    }

    // MARK: - 通用请求方法

    private func performRequest<T: Decodable>(
        url: URL,
        method: String,
        body: [String: Any]? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                completion(.failure(error))
                return
            }
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(T.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - 数据模型

struct EmptyResponse: Codable {}

struct FavoriteResponse: Codable {
    let status: String
    let data: FavoriteData

    struct FavoriteData: Codable {
        let videoId: String
        let isFavorited: Bool
        let favoritesCount: Int
    }
}
```

---

## 使用示例

### 1. 上传视频并监听进度

```swift
let videoURL = URL(fileURLWithPath: "/path/to/video.mp4")

VideoService.shared.uploadVideo(
    videoURL: videoURL,
    title: "我的健康视频",
    description: "分享我的健康心得",
    category: "健康",
    tags: ["健康", "生活"],
    progressHandler: { progress in
        print("上传进度: \(Int(progress * 100))%")
        // 更新进度条UI
    },
    completion: { result in
        switch result {
        case .success(let response):
            print("上传成功，视频ID: \(response.data.videoId)")
            // 保存videoId，稍后用于发布
        case .failure(let error):
            print("上传失败: \(error.localizedDescription)")
        }
    }
)
```

### 2. 轮询视频处理状态

```swift
func pollVideoStatus(videoId: String) {
    VideoService.shared.getVideoStatus(videoId: videoId) { result in
        switch result {
        case .success(let response):
            let status = response.data

            if status.moderationStatus == "approved" && status.canPublish {
                // 审核通过，可以发布
                print("视频审核通过，可以发布")
                self.showPublishButton()
            } else if status.moderationStatus == "rejected" {
                // 审核被拒绝
                print("视频审核未通过: \(status.message ?? "")")
            } else {
                // 继续轮询
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.pollVideoStatus(videoId: videoId)
                }
            }
        case .failure(let error):
            print("查询状态失败: \(error)")
        }
    }
}
```

### 3. 发布视频

```swift
func publishVideo(videoId: String) {
    VideoService.shared.publishVideo(videoId: videoId) { result in
        switch result {
        case .success(let response):
            print("视频已发布，正在转码")
            // 开始轮询转码状态
            self.pollTranscodeStatus(videoId: videoId)
        case .failure(let error):
            print("发布失败: \(error)")
        }
    }
}
```

### 4. 播放视频（使用AVPlayer）

```swift
import AVKit

func playVideo(videoDetail: VideoDetail) {
    // 根据网络状况选择合适的清晰度
    let playURL: String
    if isWiFiConnected() {
        playURL = videoDetail.versions.hd?.url ?? videoDetail.playUrl
    } else {
        playURL = videoDetail.versions.sd?.url ?? videoDetail.playUrl
    }

    let player = AVPlayer(url: URL(string: playURL)!)
    let playerViewController = AVPlayerViewController()
    playerViewController.player = player

    present(playerViewController, animated: true) {
        player.play()
    }
}
```

---

## 最佳实践建议

### 1. 上传优化

- **压缩视频**: 上传前对视频进行适当压缩，推荐使用H.264编码
- **进度显示**: 实现友好的进度条UI，显示百分比和预估时间
- **断点续传**: 对于大文件，建议实现分片上传和断点续传
- **网络检测**: 上传前检测网络状况，WiFi环境下提示用户

### 2. 播放优化

- **HLS流式播放**: 优先使用转码后的HLS格式（.m3u8）
- **自适应码率**: 根据网络状况自动切换清晰度
- **预加载**: 在列表中预加载视频缩略图和元数据
- **缓存策略**: 缓存已播放的视频片段

### 3. 用户体验

- **状态轮询**: 上传后定期查询处理状态，及时通知用户
- **错误处理**: 明确的错误提示和重试机制
- **离线功能**: 支持收藏的视频离线下载
- **流量提醒**: 移动网络下播放高清视频时提示用户

### 4. 性能优化

- **列表优化**: 使用懒加载和分页，避免一次加载过多数据
- **图片缓存**: 使用SDWebImage等库缓存视频封面
- **内存管理**: 及时释放不再使用的视频播放器资源

---

## 更新日志

### v1.0 (2025-10-02)
- ✅ 初始版本发布
- ✅ 支持视频上传（最大1GB）
- ✅ 阿里云视频审核集成
- ✅ 多清晰度转码（1080p/720p/480p）
- ✅ 手动发布流程
- ✅ 点赞、收藏、评论功能
- ✅ 完整的Swift示例代码

---

## 技术支持

如有问题，请联系技术支持或查看详细文档。

**文档维护**: 青禾计划技术团队
**最后更新**: 2025年10月2日
