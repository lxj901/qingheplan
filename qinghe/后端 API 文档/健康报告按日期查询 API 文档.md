# 健康报告按日期查询API文档 - iOS集成指南

## 概述

本文档描述了健康报告按日期查询相关的API接口，支持用户获取历史健康报告、按日期查询特定报告等功能。适用于iOS应用集成。

### 基础信息

- **生产环境**: `https://api.qinghejihua.com.cn`
- **API版本**: v1
- **基础路径**: `/api/v1/health`
- **认证方式**: Bearer Token (JWT)
- **响应格式**: JSON

### 通用响应格式

```json
{
  "code": 0,           // 0=成功, 非0=错误
  "success": true,     // 操作是否成功
  "msg": "获取成功",   // 响应消息
  "data": {...}        // 响应数据
}
```

## API接口列表

### 1. 生成健康报告

生成用户的综合健康报告（包含3天数据统计）。

**接口信息**
- **URL**: `POST /api/v1/health/report/generate`
- **认证**: 需要
- **功能**: 生成综合健康报告，更新频率为3天

**请求参数**
```json
{
  "reportType": "comprehensive"  // 可选，报告类型，默认comprehensive
}
```

**iOS Swift 示例**
```swift
func generateHealthReport() {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/health/report/generate")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["reportType": "comprehensive"]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        // 处理响应
        if let data = data {
            let report = try? JSONDecoder().decode(HealthReportResponse.self, from: data)
            DispatchQueue.main.async {
                // 更新UI
            }
        }
    }.resume()
}
```

**响应示例**
```json
{
  "code": 0,
  "success": true,
  "msg": "健康报告生成成功",
  "data": {
    "reportId": "HR_1759066051524_1",
    "reportType": "comprehensive",
    "generatedAt": "2025-09-28T13:27:31.524Z",
    "nextUpdateSuggested": "2025-10-01T13:27:31.524Z",
    "healthOverview": {
      "overallScore": 75,
      "healthLevel": "good",
      "primaryConstitution": "平和质"
    },
    "detailedAnalysis": {
      "workoutSummary": {
        "totalWorkouts": 15,
        "weeklyWorkouts": 3,
        "average3DayWorkouts": 1
      },
      "sleepSummary": {
        "totalSessions": 28,
        "weeklySessions": 6,
        "average3DaySessions": 2,
        "averageSleepDuration": 7.5
      }
    },
    "recommendations": {
      "priority": "medium",
      "immediate": ["保持规律作息"],
      "longTerm": ["建立健康的生活方式"]
    }
  }
}
```

### 2. 按日期获取健康报告

获取指定日期的健康报告详情。

**接口信息**
- **URL**: `GET /api/v1/health/report/date/{date}`
- **认证**: 需要
- **功能**: 获取特定日期的健康报告

**路径参数**
- `date`: 报告日期，格式为 YYYY-MM-DD，例如：2025-09-28

**iOS Swift 示例**
```swift
func getHealthReportByDate(_ date: String) {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/health/report/date/\(date)")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {
            let report = try? JSONDecoder().decode(HealthReportResponse.self, from: data)
            DispatchQueue.main.async {
                // 更新UI显示报告内容
                self.displayHealthReport(report?.data)
            }
        }
    }.resume()
}

// 日期格式化工具
func formatDateForAPI(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}
```

**响应示例**
```json
{
  "code": 0,
  "success": true,
  "msg": "获取成功",
  "data": {
    "reportId": "HR_1759066051524_1",
    "reportType": "comprehensive",
    "generatedAt": "2025-09-28T13:27:31.524Z",
    "userInfo": {
      "userId": 1,
      "username": "用户昵称"
    },
    "healthOverview": {
      "overallScore": 75,
      "healthLevel": "good",
      "primaryConstitution": "平和质",
      "currentSolarTerm": "秋分"
    },
    "detailedAnalysis": {
      "constitution": {
        "hasAnalysis": true,
        "primaryConstitution": "平和质",
        "confidence": 0.85
      },
      "workoutSummary": {
        "totalWorkouts": 15,
        "weeklyWorkouts": 3,
        "average3DayWorkouts": 1,
        "lastWorkoutDate": "2025-09-27T10:30:00.000Z"
      },
      "sleepSummary": {
        "totalSessions": 28,
        "weeklySessions": 6,
        "average3DaySessions": 2,
        "averageSleepDuration": 7.5,
        "lastSleepDate": "2025-09-28T06:30:00.000Z"
      }
    },
    "recommendations": {
      "priority": "medium",
      "constitution": "适合平和质的养生建议",
      "lifestyle": ["增加运动频率", "保持规律作息"],
      "immediate": ["立即改善睡眠质量"],
      "longTerm": ["建立健康的生活方式", "定期进行健康检查"]
    },
    "healthTrends": {
      "exercise": "improving",
      "sleep": "good",
      "overall": "stable"
    },
    "riskAssessment": [
      {
        "level": "low",
        "factor": "运动不足",
        "advice": "增加运动频率"
      }
    ]
  }
}
```

**错误响应**
```json
{
  "code": 404,
  "success": false,
  "msg": "2025-09-27 没有找到健康报告"
}
```

### 3. 获取可用报告日期列表

获取用户所有健康报告的日期列表，用于日历显示。

**接口信息**
- **URL**: `GET /api/v1/health/report/dates`
- **认证**: 需要
- **功能**: 获取用户所有健康报告日期

**iOS Swift 示例**
```swift
func getAvailableReportDates() {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/health/report/dates")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {
            let response = try? JSONDecoder().decode(ReportDatesResponse.self, from: data)
            DispatchQueue.main.async {
                // 更新日历UI，标记有报告的日期
                self.markCalendarDates(response?.data.dates ?? [])
            }
        }
    }.resume()
}
```

**响应示例**
```json
{
  "code": 0,
  "success": true,
  "msg": "获取成功",
  "data": {
    "total": 5,
    "dates": [
      {
        "date": "2025-09-28",
        "type": "comprehensive",
        "generatedAt": "2025-09-28T13:27:31.000Z"
      },
      {
        "date": "2025-09-25",
        "type": "comprehensive", 
        "generatedAt": "2025-09-25T14:15:20.000Z"
      },
      {
        "date": "2025-09-22",
        "type": "comprehensive",
        "generatedAt": "2025-09-22T09:30:45.000Z"
      }
    ]
  }
}
```

### 4. 获取日期范围内的报告列表

获取指定时间范围内的健康报告列表，支持分页。

**接口信息**
- **URL**: `GET /api/v1/health/report/range`
- **认证**: 需要
- **功能**: 获取日期范围内的报告列表

**查询参数**
- `start`: 开始日期 (YYYY-MM-DD)
- `end`: 结束日期 (YYYY-MM-DD)

**iOS Swift 示例**
```swift
func getReportsInRange(start: String, end: String) {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/health/report/range?start=\(start)&end=\(end)")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {
            let response = try? JSONDecoder().decode(ReportRangeResponse.self, from: data)
            DispatchQueue.main.async {
                // 更新报告列表UI
                self.updateReportsList(response?.data.reports ?? [])
            }
        }
    }.resume()
}
```

**响应示例**
```json
{
  "code": 0,
  "success": true,
  "msg": "获取成功",
  "data": {
    "start": "2025-09-01",
    "end": "2025-09-30",
    "total": 3,
    "reports": [
      {
        "id": 15,
        "reportDate": "2025-09-28",
        "reportType": "comprehensive",
        "reportId": "HR_1759066051524_1",
        "healthOverview": {
          "overallScore": 75,
          "healthLevel": "good",
          "primaryConstitution": "平和质"
        },
        "generatedAt": "2025-09-28T13:27:31.000Z",
        "nextUpdateSuggested": "2025-10-01T13:27:31.000Z"
      },
      {
        "id": 14,
        "reportDate": "2025-09-25",
        "reportType": "comprehensive",
        "reportId": "HR_1759063251789_1",
        "healthOverview": {
          "overallScore": 72,
          "healthLevel": "good",
          "primaryConstitution": "平和质"
        },
        "generatedAt": "2025-09-25T14:15:20.000Z",
        "nextUpdateSuggested": "2025-09-28T14:15:20.000Z"
      }
    ]
  }
}
```

## iOS数据模型定义

```swift
// MARK: - 健康报告响应模型
struct HealthReportResponse: Codable {
    let code: Int
    let success: Bool
    let msg: String
    let data: HealthReportData?
}

struct HealthReportData: Codable {
    let reportId: String
    let reportType: String
    let generatedAt: String
    let nextUpdateSuggested: String?
    let userInfo: UserInfo?
    let healthOverview: HealthOverview
    let detailedAnalysis: DetailedAnalysis?
    let recommendations: Recommendations?
    let healthTrends: HealthTrends?
    let riskAssessment: [RiskAssessment]?
}

struct HealthOverview: Codable {
    let overallScore: Int
    let healthLevel: String
    let primaryConstitution: String?
    let currentSolarTerm: String?
}

struct DetailedAnalysis: Codable {
    let constitution: ConstitutionAnalysis?
    let workoutSummary: WorkoutSummary?
    let sleepSummary: SleepSummary?
}

struct WorkoutSummary: Codable {
    let totalWorkouts: Int
    let weeklyWorkouts: Int
    let average3DayWorkouts: Int
    let lastWorkoutDate: String?
}

struct SleepSummary: Codable {
    let totalSessions: Int
    let weeklySessions: Int
    let average3DaySessions: Int
    let averageSleepDuration: Double
    let lastSleepDate: String?
}

struct Recommendations: Codable {
    let priority: String
    let constitution: String?
    let lifestyle: [String]?
    let immediate: [String]?
    let longTerm: [String]?
}

struct HealthTrends: Codable {
    let exercise: String
    let sleep: String
    let overall: String
}

struct RiskAssessment: Codable {
    let level: String
    let factor: String
    let advice: String
}

// MARK: - 报告日期列表响应模型
struct ReportDatesResponse: Codable {
    let code: Int
    let success: Bool
    let msg: String
    let data: ReportDatesData
}

struct ReportDatesData: Codable {
    let total: Int
    let dates: [ReportDate]
}

struct ReportDate: Codable {
    let date: String
    let type: String
    let generatedAt: String
}

// MARK: - 日期范围报告响应模型
struct ReportRangeResponse: Codable {
    let code: Int
    let success: Bool
    let msg: String
    let data: ReportRangeData
}

struct ReportRangeData: Codable {
    let start: String
    let end: String
    let total: Int
    let reports: [ReportSummary]
}

struct ReportSummary: Codable {
    let id: Int
    let reportDate: String
    let reportType: String
    let reportId: String
    let healthOverview: HealthOverview
    let generatedAt: String
    let nextUpdateSuggested: String?
}
```

## iOS集成示例

### 健康报告管理器

```swift
import Foundation

class HealthReportManager {
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1/health"
    private var userToken: String = ""
    
    func setUserToken(_ token: String) {
        self.userToken = token
    }
    
    // 生成健康报告
    func generateReport(completion: @escaping (Result<HealthReportData, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/report/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["reportType": "comprehensive"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            
            do {
                let response = try JSONDecoder().decode(HealthReportResponse.self, from: data)
                if response.success, let reportData = response.data {
                    completion(.success(reportData))
                } else {
                    completion(.failure(NSError(domain: "API", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.msg])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // 按日期获取报告
    func getReportByDate(_ date: String, completion: @escaping (Result<HealthReportData, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/report/date/\(date)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            
            do {
                let response = try JSONDecoder().decode(HealthReportResponse.self, from: data)
                if response.success, let reportData = response.data {
                    completion(.success(reportData))
                } else {
                    completion(.failure(NSError(domain: "API", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.msg])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // 获取可用日期列表
    func getAvailableDates(completion: @escaping (Result<[ReportDate], Error>) -> Void) {
        let url = URL(string: "\(baseURL)/report/dates")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            
            do {
                let response = try JSONDecoder().decode(ReportDatesResponse.self, from: data)
                if response.success {
                    completion(.success(response.data.dates))
                } else {
                    completion(.failure(NSError(domain: "API", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.msg])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
```

### 使用示例

```swift
class HealthViewController: UIViewController {
    let healthManager = HealthReportManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        healthManager.setUserToken(UserDefaults.standard.string(forKey: "userToken") ?? "")
        loadAvailableDates()
    }
    
    func loadAvailableDates() {
        healthManager.getAvailableDates { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let dates):
                    self?.updateCalendarWithDates(dates)
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            }
        }
    }
    
    func loadReportForDate(_ date: String) {
        healthManager.getReportByDate(date) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let report):
                    self?.displayHealthReport(report)
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func generateNewReport() {
        healthManager.generateReport { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let report):
                    self?.displayHealthReport(report)
                    self?.loadAvailableDates() // 刷新日期列表
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            }
        }
    }
}
```

## 错误处理

### 常见错误码

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| 400 | 请求参数错误 | 检查日期格式是否正确 |
| 401 | 未授权 | 重新登录获取token |
| 404 | 报告不存在 | 提示用户该日期无报告 |
| 500 | 服务器错误 | 稍后重试 |

### iOS错误处理示例

```swift
func handleAPIError(_ error: Error) {
    if let nsError = error as NSError? {
        switch nsError.code {
        case 401:
            // 重新登录
            showLoginAlert()
        case 404:
            // 显示无数据提示
            showNoDataAlert()
        case 500:
            // 显示服务器错误
            showServerErrorAlert()
        default:
            showGeneralErrorAlert(nsError.localizedDescription)
        }
    }
}
```

## 注意事项

1. **日期格式**: 所有日期参数必须使用 `YYYY-MM-DD` 格式
2. **认证**: 所有接口都需要在Header中携带有效的Bearer Token
3. **缓存策略**: 建议对报告数据进行本地缓存，避免重复请求
4. **更新频率**: 健康报告建议每3天生成一次，避免频繁生成
5. **网络处理**: 建议添加网络状态检查和重试机制
6. **数据安全**: 健康数据敏感，请确保数据传输和存储安全

## 更新日志

- **v1.0.0** (2025-09-28): 
  - 新增按日期查询健康报告功能
  - 支持获取报告日期列表
  - 支持日期范围查询
  - 健康报告更新频率调整为3天