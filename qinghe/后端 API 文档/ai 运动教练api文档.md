# 青禾计划 - 运动AI教练API文档

## 概述

运动AI教练功能为iOS应用提供基于实时运动数据的智能指导服务。系统通过分析用户的心率、步频、配速等运动指标，结合DeepSeek AI模型生成个性化的运动建议，并通过GPT-SoVITS技术提供中文语音指导。

**API基础地址**: `https://api.qinghejihua.com.cn`

## 认证

所有API请求需要在请求头中包含JWT Token：

```
Authorization: Bearer <your_jwt_token>
```

## 核心API接口

### 1. 运动AI教练语音指导 (完整版)

**接口**: `POST /api/v1/workout-ai-coach/analyze`

**描述**: 基于运动数据提供AI教练的专业语音指导，包含实时数据分析、个性化建议和中文语音合成。这是一个完整的语音交互服务，不仅分析数据，更重要的是通过语音与用户进行专业的运动指导沟通。

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
    "timestamp": "2024-01-01T10:00:00.000Z"  // 时间戳 (可选)
  },
  "userId": "user123",              // 用户ID (可选，用于首问检测)
  "options": {
    "generateAudio": true           // 语音生成 (必须为true，这是语音沟通服务的核心功能)
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
      "distance": {
        "status": "normal",
        "value": 2.3,
        "message": "已完成2.30公里"
      },
      "duration": {
        "status": "normal",
        "value": 780,
        "message": "运动时长13分0秒"
      },
      "overall": "warning"          // normal/warning/danger
    },
    "guidance": {
      "type": "ai_guidance",
      "priority": "medium",         // low/medium/high
      "message": "保持当前配速，注意呼吸节奏，心率偏高可适当补水降温",
      "analysis": { /* 分析结果 */ }
    },
    "audio": {
      "success": true,
      "audioUrl": "https://api.qinghejihua.com.cn/public/audio/tts_abc123.wav",
      "audioId": "abc123",
      "processingTime": 2.5
    },
    "isWorkoutStart": false,        // 是否是运动开始（首问）
    "timestamp": "2024-01-01T10:00:00.000Z"
  }
}
```

### 2. 实时运动分析 (轻量版)

**接口**: `POST /api/v1/workout-ai-coach/real-time`

**描述**: 轻量级运动数据分析，包含语音指导但处理更快，适用于高频调用场景

**请求参数**:
```json
{
  "workoutData": {
    "workoutType": "跑步",
    "heartRate": 145,
    "cadence": 175,
    "pace": 5.8
  }
}
```

**响应格式**:
```json
{
  "success": true,
  "analysis": {
    "heartRate": {
      "status": "normal",
      "value": 145,
      "message": "心率正常"
    },
    "cadence": {
      "status": "normal",
      "value": 175,
      "message": "步频良好"
    },
    "pace": {
      "status": "normal",
      "value": 5.8,
      "message": "配速适中"
    },
    "overall": "normal"
  },
  "guidance": {
    "type": "ai_guidance",
    "priority": "low",
    "message": "保持当前节奏，运动状态良好"
  },
  "audio": {
    "success": true,
    "audioUrl": "https://api.qinghejihua.com.cn/public/audio/tts_realtime123.wav",
    "audioId": "realtime123",
    "processingTime": 1.2
  },
  "isWorkoutStart": false,
  "timestamp": "2024-01-01T10:00:00.000Z"
}
```

### 3. 运动开始首问

**接口**: `POST /api/v1/workout-ai-coach/start-workout`

**描述**: 运动开始时的专用接口，自动生成欢迎语音"您好，我是你的专属运动教练小青禾"

**请求参数**:
```json
{
  "workoutType": "跑步",            // 运动类型 (必填)
  "userId": "user123"              // 用户ID (可选)
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
    "timestamp": "2024-01-01T10:00:00.000Z"
  }
}
```

### 4. 单独生成语音指导

**接口**: `POST /api/v1/workout-ai-coach/audio-guidance`

**描述**: 为指定文本生成语音指导

**请求参数**:
```json
{
  "message": "保持当前配速，注意呼吸节奏",
  "userId": "user123"             // 可选，用于日志记录
}
```

**响应格式**:
```json
{
  "success": true,
  "audioUrl": "https://api.qinghejihua.com.cn/public/audio/tts_def456.wav",
  "audioId": "def456",
  "processingTime": 1.8
}
```

## 音频生命周期管理

为了防止服务器存储空间被音频文件占满，系统提供了音频生命周期管理功能。

### 5. 通知音频播放开始

**接口**: `POST /api/v1/audio-lifecycle/playback-started`

**描述**: 通知服务器音频开始播放

**请求参数**:
```json
{
  "audioId": "abc123",            // 音频ID (从audio响应中获取)
  "audioUrl": "https://api.qinghejihua.com.cn/public/audio/tts_abc123.wav"  // 或提供完整URL
}
```

**响应格式**:
```json
{
  "success": true,
  "message": "播放开始通知已接收",
  "audioId": "abc123"
}
```

### 6. 通知音频播放完成

**接口**: `POST /api/v1/audio-lifecycle/playback-completed`

**描述**: 通知服务器音频播放完成，服务器将在10秒后自动清理文件

**请求参数**:
```json
{
  "audioId": "abc123"
}
```

**响应格式**:
```json
{
  "success": true,
  "message": "播放完成通知已接收，文件将自动清理",
  "audioId": "abc123"
}
```

### 7. 通知音频播放错误

**接口**: `POST /api/v1/audio-lifecycle/playback-error`

**描述**: 通知服务器音频播放出错，服务器将立即清理文件

**请求参数**:
```json
{
  "audioId": "abc123",
  "error": "网络连接失败"         // 错误描述
}
```

## 服务状态检查

### 8. 服务健康检查

**接口**: `GET /api/v1/workout-ai-coach/health`

**响应格式**:
```json
{
  "success": true,
  "service": "workout-ai-coach",
  "message": "运动AI教练服务运行正常",
  "timestamp": "2024-01-01T10:00:00.000Z",
  "features": [
    "实时运动数据分析",
    "心率监控指导", 
    "步频优化建议",
    "配速调整提醒",
    "AI语音指导"
  ]
}
```

### 9. 服务状态详情

**接口**: `GET /api/v1/workout-ai-coach/status`

**响应格式**:
```json
{
  "success": true,
  "status": {
    "service": "workout-ai-coach",
    "initialized": true,
    "ttsAvailable": true,
    "aiAvailable": true,
    "timestamp": "2024-01-01T10:00:00.000Z"
  }
}
```

## 数据结构说明

### 运动数据字段 (workoutData)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| workoutType | String | 是 | 运动类型，如"跑步"、"骑行"、"游泳"等 |
| heartRate | Number | 否 | 心率，单位：bpm |
| cadence | Number | 否 | 步频，单位：步/分钟 |
| pace | Number | 否 | 配速，单位：分钟/公里 |
| distance | Number | 否 | 距离，单位：公里 |
| duration | Number | 否 | 运动时长，单位：秒 |
| timestamp | String | 否 | ISO 8601格式时间戳 |

### 分析状态值

- **normal**: 正常范围
- **warning**: 需要注意
- **danger**: 危险状态，建议立即调整
- **unknown**: 数据不可用

### 指导优先级

- **low**: 一般建议
- **medium**: 重要提醒
- **high**: 紧急警告

## 错误处理

### 常见错误码

| 状态码 | 错误类型 | 说明 |
|--------|----------|------|
| 400 | Bad Request | 请求参数错误 |
| 401 | Unauthorized | 未提供或无效的JWT Token |
| 404 | Not Found | 资源未找到 |
| 500 | Internal Server Error | 服务器内部错误 |

### 错误响应格式

```json
{
  "success": false,
  "error": "缺少运动数据",
  "message": "请提供运动数据进行分析"
}
```

## 使用建议

### 1. 运动开始流程
- **运动开始**: 首先调用 `start-workout` 接口获取欢迎语音
- **首问检测**: 系统会自动检测运动开始（duration ≤ 30秒）
- **会话管理**: 每个用户的运动会话有效期为30分钟
- **运动类型**: 切换运动类型时会重新触发首问

### 2. 调用频率
- **运动开始**: 每次开始运动时调用一次 `start-workout`
- **完整分析**: 建议每30-60秒调用一次，包含完整语音指导
- **实时分析**: 可每10-15秒调用一次，包含轻量级语音指导
- **单独语音**: 根据特殊需要调用，所有分析接口都已包含语音

### 3. 音频处理
- 播放音频前调用 `playback-started`
- 播放完成后立即调用 `playback-completed`
- 播放出错时调用 `playback-error`
- 音频文件会在播放完成后10秒自动清理

### 4. 网络优化
- 使用实时分析接口进行高频数据更新（包含语音）
- 使用完整分析接口进行深度分析（包含完整语音指导）
- 实现适当的错误重试机制
- 所有接口都提供语音沟通服务

### 5. 数据质量
- 提供尽可能完整的运动数据以获得更准确的分析
- 确保数据的时效性和准确性
- 处理传感器数据异常情况

## 示例代码 (Swift)

```swift
// 运动开始首问示例
func startWorkout(workoutType: String, userId: String) async throws -> WelcomeResult {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/workout-ai-coach/start-workout")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

    let requestBody = [
        "workoutType": workoutType,
        "userId": userId
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw APIError.requestFailed
    }

    return try JSONDecoder().decode(WelcomeResult.self, from: data)
}

// 运动数据分析请求示例
func analyzeWorkoutData(workoutData: WorkoutData, userId: String) async throws -> AnalysisResult {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/workout-ai-coach/analyze")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
    
    let requestBody = [
        "workoutData": [
            "workoutType": workoutData.type,
            "heartRate": workoutData.heartRate,
            "cadence": workoutData.cadence,
            "pace": workoutData.pace,
            "distance": workoutData.distance,
            "duration": workoutData.duration,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ],
        "userId": userId,
        "options": [
            "generateAudio": true
        ]
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw APIError.requestFailed
    }
    
    return try JSONDecoder().decode(AnalysisResult.self, from: data)
}

// 音频播放完成通知
func notifyAudioPlaybackCompleted(audioId: String) async {
    let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/audio-lifecycle/playback-completed")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let requestBody = ["audioId": audioId]
    request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
    
    do {
        let (_, _) = try await URLSession.shared.data(for: request)
        print("音频播放完成通知已发送")
    } catch {
        print("发送音频播放完成通知失败: \(error)")
    }
}
```

---

**文档版本**: v1.0  
**最后更新**: 2024-01-01  
**联系方式**: 如有问题请联系后端开发团队
