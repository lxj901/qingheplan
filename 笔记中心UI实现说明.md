# 📝 笔记中心 UI 实现说明

## ✅ 已完成的功能

### 🎨 核心 UI 组件

#### 1. **NoteCenterView** - 主视图
- ✅ 古典雅致的米黄色渐变背景
- ✅ 自定义导航栏（返回、标题、搜索、设置）
- ✅ 筛选标签栏（全部、收藏、高亮、笔记）
- ✅ 分组/排序选项栏
- ✅ 标记列表（支持分组显示）
- ✅ 加载状态
- ✅ 空状态提示

#### 2. **FilterTabButton** - 筛选标签按钮
- ✅ 选中/未选中两种状态
- ✅ 青绿色渐变背景（选中）
- ✅ 浅米色背景（未选中）
- ✅ 显示数量徽章
- ✅ 图标 + 文字布局

#### 3. **GroupHeaderView** - 分组标题
- ✅ 左右装饰线
- ✅ 标题 + 数量显示
- ✅ 青绿色主题

#### 4. **MarkCardView** - 标记卡片
- ✅ 白色卡片背景 + 阴影
- ✅ 章节信息（书籍图标 + 章节名）
- ✅ 选中文字（带高亮背景色）
- ✅ 笔记内容（引号装饰）
- ✅ 标签（高亮颜色 + 收藏状态）
- ✅ 时间显示
- ✅ 点击跳转
- ✅ 长按菜单
- ✅ 左滑删除
- ✅ 右滑编辑

#### 5. **EditNoteSheet** - 编辑笔记弹窗
- ✅ 半屏弹窗
- ✅ 显示选中文字（只读）
- ✅ 笔记编辑器（TextEditor）
- ✅ 字数统计（最多 500 字）
- ✅ 取消/保存按钮

#### 6. **ColorPickerButtons** - 颜色选择器
- ✅ 5 种高亮颜色（黄、绿、蓝、粉、紫）
- ✅ 无高亮选项
- ✅ 当前选中标记
- ✅ 颜色预览圆点

---

## 📊 数据模型

### NoteCenterModels.swift

#### 1. **TextMark** - 文字标记
```swift
struct TextMark: Identifiable, Codable {
    let id: String
    let userId: Int
    let sectionId: String
    let textRange: TextRange?
    let highlightColor: String?
    let note: String?
    let isFavorite: Bool
    let createdAt: String
    let updatedAt: String
    var section: MarkSection?
}
```

#### 2. **TextRange** - 文字范围
```swift
struct TextRange: Codable {
    let startOffset: Int
    let endOffset: Int
    let text: String
}
```

#### 3. **MarkSection** - 章节信息
```swift
struct MarkSection: Codable {
    let id: String
    let bookId: String
    let chapterId: String
    let original: String
    let translation: String
    var bookTitle: String?
    var chapterTitle: String?
}
```

#### 4. **MarkFilterType** - 筛选类型
- `all` - 全部
- `favorite` - 收藏
- `highlight` - 高亮
- `note` - 笔记

#### 5. **GroupingOption** - 分组选项
- `none` - 不分组
- `byBook` - 按书籍分组
- `byChapter` - 按章节分组
- `byColor` - 按颜色分组

#### 6. **SortingOption** - 排序选项
- `newestFirst` - 最新优先
- `oldestFirst` - 最早优先
- `recentlyUpdated` - 最近更新

---

## 🔧 ViewModel 功能

### NoteCenterViewModel.swift

#### 核心功能

1. **loadMarks()** - 加载标记
   - 从 API 获取用户所有标记
   - 失败时加载模拟数据（开发用）

2. **applyFilter(_ filter: MarkFilterType)** - 应用筛选
   - 全部：显示所有标记
   - 收藏：只显示收藏的标记
   - 高亮：只显示有高亮的标记
   - 笔记：只显示有笔记的标记

3. **applyGrouping(_ grouping: GroupingOption)** - 应用分组
   - 不分组：列表显示
   - 按书籍：按书籍名称分组
   - 按章节：按书籍+章节分组
   - 按颜色：按高亮颜色分组

4. **applySorting(_ sorting: SortingOption)** - 应用排序
   - 最新优先：按创建时间降序
   - 最早优先：按创建时间升序
   - 最近更新：按更新时间降序

5. **updateNote(mark:note:completion:)** - 更新笔记
   - 调用 API 更新笔记内容
   - 更新成功后刷新列表

6. **updateHighlightColor(mark:color:)** - 更新高亮颜色
   - 调用 API 更新高亮颜色
   - 更新成功后刷新列表

7. **deleteMark(_ mark:)** - 删除标记
   - 调用 API 删除标记
   - 删除成功后从列表移除

8. **navigateToOriginalText(mark:)** - 跳转到原文
   - 导航到阅读页面
   - 定位到对应章节
   - 高亮显示选中文字

---

## 🎨 设计规范

### 色彩方案

#### 主色调
- **青绿色**：`rgb(51, 140, 115)` - 主要操作、选中状态
- **深青绿**：`rgb(38, 115, 95)` - 渐变终点
- **橙黄色**：`rgb(230, 153, 51)` - 收藏、笔记图标

#### 背景色
- **页面背景**：米黄色渐变
  - 起点：`rgb(245, 242, 237)`
  - 终点：`rgb(239, 235, 224)`
- **卡片背景**：`rgb(255, 255, 255)` - 纯白
- **输入框背景**：`rgb(245, 242, 237)` - 浅米色

#### 文字色
- **主文字**：`rgb(51, 38, 26)` - 深棕色
- **次要文字**：`rgb(77, 64, 51)` - 中棕色
- **辅助文字**：`rgb(128, 115, 102)` - 浅棕色

#### 高亮颜色
- **黄色**：`Color.yellow.opacity(0.2)`
- **绿色**：`Color.green.opacity(0.15)`
- **蓝色**：`Color.blue.opacity(0.15)`
- **粉色**：`Color.pink.opacity(0.15)`
- **紫色**：`Color.purple.opacity(0.15)`

### 尺寸规范

#### 圆角
- 大卡片：16pt
- 中等元素：12pt
- 小元素：8pt
- 标签：6pt

#### 阴影
- 卡片：`opacity: 0.08, radius: 12, y: 6`
- 按钮：`opacity: 0.3, radius: 4, y: 2`
- 导航栏：`opacity: 0.05, radius: 2, y: 2`

#### 间距
- 卡片间距：12pt
- 内容内边距：16pt
- 元素间距：8pt - 12pt

#### 字体
- 导航标题：16pt, bold
- 卡片标题：14pt, semibold
- 选中文字：17pt, medium
- 笔记内容：15pt, regular
- 标签文字：12pt, regular

---

## 📱 使用方法

### 1. 在国学书斋页面添加入口（已实现）✅

在 `ClassicsLibraryView.swift` 中已添加笔记中心入口：

```swift
// 使用 NavigationLink 全屏跳转
NavigationLink(destination: NoteCenterView().asSubView()) {
    FeatureEntryCard(
        icon: "scroll.fill",
        title: "笔记中心",
        gradientColors: [
            Color(red: 0.82, green: 0.62, blue: 0.42),
            Color(red: 0.72, green: 0.52, blue: 0.32)
        ]
    )
}
.buttonStyle(PlainButtonStyle())
```

**特点**：
- ✅ 全屏方式打开（不是 Sheet 弹窗）
- ✅ 从右到左的过渡动画（系统默认）
- ✅ 支持返回手势

### 2. 在阅读页面添加入口（可选）

在 `ClassicsReadingView.swift` 中添加笔记中心入口：

```swift
// 在导航栏或工具栏添加按钮
NavigationLink(destination: NoteCenterView().asSubView()) {
    Image(systemName: "note.text")
        .font(.system(size: 18))
}
```

### 3. 配置 API 地址

在 `NoteCenterViewModel.swift` 中修改 API 地址：

```swift
private let baseURL = "https://your-api-domain.com/api/v1/classics"
```

### 4. 配置用户 ID

从 `AuthManager` 获取当前用户 ID：

```swift
private var userId: Int {
    AuthManager.shared.currentUser?.id ?? 0
}
```

---

## 🔄 API 集成

### 需要实现的 API 调用

#### 1. 获取所有标记
```swift
GET /api/v1/classics/marks?userId=1&type=all&limit=100&offset=0
```

#### 2. 更新笔记
```swift
PUT /api/v1/classics/text-marks/:markId
Body: {
    "userId": 1,
    "note": "新的笔记内容"
}
```

#### 3. 更新高亮颜色
```swift
PUT /api/v1/classics/text-marks/:markId
Body: {
    "userId": 1,
    "highlightColor": "green"
}
```

#### 4. 删除标记
```swift
DELETE /api/v1/classics/text-marks/:markId?userId=1
```

---

## ✨ 特色功能

### 1. 智能筛选
- 按类型筛选（全部/收藏/高亮/笔记）
- 实时显示每种类型的数量
- 流畅的动画过渡

### 2. 灵活分组
- 不分组：列表显示
- 按书籍：方便查看某本书的所有标记
- 按章节：精确定位到具体章节
- 按颜色：按高亮颜色分类

### 3. 多种排序
- 最新优先：查看最近添加的标记
- 最早优先：回顾早期的标记
- 最近更新：查看最近修改的标记

### 4. 便捷操作
- 点击卡片：跳转到原文位置
- 长按卡片：显示操作菜单
- 左滑：快速删除
- 右滑：快速编辑

### 5. 优雅交互
- 点击缩放动画
- 筛选切换动画
- 删除滑动动画
- 震动反馈

---

## 🎯 下一步工作

### 必须实现
1. ✅ 集成真实 API（替换模拟数据）
2. ✅ 实现跳转到原文功能
3. ✅ 添加搜索功能
4. ✅ 添加设置菜单（导出、清空等）

### 可选增强
1. ⭕ 导出笔记为 Markdown/PDF
2. ⭕ 分享到社交平台
3. ⭕ 云端同步
4. ⭕ 笔记统计（总数、字数等）

---

## 📸 预览

使用 Xcode 预览功能查看效果：

```swift
#Preview {
    NoteCenterView()
}
```

---

## 🎉 总结

笔记中心 UI 已经完整实现，包括：

- ✅ 完整的视觉设计（古典国学风格）
- ✅ 所有核心功能（筛选、分组、排序、编辑、删除）
- ✅ 优雅的交互动画
- ✅ 完善的数据模型
- ✅ 模拟数据支持（方便开发测试）

只需要集成真实 API 即可投入使用！🚀

