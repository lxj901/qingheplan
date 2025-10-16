# iOS同城功能API文档

## 概述

同城功能允许用户基于地理位置发现附近的帖子和用户，为用户提供本地化的社区体验。

**基础URL**: `https://api.qinghejihua.com.cn/api/v1`

## 认证

所有API请求需要在Header中包含JWT Token：
```
Authorization: Bearer <your_jwt_token>
```

## 1. 用户认证

### 1.1 发送验证码
```
POST /auth/send-sms-code
```

**请求参数**:
```json
{
  "phone": "19820722496"
}
```

**响应**:
```json
{
  "status": "success",
  "message": "验证码发送成功",
  "data": {
    "phone": "19820722496",
    "requestId": "BD82AE26-EBB0-5C12-9F5D-5ED44519498E"
  }
}
```

### 1.2 验证码登录
```
POST /auth/login-sms
```

**请求参数**:
```json
{
  "phone": "19820722496",
  "code": "364559"
}
```

**响应**:
```json
{
  "status": "success",
  "message": "登录成功",
  "data": {
    "user": {
      "id": 1,
      "phone": "19820722496",
      "nickname": "青禾测试用户",
      "avatar": "https://example.com/avatar.jpg",
      "status": "active"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": "7d"
  }
}
```

## 2. 同城帖子功能

### 2.1 获取同城帖子
```
GET /community/nearby/posts
```

**查询参数**:
- `latitude` (必需): 纬度，如 `39.9042`
- `longitude` (必需): 经度，如 `116.4074`
- `radius` (可选): 搜索半径(km)，默认50，最大200
- `page` (可选): 页码，默认1
- `limit` (可选): 每页数量，默认10，最大50

**示例请求**:
```
GET /community/nearby/posts?latitude=39.9042&longitude=116.4074&radius=50&page=1&limit=5
```

**响应**:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "cee0ce3c-8c98-4ec2-b0f6-4a4df4f82484",
        "authorId": 3,
        "content": "🎯 最终功能测试 - checkinId和workoutId关联功能完全修复！",
        "images": [],
        "video": null,
        "tags": ["功能修复", "关联测试", "最终成功"],
        "location": "北京天安门",
        "latitude": "39.90420000",
        "longitude": "116.40740000",
        "likesCount": 0,
        "commentsCount": 0,
        "sharesCount": 0,
        "bookmarksCount": 0,
        "viewsCount": 6,
        "allowComments": true,
        "allowShares": true,
        "visibility": "public",
        "status": "active",
        "isTop": false,
        "hotScore": 0,
        "lastActiveAt": "2025-08-06 10:06:59",
        "checkinId": null,
        "workoutId": null,
        "createdAt": "2025-08-06 10:06:59",
        "updatedAt": "2025-08-09 14:18:00",
        "author": {
          "id": 3,
          "nickname": "用户4058",
          "avatar": "",
          "isVerified": false,
          "level": 1
        },
        "distance": 0,
        "distanceText": "附近",
        "isLiked": false,
        "isBookmarked": false
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 5,
      "total": 10,
      "hasNext": true
    },
    "location": {
      "latitude": 39.9042,
      "longitude": 116.4074,
      "radius": 50
    }
  }
}
```

### 2.2 获取同城用户
```
GET /community/nearby/users
```

**查询参数**:
- `latitude` (必需): 纬度
- `longitude` (必需): 经度  
- `radius` (可选): 搜索半径(km)，默认50
- `page` (可选): 页码，默认1
- `limit` (可选): 每页数量，默认10

**响应**:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 1,
        "nickname": "青禾测试用户",
        "avatar": "https://example.com/avatar.jpg",
        "isVerified": false,
        "level": 1,
        "location": "北京市",
        "distance": 1.2,
        "distanceText": "1.2km",
        "lastActiveAt": "2025-08-09 15:40:15"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 5,
      "hasNext": false
    }
  }
}
```

## 3. iOS实现要点

### 3.1 位置权限
```swift
import CoreLocation

// 请求位置权限
locationManager.requestWhenInUseAuthorization()

// 获取当前位置
func getCurrentLocation() {
    locationManager.requestLocation()
}
```

### 3.2 API调用示例
```swift
// 获取同城帖子
func fetchNearbyPosts(latitude: Double, longitude: Double, radius: Int = 50) {
    let url = "https://api.qinghejihua.com.cn/api/v1/community/nearby/posts"
    let params = [
        "latitude": latitude,
        "longitude": longitude,
        "radius": radius,
        "page": 1,
        "limit": 10
    ]
    
    // 使用Alamofire或URLSession发送请求
    // 记得添加Authorization header
}
```

### 3.3 数据模型
```swift
struct NearbyPost {
    let id: String
    let content: String
    let author: Author
    let location: String
    let distance: Double
    let distanceText: String
    let isLiked: Bool
    let isBookmarked: Bool
    // ... 其他字段
}

struct Author {
    let id: Int
    let nickname: String
    let avatar: String
    let isVerified: Bool
    let level: Int
}
```

## 3. 用户资料API

### 3.1 获取用户资料
```
GET /users/{userId}/profile
```

**路径参数**:
- `userId` (必需): 用户ID

**响应**:
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "nickname": "青禾测试用户",
    "avatar": "https://example.com/avatar.jpg",
    "bio": null,
    "location": "",
    "level": 1,
    "isVerified": false,
    "followersCount": -1,
    "followingCount": 0,
    "postsCount": 53,
    "createdAt": "2025-06-21 20:14:38",
    "lastActiveAt": null,
    "isFollowing": false,
    "isMe": true
  }
}
```

**错误响应**:
```json
{
  "status": "error",
  "message": "用户不存在"
}
```

### 3.2 获取当前用户信息
```
GET /auth/me
```

**响应**:
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": 1,
      "phone": "19820722496",
      "nickname": "青禾测试用户",
      "avatar": "https://example.com/avatar.jpg",
      "status": "active",
      "lastLoginTime": "2025-08-09 15:40:15",
      "createdAt": "2025-06-21 20:14:38"
    }
  }
}
```

## 4. iOS实现要点

### 4.1 统一响应格式
所有API响应都使用统一格式：
- 成功: `{"status": "success", "data": {...}}`
- 失败: `{"status": "error", "message": "错误信息"}`

### 4.2 错误处理
- **401**: Token过期，需要重新登录
- **400**: 参数错误，检查经纬度格式
- **404**: 资源不存在（如用户不存在）
- **429**: 请求过于频繁，需要限流
- **500**: 服务器错误，稍后重试

### 4.3 性能优化建议
1. **缓存位置**: 避免频繁获取GPS位置
2. **分页加载**: 实现上拉加载更多
3. **距离阈值**: 位置变化超过一定距离才刷新
4. **后台刷新**: 合理控制后台数据更新频率

## 5. 功能特性

✅ **地理位置筛选**: 基于经纬度精确筛选  
✅ **距离计算**: 自动计算并显示距离  
✅ **分页支持**: 完整的分页信息  
✅ **用户状态**: 个性化的点赞收藏状态  
✅ **实时数据**: 最新的帖子和用户信息  

## 6. 注意事项

1. **位置精度**: 建议使用GPS获取精确位置
2. **隐私保护**: 遵循iOS位置权限最佳实践
3. **网络优化**: 合理控制请求频率
4. **用户体验**: 提供位置加载状态提示
5. **错误处理**: 优雅处理网络和位置获取失败
