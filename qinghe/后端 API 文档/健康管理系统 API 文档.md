# 🏥 青禾计划健康管理系统 API 文档

## 📋 文档概述

本文档为青禾计划健康管理系统的完整API接口文档，专为iOS前端开发对接使用。系统基于中医理论，集成现代AI技术，提供智能健康管理服务。

### 🔧 技术架构
- **后端框架**: Node.js + Express.js
- **数据库**: MySQL (阿里云RDS)
- **缓存**: Redis
- **AI服务**: DeepSeek Chat API
- **文件存储**: 阿里云OSS
- **认证**: JWT Token

### 🌐 服务器信息
- **服务器地址**: `api.qinghejihua.com.cn`
- **API基础URL**: `https://api.qinghejihua.com.cn/api/v1`
- **健康管理API前缀**: `/api/v1/health`

---

## 🔐 认证机制

### JWT Token 认证
所有健康管理API都需要在请求头中携带JWT Token：

```http
Authorization: Bearer <your_jwt_token>
```

### Token 获取
通过用户登录接口获取Token：
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "phone": "手机号",
  "password": "密码"
}
```

**响应示例**:
```json
{
  "status": "success",
  "message": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "phone": "13800138000",
      "nickname": "用户昵称"
    }
  }
}
```

---

## 📱 iOS 集成说明

### 网络请求配置
```swift
// 基础URL配置
let baseURL = "https://api.qinghejihua.com.cn"
let healthAPIPrefix = "/api/v1/health"

// 请求头配置
var request = URLRequest(url: url)
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
```

### 错误处理
API统一返回格式：
```json
{
  "success": true/false,
  "message": "操作结果描述",
  "data": {}, // 成功时的数据
  "error": "错误信息" // 失败时的错误信息
}
```

---

## 🏥 健康管理 API 接口

### 1. 👅 舌诊分析系统

#### 1.1 舌诊分析
**接口**: `POST /api/v1/health/tongue/analyze`

**功能**: 上传舌诊图片进行AI分析

**请求参数**:
```json
{
  "imageUrl": "图片URL地址",
  "description": "可选的描述信息"
}
```

**iOS 示例**:
```swift
let parameters = [
    "imageUrl": "https://example.com/tongue_image.jpg",
    "description": "舌诊图片分析"
]
```

**响应示例**:
```json
{
  "success": true,
  "message": "舌诊分析完成",
  "data": {
    "analysisId": 6,
    "analyzedAt": "2025-09-22T12:44:50.756Z"
  }
}
```

#### 1.2 获取舌诊历史记录
**接口**: `GET /api/v1/health/tongue/history`

**功能**: 获取用户的舌诊分析历史记录

**请求参数**: 无

**响应示例**:
```json
{
  "success": true,
  "data": {
    "records": [
      {
        "id": 6,
        "originalImageUrl": "图片URL",
        "analysisStatus": "completed",
        "analyzedAt": "2025-09-22 20:44:50",
        "created_at": "2025-09-22 20:44:49"
      }
    ]
  }
}
```

#### 1.3 获取单个舌诊记录详情
**接口**: `GET /api/v1/health/tongue/{id}`

**功能**: 获取指定舌诊记录的详细信息

**路径参数**:
- `id`: 舌诊记录ID

**响应示例**:
```json
{
  "success": true,
  "data": {
    "id": "6",
    "userId": 1,
    "originalImageUrl": "图片URL",
    "analysisStatus": "completed",
    "constitutionAnalysis": "体质分析结果",
    "tongueCharacteristics": "舌象特征",
    "syndromeAnalysis": "证候分析",
    "treatmentAdvice": "调理建议",
    "primaryConstitution": "主要体质",
    "constitutionScore": "体质评分",
    "apiProvider": "aliyun",
    "analyzedAt": "2025-09-22 20:44:50"
  }
}
```

### 2. 😊 面诊分析系统

#### 2.1 面诊分析
**接口**: `POST /api/v1/health/face/analyze`

**功能**: 上传面部图片进行AI分析

**请求参数**:
```json
{
  "imageUrl": "面部图片URL地址",
  "description": "可选的描述信息"
}
```

**响应示例**:
```json
{
  "success": true,
  "message": "面诊分析完成",
  "data": {
    "analysisId": 6,
    "analyzedAt": "2025-09-22T12:44:53.758Z"
  }
}
```

#### 2.2 获取面诊历史记录
**接口**: `GET /api/v1/health/face/history`

**功能**: 获取用户的面诊分析历史记录

#### 2.3 获取单个面诊记录详情
**接口**: `GET /api/v1/health/face/{id}`

**功能**: 获取指定面诊记录的详细信息

### 3. 📋 健康档案管理

#### 3.1 获取健康档案
**接口**: `GET /api/v1/health/profile`

**功能**: 获取用户基础健康档案信息

**响应示例**:
```json
{
  "success": true,
  "data": {
    "userId": 1,
    "height": 175,
    "weight": 70,
    "bloodType": "A",
    "primaryConstitution": "平和质",
    "overallHealthScore": 85,
    "healthLevel": "good",
    "lastUpdated": "2025-09-22T12:00:00.000Z"
  }
}
```

#### 3.2 获取完整健康档案
**接口**: `GET /api/v1/health/profile/comprehensive`

**功能**: 获取包含所有关联数据的完整健康档案

**响应示例**:
```json
{
  "success": true,
  "message": "完整健康档案获取成功",
  "data": {
    "userInfo": {
      "userId": 1,
      "nickname": "用户昵称",
      "gender": "male",
      "age": 30,
      "memberSince": "2025-01-01T00:00:00.000Z"
    },
    "healthProfile": {
      "height": 175,
      "weight": 70,
      "bloodType": "A",
      "primaryConstitution": "平和质",
      "overallHealthScore": 85,
      "healthLevel": "good"
    },
    "analysisData": {
      "tongueAnalysis": {
        "id": 6,
        "analysisResult": "分析结果",
        "createdAt": "2025-09-22T12:44:50.000Z"
      },
      "faceAnalysis": {
        "id": 6,
        "analysisResult": "分析结果",
        "createdAt": "2025-09-22T12:44:53.000Z"
      }
    },
    "dataCompleteness": {
      "hasHealthProfile": true,
      "hasTongueAnalysis": true,
      "hasFaceAnalysis": true,
      "completenessScore": 85
    }
  }
}
```

#### 3.3 更新基础健康信息
**接口**: `PUT /api/v1/health/profile/basic`

**功能**: 更新用户基础健康信息

**请求参数**:
```json
{
  "height": 175,
  "weight": 70,
  "bloodType": "A",
  "allergies": ["花粉", "海鲜"],
  "chronicDiseases": ["高血压"],
  "medications": ["降压药"]
}
```

#### 3.4 更新健康档案详细信息
**接口**: `PUT /api/v1/health/profile/details`

**功能**: 更新健康档案的详细信息

**请求参数**:
```json
{
  "primaryConstitution": "平和质",
  "secondaryConstitution": "气虚质",
  "constitutionScore": {
    "平和质": 85,
    "气虚质": 60
  },
  "healthMetrics": {
    "bloodPressure": "120/80",
    "heartRate": 72
  },
  "personalizedAdvice": "个性化建议",
  "caregiverPlan": "调理方案"
}
```

### 4. 🧬 中医体质分析

#### 4.1 综合体质分析
**接口**: `POST /api/v1/health/constitution/analyze`

**功能**: 基于舌诊和面诊数据进行综合体质分析

**请求参数**: 无（自动使用最新的舌诊面诊数据）

**响应示例**:
```json
{
  "success": true,
  "message": "体质分析完成",
  "data": {
    "primaryConstitution": "平和质",
    "secondaryConstitution": "气虚质",
    "constitutionScores": {
      "平和质": 85,
      "气虚质": 60,
      "阳虚质": 30
    },
    "analysisResult": "详细分析结果",
    "recommendations": "调理建议"
  }
}
```

#### 4.2 获取体质分析历史
**接口**: `GET /api/v1/health/constitution/history`

**功能**: 获取用户的体质分析历史记录

#### 4.3 获取体质类型详情
**接口**: `GET /api/v1/health/constitution/types`

**功能**: 获取所有中医体质类型的详细信息

**响应示例**:
```json
{
  "success": true,
  "data": {
    "constitutionTypes": [
      {
        "name": "平和质",
        "description": "体质平和，健康状态良好",
        "characteristics": ["精力充沛", "睡眠良好", "食欲正常"],
        "recommendations": ["保持规律作息", "适量运动"]
      }
    ]
  }
}
```

### 5. 🌟 五运六气分析

#### 5.1 获取当前五运六气分析
**接口**: `GET /api/v1/health/five-elements/current`

**功能**: 获取当前时间的五运六气分析和个性化建议

**响应示例**:
```json
{
  "success": true,
  "data": {
    "analysisDate": "2025-09-22T12:00:00.000Z",
    "currentSolarTerm": {
      "name": "秋分",
      "date": "2025-09-22",
      "characteristics": "昼夜平分，阴阳平衡"
    },
    "fiveMovements": {
      "year": "木运太过",
      "current": "金运"
    },
    "sixQi": {
      "hostQi": "阳明燥金",
      "guestQi": "少阴君火"
    },
    "personalizedAdvice": "根据您的体质特点，建议...",
    "constitutionMatch": {
      "matchScore": 85,
      "suitability": "非常适合"
    },
    "analysisId": 123
  }
}

```

##### 字段说明（中英对照）
- 客户端模型命名建议：fiveElements（不改变现有 API 字段，仅为客户端命名建议）
- 字段对照：
  - analysisId → 分析 ID
  - currentSolarTerm → 当前节气（名称 + 日期）
  - fiveMovements → 今年整体运势
    - year → 年度运势（例如：“木运太过/不足”等）
    - current → 当前运势（例如：“金运”、“火运”）
  - sixQi → 六气
    - hostQi → 主气
    - guestQi → 客气
  - personalizedAdvice → 五运六气个性化建议

说明：以上为字段语义说明，以英文字段对接，括号内为中文含义，不改变现有 API 返回结构。

#### 5.2 获取五运六气历史记录
**接口**: `GET /api/v1/health/five-elements/history`

**功能**: 获取用户的五运六气分析历史记录

**查询参数**:
- `page`: 页码（默认1）
- `limit`: 每页数量（默认10）

### 6. 📊 健康报告生成

#### 6.1 生成综合健康报告
**接口**: `POST /api/v1/health/report/generate`

**功能**: 生成用户的综合健康报告

**请求参数**:
```json
{
  "reportType": "comprehensive" // 可选: comprehensive, simple, detailed
}
```

**响应示例**:
```json
{
  "success": true,
  "message": "健康报告生成成功",
  "data": {
    "reportId": "report_123",
    "reportType": "comprehensive",
    "generatedAt": "2025-09-22T12:00:00.000Z",
    "overallScore": 85,
    "healthLevel": "good",
    "summary": "整体健康状况良好",
    "recommendations": ["建议1", "建议2"],
    "analysisDetails": {
      "constitution": "平和质",
      "tongueAnalysis": "舌诊结果",
      "faceAnalysis": "面诊结果"
    }
  }
}
```

#### 6.2 获取健康报告历史
**接口**: `GET /api/v1/health/report/history`

**功能**: 获取用户的健康报告历史记录

### 7. 🤖 AI健康对话系统

#### 7.1 健康对话聊天
**接口**: `POST /api/v1/health/chat`

**功能**: 与AI进行健康相关的对话咨询

**请求参数**:
```json
{
  "message": "我最近总是感觉疲劳，应该怎么办？",
  "conversationId": "可选的对话ID"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "conversationId": "conv_123",
    "messageId": "msg_456",
    "response": "根据您的描述，疲劳可能与多种因素有关...",
    "jobId": "job_789", // 异步处理任务ID
    "status": "processing" // processing, completed, failed
  }
}
```

**⚠️ 重要：AI回复格式要求**

前端已支持 Markdown 格式渲染，后端返回的 `response` 或 `aiReply` 字段应使用 Markdown 格式，以提供更好的排版效果：

**支持的 Markdown 语法**：
- ✅ **标题**：`## 标题` 或 `### 标题`
- ✅ **列表**：`- 列表项` 或 `• 列表项`
- ✅ **数字列表**：`1. 第一项`、`2. 第二项`
- ✅ **粗体**：`**粗体文字**`
- ✅ **换行**：使用空行分隔段落

**推荐的回复格式示例**：
```markdown
## 2. 日常轻度运动

• **散步**：每天30分钟左右的慢走（可分次完成），以身体微微发热、不疲劳为度，逐步提升心肺功能。

• **慢跑/快走**：选择平坦路面，速度以能正常说话为宜，避免大汗淋漓。

• **骑自行车**：选择平坦路线，低速骑行，避免过度消耗体力。

### 注意事项

1. 运动前做好热身准备
2. 运动中注意补充水分
3. 感到不适立即停止
```

**注意事项**：
- 段落之间用空行分隔（`\n\n`）
- 列表项每行一个
- 标题前后建议加空行，提升可读性

**🔗 推荐链接格式**：

AI 回复中可以包含帖子推荐链接，用户点击后会自动跳转到对应的帖子详情页面。

**链接格式规范**：
```markdown
[帖子标题或描述](qinghe://post/{postId})
```

**实际示例**：
```markdown
📚 **相关推荐**：
[1. 八段锦-官方横屏观看跟练版](qinghe://post/1e0c51be-62fb-47ac-be7d-d41564228dc1)
[2. 太极拳](qinghe://post/7cae9b1c-fc43-4b5b-9ded-432a848203b5)
[3. 今天的运动完成了！消耗了很多卡路里 🏃‍♂️](qinghe://post/10bd244e-c4ad-49e8-a731-f2f348690b35)
```

**渲染效果**：
- 链接文字显示为蓝色（`#4A90E2`）
- 带下划线
- 可点击，点击后自动跳转到帖子详情页

**注意事项**：
- URL scheme 必须是 `qinghe://post/`
- `postId` 必须是有效的帖子 ID（字符串格式）
- 链接文字建议简洁明了，突出帖子主题

#### 7.2 获取对话任务状态
**接口**: `GET /api/v1/health/chat/job/{jobId}`

**功能**: 查询异步对话任务的处理状态

**路径参数**:
- `jobId`: 任务ID

#### 7.3 获取对话历史
**接口**: `GET /api/v1/health/chat/history`

**功能**: 获取用户的AI对话历史记录

**查询参数**:
- `conversationId`: 可选，指定对话ID
- `page`: 页码
- `limit`: 每页数量

#### 7.4 开始新对话
**接口**: `POST /api/v1/health/chat/new`

**功能**: 开始一个新的健康对话会话

#### 7.5 删除对话
**接口**: `DELETE /api/v1/health/chat/conversation/{conversationId}`

**功能**: 删除指定的对话记录

#### 7.6 生成AI健康报告
**接口**: `POST /api/v1/health/chat/generate-report`

**功能**: 使用AI生成个性化健康报告

#### 7.7 获取AI健康报告历史
**接口**: `GET /api/v1/health/chat/reports`

**功能**: 获取AI生成的健康报告历史

#### 7.8 获取健康队列统计信息
**接口**: `GET /api/v1/health/chat/queue/stats`

**功能**: 获取健康对话队列的统计信息

**响应示例**:
```json
{
  "success": true,
  "data": {
    "totalJobs": 150,
    "activeJobs": 5,
    "completedJobs": 140,
    "failedJobs": 5,
    "queueHealth": "healthy"
  }
}
```

### 8. 😴 睡眠数据管理

#### 8.1 上传睡眠数据
**接口**: `POST /api/v1/health/sleep/upload`

**功能**: 上传单次睡眠数据到健康档案

**请求参数**:
```json
{
  "sleepDate": "2025-09-22",
  "startTime": "2025-09-22T22:30:00.000Z",
  "endTime": "2025-09-22T06:30:00.000Z",
  "duration": 480, // 分钟
  "quality": 8.5, // 睡眠质量评分 1-10
  "deepSleepDuration": 120,
  "lightSleepDuration": 300,
  "remSleepDuration": 60,
  "awakeDuration": 15
}
```

#### 8.2 批量上传睡眠数据
**接口**: `POST /api/v1/health/sleep/upload/batch`

**功能**: 批量上传多天的睡眠数据

**请求参数**:
```json
{
  "sleepRecords": [
    {
      "sleepDate": "2025-09-22",
      "startTime": "2025-09-22T22:30:00.000Z",
      "endTime": "2025-09-22T06:30:00.000Z",
      "duration": 480,
      "quality": 8.5
    }
  ]
}
```

#### 8.3 获取睡眠数据记录
**接口**: `GET /api/v1/health/sleep/records`

**功能**: 获取用户的睡眠数据记录

**查询参数**:
- `startDate`: 开始日期
- `endDate`: 结束日期
- `page`: 页码
- `limit`: 每页数量

#### 8.4 删除睡眠数据记录
**接口**: `DELETE /api/v1/health/sleep/records/{sleepDate}`

**功能**: 删除指定日期的睡眠数据记录

### 9. 🔄 数据集成服务

#### 9.1 集成用户健康数据
**接口**: `POST /api/v1/health/integration/user`

**功能**: 集成用户的所有健康数据，生成综合分析

#### 9.2 获取数据集成状态
**接口**: `GET /api/v1/health/integration/status`

**功能**: 获取数据集成服务的状态信息

**响应示例**:
```json
{
  "success": true,
  "data": {
    "status": "running",
    "lastIntegration": "2025-09-22T12:00:00.000Z",
    "totalUsers": 1000,
    "integratedUsers": 950,
    "pendingUsers": 50
  }
}
```

---

## 📱 iOS 开发最佳实践

### 1. 网络请求封装
```swift
class HealthAPIManager {
    static let shared = HealthAPIManager()
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1/health"

    func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        responseType: T.Type
    ) async throws -> T {
        // 实现网络请求逻辑
    }
}
```

### 2. 数据模型定义
```swift
struct HealthProfile: Codable {
    let userId: Int
    let height: Double?
    let weight: Double?
    let bloodType: String?
    let primaryConstitution: String?
    let overallHealthScore: Int
    let healthLevel: String
    let lastUpdated: Date
}

struct TongueAnalysis: Codable {
    let id: String
    let originalImageUrl: String
    let analysisStatus: String
    let constitutionAnalysis: String?
    let analyzedAt: Date
}
```

### 3. 错误处理
```swift
enum HealthAPIError: Error {
    case unauthorized
    case networkError
    case dataParsingError
    case serverError(String)
}
```

### 4. 图片上传处理
```swift
func uploadTongueImage(_ image: UIImage) async throws -> TongueAnalysis {
    // 1. 先上传图片到OSS获取URL
    let imageUrl = try await uploadImageToOSS(image)

    // 2. 调用舌诊分析API
    let parameters = [
        "imageUrl": imageUrl,
        "description": "iOS客户端上传"
    ]

    return try await makeRequest(
        endpoint: "/tongue/analyze",
        method: .POST,
        parameters: parameters,
        responseType: TongueAnalysisResponse.self
    )
}
```

---

## 🔧 常见问题解决

### 1. 认证失败
- 检查Token是否正确设置在请求头中
- 确认Token未过期
- 验证Token格式是否正确

### 2. 图片上传失败
- 确保图片URL可访问
- 检查图片格式是否支持
- 验证网络连接状态

### 3. API响应慢
- 使用异步请求避免阻塞UI

---

## 📎 附录A：通用字段说明

### A.1 健康指标 healthMetrics
- 适用位置：健康档案、综合报告、仪表盘等模块的指标小结
- 字段定义：
  - bmi → BMI 指数（注：示例中 85 代表整体健康指数而非标准 BMI，实际使用时应为 18.5–24.9 为正常区间；若作为“健康指数”使用，请在前端文案中标注“健康指数”而非 BMI）
  - constitution → 体质分数
  - exercise → 运动分数
  - sleep → 睡眠分数

建议：保持这些指标统一为 0–100 分制，便于横向比较；如采用真实 BMI，请使用浮点值（示例：22.4）。

- 实现请求超时处理
- 考虑使用缓存机制

### 4. 数据同步问题
- 实现本地数据缓存
- 定期同步服务器数据
- 处理网络异常情况

---

## 📞 技术支持

如有API使用问题，请联系技术支持团队。

**文档版本**: v1.0
**最后更新**: 2025年9月22日
**服务器状态**: 正常运行 ✅

---

*本文档为青禾计划健康管理系统的完整API参考，专为iOS开发团队提供。*
