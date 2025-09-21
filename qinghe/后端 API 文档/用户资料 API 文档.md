# 青禾计划 - 用户资料和关注系统 API 文档

## 基础信息

**API 基础域名**: `https://api.qinghejihua.com.cn`  
**API 版本**: v1  
**基础路径**: `/api/v1/users`

## 认证说明

- 🔒 **需要认证**: 需要在请求头中包含 `Authorization: Bearer <token>`
- 🔓 **可选认证**: 可以不传token，但传了token会返回更多信息（如关注状态）
- ⚠️ **无需认证**: 不需要token

## 用户资料管理

### 1. 获取用户资料

**接口**: `GET /api/v1/users/{userId}/profile`  
**认证**: 🔓 可选认证  
**描述**: 获取指定用户的详细资料信息

#### 请求参数

| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| userId | string | path | ✅ | 用户ID |

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 123,
    "nickname": "青禾用户",
    "avatar": "https://example.com/avatar.jpg",
    "backgroundImage": "https://example.com/background.jpg",
    "bio": "热爱生活，追求健康",
    "location": "北京市",
    "gender": "female",
    "birthday": "1995-08-20",
    "constellation": "狮子座",
    "hometown": "广州市天河区",
    "school": "北京大学",
    "ipLocation": "广东省深圳市",
    "level": 5,
    "isVerified": true,
    "followersCount": 128,
    "followingCount": 56,
    "postsCount": 89,
    "createdAt": "2025-06-21 20:14:38",
    "lastActiveAt": "2025-09-03T10:30:00.000Z",
    "isFollowing": false,
    "isFollowedBy": false,
    "isBlocked": false,
    "isMe": false
  }
}
```

#### 字段说明

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | string | 用户唯一标识 |
| nickname | string | 用户昵称 |
| avatar | string | 头像URL |
| backgroundImage | string | 背景图URL |
| bio | string | 个人简介 |
| location | string | 所在地区 |
| gender | string | 性别（male/female/private） |
| birthday | string | 生日（YYYY-MM-DD格式） |
| constellation | string | 星座（系统自动计算） |
| hometown | string | 家乡 |
| school | string | 学校 |
| ipLocation | string | IP归属地（系统自动获取） |
| level | number | 用户等级 |
| isVerified | boolean | 是否认证用户 |
| followersCount | number | 粉丝数量 |
| followingCount | number | 关注数量 |
| postsCount | number | 帖子数量 |
| createdAt | string | 注册时间 |
| lastActiveAt | string | 最后活跃时间 |
| isFollowing | boolean | 当前用户是否关注了该用户 |
| isFollowedBy | boolean | 该用户是否关注了当前用户 |
| isBlocked | boolean | 当前用户是否屏蔽了该用户 |
| isMe | boolean | 是否为当前用户本人 |

### 2. 更新用户资料

**接口**: `PUT /api/v1/users/profile`  
**认证**: 🔒 需要认证  
**描述**: 更新当前用户的资料信息

#### 请求体

```json
{
  "nickname": "新昵称",
  "bio": "新的个人简介",
  "location": "新的地区",
  "avatar": "https://example.com/new-avatar.jpg",
  "backgroundImage": "https://example.com/background.jpg",
  "gender": "male",
  "birthday": "1990-01-01",
  "hometown": "上海市",
  "school": "清华大学"
}
```

#### 请求参数

| 参数名 | 类型 | 必填 | 长度限制 | 说明 |
|--------|------|------|----------|------|
| nickname | string | ❌ | 2-50字符 | 用户昵称 |
| bio | string | ❌ | 最大500字符 | 个人简介 |
| location | string | ❌ | 最大100字符 | 所在地区 |
| avatar | string | ❌ | - | 头像URL |
| backgroundImage | string | ❌ | - | 背景图URL |
| gender | string | ❌ | - | 性别（male/female/private） |
| birthday | string | ❌ | YYYY-MM-DD | 生日日期 |
| hometown | string | ❌ | 最大100字符 | 家乡 |
| school | string | ❌ | 最大100字符 | 学校 |

#### 注意事项

- **星座字段**：系统会根据生日自动计算星座，无需手动设置
- **IP归属地**：系统自动获取，用户无法修改
- **性别默认值**：如不设置，默认为 `private`（不透露）
- **生日限制**：必须是有效的历史日期，不能是未来日期

#### 响应示例

```json
{
  "success": true,
  "data": {
    "id": 123,
    "nickname": "新昵称",
    "avatar": "https://example.com/new-avatar.jpg",
    "backgroundImage": "https://example.com/new-background.jpg",
    "bio": "新的个人简介",
    "location": "新的地区",
    "gender": "male",
    "birthday": "1990-01-01",
    "constellation": "摩羯座",
    "hometown": "上海市",
    "school": "清华大学",
    "ipLocation": "北京市朝阳区",
    "level": 5,
    "isVerified": true,
    "followersCount": 128,
    "followingCount": 56,
    "postsCount": 89
  },
  "message": "资料更新成功"
}
```

### 3. 获取用户帖子

**接口**: `GET /api/v1/users/{userId}/posts`  
**认证**: 🔓 可选认证  
**描述**: 获取指定用户发布的帖子列表

#### 请求参数

| 参数名 | 类型 | 位置 | 必填 | 默认值 | 说明 |
|--------|------|------|------|--------|------|
| userId | string | path | ✅ | - | 用户ID |
| page | number | query | ❌ | 1 | 页码 |
| limit | number | query | ❌ | 20 | 每页数量 |

#### 可见性规则

- **查看自己的帖子**: 可以看到所有自己的帖子（包括private）
- **查看他人的帖子**:
  - 未关注：只能看到public帖子
  - 已关注：可以看到public和followers帖子

#### 响应示例

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "post123",
        "content": "今天的健身打卡",
        "images": ["https://example.com/image1.jpg"],
        "visibility": "public",
        "likesCount": 25,
        "commentsCount": 8,
        "createdAt": "2025-09-03T10:00:00.000Z",
        "author": {
          "id": 123,
          "nickname": "青禾用户",
          "avatar": "https://example.com/avatar.jpg",
          "isVerified": true
        }
      }
    ],
    "pagination": {
      "page": 1,
      "current_page": 1,
      "limit": 20,
      "total": 89,
      "total_items": 89,
      "totalPages": 5,
      "total_pages": 5,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

### 4. 获取用户收藏

**接口**: `GET /api/v1/users/bookmarks`  
**认证**: 🔒 需要认证  
**描述**: 获取当前用户收藏的帖子列表

#### 请求参数

| 参数名 | 类型 | 位置 | 必填 | 默认值 | 说明 |
|--------|------|------|------|--------|------|
| page | number | query | ❌ | 1 | 页码 |
| limit | number | query | ❌ | 20 | 每页数量 |

#### 响应示例

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "post456",
        "content": "很棒的健身分享",
        "images": ["https://example.com/image2.jpg"],
        "visibility": "public",
        "likesCount": 45,
        "commentsCount": 12,
        "createdAt": "2025-09-02T15:30:00.000Z",
        "bookmarkedAt": "2025-09-03T09:00:00.000Z",
        "author": {
          "id": 456,
          "nickname": "健身达人",
          "avatar": "https://example.com/avatar2.jpg",
          "isVerified": false
        }
      }
    ],
    "pagination": {
      "page": 1,
      "current_page": 1,
      "limit": 20,
      "total": 15,
      "total_items": 15,
      "totalPages": 1,
      "total_pages": 1,
      "hasNext": false,
      "hasPrev": false
    }
  }
}
```

## 关注系统

### 5. 关注用户

**接口**: `POST /api/v1/users/{userId}/follow`  
**认证**: 🔒 需要认证  
**描述**: 关注指定用户

#### 请求参数

| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| userId | string | path | ✅ | 要关注的用户ID |

#### 响应示例

```json
{
  "success": true,
  "message": "关注成功"
}
```

#### 错误响应

```json
{
  "success": false,
  "message": "不能关注自己"
}
```

```json
{
  "success": false,
  "message": "已经关注了该用户"
}
```

### 6. 取消关注用户

**接口**: `DELETE /api/v1/users/{userId}/follow`  
**认证**: 🔒 需要认证  
**描述**: 取消关注指定用户

#### 请求参数

| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| userId | string | path | ✅ | 要取消关注的用户ID |

#### 响应示例

```json
{
  "success": true,
  "message": "取消关注成功"
}
```

### 7. 获取关注列表

**接口**: `GET /api/v1/users/{userId}/following`
**认证**: 🔓 可选认证
**描述**: 获取指定用户的关注列表

#### 请求参数

| 参数名 | 类型 | 位置 | 必填 | 默认值 | 说明 |
|--------|------|------|------|--------|------|
| userId | string | path | ✅ | - | 用户ID |
| page | number | query | ❌ | 1 | 页码 |
| limit | number | query | ❌ | 20 | 每页数量 |

#### 响应示例

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 789,
        "nickname": "运动爱好者",
        "avatar": "https://example.com/avatar3.jpg",
        "bio": "每天运动一小时",
        "isVerified": false,
        "level": 3,
        "followersCount": 89,
        "postsCount": 45
      }
    ],
    "pagination": {
      "page": 1,
      "current_page": 1,
      "limit": 20,
      "total": 56,
      "totalPages": 3,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

### 8. 获取粉丝列表

**接口**: `GET /api/v1/users/{userId}/followers`
**认证**: 🔓 可选认证
**描述**: 获取指定用户的粉丝列表

#### 请求参数

| 参数名 | 类型 | 位置 | 必填 | 默认值 | 说明 |
|--------|------|------|------|--------|------|
| userId | string | path | ✅ | - | 用户ID |
| page | number | query | ❌ | 1 | 页码 |
| limit | number | query | ❌ | 20 | 每页数量 |

#### 响应示例

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 101,
        "nickname": "健康生活家",
        "avatar": "https://example.com/avatar4.jpg",
        "bio": "追求健康生活方式",
        "isVerified": true,
        "level": 7,
        "followersCount": 234,
        "postsCount": 156
      }
    ],
    "pagination": {
      "page": 1,
      "current_page": 1,
      "limit": 20,
      "total": 128,
      "totalPages": 7,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

## 图片上传

### 图片上传接口

**接口**: `POST /api/v1/upload/image`
**认证**: 🔒 需要认证
**描述**: 上传单张图片文件

#### 请求格式

```http
POST /api/v1/upload/image
Authorization: Bearer <token>
Content-Type: multipart/form-data

form-data:
- image: [图片文件]
```

#### 支持的图片格式
- JPEG (.jpg, .jpeg)
- PNG (.png)
- WebP (.webp)
- GIF (.gif)

#### 文件限制
- 单张图片最大 10MB
- 支持自动压缩和格式转换

#### 响应示例

```json
{
  "success": true,
  "data": {
    "url": "https://cdn.qinghejihua.com.cn/images/20250903/avatar_123456.jpg",
    "thumbnails": {
      "small": "https://cdn.qinghejihua.com.cn/images/20250903/avatar_123456.jpg?x-oss-process=image/resize,w_150,h_150",
      "medium": "https://cdn.qinghejihua.com.cn/images/20250903/avatar_123456.jpg?x-oss-process=image/resize,w_300,h_300",
      "large": "https://cdn.qinghejihua.com.cn/images/20250903/avatar_123456.jpg?x-oss-process=image/resize,w_800,h_600"
    },
    "filename": "images/20250903/avatar_123456.jpg",
    "originalName": "avatar.jpg",
    "size": 102400,
    "mimetype": "image/jpeg",
    "provider": "aliyun"
  },
  "message": "图片上传成功"
}
```

#### 使用方式

**方式一：直接使用URL链接**
```json
{
  "avatar": "https://example.com/avatar.jpg",
  "backgroundImage": "https://example.com/background.jpg"
}
```

**方式二：先上传后使用**
1. 调用图片上传接口获取URL
2. 使用返回的URL更新用户资料

## 屏蔽系统

### 9. 屏蔽用户

**接口**: `POST /api/v1/users/{userId}/block`
**认证**: 🔒 需要认证
**描述**: 屏蔽指定用户

#### 请求参数

| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| userId | string | path | ✅ | 要屏蔽的用户ID |

#### 请求体

```json
{
  "reason": "屏蔽原因（可选）"
}
```

#### 响应示例

```json
{
  "success": true,
  "message": "屏蔽成功"
}
```

### 10. 取消屏蔽用户

**接口**: `DELETE /api/v1/users/{userId}/block`
**认证**: 🔒 需要认证
**描述**: 取消屏蔽指定用户

#### 请求参数

| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| userId | string | path | ✅ | 要取消屏蔽的用户ID |

#### 响应示例

```json
{
  "success": true,
  "message": "取消屏蔽成功"
}
```

### 11. 获取屏蔽列表

**接口**: `GET /api/v1/users/blocked`
**认证**: 🔒 需要认证
**描述**: 获取当前用户的屏蔽列表

#### 请求参数

| 参数名 | 类型 | 位置 | 必填 | 默认值 | 说明 |
|--------|------|------|------|--------|------|
| page | number | query | ❌ | 1 | 页码 |
| limit | number | query | ❌ | 20 | 每页数量 |

#### 响应示例

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "999",
        "nickname": "被屏蔽用户",
        "avatar": "https://example.com/avatar5.jpg",
        "bio": "用户简介",
        "isVerified": false,
        "blockedAt": "2024-08-15T14:20:00.000Z",
        "reason": "发布不当内容"
      }
    ],
    "pagination": {
      "page": 1,
      "current_page": 1,
      "limit": 20,
      "total": 3,
      "totalPages": 1,
      "hasNext": false,
      "hasPrev": false
    }
  }
}
```

## 错误码说明

| HTTP状态码 | 错误类型 | 说明 |
|------------|----------|------|
| 200 | 成功 | 请求成功 |
| 400 | 请求错误 | 参数错误或业务逻辑错误 |
| 401 | 未授权 | 需要登录或token无效 |
| 403 | 禁止访问 | 权限不足 |
| 404 | 未找到 | 用户不存在 |
| 500 | 服务器错误 | 内部服务器错误 |

## 通用错误响应格式

```json
{
  "success": false,
  "message": "错误描述"
}
```

## iOS 开发注意事项

### 1. 网络请求配置

```swift
// 基础URL配置
let baseURL = "https://api.qinghejihua.com.cn/api/v1"

// 请求头配置
var request = URLRequest(url: url)
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
```

### 2. 数据模型建议

```swift
struct UserProfile: Codable {
    let id: Int
    let nickname: String
    let avatar: String?
    let backgroundImage: String?
    let bio: String?
    let location: String?
    let gender: String?
    let birthday: String?
    let constellation: String?
    let hometown: String?
    let school: String?
    let ipLocation: String?
    let level: Int
    let isVerified: Bool
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    let createdAt: String
    let lastActiveAt: String?
    let isFollowing: Bool
    let isFollowedBy: Bool
    let isBlocked: Bool
    let isMe: Bool
}

struct APIResponse<T: Codable>: Codable {
    let status: String
    let data: T?
    let message: String?
}

struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let pagination: Pagination
}

struct Pagination: Codable {
    let page: Int
    let currentPage: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrev: Bool

    enum CodingKeys: String, CodingKey {
        case page, limit, total, hasNext, hasPrev
        case currentPage = "current_page"
        case totalPages = "totalPages"
    }
}
```

### 3. 布尔值处理

API返回的布尔值字段（如`isVerified`、`isFollowing`等）已经在服务端进行了类型转换，iOS端可以直接使用。

### 4. 分页处理

所有列表接口都支持分页，建议实现无限滚动加载：

```swift
func loadMoreData() {
    guard pagination.hasNext else { return }
    let nextPage = pagination.page + 1
    // 发起下一页请求
}
```

### 5. 错误处理

建议统一处理API错误：

```swift
func handleAPIError(_ error: Error) {
    if let apiError = error as? APIError {
        switch apiError.statusCode {
        case 401:
            // 处理未授权，跳转登录
            break
        case 404:
            // 处理资源不存在
            break
        default:
            // 显示错误消息
            showAlert(message: apiError.message)
        }
    }
}
```

---

**文档版本**: v1.1
**最后更新**: 2025年9月3日
**更新内容**:
- 新增用户资料扩展字段（背景图、性别、生日、星座、家乡、学校、IP归属地）
- 统一响应格式为 `success: true/false`
- 更新所有响应示例
- 完善字段说明和验证规则

**联系方式**: 如有问题请联系后端开发团队
