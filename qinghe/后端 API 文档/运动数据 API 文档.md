# 青禾计划 - AI运动教练与运动数据API文档 (iOS对接版)

## 概述

本文档为青禾计划iOS应用提供AI运动教练和运动数据上传功能的完整API接口说明。系统提供基于实时运动数据的智能指导服务和完整的运动数据管理功能。

**API基础地址**: `https://api.qinghejihua.com.cn`

## 认证

所有API请求需要在请求头中包含JWT Token：

```
Authorization: Bearer <your_jwt_token>
```

## 一、AI运动教练功能

### 1.1 运动开始首问

**接口**: `POST /api/v1/workout-ai-coach/start-workout`

**描述**: 运动开始时调用，获取AI教练的欢迎语音指导

**请求参数**:
```json
{
  "workoutType": "跑步",           // 运动类型 (必填)
  "userId": "user123"             // 用户ID (可选)
}
```

**响应格式**:
```json
{
  "success": true,
  "data": {
    "guidance": {
      "type": "welcome_guidance",
      "priority": "medium",
      "message": "您好，我是你的专属运动教练小青禾！今天我们来进行跑步训练，让我为您提供专业指导。准备好了吗？让我们开始吧！",
      "isWelcome": true
    },
    "audio": {
      "success": true,
      "audioUrl": "https://api.qinghejihua.com.cn/public/audio/tts_welcome123.wav",
      "audioId": "welcome123",
      "processingTime": 2.1
    },
    "isWorkoutStart": true,
    "timestamp": "2025-09-09T03:41:05.911Z"
  }
}
```

### 1.2 运动数据实时分析

**接口**: `POST /api/v1/workout-ai-coach/analyze`

**描述**: 基于实时运动数据提供AI教练的专业指导

**请求参数**:
```json
{
  "workoutData": {
    "workoutType": "跑步",           // 运动类型 (必填)
    "heartRate": 150,               // 心率 (bpm) (可选)
    "cadence": 180,                 // 步频 (步/分) (可选)
    "pace": 5.5,                    // 配速 (分/公里) (可选)
    "distance": 2.3,                // 距离 (公里) (可选)
    "duration": 780,                // 运动时长 (秒) (可选)
    "timestamp": "2025-09-09T03:30:00.000Z"
  },
  "userId": "user123",              // 用户ID (可选)
  "options": {
    "generateAudio": true           // 是否生成语音 (默认true)
  }
}
```

**响应格式**:
```json
{
  "success": true,
  "data": {
    "analysis": {
      "heartRate": {
        "status": "warning",        // normal/warning/danger/unknown
        "value": 150,
        "message": "心率偏高，注意运动强度"
      },
      "cadence": {
        "status": "normal",
        "value": 180,
        "message": "步频良好，保持当前节奏"
      },
      "pace": {
        "status": "normal",
        "value": 5.5,
        "message": "配速适中，继续保持"
      },
      "overall": "warning"          // normal/warning/danger
    },
    "guidance": {
      "type": "ai_guidance",
      "priority": "medium",         // low/medium/high
      "message": "保持当前配速，注意呼吸节奏，心率偏高可适当补水降温"
    },
    "audio": {
      "success": true,
      "audioUrl": "https://api.qinghejihua.com.cn/public/audio/tts_abc123.wav",
      "audioId": "abc123",
      "processingTime": 2.5
    },
    "isWorkoutStart": false,
    "timestamp": "2025-09-09T03:30:00.000Z"
  }
}
```

### 1.3 轻量级实时分析

**接口**: `POST /api/v1/workout-ai-coach/real-time`

**描述**: 快速响应的轻量级运动数据分析，适用于高频调用

**请求参数**:
```json
{
  "workoutData": {
    "workoutType": "跑步",
    "heartRate": 145,
    "cadence": 175,
    "pace": 5.8
  },
  "userId": "user123"
}
```

### 1.4 服务健康检查

**接口**: `GET /api/v1/workout-ai-coach/health`

**描述**: 检查AI运动教练服务状态

**响应格式**:
```json
{
  "success": true,
  "service": "workout-ai-coach",
  "message": "运动AI教练服务运行正常",
  "timestamp": "2025-09-09T03:40:08.952Z",
  "features": [
    "实时运动数据分析",
    "心率监控指导",
    "步频优化建议",
    "配速调整提醒",
    "AI语音指导"
  ]
}
```

## 二、运动数据管理功能

### 2.1 创建运动记录

**接口**: `POST /api/v1/workouts`

**描述**: 上传完整的运动数据记录

**频率限制**: 每分钟最多5个运动记录

**请求参数**:
```json
{
  "workoutType": "running",         // 运动类型 (必填)
  "startTime": "2025-09-09T03:30:00.000Z",  // 开始时间 (必填)
  "endTime": "2025-09-09T04:00:00.000Z",    // 结束时间 (必填)
  "duration": 1800,                 // 运动时长(秒) (必填)
  "basicMetrics": {                 // 基础指标 (必填)
    "totalDistance": 5.2,           // 总距离(公里)
    "totalSteps": 6500,             // 总步数
    "calories": 320,                // 消耗卡路里
    "averagePace": 5.8,             // 平均配速(分/公里)
    "maxSpeed": 12.5                // 最大速度(公里/小时)
  },
  "advancedMetrics": {              // 高级指标 (可选)
    "averageHeartRate": 145,        // 平均心率
    "maxHeartRate": 165,            // 最大心率
    "averageCadence": 180,          // 平均步频
    "elevationGain": 50,            // 海拔上升
    "elevationLoss": 45             // 海拔下降
  },
  "routeData": {                    // 路线数据 (可选)
    "coordinates": [                // GPS坐标点数组
      {
        "latitude": 39.9042,
        "longitude": 116.4074,
        "timestamp": "2025-09-09T03:30:00.000Z",
        "altitude": 50.0
      }
    ]
  },
  "deviceInfo": {                   // 设备信息 (必填)
    "deviceType": "iPhone",
    "appVersion": "1.0.0",
    "osVersion": "17.0"
  },
  "weatherInfo": {                  // 天气信息 (可选)
    "temperature": 22,
    "humidity": 65,
    "weather": "晴朗"
  },
  "notes": "晨跑训练"               // 备注 (可选)
}
```

**响应格式**:
```json
{
  "status": "success",
  "message": "运动记录创建成功",
  "data": {
    "workoutId": "12345",
    "workoutType": "running",
    "startTime": "2025-09-09T03:30:00.000Z",
    "endTime": "2025-09-09T04:00:00.000Z",
    "duration": 1800,
    "basicMetrics": {
      "totalDistance": 5.2,
      "totalSteps": 6500,
      "calories": 320,
      "averagePace": 5.8,
      "maxSpeed": 12.5
    },
    "createdAt": "2025-09-09T04:01:00.000Z"
  }
}
```

### 2.2 获取今日运动数据

**接口**: `GET /api/v1/workouts/today`

**描述**: 获取当前用户今日的所有运动数据和统计信息

**响应格式**:
```json
{
  "status": "success",
  "message": "获取今日运动数据成功",
  "data": {
    "date": "2025-09-09",
    "workouts": [
      {
        "workoutId": "12345",
        "workoutType": "running",
        "startTime": "2025-09-09T03:30:00.000Z",
        "endTime": "2025-09-09T04:00:00.000Z",
        "duration": 1800,
        "basicMetrics": {
          "totalDistance": 5.2,
          "totalSteps": 6500,
          "calories": 320,
          "averagePace": 5.8,
          "maxSpeed": 12.5
        },
        "advancedMetrics": {
          "averageHeartRate": 145,
          "maxHeartRate": 165,
          "averageCadence": 180
        }
      }
    ],
    "statistics": {
      "totalWorkouts": 2,
      "totalDistance": 8.5,
      "totalDuration": 3200,
      "totalCalories": 520,
      "totalSteps": 10500
    },
    "typeDistribution": [
      {
        "workoutType": "running",
        "count": 2,
        "totalDuration": 3200,
        "totalCalories": 520
      }
    ],
    "hourlyDistribution": {
      "06:00": 1,
      "18:00": 1
    },
    "qualityAnalysis": {
      "validWorkouts": 2,
      "shortWorkouts": 0,
      "averageDuration": 1600,
      "averageDistance": 4.25,
      "averageCalories": 260
    }
  }
}
```

### 2.3 获取运动记录列表

**接口**: `GET /api/v1/workouts`

**描述**: 分页获取用户的运动记录列表

**查询参数**:
- `page`: 页码 (默认1)
- `limit`: 每页数量 (默认10)
- `workoutType`: 运动类型筛选
- `startDate`: 开始日期
- `endDate`: 结束日期
- `sortBy`: 排序字段 (默认startTime)
- `sortOrder`: 排序方向 (asc/desc，默认desc)

**示例**: `GET /api/v1/workouts?page=1&limit=10&workoutType=running`

### 2.4 获取运动统计数据

**接口**: `GET /api/v1/workouts/statistics`

**描述**: 获取用户的运动统计数据

**查询参数**:
- `period`: 统计周期 (week/month/year，默认week)
- `workoutType`: 运动类型筛选

**示例**: `GET /api/v1/workouts/statistics?period=week&workoutType=running`

### 2.5 获取单个运动记录详情

**接口**: `GET /api/v1/workouts/:workoutId`

**描述**: 获取指定运动记录的详细信息

**示例**: `GET /api/v1/workouts/12345`

## 三、数据结构说明

### 3.1 运动类型 (workoutType)

支持的运动类型：
- `running`: 跑步
- `walking`: 步行
- `cycling`: 骑行
- `swimming`: 游泳
- `hiking`: 徒步
- `yoga`: 瑜伽
- `strength`: 力量训练
- `other`: 其他运动

### 3.2 分析状态值

- `normal`: 正常范围
- `warning`: 需要注意
- `danger`: 危险状态，建议立即调整
- `unknown`: 数据不可用

### 3.3 指导优先级

- `low`: 一般建议
- `medium`: 重要提醒
- `high`: 紧急警告

## 四、错误处理

### 4.1 常见错误码

| 状态码 | 错误类型 | 说明 |
|--------|----------|------|
| 400 | Bad Request | 请求参数错误 |
| 401 | Unauthorized | 未提供或无效的JWT Token |
| 404 | Not Found | 资源未找到 |
| 429 | Too Many Requests | 请求频率超限 |
| 500 | Internal Server Error | 服务器内部错误 |

### 4.2 错误响应格式

```json
{
  "success": false,
  "error": "缺少运动数据",
  "message": "请提供运动数据进行分析",
  "code": 40001
}
```

## 五、使用建议

### 5.1 调用频率建议

- **运动开始**: 每次开始运动时调用一次 `start-workout`
- **实时分析**: 建议每30-60秒调用一次完整分析接口
- **轻量分析**: 可每10-15秒调用一次实时分析接口
- **数据上传**: 运动结束后上传完整运动记录

### 5.2 数据质量建议

- 提供尽可能完整的运动数据以获得更准确的分析
- 确保时间戳的准确性和一致性
- 处理传感器数据异常情况
- 实现适当的错误重试机制

## 六、Swift集成示例

### 6.1 基础配置

```swift
import Foundation

class QingHeAPIClient {
    static let shared = QingHeAPIClient()
    private let baseURL = "https://api.qinghejihua.com.cn"
    private var jwtToken: String?

    private init() {}

    func setJWTToken(_ token: String) {
        self.jwtToken = token
    }

    private func createRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = jwtToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }
}
```

### 6.2 AI运动教练集成

```swift
// MARK: - AI运动教练相关数据结构
struct WorkoutData: Codable {
    let workoutType: String
    let heartRate: Int?
    let cadence: Int?
    let pace: Double?
    let distance: Double?
    let duration: Int?
    let timestamp: String?
}

struct AICoachResponse: Codable {
    let success: Bool
    let data: AICoachData?
    let error: String?
}

struct AICoachData: Codable {
    let analysis: WorkoutAnalysis
    let guidance: AIGuidance
    let audio: AudioResult?
    let isWorkoutStart: Bool
    let timestamp: String
}

struct WorkoutAnalysis: Codable {
    let heartRate: MetricAnalysis
    let cadence: MetricAnalysis
    let pace: MetricAnalysis
    let overall: String
}

struct MetricAnalysis: Codable {
    let status: String
    let value: Double?
    let message: String
}

struct AIGuidance: Codable {
    let type: String
    let priority: String
    let message: String
    let isWelcome: Bool?
}

struct AudioResult: Codable {
    let success: Bool
    let audioUrl: String?
    let audioId: String?
    let processingTime: Double?
    let error: String?
}

// MARK: - AI运动教练服务
extension QingHeAPIClient {

    /// 开始运动 - 获取欢迎指导
    func startWorkout(workoutType: String, userId: String? = nil) async throws -> AICoachResponse {
        let url = URL(string: "\(baseURL)/api/v1/workout-ai-coach/start-workout")!
        var request = createRequest(url: url, method: "POST")

        let requestBody: [String: Any] = [
            "workoutType": workoutType,
            "userId": userId ?? "anonymous"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }

        return try JSONDecoder().decode(AICoachResponse.self, from: data)
    }

    /// 实时运动数据分析
    func analyzeWorkoutData(_ workoutData: WorkoutData, userId: String? = nil, generateAudio: Bool = true) async throws -> AICoachResponse {
        let url = URL(string: "\(baseURL)/api/v1/workout-ai-coach/analyze")!
        var request = createRequest(url: url, method: "POST")

        let requestBody: [String: Any] = [
            "workoutData": try workoutData.toDictionary(),
            "userId": userId ?? "anonymous",
            "options": [
                "generateAudio": generateAudio
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }

        return try JSONDecoder().decode(AICoachResponse.self, from: data)
    }

    /// 轻量级实时分析
    func realTimeAnalysis(_ workoutData: WorkoutData, userId: String? = nil) async throws -> AICoachResponse {
        let url = URL(string: "\(baseURL)/api/v1/workout-ai-coach/real-time")!
        var request = createRequest(url: url, method: "POST")

        let requestBody: [String: Any] = [
            "workoutData": try workoutData.toDictionary(),
            "userId": userId ?? "anonymous"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }

        return try JSONDecoder().decode(AICoachResponse.self, from: data)
    }

    /// 检查AI教练服务健康状态
    func checkAICoachHealth() async throws -> [String: Any] {
        let url = URL(string: "\(baseURL)/api/v1/workout-ai-coach/health")!
        let request = createRequest(url: url)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }

        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}
```

### 6.3 运动数据管理集成

```swift
// MARK: - 运动数据相关数据结构
struct WorkoutRecord: Codable {
    let workoutType: String
    let startTime: String
    let endTime: String
    let duration: Int
    let basicMetrics: BasicMetrics
    let advancedMetrics: AdvancedMetrics?
    let routeData: RouteData?
    let deviceInfo: DeviceInfo
    let weatherInfo: WeatherInfo?
    let notes: String?
}

struct BasicMetrics: Codable {
    let totalDistance: Double
    let totalSteps: Int
    let calories: Int
    let averagePace: Double
    let maxSpeed: Double
}

struct AdvancedMetrics: Codable {
    let averageHeartRate: Int?
    let maxHeartRate: Int?
    let averageCadence: Int?
    let elevationGain: Double?
    let elevationLoss: Double?
}

struct RouteData: Codable {
    let coordinates: [GPSCoordinate]
}

struct GPSCoordinate: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: String
    let altitude: Double?
}

struct DeviceInfo: Codable {
    let deviceType: String
    let appVersion: String
    let osVersion: String?
}

struct WeatherInfo: Codable {
    let temperature: Int?
    let humidity: Int?
    let weather: String?
}

struct WorkoutResponse: Codable {
    let status: String
    let message: String
    let data: WorkoutResponseData?
}

struct WorkoutResponseData: Codable {
    let workoutId: String
    let workoutType: String
    let startTime: String
    let endTime: String
    let duration: Int
    let basicMetrics: BasicMetrics
    let createdAt: String
}

struct TodayWorkoutsResponse: Codable {
    let status: String
    let message: String
    let data: TodayWorkoutsData
}

struct TodayWorkoutsData: Codable {
    let date: String
    let workouts: [WorkoutDetail]
    let statistics: WorkoutStatistics
    let typeDistribution: [TypeDistribution]
    let hourlyDistribution: [String: Int]
    let qualityAnalysis: QualityAnalysis
}

struct WorkoutDetail: Codable {
    let workoutId: String
    let workoutType: String
    let startTime: String
    let endTime: String
    let duration: Int
    let basicMetrics: BasicMetrics
    let advancedMetrics: AdvancedMetrics?
}

struct WorkoutStatistics: Codable {
    let totalWorkouts: Int
    let totalDistance: Double
    let totalDuration: Int
    let totalCalories: Int
    let totalSteps: Int
}

struct TypeDistribution: Codable {
    let workoutType: String
    let count: Int
    let totalDuration: Int
    let totalCalories: Int
}

struct QualityAnalysis: Codable {
    let validWorkouts: Int
    let shortWorkouts: Int
    let averageDuration: Int
    let averageDistance: Double
    let averageCalories: Int
}

// MARK: - 运动数据管理服务
extension QingHeAPIClient {

    /// 创建运动记录
    func createWorkout(_ workout: WorkoutRecord) async throws -> WorkoutResponse {
        let url = URL(string: "\(baseURL)/api/v1/workouts")!
        var request = createRequest(url: url, method: "POST")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(workout)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }

        return try JSONDecoder().decode(WorkoutResponse.self, from: data)
    }

    /// 获取今日运动数据
    func getTodayWorkouts() async throws -> TodayWorkoutsResponse {
        let url = URL(string: "\(baseURL)/api/v1/workouts/today")!
        let request = createRequest(url: url)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }

        return try JSONDecoder().decode(TodayWorkoutsResponse.self, from: data)
    }

    /// 获取运动记录列表
    func getWorkouts(page: Int = 1, limit: Int = 10, workoutType: String? = nil, startDate: String? = nil, endDate: String? = nil) async throws -> [String: Any] {
        var urlComponents = URLComponents(string: "\(baseURL)/api/v1/workouts")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        if let workoutType = workoutType {
            queryItems.append(URLQueryItem(name: "workoutType", value: workoutType))
        }
        if let startDate = startDate {
            queryItems.append(URLQueryItem(name: "startDate", value: startDate))
        }
        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "endDate", value: endDate))
        }

        urlComponents.queryItems = queryItems

        let request = createRequest(url: urlComponents.url!)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }

        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    /// 获取运动统计数据
    func getWorkoutStatistics(period: String = "week", workoutType: String? = nil) async throws -> [String: Any] {
        var urlComponents = URLComponents(string: "\(baseURL)/api/v1/workouts/statistics")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "period", value: period)
        ]

        if let workoutType = workoutType {
            queryItems.append(URLQueryItem(name: "workoutType", value: workoutType))
        }

        urlComponents.queryItems = queryItems

        let request = createRequest(url: urlComponents.url!)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }

        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}

// MARK: - 辅助扩展
extension Codable {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}

enum APIError: Error {
    case requestFailed
    case invalidResponse
    case decodingError
}
```

### 6.4 使用示例

```swift
class WorkoutManager {
    private let apiClient = QingHeAPIClient.shared

    func startWorkoutSession(workoutType: String) async {
        do {
            // 1. 开始运动，获取欢迎指导
            let welcomeResponse = try await apiClient.startWorkout(workoutType: workoutType, userId: "user123")

            if let guidance = welcomeResponse.data?.guidance {
                print("AI教练说: \(guidance.message)")

                // 播放语音指导
                if let audioUrl = welcomeResponse.data?.audio?.audioUrl {
                    await playAudioGuidance(audioUrl)
                }
            }

        } catch {
            print("开始运动失败: \(error)")
        }
    }

    func analyzeRealTimeData(heartRate: Int, cadence: Int, pace: Double, distance: Double, duration: Int) async {
        do {
            let workoutData = WorkoutData(
                workoutType: "跑步",
                heartRate: heartRate,
                cadence: cadence,
                pace: pace,
                distance: distance,
                duration: duration,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )

            // 实时分析运动数据
            let analysisResponse = try await apiClient.analyzeWorkoutData(workoutData, userId: "user123")

            if let guidance = analysisResponse.data?.guidance {
                print("AI指导: \(guidance.message)")

                // 根据优先级处理指导
                switch guidance.priority {
                case "high":
                    // 紧急警告，立即显示
                    showUrgentAlert(guidance.message)
                case "medium":
                    // 重要提醒
                    showImportantNotification(guidance.message)
                default:
                    // 一般建议
                    showGeneralGuidance(guidance.message)
                }

                // 播放语音指导
                if let audioUrl = analysisResponse.data?.audio?.audioUrl {
                    await playAudioGuidance(audioUrl)
                }
            }

        } catch {
            print("实时分析失败: \(error)")
        }
    }

    func saveWorkoutRecord(workoutType: String, startTime: Date, endTime: Date, basicMetrics: BasicMetrics, advancedMetrics: AdvancedMetrics? = nil) async {
        do {
            let deviceInfo = DeviceInfo(
                deviceType: "iPhone",
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
                osVersion: UIDevice.current.systemVersion
            )

            let workoutRecord = WorkoutRecord(
                workoutType: workoutType,
                startTime: ISO8601DateFormatter().string(from: startTime),
                endTime: ISO8601DateFormatter().string(from: endTime),
                duration: Int(endTime.timeIntervalSince(startTime)),
                basicMetrics: basicMetrics,
                advancedMetrics: advancedMetrics,
                routeData: nil,
                deviceInfo: deviceInfo,
                weatherInfo: nil,
                notes: nil
            )

            let response = try await apiClient.createWorkout(workoutRecord)

            if response.status == "success" {
                print("运动记录保存成功: \(response.data?.workoutId ?? "")")
            }

        } catch {
            print("保存运动记录失败: \(error)")
        }
    }

    func loadTodayWorkouts() async {
        do {
            let response = try await apiClient.getTodayWorkouts()

            print("今日运动统计:")
            print("- 总运动次数: \(response.data.statistics.totalWorkouts)")
            print("- 总距离: \(response.data.statistics.totalDistance) 公里")
            print("- 总时长: \(response.data.statistics.totalDuration) 秒")
            print("- 总卡路里: \(response.data.statistics.totalCalories)")

            // 显示运动记录列表
            for workout in response.data.workouts {
                print("运动记录: \(workout.workoutType) - \(workout.basicMetrics.totalDistance) 公里")
            }

        } catch {
            print("加载今日运动数据失败: \(error)")
        }
    }

    // MARK: - 辅助方法
    private func playAudioGuidance(_ audioUrl: String) async {
        // 实现音频播放逻辑
        print("播放语音指导: \(audioUrl)")
    }

    private func showUrgentAlert(_ message: String) {
        // 显示紧急警告
        print("🚨 紧急警告: \(message)")
    }

    private func showImportantNotification(_ message: String) {
        // 显示重要通知
        print("⚠️ 重要提醒: \(message)")
    }

    private func showGeneralGuidance(_ message: String) {
        // 显示一般指导
        print("💡 建议: \(message)")
    }
}
```

---

**文档版本**: v1.0
**最后更新**: 2025-09-09
**服务状态**: ✅ 正常运行
**联系方式**: 如有问题请联系后端开发团队
