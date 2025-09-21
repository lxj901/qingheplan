# 青禾计划 - 社区功能API文档

## 概述

本文档描述了青禾计划社区功能的API接口，包括帖子管理、评论系统、用户互动等功能。

## 基础信息

- **基础URL**: `https://api.qinghejihua.com.cn/api/v1/community`
- **认证方式**: Bearer Token
- **数据格式**: JSON


大部分API需要用户认证，请在请求头中包含：
```
Authorization: Bearer <your_token>
```

部分API支持可选认证（optionalAuth），即可以不提供token，但提供token时会返回更多用户相关信息。

## API接口

### 1. 帖子管理

#### 1.1 发布帖子
```http
POST /posts
```

**请求体：**
```json
{
  "content": "帖子内容",
  "images": ["image_url1", "image_url2"],
  "video": "video_url",
  "tags": ["健身", "HIIT", "减脂"],
  "category": "fitness",
  "allowComments": true,
  "allowShares": true,
  "visibility": "public"
}
```

**响应：**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "authorId": 123,
    "content": "帖子内容",
    "images": ["image_url1", "image_url2"],
    "video": "video_url",
    "tags": ["健身", "HIIT", "减脂"],
    "category": "fitness",
    "likesCount": 0,
    "commentsCount": 0,
    "sharesCount": 0,
    "bookmarksCount": 0,
    "viewsCount": 0,
    "allowComments": true,
    "allowShares": true,
    "visibility": "public",
    "status": "active",
    "isTop": false,
    "hotScore": 0,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z",
    "author": {
      "id": 123,
      "nickname": "用户昵称",
      "avatar": "avatar_url",
      "isVerified": false
    }
  },
  "message": "帖子发布成功"
}
```

#### 1.2 获取帖子列表
```http
GET /posts?tab={tab}&category={category}&page={page}&limit={limit}
```

**参数：**
- `tab`: recommended(推荐) | following(关注) | hot(热门) | mine(我的)
- `category`: all | tech | life | fitness | food | travel | learning | qa | share
- `page`: 页码，默认1
- `limit`: 每页数量，默认20

**响应：**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "content": "帖子内容",
        "author": {
          "id": 123,
          "nickname": "用户昵称",
          "avatar": "avatar_url",
          "isVerified": false,
          "level": 1
        },
        "likesCount": 10,
        "commentsCount": 5,
        "sharesCount": 2,
        "bookmarksCount": 3,
        "viewsCount": 100,
        "isLiked": false,
        "isBookmarked": false,
        "createdAt": "2024-01-01T00:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "totalPages": 5,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

#### 1.3 获取单个帖子详情
```http
GET /posts/{postId}
```

**响应：**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "content": "帖子内容",
    "images": ["image_url1"],
    "video": "video_url",
    "tags": ["标签1", "标签2"],
    "category": "tech",
    "author": {
      "id": 123,
      "nickname": "用户昵称",
      "avatar": "avatar_url",
      "isVerified": false,
      "level": 1,
      "followersCount": 100
    },
    "likesCount": 10,
    "commentsCount": 5,
    "sharesCount": 2,
    "bookmarksCount": 3,
    "viewsCount": 101,
    "isLiked": false,
    "isBookmarked": false,
    "allowComments": true,
    "allowShares": true,
    "visibility": "public",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

#### 1.4 编辑帖子
```http
PUT /posts/{postId}
```

**请求体：**
```json
{
  "content": "更新后的帖子内容",
  "images": ["new_image_url"],
  "tags": ["新标签"],
  "category": "life",
  "allowComments": false
}
```

#### 1.5 删除帖子
```http
DELETE /posts/{postId}
```

**响应：**
```json
{
  "success": true,
  "message": "帖子删除成功"
}
```

### 2. 帖子互动

#### 2.1 点赞/取消点赞帖子
```http
POST /posts/{postId}/like
```

**响应：**
```json
{
  "success": true,
  "data": {
    "isLiked": true
  },
  "message": "点赞成功"
}
```

#### 2.2 收藏/取消收藏帖子
```http
POST /posts/{postId}/bookmark
```

**响应：**
```json
{
  "success": true,
  "data": {
    "isBookmarked": true
  },
  "message": "收藏成功"
}
```

#### 2.3 分享帖子
```http
POST /posts/{postId}/share
```

**请求体：**
```json
{
  "platform": "wechat"
}
```

**响应：**
```json
{
  "success": true,
  "message": "分享成功"
}
```

#### 2.4 举报帖子
```http
POST /posts/{postId}/report
```

**请求体：**
```json
{
  "reason": "spam",
  "description": "具体描述"
}
```

**举报原因：**
- `spam`: 垃圾信息
- `inappropriate`: 不当内容
- `harassment`: 骚扰
- `violence`: 暴力内容
- `copyright`: 版权问题
- `other`: 其他

### 3. 评论系统

#### 3.1 发表评论
```http
POST /posts/{postId}/comments
```

**请求体：**
```json
{
  "content": "评论内容",
  "parentCommentId": "回复评论的ID（可选）",
  "replyToUserId": "回复用户的ID（可选）"
}
```

**响应：**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "postId": "post_uuid",
    "authorId": 123,
    "content": "评论内容",
    "parentCommentId": null,
    "replyToUserId": null,
    "likesCount": 0,
    "repliesCount": 0,
    "level": 0,
    "status": "active",
    "isTop": false,
    "createdAt": "2024-01-01T00:00:00Z",
    "author": {
      "id": 123,
      "nickname": "用户昵称",
      "avatar": "avatar_url",
      "isVerified": false
    },
    "replyToUser": null
  },
  "message": "评论发表成功"
}
```

#### 3.2 获取评论列表
```http
GET /posts/{postId}/comments?page={page}&limit={limit}&sortBy={sortBy}
```

**参数：**
- `page`: 页码，默认1
- `limit`: 每页数量，默认20
- `sortBy`: time(时间) | hot(热度)

#### 3.3 删除评论
```http
DELETE /comments/{commentId}
```

#### 3.4 点赞/取消点赞评论
```http
POST /comments/{commentId}/like
```

#### 3.5 获取评论的回复列表
```http
GET /comments/{commentId}/replies?page={page}&limit={limit}
```

## 错误响应

所有API在出错时都会返回以下格式：

```json
{
  "success": false,
  "message": "错误描述"
}
```

常见HTTP状态码：
- `200`: 成功
- `201`: 创建成功
- `400`: 请求参数错误
- `401`: 未认证
- `403`: 无权限
- `404`: 资源不存在
- `500`: 服务器错误

## 数据模型

### 帖子分类

#### 内容分类（用于发布帖子）
- `life`: 生活
- `sports`: 运动
- `sleep`: 睡眠
- `discipline`: 自律

#### 全局分类（用于内容展示，通过tab参数获取）
- `recommended`: 推荐
- `following`: 关注
- `latest`: 最新

**注意**: 发布帖子时只能使用内容分类，全局分类由系统自动管理

### 帖子可见性
- `public`: 公开
- `followers`: 仅关注者可见
- `private`: 私有

### 帖子状态
- `active`: 正常
- `hidden`: 隐藏
- `deleted`: 已删除
- `reported`: 被举报

## 使用示例

### JavaScript/Node.js
```javascript
// 发布帖子（使用内容分类）
const response = await fetch('/api/v1/community/posts', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    content: '今天的运动打卡！',
    tags: ['运动', '健身', '打卡'],
    category: 'sports'  // 只能使用内容分类：life, sports, sleep, discipline
  })
});

const result = await response.json();
console.log(result);

// 获取推荐内容（全局分类）
const recommendedPosts = await fetch('/api/v1/community/posts?tab=recommended&page=1&limit=10', {
  headers: { 'Authorization': `Bearer ${token}` }
});

// 获取特定内容分类的帖子
const sportsPosts = await fetch('/api/v1/community/posts?category=sports&page=1&limit=10', {
  headers: { 'Authorization': `Bearer ${token}` }
});
```

### cURL
```bash
# 获取推荐帖子列表（全局分类）
curl -X GET "http://localhost:3000/api/v1/community/posts?tab=recommended&page=1&limit=10" \
  -H "Authorization: Bearer your_token"

# 获取运动分类的帖子（内容分类）
curl -X GET "http://localhost:3000/api/v1/community/posts?category=sports&page=1&limit=10" \
  -H "Authorization: Bearer your_token"

# 点赞帖子
curl -X POST "http://localhost:3000/api/v1/community/posts/post_id/like" \
  -H "Authorization: Bearer your_token"
```

# 青禾计划 - 发布帖子位置功能 API 文档 (iOS版)

## 📋 概述

青禾计划发布帖子功能现已支持位置信息，用户可以在发布帖子时添加位置名称和精确的地理坐标。

**基础信息**
- **API基础URL**: `https://api.qinghejihua.com.cn/api/v1`
- **协议**: HTTPS
- **认证方式**: Bearer Token (JWT)
- **内容类型**: `application/json`

## 🚀 发布帖子接口

### 接口信息
- **URL**: `POST /community/posts`
- **完整地址**: `https://api.qinghejihua.com.cn/api/v1/community/posts`
- **认证**: 必需 (Bearer Token)

### 请求头 (Headers)
```http
Content-Type: application/json
Authorization: Bearer {JWT_TOKEN}
```

### 请求参数 (Request Body)

| 参数名 | 类型 | 必填 | 说明 | 示例 |
|--------|------|------|------|------|
| `content` | String | ✅ | 帖子内容，1-5000字符 | "今天天气真好！" |
| `location` | String | ❌ | 位置名称，最多200字符 | "北京市朝阳区三里屯" |
| `latitude` | Number | ❌ | 纬度，-90到90之间 | 39.9042 |
| `longitude` | Number | ❌ | 经度，-180到180之间 | 116.4074 |
| `checkinId` | Number | ❌ | 关联的打卡记录ID | 123 |
| `workoutId` | Number | ❌ | 关联的运动记录ID | 456 |
| `images` | Array | ❌ | 图片URL数组，最多9张 | ["https://example.com/1.jpg"] |
| `video` | String | ❌ | 视频URL | "https://example.com/video.mp4" |
| `tags` | Array | ❌ | 标签数组，最多10个 | ["健身", "跑步"] |
| `allowComments` | Boolean | ❌ | 是否允许评论，默认true | true |
| `allowShares` | Boolean | ❌ | 是否允许分享，默认true | true |
| `visibility` | String | ❌ | 可见性，默认"public" | "public" |

### 数据关联使用规则

#### 位置信息
1. **仅位置名称**: 只传 `location` 参数
2. **完整位置信息**: 同时传 `location`、`latitude`、`longitude`
3. **无位置信息**: 不传任何位置参数
4. **重要**: `latitude` 和 `longitude` 必须同时提供，不能只提供其中一个

#### 打卡和运动数据关联
1. **普通帖子**: 不传 `checkinId` 和 `workoutId`
2. **打卡帖子**: 传入 `checkinId`，系统会自动关联打卡数据
3. **运动帖子**: 传入 `workoutId`，系统会自动关联运动数据
4. **混合帖子**: 同时传入 `checkinId` 和 `workoutId`
5. **自动位置**: 如果关联了打卡/运动数据但未提供位置信息，系统会自动从关联数据中获取位置

### 请求示例

#### 1. 完整位置信息
```json
{
  "content": "今天在三里屯逛街，人好多啊！",
  "location": "北京市朝阳区三里屯",
  "latitude": 39.9365,
  "longitude": 116.4477,
  "tags": ["逛街", "三里屯", "周末"],
  "images": ["https://example.com/photo1.jpg"],
  "allowComments": true,
  "allowShares": true
}
```

#### 2. 仅位置名称
```json
{
  "content": "在咖啡厅工作中...",
  "location": "星巴克(国贸店)",
  "tags": ["工作", "咖啡"],
  "allowComments": true
}
```

#### 3. 无位置信息
```json
{
  "content": "今天心情不错，分享一下",
  "tags": ["心情", "分享"],
  "allowComments": true
}
```

#### 4. 打卡帖子
```json
{
  "content": "今日打卡完成！坚持就是胜利💪",
  "checkinId": 123,
  "tags": ["打卡", "坚持", "成长"],
  "allowComments": true
}
```

#### 5. 运动帖子
```json
{
  "content": "今天跑步5公里，感觉棒极了！🏃‍♂️",
  "workoutId": 456,
  "tags": ["跑步", "健身", "运动"],
  "allowComments": true
}
```

#### 6. 混合数据帖子
```json
{
  "content": "晨跑打卡，新的一天开始了！",
  "checkinId": 123,
  "workoutId": 456,
  "location": "奥林匹克森林公园",
  "latitude": 40.0031,
  "longitude": 116.3969,
  "tags": ["晨跑", "打卡", "健康生活"],
  "allowComments": true
}
```

### 响应格式

#### 成功响应 (HTTP 201)
```json
{
  "success": true,
  "data": {
    "id": "b8c5a8c7-7c4a-4b5e-9f2d-1a3b4c5d6e7f",
    "authorId": 1,
    "content": "今天在三里屯逛街，人好多啊！",
    "location": "北京市朝阳区三里屯",
    "latitude": "39.93650000",
    "longitude": "116.44770000",
    "checkinId": null,
    "workoutId": null,
    "dataType": "normal",
    "images": ["https://example.com/photo1.jpg"],
    "video": null,
    "tags": ["逛街", "三里屯", "周末"],
    "likesCount": 0,
    "commentsCount": 0,
    "sharesCount": 0,
    "bookmarksCount": 0,
    "viewsCount": 0,
    "allowComments": true,
    "allowShares": true,
    "visibility": "public",
    "status": "active",
    "isTop": false,
    "hotScore": 0,
    "lastActiveAt": "2025-08-05T10:30:15.000Z",
    "createdAt": "2025-08-05T10:30:15.000Z",
    "updatedAt": "2025-08-05T10:30:15.000Z",
    "author": {
      "id": 1,
      "nickname": "青禾用户",
      "avatar": "https://example.com/avatar.jpg",
      "isVerified": false
    },
    "checkin": null,
    "workout": null
  }
}
```

#### 错误响应

##### 参数验证错误 (HTTP 400)
```json
{
  "success": false,
  "message": "纬度必须在-90到90之间"
}
```

##### 认证错误 (HTTP 401)
```json
{
  "success": false,
  "message": "未授权访问"
}
```

##### 服务器错误 (HTTP 500)
```json
{
  "success": false,
  "message": "服务器内部错误"
}
```

## 📱 iOS 集成示例

### Swift URLSession 示例

```swift
import Foundation
import CoreLocation

struct PostRequest: Codable {
    let content: String
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let tags: [String]?
    let images: [String]?
    let allowComments: Bool?
    let allowShares: Bool?
}

struct PostResponse: Codable {
    let success: Bool
    let data: PostData?
    let message: String?
}

struct PostData: Codable {
    let id: String
    let content: String
    let location: String?
    let latitude: String?
    let longitude: String?
    let author: Author
    let createdAt: String
}

struct Author: Codable {
    let id: Int
    let nickname: String
    let avatar: String?
}

class PostService {
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1"
    private var authToken: String?
    
    func createPost(
        content: String,
        location: String? = nil,
        coordinate: CLLocationCoordinate2D? = nil,
        tags: [String]? = nil,
        images: [String]? = nil,
        completion: @escaping (Result<PostData, Error>) -> Void
    ) {
        guard let token = authToken else {
            completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "未登录"])))
            return
        }
        
        let url = URL(string: "\(baseURL)/community/posts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let postRequest = PostRequest(
            content: content,
            location: location,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude,
            tags: tags,
            images: images,
            allowComments: true,
            allowShares: true
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(postRequest)
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
                completion(.failure(NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "无响应数据"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(PostResponse.self, from: data)
                if response.success, let postData = response.data {
                    completion(.success(postData))
                } else {
                    let errorMessage = response.message ?? "发布失败"
                    completion(.failure(NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
}
```

### 使用示例

```swift
let postService = PostService()
postService.setAuthToken("your_jwt_token_here")

// 1. 发布带完整位置信息的帖子
let coordinate = CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
postService.createPost(
    content: "今天在北京天安门广场！",
    location: "北京市东城区天安门广场",
    coordinate: coordinate,
    tags: ["旅游", "北京", "天安门"]
) { result in
    DispatchQueue.main.async {
        switch result {
        case .success(let postData):
            print("发布成功: \(postData.id)")
        case .failure(let error):
            print("发布失败: \(error.localizedDescription)")
        }
    }
}

// 2. 发布仅位置名称的帖子
postService.createPost(
    content: "在咖啡厅工作中...",
    location: "星巴克(三里屯店)",
    tags: ["工作", "咖啡"]
) { result in
    // 处理结果
}

// 3. 发布无位置信息的帖子
postService.createPost(
    content: "今天心情不错！",
    tags: ["心情", "分享"]
) { result in
    // 处理结果
}
```

## 🔍 常见错误处理

### 错误码对照表

| HTTP状态码 | 错误类型 | 常见原因 | 解决方案 |
|-----------|----------|----------|----------|
| 400 | 参数错误 | 经纬度超出范围 | 检查坐标值是否在有效范围内 |
| 400 | 参数错误 | 只提供了经度或纬度 | 经纬度必须同时提供 |
| 400 | 参数错误 | 内容为空 | 确保content不为空 |
| 401 | 认证失败 | Token无效或过期 | 重新登录获取新Token |
| 413 | 请求过大 | 图片或内容过大 | 压缩图片或减少内容长度 |
| 500 | 服务器错误 | 服务器内部错误 | 稍后重试或联系技术支持 |

### iOS错误处理建议

```swift
func handlePostError(_ error: Error) {
    if let nsError = error as NSError? {
        switch nsError.code {
        case 400:
            // 参数错误，显示具体错误信息
            showAlert(title: "参数错误", message: nsError.localizedDescription)
        case 401:
            // 认证失败，跳转到登录页面
            redirectToLogin()
        case 413:
            // 请求过大，提示用户压缩内容
            showAlert(title: "内容过大", message: "请压缩图片或减少内容长度")
        default:
            // 其他错误
            showAlert(title: "发布失败", message: "请稍后重试")
        }
    }
}
```

## 📍 位置获取建议

### Core Location 集成

```swift
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var completion: ((CLLocation?) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func getCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            completion(nil)
        @unknown default:
            completion(nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        completion?(locations.first)
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(nil)
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        } else if status == .denied || status == .restricted {
            completion?(nil)
            completion = nil
        }
    }
}
```

## 🔧 测试建议

1. **单元测试**: 测试不同位置参数组合
2. **网络测试**: 测试网络异常情况
3. **权限测试**: 测试位置权限被拒绝的情况
4. **边界测试**: 测试极限经纬度值

---

**文档版本**: v1.0  
**更新时间**: 2025年8月5日  
**技术支持**: 如有问题请联系后端开发团队
