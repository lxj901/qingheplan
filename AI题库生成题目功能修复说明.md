# AI题库生成题目功能修复说明

## 修复日期
2025-10-21

## 问题描述

1. **书籍和章节选择使用模拟数据**：生成题目页面中的书籍和章节选项是硬编码的，没有从后端API获取真实数据
2. **每种题型数量限制未实现**：虽然每种题型只支持生成5道题，但界面上允许选择最多20道，且没有相应的限制提示

## 修复内容

### 1. 从后端API获取真实的书籍和章节数据

#### 修改文件
`qinghe/ /qinghe/qinghe/AIQuestionGenerateView.swift`

#### 主要改动

**添加状态变量**：
```swift
// 书籍和章节数据
@State private var books: [ClassicsBookAPI] = []
@State private var chapters: [ClassicsChapterAPI] = []
@State private var isLoadingBooks: Bool = false
@State private var isLoadingChapters: Bool = false
@State private var errorMessage: String?
```

**修改书籍选择区域**：
- 从硬编码的4本书改为动态加载所有书籍
- 添加加载状态和空数据提示
- 使用 `ForEach` 遍历 `books` 数组

**修改章节选择区域**：
- 从硬编码的4个章节改为根据选中书籍动态加载章节
- 添加加载状态指示器
- 只在选择了书籍后才显示章节选择区域

**添加数据加载方法**：
```swift
// 加载书籍列表
private func loadBooks() {
    Task {
        let loadedBooks = try await ClassicsAPIService.shared.getBooks(limit: 100)
        // 默认选择第一本书并加载其章节
    }
}

// 加载章节列表
private func loadChapters(bookId: String) {
    Task {
        let bookDetail = try await ClassicsAPIService.shared.getBookDetail(bookId: bookId)
        // 默认选择第一个章节
    }
}
```

### 2. 实现每种题型5道题的限制

#### 修改数量选择区域

**添加限制提示**：
```swift
HStack {
    Text("每种题型生成数量")
    Spacer()
    Text("最多5道")
        .font(.system(size: 12))
        .foregroundColor(.gray)
}
```

**修改数量上限**：
- 将最大值从20改为5
- 添加按钮禁用状态
- 当达到上限时，按钮变灰且不可点击

**更新生成按钮逻辑**：
```swift
// 生成按钮是否禁用
private var isGenerateButtonDisabled: Bool {
    return isGenerating || !canGenerate
}

// 是否可以生成
private var canGenerate: Bool {
    return !selectedBookId.isEmpty && 
           !selectedChapterId.isEmpty && 
           !selectedQuestionTypes.isEmpty &&
           countPerType >= 1 && 
           countPerType <= 5
}

// 生成按钮提示
private var generateButtonHint: String {
    if selectedBookId.isEmpty {
        return "请选择书籍"
    } else if selectedChapterId.isEmpty {
        return "请选择章节"
    } else if selectedQuestionTypes.isEmpty {
        return "请至少选择一种题型"
    } else if countPerType < 1 || countPerType > 5 {
        return "每种题型数量必须在1-5之间"
    }
    return ""
}
```

### 3. 改进用户体验

**添加加载视图**：
```swift
private var loadingView: some View {
    VStack(spacing: 16) {
        Spacer()
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(1.5)
        Text("加载书籍列表...")
            .font(.system(size: 14))
            .foregroundColor(.gray)
        Spacer()
    }
}
```

**添加错误提示**：
```swift
.alert("错误", isPresented: .constant(errorMessage != nil)) {
    Button("确定", role: .cancel) {
        errorMessage = nil
    }
} message: {
    if let errorMessage = errorMessage {
        Text(errorMessage)
    }
}
```

**添加验证提示**：
- 在生成按钮下方显示红色提示文字
- 明确告知用户缺少哪些必填项

## 技术细节

### API调用
使用 `ClassicsAPIService.shared` 获取数据：
- `getBooks(limit: 100)` - 获取书籍列表
- `getBookDetail(bookId:)` - 获取书籍详情（包含章节列表）

### 数据模型
- `ClassicsBookAPI` - 书籍信息（包含 `id`, `title` 等属性）
- `ClassicsChapterAPI` - 章节信息（包含 `id`, `chapterTitle` 等属性）

### 注意事项
⚠️ **重要**：`ClassicsChapterAPI` 的章节标题属性是 `chapterTitle` 而不是 `title`

## 编译结果

✅ **编译成功** (2025-10-21)
- 使用 iPhone 16 模拟器 (iOS 18.5)
- 使用 Xcode 16 编译器
- 无错误，仅有少量警告（与本次修复无关）

## 功能验证

### 修复前
- ❌ 书籍选择：只有4本硬编码的书（论语、大学、中庸、孟子）
- ❌ 章节选择：只有4个硬编码的章节（学而、为政、八佾、里仁）
- ❌ 数量限制：可以选择1-20道题，超过5道也能点击生成按钮

### 修复后
- ✅ 书籍选择：从后端API动态加载所有可用书籍
- ✅ 章节选择：根据选中的书籍动态加载对应章节
- ✅ 数量限制：最多只能选择5道题，超过5道按钮禁用
- ✅ 验证提示：未选择书籍/章节时显示明确提示
- ✅ 加载状态：显示加载指示器，提升用户体验

## 后续建议

1. **缓存优化**：考虑缓存书籍列表，避免每次打开页面都重新加载
2. **错误重试**：添加网络错误时的重试机制
3. **默认选择**：可以根据用户最近使用的书籍/章节进行智能默认选择
4. **章节搜索**：当章节数量较多时，添加搜索功能
5. **批量生成**：考虑支持一次性为多个章节生成题目

## 相关文件

- `qinghe/ /qinghe/qinghe/AIQuestionGenerateView.swift` - 生成题目视图（主要修改）
- `qinghe/ /qinghe/qinghe/ClassicsAPIService.swift` - API服务（数据模型定义）
- `qinghe/ /qinghe/qinghe/AIQuestionViewModel.swift` - 题库视图模型
- `qinghe/ /qinghe/qinghe/AIQuestionModels.swift` - 题目数据模型

## 测试建议

1. **书籍加载测试**：
   - 打开生成题目页面，验证书籍列表是否正确加载
   - 检查是否显示所有可用书籍

2. **章节加载测试**：
   - 选择不同书籍，验证章节列表是否正确切换
   - 检查章节标题是否正确显示

3. **数量限制测试**：
   - 尝试增加数量到5，验证是否能继续增加
   - 验证超过5道时按钮是否禁用

4. **验证提示测试**：
   - 不选择书籍时点击生成，验证提示信息
   - 不选择章节时点击生成，验证提示信息
   - 不选择题型时点击生成，验证提示信息

5. **网络错误测试**：
   - 断网情况下打开页面，验证错误提示
   - 网络恢复后是否能正常加载

## 总结

本次修复解决了AI题库生成题目功能的两个主要问题：
1. 将硬编码的模拟数据替换为从后端API获取的真实数据
2. 实现了每种题型最多5道题的限制逻辑

修复后的功能更加完善，用户体验得到显著提升，且符合业务需求。

