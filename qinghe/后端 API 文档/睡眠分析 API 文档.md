# 青禾计划 - 睡眠分析与健康评估 API 文档 (iOS版)

## 📋 概述

青禾计划睡眠管理服务提供完整的睡眠数据分析和个性化健康建议功能，包括AI驱动的睡眠质量分析、7天健康评估、个性化建议生成等功能。

**基础信息**
- **API基础URL**: `https://api.qinghejihua.com.cn/api/v1/sleep`
- **协议**: HTTPS
- **认证方式**: Bearer Token (JWT)
- **内容类型**: `application/json`

**核心功能**
- ✅ 睡眠质量分析与趋势
- ✅ 7天健康评估与风险分析
- ✅ 个性化健康建议生成
- ✅ AI驱动的深度睡眠分析
- ✅ 睡眠统计与趋势可视化

---

## 🌙 核心API接口

### 1. 睡眠质量分析

获取用户的睡眠质量分析数据，包括整体评分、质量等级和最近趋势。

#### 接口信息
- **URL**: `GET /api/v1/sleep/quality-analysis`
- **完整地址**: `https://api.qinghejihua.com.cn/api/v1/sleep/quality-analysis`
- **认证**: 必需 (Bearer Token)

#### 请求头 (Headers)
```http
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json
```

#### 查询参数 (Query Parameters)

| 参数名 | 类型 | 必填 | 说明 | 默认值 |
|--------|------|------|------|--------|
| `sessionId` | String | ❌ | 指定睡眠会话ID，获取单次分析 | - |
| `limit` | Number | ❌ | 最近N次睡眠记录，用于整体分析 | 10 |

#### 响应格式

##### 成功响应 - 整体质量分析 (HTTP 200)
```json
{
  "status": "success",
  "data": {
    "period": "最近10次睡眠",
    "overallQuality": {
      "averageScore": 56,
      "qualityLevel": "fair",
      "totalSessions": 10
    },
    "recentTrend": [
      {
        "date": "2025-07-23 18:32:30",
        "score": 54,
        "efficiency": "68.75"
      },
      {
        "date": "2025-07-23 18:30:44",
        "score": 54,
        "efficiency": "68.75"
      }
    ]
  }
}
```

##### 成功响应 - 单次会话分析 (HTTP 200)
```json
{
  "status": "success",
  "data": {
    "sessionId": "73",
    "qualityAnalysis": {
      "overallScore": 54,
      "qualityLevel": "fair",
      "keyMetrics": {
        "sleepEfficiency": "68.75",
        "deepSleepPercentage": "36.36",
        "remSleepPercentage": "27.27",
        "sleepLatency": 15
      },
      "insights": [
        {
          "type": "warning",
          "title": "睡眠效率偏低",
          "description": "当前睡眠效率为68.75%，建议提高至85%以上"
        }
      ],
      "recommendations": [
        {
          "text": "保持规律作息",
          "priority": "high",
          "description": "每天相同时间入睡起床"
        }
      ]
    }
  }
}
```

#### 质量等级说明

| 评分范围 | 等级 (qualityLevel) | 说明 |
|---------|---------------------|------|
| 85-100 | excellent | 优秀 |
| 70-84 | good | 良好 |
| 55-69 | fair | 一般 |
| 0-54 | poor | 较差 |

---

### 2. 7天睡眠健康评估

获取用户最近7天的综合健康评估，包括详细指标、风险因素和个性化建议。

#### 接口信息
- **URL**: `GET /api/v1/sleep/health-assessment`
- **完整地址**: `https://api.qinghejihua.com.cn/api/v1/sleep/health-assessment`
- **认证**: 必需 (Bearer Token)

#### 请求头 (Headers)
```http
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json
```

#### 查询参数
无需额外参数，默认分析最近7天数据。

#### 响应格式

##### 成功响应 - 完整健康评估 (HTTP 200)
```json
{
  "status": "success",
  "data": {
    "assessmentPeriod": "7天",
    "assessmentDate": "2025-10-09T08:29:56.484Z",
    "dataPoints": 15,
    
    "overallHealthScore": 68,
    "healthLevel": "fair",
    
    "sleepQuality": {
      "averageScore": 56,
      "scoreRange": {
        "min": 45,
        "max": 72
      },
      "consistency": 75
    },
    
    "sleepDuration": {
      "averageDuration": 420,
      "durationConsistency": 68,
      "optimalRange": 65
    },
    
    "sleepEfficiency": {
      "averageEfficiency": 72.5,
      "efficiencyTrend": "stable"
    },
    
    "sleepTiming": {
      "regularity": 70,
      "averageBedtime": "23:30",
      "averageWakeTime": "07:15",
      "bedtimeVariation": "45分钟"
    },
    
    "sleepStages": {
      "deepSleepPercentage": 18.5,
      "remSleepPercentage": 22.3,
      "lightSleepPercentage": 59.2,
      "stageBalance": "balanced"
    },
    
    "riskFactors": [
      {
        "type": "efficiency",
        "severity": "medium",
        "description": "睡眠效率低于建议值85%"
      },
      {
        "type": "consistency",
        "severity": "low",
        "description": "作息时间不够规律"
      }
    ],
    
    "recommendations": [
      {
        "priority": "high",
        "category": "sleep_quality",
        "title": "改善睡眠质量",
        "description": "建议优化睡眠环境，保持室温在18-22°C，减少噪音和光线干扰"
      },
      {
        "priority": "high",
        "category": "consistency",
        "title": "保持规律作息",
        "description": "每天在相同时间入睡和起床，包括周末，有助于调节生物钟"
      },
      {
        "priority": "medium",
        "category": "efficiency",
        "title": "提高睡眠效率",
        "description": "如果20分钟内无法入睡，建议起床进行轻松活动，直到感到困倦"
      },
      {
        "priority": "low",
        "category": "general",
        "title": "保持健康生活方式",
        "description": "规律运动、均衡饮食、限制咖啡因摄入，特别是下午和晚上"
      }
    ],
    
    "trends": {
      "scoreImprovement": "improving",
      "durationTrend": "stable",
      "efficiencyChange": 2.5
    }
  }
}
```

##### 无数据响应 (HTTP 200)
```json
{
  "status": "success",
  "data": {
    "message": "最近7天暂无睡眠数据",
    "period": "7天",
    "assessmentDate": "2025-10-09T08:29:56.484Z"
  }
}
```

#### 字段说明

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `overallHealthScore` | Number | 整体健康评分 (0-100) |
| `healthLevel` | String | 健康等级：excellent/good/fair/poor |
| `averageDuration` | Number | 平均睡眠时长（分钟） |
| `durationConsistency` | Number | 时长一致性 (0-100) |
| `averageEfficiency` | Number | 平均睡眠效率 (%) |
| `regularity` | Number | 作息规律性 (0-100) |
| `deepSleepPercentage` | Number | 深度睡眠占比 (%) |
| `remSleepPercentage` | Number | REM睡眠占比 (%) |

---

### 3. 单次睡眠详细报告

获取指定睡眠会话的完整AI分析报告。

#### 接口信息
- **URL**: `GET /api/v1/sleep/report/:sessionId`
- **完整地址**: `https://api.qinghejihua.com.cn/api/v1/sleep/report/{sessionId}`
- **认证**: 必需 (Bearer Token)

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `sessionId` | String | ✅ | 睡眠会话ID |

#### 请求头 (Headers)
```http
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json
```

#### 响应格式

##### 成功响应 (HTTP 200)
```json
{
  "status": "success",
  "data": {
    "sessionId": "73",
    "reportId": "59",
    "generatedAt": "2025-07-23 18:33:00",
    
    "sleepSummary": {
      "totalSleepTime": 330,
      "sleepEfficiency": "68.75",
      "overallQuality": 54,
      "sleepLatency": 15
    },
    
    "sleepStages": [
      {
        "stage": "light",
        "startTime": "2025-07-23 18:32:30",
        "endTime": "2025-07-23 20:02:30",
        "duration": 90,
        "quality": 7
      },
      {
        "stage": "deep",
        "startTime": "2025-07-23 20:02:30",
        "endTime": "2025-07-23 22:02:30",
        "duration": 120,
        "quality": 7
      },
      {
        "stage": "rem",
        "startTime": "2025-07-23 22:02:30",
        "endTime": "2025-07-23 23:32:30",
        "duration": 90,
        "quality": 9
      }
    ],
    
    "insights": [
      {
        "type": "info",
        "title": "AI分析完成",
        "description": "基于DeepSeek AI的专业睡眠分析"
      },
      {
        "type": "warning",
        "title": "睡眠效率偏低",
        "description": "建议改善睡眠环境"
      }
    ],
    
    "aiAnalysis": {
      "sleepPatterns": "睡眠模式正常",
      "environmentalFactors": "环境因素良好",
      "recommendations": [
        {
          "text": "保持规律作息",
          "priority": "medium",
          "description": "基于AI分析建议"
        }
      ]
    }
  }
}
```

---

### 4. 睡眠统计数据

获取用户的睡眠统计信息，支持自定义时间范围。

#### 接口信息
- **URL**: `GET /api/v1/sleep/statistics`
- **完整地址**: `https://api.qinghejihua.com.cn/api/v1/sleep/statistics`
- **认证**: 必需 (Bearer Token)

#### 查询参数

| 参数名 | 类型 | 必填 | 说明 | 默认值 |
|--------|------|------|------|--------|
| `period` | String | ❌ | 统计周期：7d/30d/90d/year | 30d |
| `startDate` | String | ❌ | 开始日期 (YYYY-MM-DD) | - |
| `endDate` | String | ❌ | 结束日期 (YYYY-MM-DD) | - |

#### 请求示例
```http
GET /api/v1/sleep/statistics?period=7d
Authorization: Bearer {JWT_TOKEN}
```

---

### 5. 睡眠趋势分析

获取睡眠数据的趋势变化，用于图表展示。

#### 接口信息
- **URL**: `GET /api/v1/sleep/trends`
- **完整地址**: `https://api.qinghejihua.com.cn/api/v1/sleep/trends`
- **认证**: 必需 (Bearer Token)

#### 查询参数

| 参数名 | 类型 | 必填 | 说明 | 默认值 |
|--------|------|------|------|--------|
| `metric` | String | ❌ | 趋势指标：score/duration/efficiency | score |
| `period` | String | ❌ | 时间周期：7d/30d/90d | 30d |

---

### 6. 获取睡眠会话列表

获取用户的所有睡眠会话记录。

#### 接口信息
- **URL**: `GET /api/v1/sleep/sessions`
- **完整地址**: `https://api.qinghejihua.com.cn/api/v1/sleep/sessions`
- **认证**: 必需 (Bearer Token)

#### 查询参数

| 参数名 | 类型 | 必填 | 说明 | 默认值 |
|--------|------|------|------|--------|
| `page` | Number | ❌ | 页码 | 1 |
| `limit` | Number | ❌ | 每页数量 | 20 |
| `status` | String | ❌ | 处理状态：completed/failed/processing | - |

#### 响应示例
```json
{
  "status": "success",
  "data": {
    "sessions": [
      {
        "id": "73",
        "startTime": "2025-07-23 18:32:30",
        "endTime": "2025-07-23 18:32:36",
        "duration": 330,
        "quality": "fair",
        "processingStatus": "completed",
        "sleepScore": 54,
        "sleepEfficiency": "68.75"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalItems": 45,
      "itemsPerPage": 20
    }
  }
}
```

---

## 📱 iOS Swift 集成示例

### 数据模型定义

```swift
import Foundation

// MARK: - 睡眠质量分析响应
struct SleepQualityResponse: Codable {
    let status: String
    let data: QualityData
}

struct QualityData: Codable {
    let period: String
    let overallQuality: OverallQuality
    let recentTrend: [TrendItem]
}

struct OverallQuality: Codable {
    let averageScore: Int
    let qualityLevel: String
    let totalSessions: Int
}

struct TrendItem: Codable {
    let date: String
    let score: Int
    let efficiency: String
}

// MARK: - 健康评估响应
struct HealthAssessmentResponse: Codable {
    let status: String
    let data: HealthAssessmentData
}

struct HealthAssessmentData: Codable {
    let assessmentPeriod: String
    let assessmentDate: String
    let dataPoints: Int?
    let overallHealthScore: Int?
    let healthLevel: String?
    let sleepQuality: SleepQuality?
    let sleepDuration: SleepDuration?
    let sleepEfficiency: SleepEfficiencyData?
    let sleepTiming: SleepTiming?
    let sleepStages: SleepStages?
    let riskFactors: [RiskFactor]?
    let recommendations: [Recommendation]?
    let trends: Trends?
    let message: String? // 无数据时返回
}

struct SleepQuality: Codable {
    let averageScore: Int
    let scoreRange: ScoreRange
    let consistency: Int
}

struct ScoreRange: Codable {
    let min: Int
    let max: Int
}

struct SleepDuration: Codable {
    let averageDuration: Int
    let durationConsistency: Int
    let optimalRange: Int
}

struct SleepEfficiencyData: Codable {
    let averageEfficiency: Double
    let efficiencyTrend: String
}

struct SleepTiming: Codable {
    let regularity: Int
    let averageBedtime: String
    let averageWakeTime: String
    let bedtimeVariation: String
}

struct SleepStages: Codable {
    let deepSleepPercentage: Double
    let remSleepPercentage: Double
    let lightSleepPercentage: Double
    let stageBalance: String
}

struct RiskFactor: Codable {
    let type: String
    let severity: String
    let description: String
}

struct Recommendation: Codable {
    let priority: String
    let category: String
    let title: String
    let description: String
}

struct Trends: Codable {
    let scoreImprovement: String
    let durationTrend: String
    let efficiencyChange: Double
}

// MARK: - 睡眠报告响应
struct SleepReportResponse: Codable {
    let status: String
    let data: SleepReportData
}

struct SleepReportData: Codable {
    let sessionId: String
    let reportId: String
    let generatedAt: String
    let sleepSummary: SleepSummary
    let sleepStages: [SleepStage]
    let insights: [Insight]
    let aiAnalysis: AIAnalysis
}

struct SleepSummary: Codable {
    let totalSleepTime: Int
    let sleepEfficiency: String
    let overallQuality: Int
    let sleepLatency: Int
}

struct SleepStage: Codable {
    let stage: String
    let startTime: String
    let endTime: String
    let duration: Int
    let quality: Int
}

struct Insight: Codable {
    let type: String
    let title: String
    let description: String
}

struct AIAnalysis: Codable {
    let sleepPatterns: String
    let environmentalFactors: String
    let recommendations: [AIRecommendation]
}

struct AIRecommendation: Codable {
    let text: String
    let priority: String
    let description: String
}
```

### 网络服务类

```swift
import Foundation

class SleepAnalysisService {
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1/sleep"
    private var authToken: String?
    
    // MARK: - 设置认证Token
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    // MARK: - 1. 获取睡眠质量分析
    func getSleepQualityAnalysis(
        sessionId: String? = nil,
        limit: Int = 10,
        completion: @escaping (Result<QualityData, Error>) -> Void
    ) {
        guard let token = authToken else {
            completion(.failure(SleepAPIError.unauthorized))
            return
        }
        
        var urlString = "\(baseURL)/quality-analysis?limit=\(limit)"
        if let sessionId = sessionId {
            urlString += "&sessionId=\(sessionId)"
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(SleepAPIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(SleepAPIError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(SleepQualityResponse.self, from: data)
                
                if response.status == "success" {
                    completion(.success(response.data))
                } else {
                    completion(.failure(SleepAPIError.apiError("分析失败")))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - 2. 获取7天健康评估
    func getHealthAssessment(
        completion: @escaping (Result<HealthAssessmentData, Error>) -> Void
    ) {
        guard let token = authToken else {
            completion(.failure(SleepAPIError.unauthorized))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/health-assessment") else {
            completion(.failure(SleepAPIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(SleepAPIError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(HealthAssessmentResponse.self, from: data)
                
                if response.status == "success" {
                    completion(.success(response.data))
                } else {
                    completion(.failure(SleepAPIError.apiError("评估失败")))
                }
            } catch {
                print("解码错误: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - 3. 获取单次睡眠报告
    func getSleepReport(
        sessionId: String,
        completion: @escaping (Result<SleepReportData, Error>) -> Void
    ) {
        guard let token = authToken else {
            completion(.failure(SleepAPIError.unauthorized))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/report/\(sessionId)") else {
            completion(.failure(SleepAPIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(SleepAPIError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(SleepReportResponse.self, from: data)
                
                if response.status == "success" {
                    completion(.success(response.data))
                } else {
                    completion(.failure(SleepAPIError.apiError("获取报告失败")))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - 错误类型定义
enum SleepAPIError: LocalizedError {
    case unauthorized
    case invalidURL
    case noData
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "未授权，请先登录"
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "无响应数据"
        case .apiError(let message):
            return message
        }
    }
}
```

### 使用示例

```swift
import UIKit

class SleepAnalysisViewController: UIViewController {
    
    let sleepService = SleepAnalysisService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置认证token
        sleepService.setAuthToken("your_jwt_token_here")
        
        // 示例1: 获取睡眠质量分析
        loadSleepQualityAnalysis()
        
        // 示例2: 获取健康评估
        loadHealthAssessment()
        
        // 示例3: 获取单次睡眠报告
        loadSleepReport(sessionId: "73")
    }
    
    // MARK: - 示例1: 加载睡眠质量分析
    func loadSleepQualityAnalysis() {
        sleepService.getSleepQualityAnalysis(limit: 10) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let qualityData):
                    print("✅ 平均评分: \(qualityData.overallQuality.averageScore)")
                    print("✅ 质量等级: \(qualityData.overallQuality.qualityLevel)")
                    print("✅ 会话总数: \(qualityData.overallQuality.totalSessions)")
                    
                    // 更新UI
                    self?.updateQualityUI(with: qualityData)
                    
                case .failure(let error):
                    print("❌ 获取质量分析失败: \(error.localizedDescription)")
                    self?.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - 示例2: 加载健康评估
    func loadHealthAssessment() {
        sleepService.getHealthAssessment { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let assessment):
                    if let message = assessment.message {
                        // 无数据情况
                        print("ℹ️ \(message)")
                        self?.showNoDataView()
                    } else {
                        // 有数据，显示完整评估
                        print("✅ 整体健康评分: \(assessment.overallHealthScore ?? 0)")
                        print("✅ 健康等级: \(assessment.healthLevel ?? "unknown")")
                        print("✅ 数据点数: \(assessment.dataPoints ?? 0)")
                        
                        // 显示建议
                        if let recommendations = assessment.recommendations {
                            self?.displayRecommendations(recommendations)
                        }
                        
                        // 显示风险因素
                        if let risks = assessment.riskFactors {
                            self?.displayRiskFactors(risks)
                        }
                        
                        // 更新UI
                        self?.updateHealthAssessmentUI(with: assessment)
                    }
                    
                case .failure(let error):
                    print("❌ 获取健康评估失败: \(error.localizedDescription)")
                    self?.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - 示例3: 加载单次睡眠报告
    func loadSleepReport(sessionId: String) {
        sleepService.getSleepReport(sessionId: sessionId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let report):
                    print("✅ 总睡眠时间: \(report.sleepSummary.totalSleepTime)分钟")
                    print("✅ 睡眠效率: \(report.sleepSummary.sleepEfficiency)%")
                    print("✅ 整体质量: \(report.sleepSummary.overallQuality)")
                    print("✅ 入睡时长: \(report.sleepSummary.sleepLatency)分钟")
                    
                    // 显示睡眠阶段
                    print("\n睡眠阶段分析:")
                    for stage in report.sleepStages {
                        print("  - \(stage.stage): \(stage.duration)分钟, 质量:\(stage.quality)")
                    }
                    
                    // 显示洞察
                    print("\n睡眠洞察:")
                    for insight in report.insights {
                        print("  - [\(insight.type)] \(insight.title)")
                    }
                    
                    // 更新UI
                    self?.updateReportUI(with: report)
                    
                case .failure(let error):
                    print("❌ 获取睡眠报告失败: \(error.localizedDescription)")
                    self?.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - UI更新方法
    private func updateQualityUI(with data: QualityData) {
        // 更新睡眠质量UI
        // 例如：显示评分、质量等级、趋势图表等
    }
    
    private func updateHealthAssessmentUI(with data: HealthAssessmentData) {
        // 更新健康评估UI
        // 例如：显示各项指标、建议卡片、风险提示等
    }
    
    private func updateReportUI(with data: SleepReportData) {
        // 更新睡眠报告UI
        // 例如：显示睡眠阶段图表、AI分析结果等
    }
    
    private func displayRecommendations(_ recommendations: [Recommendation]) {
        print("\n💡 健康建议:")
        for rec in recommendations {
            let emoji = rec.priority == "high" ? "🔴" : rec.priority == "medium" ? "🟡" : "🟢"
            print("\(emoji) [\(rec.category)] \(rec.title)")
            print("   \(rec.description)")
        }
    }
    
    private func displayRiskFactors(_ risks: [RiskFactor]) {
        print("\n⚠️ 风险因素:")
        for risk in risks {
            print("  - [\(risk.severity)] \(risk.type): \(risk.description)")
        }
    }
    
    private func showNoDataView() {
        // 显示无数据视图
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "错误",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
```

### SwiftUI 示例

```swift
import SwiftUI

struct SleepHealthView: View {
    @StateObject private var viewModel = SleepHealthViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 整体健康评分卡片
                    if let assessment = viewModel.healthAssessment {
                        HealthScoreCard(assessment: assessment)
                    }
                    
                    // 睡眠质量趋势
                    if let quality = viewModel.qualityData {
                        SleepQualityTrendCard(quality: quality)
                    }
                    
                    // 健康建议列表
                    if let recommendations = viewModel.healthAssessment?.recommendations {
                        RecommendationsSection(recommendations: recommendations)
                    }
                    
                    // 风险因素提示
                    if let risks = viewModel.healthAssessment?.riskFactors {
                        RiskFactorsSection(risks: risks)
                    }
                }
                .padding()
            }
            .navigationTitle("睡眠健康")
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}

class SleepHealthViewModel: ObservableObject {
    @Published var qualityData: QualityData?
    @Published var healthAssessment: HealthAssessmentData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let sleepService = SleepAnalysisService()
    
    func loadData() {
        isLoading = true
        
        // 设置token
        sleepService.setAuthToken(UserDefaults.standard.string(forKey: "auth_token") ?? "")
        
        // 加载质量分析
        sleepService.getSleepQualityAnalysis { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.qualityData = data
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
        
        // 加载健康评估
        sleepService.getHealthAssessment { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let data):
                    self?.healthAssessment = data
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// 健康评分卡片
struct HealthScoreCard: View {
    let assessment: HealthAssessmentData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("整体健康评分")
                .font(.headline)
            
            HStack {
                Text("\(assessment.overallHealthScore ?? 0)")
                    .font(.system(size: 48, weight: .bold))
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(healthLevelText)
                        .font(.title3)
                        .foregroundColor(healthLevelColor)
                    Text("\(assessment.dataPoints ?? 0) 个数据点")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    var healthLevelText: String {
        switch assessment.healthLevel {
        case "excellent": return "优秀"
        case "good": return "良好"
        case "fair": return "一般"
        case "poor": return "较差"
        default: return "未知"
        }
    }
    
    var healthLevelColor: Color {
        switch assessment.healthLevel {
        case "excellent": return .green
        case "good": return .blue
        case "fair": return .orange
        case "poor": return .red
        default: return .gray
        }
    }
}

// 建议列表组件
struct RecommendationsSection: View {
    let recommendations: [Recommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("健康建议")
                .font(.headline)
            
            ForEach(recommendations.indices, id: \.self) { index in
                RecommendationRow(recommendation: recommendations[index])
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RecommendationRow: View {
    let recommendation: Recommendation
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: priorityIcon)
                .foregroundColor(priorityColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
    
    var priorityIcon: String {
        switch recommendation.priority {
        case "high": return "exclamationmark.circle.fill"
        case "medium": return "info.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }
    
    var priorityColor: Color {
        switch recommendation.priority {
        case "high": return .red
        case "medium": return .orange
        default: return .green
        }
    }
}

// 风险因素组件
struct RiskFactorsSection: View {
    let risks: [RiskFactor]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("风险因素")
                .font(.headline)
            
            ForEach(risks.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(severityColor(risks[index].severity))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(risks[index].type)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(risks[index].description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    func severityColor(_ severity: String) -> Color {
        switch severity {
        case "high": return .red
        case "medium": return .orange
        default: return .yellow
        }
    }
}
```

---

## 🔍 错误处理

### 错误码对照表

| HTTP状态码 | 错误类型 | 常见原因 | 解决方案 |
|-----------|----------|----------|----------|
| 200 | 成功但无数据 | 最近7天无睡眠记录 | 引导用户上传睡眠数据 |
| 401 | 认证失败 | Token无效或过期 | 重新登录获取新Token |
| 404 | 未找到 | sessionId不存在 | 检查会话ID是否正确 |
| 500 | 服务器错误 | 服务器内部错误 | 稍后重试或联系技术支持 |

### 完善的错误处理示例

```swift
extension SleepAnalysisService {
    
    // 通用错误处理方法
    private func handleAPIError(_ error: Error, completion: @escaping (Error) -> Void) {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                completion(SleepAPIError.apiError("网络连接失败，请检查网络设置"))
            case .timedOut:
                completion(SleepAPIError.apiError("请求超时，请稍后重试"))
            default:
                completion(SleepAPIError.apiError("网络错误: \(urlError.localizedDescription)"))
            }
        } else {
            completion(error)
        }
    }
    
    // 处理HTTP响应状态码
    private func handleHTTPResponse(_ response: URLResponse?, data: Data?) -> Error? {
        guard let httpResponse = response as? HTTPURLResponse else {
            return SleepAPIError.apiError("无效的响应")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return nil
        case 401:
            return SleepAPIError.unauthorized
        case 404:
            return SleepAPIError.apiError("请求的资源不存在")
        case 500...599:
            return SleepAPIError.apiError("服务器错误，请稍后重试")
        default:
            if let data = data,
               let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                return SleepAPIError.apiError(errorMessage.message)
            }
            return SleepAPIError.apiError("未知错误")
        }
    }
}

struct ErrorResponse: Codable {
    let status: String
    let message: String
    let code: Int?
}
```

---

## 💡 最佳实践

### 1. 缓存策略

```swift
class SleepDataCache {
    static let shared = SleepDataCache()
    
    private let cache = NSCache<NSString, CacheItem>()
    private let cacheExpiry: TimeInterval = 300 // 5分钟
    
    func get<T: Codable>(_ key: String) -> T? {
        guard let item = cache.object(forKey: key as NSString),
              item.expiryDate > Date() else {
            return nil
        }
        return item.data as? T
    }
    
    func set<T: Codable>(_ value: T, forKey key: String) {
        let item = CacheItem(
            data: value,
            expiryDate: Date().addingTimeInterval(cacheExpiry)
        )
        cache.setObject(item, forKey: key as NSString)
    }
}

class CacheItem {
    let data: Any
    let expiryDate: Date
    
    init(data: Any, expiryDate: Date) {
        self.data = data
        self.expiryDate = expiryDate
    }
}
```

### 2. 后台刷新

```swift
import BackgroundTasks

class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()
    
    func scheduleHealthAssessmentRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.qinghe.sleep.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1小时后
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("无法安排后台刷新: \(error)")
        }
    }
    
    func handleBackgroundRefresh(task: BGAppRefreshTask) {
        let service = SleepAnalysisService()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        service.getHealthAssessment { result in
            switch result {
            case .success(let data):
                // 保存到本地
                UserDefaults.standard.set(try? JSONEncoder().encode(data), forKey: "cached_health_assessment")
                task.setTaskCompleted(success: true)
            case .failure:
                task.setTaskCompleted(success: false)
            }
        }
        
        scheduleHealthAssessmentRefresh()
    }
}
```

### 3. 网络请求重试机制

```swift
extension SleepAnalysisService {
    
    func getHealthAssessmentWithRetry(
        maxRetries: Int = 3,
        completion: @escaping (Result<HealthAssessmentData, Error>) -> Void
    ) {
        retryRequest(currentAttempt: 0, maxRetries: maxRetries, completion: completion)
    }
    
    private func retryRequest(
        currentAttempt: Int,
        maxRetries: Int,
        completion: @escaping (Result<HealthAssessmentData, Error>) -> Void
    ) {
        getHealthAssessment { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                if currentAttempt < maxRetries {
                    // 指数退避策略
                    let delay = pow(2.0, Double(currentAttempt))
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.retryRequest(
                            currentAttempt: currentAttempt + 1,
                            maxRetries: maxRetries,
                            completion: completion
                        )
                    }
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
}
```

### 4. 数据本地持久化

```swift
class SleepDataManager {
    static let shared = SleepDataManager()
    
    private let userDefaults = UserDefaults.standard
    
    // 保存健康评估数据
    func saveHealthAssessment(_ data: HealthAssessmentData) {
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: "health_assessment")
            userDefaults.set(Date(), forKey: "health_assessment_timestamp")
        }
    }
    
    // 读取健康评估数据
    func loadHealthAssessment() -> HealthAssessmentData? {
        guard let data = userDefaults.data(forKey: "health_assessment"),
              let assessment = try? JSONDecoder().decode(HealthAssessmentData.self, from: data) else {
            return nil
        }
        return assessment
    }
    
    // 检查数据是否过期
    func isHealthAssessmentExpired() -> Bool {
        guard let timestamp = userDefaults.object(forKey: "health_assessment_timestamp") as? Date else {
            return true
        }
        return Date().timeIntervalSince(timestamp) > 3600 // 1小时过期
    }
}
```

---

## 📊 UI展示建议

### 1. 睡眠质量等级显示

```swift
func qualityLevelDisplay(level: String) -> (emoji: String, color: UIColor, text: String) {
    switch level {
    case "excellent":
        return ("🌟", .systemGreen, "优秀")
    case "good":
        return ("😊", .systemBlue, "良好")
    case "fair":
        return ("😐", .systemOrange, "一般")
    case "poor":
        return ("😴", .systemRed, "较差")
    default:
        return ("❓", .systemGray, "未知")
    }
}
```

### 2. 建议优先级UI

| 优先级 | 图标 | 颜色 | 显示位置 |
|-------|------|------|---------|
| high | ⚠️ | 红色 | 顶部优先 |
| medium | ℹ️ | 橙色 | 中间位置 |
| low | ✓ | 绿色 | 底部位置 |

### 3. 趋势图表建议

使用 `Charts` 框架（iOS 16+）或 `SwiftUI Charts` 展示：
- 睡眠评分趋势线图
- 睡眠时长柱状图
- 睡眠效率面积图
- 睡眠阶段堆叠图

---

## 🧪 测试建议

### 单元测试示例

```swift
import XCTest
@testable import QingheApp

class SleepAnalysisServiceTests: XCTestCase {
    
    var service: SleepAnalysisService!
    
    override func setUp() {
        super.setUp()
        service = SleepAnalysisService()
        service.setAuthToken("test_token")
    }
    
    func testGetSleepQualityAnalysis() {
        let expectation = self.expectation(description: "获取睡眠质量分析")
        
        service.getSleepQualityAnalysis { result in
            switch result {
            case .success(let data):
                XCTAssertNotNil(data)
                XCTAssertGreaterThanOrEqual(data.overallQuality.averageScore, 0)
                XCTAssertLessThanOrEqual(data.overallQuality.averageScore, 100)
            case .failure(let error):
                XCTFail("请求失败: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func testHealthAssessmentDataValidation() {
        // 测试数据验证逻辑
        let mockData = HealthAssessmentData(
            assessmentPeriod: "7天",
            assessmentDate: "2025-10-09T08:29:56.484Z",
            dataPoints: 15,
            overallHealthScore: 68,
            healthLevel: "fair",
            sleepQuality: nil,
            sleepDuration: nil,
            sleepEfficiency: nil,
            sleepTiming: nil,
            sleepStages: nil,
            riskFactors: nil,
            recommendations: nil,
            trends: nil,
            message: nil
        )
        
        XCTAssertEqual(mockData.assessmentPeriod, "7天")
        XCTAssertEqual(mockData.overallHealthScore, 68)
    }
}
```

---

## 📝 常见问题 FAQ

### Q1: 为什么健康评估返回"暂无数据"？
**A**: 需要至少有1条最近7天内的睡眠记录。请确保用户已上传睡眠数据。

### Q2: 如何刷新健康评估数据？
**A**: 重新调用 `/health-assessment` 接口即可获取最新数据，建议间隔不少于5分钟。

### Q3: 建议的优先级是如何确定的？
**A**: 基于用户的睡眠指标自动生成：
- **high**: 评分<70或一致性<70%
- **medium**: 深度睡眠<18%或效率<85%
- **low**: 一般性健康建议

### Q4: 睡眠阶段百分比如何计算？
**A**: 各阶段时长 / 总睡眠时长 × 100%

### Q5: 如何处理Token过期？
**A**: 捕获401错误，引导用户重新登录获取新Token。

---

## 📞 技术支持

**文档版本**: v1.0  
**更新时间**: 2025年10月9日  
**服务器状态**: ✅ 在线运行  
**技术支持**: 如有问题请联系后端开发团队

**服务器信息**:
- IP: 123.57.205.94
- 端口: 3000 (HTTPS)
- 进程: PM2管理，自动重启
- 数据库: MySQL 8.0

---

## 🔄 更新日志

### v1.0 (2025-10-09)
- ✅ 初始版本发布
- ✅ 睡眠质量分析API
- ✅ 7天健康评估API
- ✅ 个性化建议生成
- ✅ Swift完整示例代码
- ✅ SwiftUI集成示例

