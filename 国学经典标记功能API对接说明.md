# 国学经典阅读页面标记功能 API 对接说明

## 概述

已成功对接国学经典阅读页面的**高亮/收藏/笔记**功能到后端 API。

## 修改文件

### 1. ClassicsAPIService.swift

#### 新增数据模型

```swift
/// 标记信息（收藏、高亮、笔记）
struct ClassicsMark: Codable, Identifiable {
    let id: String
    let userId: Int?
    let sectionId: String
    let isFavorite: Bool?
    let highlight: String?  // yellow/green/blue/red
    let note: String?
    let createdAt: String?
    let updatedAt: String?
}

/// 带句段信息的标记（用于获取标记列表）
struct ClassicsMarkWithSection: Codable, Identifiable {
    let id: String
    let sectionId: String
    let isFavorite: Bool?
    let highlight: String?
    let note: String?
    let section: ClassicsMarkSection?
    let createdAt: String?
}

/// 标记关联的句段信息
struct ClassicsMarkSection: Codable {
    let original: String
    let bookId: String
    let chapterId: String
}
```

#### 新增 API 方法

1. **addOrUpdateMark** - 添加/更新标记
   - 参数：userId, sectionId, isFavorite, highlight, note
   - 支持单独或组合更新收藏/高亮/笔记

2. **getMarks** - 获取用户标记列表
   - 参数：userId, bookId (可选), isFavorite (可选)
   - 返回用户的所有标记数据

### 2. ClassicsReadingView.swift

#### 新增状态变量

```swift
@State private var currentSectionId: String? = nil  // 当前操作的 sectionId
@State private var sectionMarks: [String: ClassicsMark] = [:]  // 每个 section 的标记数据
```

#### 新增 API 对接方法

1. **addFavorite(sectionId:)** - 添加收藏
   - 调用 API 保存收藏状态
   - 更新本地状态和 UI

2. **addHighlight(sectionId:color:)** - 添加/更新高亮
   - 调用 API 保存高亮颜色
   - 支持 yellow/green/blue/red 四种颜色

3. **addNote(sectionId:noteContent:)** - 添加/更新笔记
   - 调用 API 保存笔记内容
   - 限制 300 字以内

4. **loadUserMarks(bookId:)** - 加载用户标记数据
   - 在页面加载时调用
   - 将标记数据存入 `sectionMarks` 字典

#### 修改点

1. **收藏按钮** (第 903-914 行)
   - 点击收藏时保存 sectionId
   - 调用 `addFavorite` API

2. **高亮选择器** (第 1179-1184 行)
   - 选择颜色时调用 `addHighlight` API
   - 传递 sectionId 和颜色参数

3. **笔记保存** (第 1270-1278 行)
   - 保存笔记时调用 `addNote` API
   - 传递 sectionId 和笔记内容

4. **页面初始化** (第 1581 行)
   - 添加 `await loadUserMarks(bookId: bookId)`
   - 加载用户已有的标记数据

## API 端点

### 基础 URL
```
https://api.qinghejihua.com.cn/api/v1/classics
```

### 接口列表

#### 1. 添加/更新标记
```http
POST /marks
Content-Type: application/json
Authorization: Bearer {token}

{
  "userId": 123,
  "sectionId": "uuid",
  "isFavorite": true,          // 可选
  "highlight": "yellow",       // 可选: yellow/green/blue/red
  "note": "这句话很有道理"      // 可选
}
```

**响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "uuid",
    "isFavorite": true,
    "highlight": "yellow",
    "note": "这句话很有道理"
  }
}
```

#### 2. 获取用户标记
```http
GET /marks?userId=123&bookId=lunyu&isFavorite=true
Authorization: Bearer {token}
```

**响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "id": "uuid",
      "sectionId": "uuid",
      "isFavorite": true,
      "highlight": "yellow",
      "note": "这句话很有道理",
      "section": {
        "original": "子曰：「学而时习之...",
        "bookId": "lunyu",
        "chapterId": "xueer"
      }
    }
  ]
}
```

## 功能说明

### 1. 收藏功能
- 用户长按选中文字后,点击"收藏"按钮
- 自动调用 API 保存收藏状态 (isFavorite: true)
- 显示 Toast 提示"已添加收藏"

### 2. 高亮功能
- 用户长按选中文字后,点击"高亮"按钮
- 弹出颜色选择器(黄/绿/蓝/红)
- 选择颜色后调用 API 保存高亮颜色
- 显示 Toast 提示"已添加高亮"

### 3. 笔记功能
- 用户长按选中文字后,点击"笔记"按钮
- 弹出笔记输入面板
- 输入笔记内容(限 300 字)
- 点击保存后调用 API 保存笔记
- 显示 Toast 提示"已保存笔记"

### 4. 数据加载
- 页面加载时自动调用 `loadUserMarks`
- 获取用户在当前书籍的所有标记
- 存储到 `sectionMarks` 字典中
- 可用于显示已收藏/高亮的句段

## 错误处理

所有 API 调用都包含错误处理:
- 用户未登录: 显示"请先登录"
- API 调用失败: 显示具体错误信息
- 使用 Toast 提示向用户反馈结果

## 后续优化建议

1. **UI 状态显示**
   - 根据 `sectionMarks` 数据显示收藏图标
   - 根据高亮颜色渲染文字背景色
   - 在句段旁显示笔记数量标记

2. **离线支持**
   - 缓存标记数据到本地
   - 支持离线查看已标记内容
   - 网络恢复后同步到服务器

3. **批量操作**
   - 支持批量删除标记
   - 支持导出所有笔记
   - 支持分享高亮内容

4. **数据同步**
   - 定期同步最新标记数据
   - 处理多设备同步冲突
   - 实现标记数据的增量更新

## 测试建议

1. **功能测试**
   - 测试收藏/高亮/笔记的添加
   - 测试重复标记的更新
   - 测试标记数据的加载

2. **边界测试**
   - 测试未登录状态
   - 测试网络异常情况
   - 测试笔记字数限制

3. **性能测试**
   - 测试大量标记的加载速度
   - 测试 API 响应时间
   - 测试并发标记操作

## 版本信息

- **修改日期**: 2025-10-20
- **API 版本**: v1
- **文档版本**: 1.0.0
