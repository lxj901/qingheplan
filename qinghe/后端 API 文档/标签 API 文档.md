# 青禾计划 - 标签功能API文档

## 概述

青禾计划标签功能提供了完整的标签管理和基于标签的内容检索功能。用户可以通过标签快速找到相关的帖子内容。

**基础URL**: https://api.qinghejihua.com.cn/api/v1

## 🏷️ 标签功能特性

- ✅ 支持中文标签（如：`运动`、`健身`、`瑜伽`）
- ✅ 支持英文标签（如：`fitness`、`workout`、`yoga`）
- ✅ 支持带#号标签（如：`#运动`、`#健身`）
- ✅ 智能标签匹配（`#运动` 会匹配 `运动` 标签的内容）
- ✅ 分页和排序功能
- ✅ 无需认证即可访问

## 📋 API接口列表

### 1. 根据标签获取帖子列表

**接口地址**: `GET /community/tags/:tagName/posts`

**功能描述**: 获取包含指定标签的帖子列表，支持分页、排序和多种标签格式

**需要认证**: 否

#### 请求参数

| 参数名 | 位置 | 类型 | 必需 | 描述 |
|--------|------|------|------|------|
| tagName | path | string | 是 | 标签名称 |
| page | query | integer | 否 | 页码，默认1 |
| limit | query | integer | 否 | 每页数量，默认20，最大100 |
| sortBy | query | string | 否 | 排序方式，默认latest |

#### 标签格式说明

| 格式 | 示例 | URL编码示例 | 说明 |
|------|------|-------------|------|
| 中文标签 | `运动` | `%E8%BF%90%E5%8A%A8` | 直接使用中文标签名 |
| 英文标签 | `fitness` | `fitness` | 直接使用英文标签名 |
| 带#号标签 | `#运动` | `%23%E8%BF%90%E5%8A%A8` | 自动去掉#号进行匹配 |

#### 排序方式

| 值 | 说明 |
|----|------|
| `latest` | 按最新时间排序（默认） |
| `hot` | 按热度排序（综合点赞、评论、分享） |
| `popular` | 按流行度排序（基于互动数据） |

#### 请求示例

```bash
# 1. 获取"健身"标签的帖子（中文标签）
curl -X GET \
  "https://api.qinghejihua.com.cn/api/v1/community/tags/健身/posts?page=1&limit=10&sortBy=latest" \
  -H "Content-Type: application/json"

# 2. 获取带#号标签的帖子（需要URL编码）
curl -X GET \
  "https://api.qinghejihua.com.cn/api/v1/community/tags/%23%E5%81%A5%E8%BA%AB/posts?page=1&limit=5" \
  -H "Content-Type: application/json"

# 3. 获取英文标签的帖子
curl -X GET \
  "https://api.qinghejihua.com.cn/api/v1/community/tags/fitness/posts?page=1&limit=10" \
  -H "Content-Type: application/json"

# 4. 获取"运动"标签的帖子，按热度排序
curl -X GET \
  "https://api.qinghejihua.com.cn/api/v1/community/tags/%E8%BF%90%E5%8A%A8/posts?page=1&limit=20&sortBy=hot" \
  -H "Content-Type: application/json"
```

#### 响应格式

```json
{
  "success": true,
  "data": {
    "tagName": "#健身",
    "items": [
      {
        "id": "post-id-1",
        "authorId": 1,
        "content": "今天的运动完成了！消耗了很多卡路里 🏃‍♂️",
        "images": [],
        "video": null,
        "tags": ["运动", "健身", "卡路里"],
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
        "lastActiveAt": "2025-08-06 08:56:09",
        "createdAt": "2025-08-06 08:56:09",
        "updatedAt": "2025-08-06 08:56:09",
        "isLiked": false,
        "isBookmarked": false,
        "author": {
          "id": 1,
          "nickname": "青禾测试用户",
          "avatar": "https://example.com/avatar.jpg",
          "isVerified": false,
          "level": 1
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 4,
      "totalPages": 1,
      "hasNext": false,
      "hasPrev": false
    }
  }
}
```

#### 响应字段说明

**帖子对象字段**:

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | string | 帖子唯一标识 |
| authorId | integer | 作者用户ID |
| content | string | 帖子内容 |
| images | array | 图片URL数组 |
| video | string/null | 视频URL |
| tags | array | 标签数组 |
| likesCount | integer | 点赞数 |
| commentsCount | integer | 评论数 |
| sharesCount | integer | 分享数 |
| bookmarksCount | integer | 收藏数 |
| viewsCount | integer | 浏览数 |
| allowComments | boolean | 是否允许评论 |
| allowShares | boolean | 是否允许分享 |
| visibility | string | 可见性：public/private |
| status | string | 状态：active/deleted |
| isTop | boolean | 是否置顶 |
| hotScore | number | 热度分数 |
| lastActiveAt | string | 最后活跃时间 |
| createdAt | string | 创建时间 |
| updatedAt | string | 更新时间 |
| isLiked | boolean | 当前用户是否已点赞 |
| isBookmarked | boolean | 当前用户是否已收藏 |

**作者对象字段**:

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | integer | 用户ID |
| nickname | string | 用户昵称 |
| avatar | string | 头像URL |
| isVerified | boolean | 是否认证用户 |
| level | integer | 用户等级 |

**分页对象字段**:

| 字段名 | 类型 | 说明 |
|--------|------|------|
| page | integer | 当前页码 |
| limit | integer | 每页数量 |
| total | integer | 总记录数 |
| totalPages | integer | 总页数 |
| hasNext | boolean | 是否有下一页 |
| hasPrev | boolean | 是否有上一页 |

### 2. 获取热门标签列表

**接口地址**: `GET /community/tags/popular`

**功能描述**: 获取当前热门的标签列表

**需要认证**: 否

#### 请求参数

| 参数名 | 位置 | 类型 | 必需 | 描述 |
|--------|------|------|------|------|
| limit | query | integer | 否 | 返回数量，默认10，最大50 |

#### 请求示例

```bash
curl -X GET \
  "https://api.qinghejihua.com.cn/api/v1/community/tags/popular?limit=10" \
  -H "Content-Type: application/json"
```

#### 响应格式

```json
{
  "success": true,
  "data": [
    {
      "trend": "健身",
      "count": 1250
    },
    {
      "trend": "运动",
      "count": 980
    },
    {
      "trend": "瑜伽",
      "count": 756
    }
  ]
}
```

## 🔧 使用建议

### 1. URL编码处理

对于中文标签和带特殊字符的标签，需要进行URL编码：

```javascript
// JavaScript示例
const tagName = "#健身";
const encodedTag = encodeURIComponent(tagName);
// 结果: %23%E5%81%A5%E8%BA%AB
```

### 2. 错误处理

```javascript
// 处理API响应
fetch(`https://api.qinghejihua.com.cn/api/v1/community/tags/${encodedTag}/posts`)
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      console.log('帖子列表:', data.data.items);
      console.log('分页信息:', data.data.pagination);
    } else {
      console.error('API错误:', data.message);
    }
  })
  .catch(error => {
    console.error('网络错误:', error);
  });
```

### 3. 分页加载

```javascript
// 分页加载示例
const loadTagPosts = async (tagName, page = 1, limit = 20) => {
  const encodedTag = encodeURIComponent(tagName);
  const response = await fetch(
    `https://api.qinghejihua.com.cn/api/v1/community/tags/${encodedTag}/posts?page=${page}&limit=${limit}`
  );
  const data = await response.json();
  
  if (data.success) {
    return {
      posts: data.data.items,
      pagination: data.data.pagination
    };
  }
  throw new Error(data.message || '获取帖子失败');
};
```

## 📊 测试数据

当前系统中包含以下测试标签和数据：

| 标签名 | 帖子数量 | 说明 |
|--------|----------|------|
| 健身 | 4条 | 健身相关内容 |
| 运动 | 6条 | 运动相关内容 |
| 打卡 | 3条 | 打卡记录相关 |
| 卡路里 | 4条 | 卡路里消耗相关 |

## 🎯 总结

青禾计划标签API提供了强大而灵活的标签检索功能：

✅ **多格式支持** - 中文、英文、带#号标签全支持  
✅ **智能匹配** - #运动自动匹配运动标签内容  
✅ **完整分页** - 支持分页和多种排序方式  
✅ **无需认证** - 公开访问，便于集成  
✅ **详细数据** - 返回完整的帖子和作者信息  

前端可以基于这个API快速实现标签页面和内容检索功能。