# 青禾计划 - 打卡功能API文档

## 概述

青禾计划的打卡功能提供了完整的签到管理系统，包括每日签到、签到记录查询、统计分析、时间模式分析等功能，帮助用户建立良好的习惯养成机制。

## 基础信息

- **基础URL**: `https://api.qinghejihua.com.cn/api/v1`
- **认证方式**: Bearer Token (JWT)
- **响应格式**: JSON
- **路由前缀**: `/checkins`

## API接口列表

### 1. 用户签到

创建新的签到记录。

**接口地址**: `POST /checkins`

**认证**: 需要Bearer Token

**请求参数**:
```json
{
  "deviceInfo": "iPhone 15 Pro Max",
  "location": {
    "latitude": 39.9042,
    "longitude": 116.4074,
    "address": "北京市朝阳区"
  },
  "note": "今天状态很好，继续加油！",
  "mood": "积极",
  "challenges": "今天遇到了一些诱惑，但成功抵制了"
}
```

**参数说明**:
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| deviceInfo | string | 否 | 设备信息，最大200字符 |
| location | object | 否 | 位置信息对象 |
| location.latitude | number | 否 | 纬度 |
| location.longitude | number | 否 | 经度 |
| location.address | string | 否 | 地址描述，最大200字符 |
| note | string | 否 | 签到备注，最大200字符 |
| mood | string | 否 | 心情描述，最大50字符 |
| challenges | string | 否 | 挑战描述，最大300字符 |

**成功响应** (HTTP 201):
```json
{
  "status": "success",
  "message": "签到成功",
  "data": {
    "checkin": {
      "id": 123,
      "userId": 456,
      "date": "2024-01-15",
      "time": "08:30:00",
      "deviceInfo": "iPhone 15 Pro Max",
      "ipAddress": "192.168.1.1",
      "locationLatitude": 39.9042,
      "locationLongitude": 116.4074,
      "locationAddress": "北京市朝阳区",
      "note": "今天状态很好，继续加油！",
      "createdAt": "2024-01-15T08:30:00.000Z",
      "updatedAt": "2024-01-15T08:30:00.000Z"
    }
  }
}
```

**错误响应**:
```json
{
  "status": "error",
  "message": "今天已经签到过了"
}
```

**限制说明**:
- 每天只能签到一次
- 系统自动记录签到时间和IP地址
- 所有字段都有长度限制

---

### 2. 获取签到记录

获取用户的签到记录列表，支持分页和日期筛选。

**接口地址**: `GET /checkins`

**认证**: 需要Bearer Token

**查询参数**:
| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| page | integer | 否 | 1 | 页码 |
| limit | integer | 否 | 10 | 每页记录数 |
| startDate | string | 否 | - | 开始日期 (YYYY-MM-DD) |
| endDate | string | 否 | - | 结束日期 (YYYY-MM-DD) |

**成功响应** (HTTP 200):
```json
{
  "status": "success",
  "data": {
    "checkins": [
      {
        "id": 123,
        "userId": 456,
        "date": "2024-01-15",
        "time": "08:30:00",
        "deviceInfo": "iPhone 15 Pro Max",
        "ipAddress": "192.168.1.1",
        "locationLatitude": 39.9042,
        "locationLongitude": 116.4074,
        "locationAddress": "北京市朝阳区",
        "note": "今天状态很好，继续加油！",
        "createdAt": "2024-01-15T08:30:00.000Z",
        "updatedAt": "2024-01-15T08:30:00.000Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalCheckins": 45,
      "hasNextPage": true,
      "hasPrevPage": false
    }
  }
}
```

---

### 3. 获取签到统计

获取用户的签到统计信息，包括总天数、连续天数、本月天数等。

**接口地址**: `GET /checkins/statistics`

**认证**: 需要Bearer Token

**成功响应** (HTTP 200):
```json
{
  "status": "success",
  "data": {
    "totalDays": 45,
    "consecutiveDays": 7,
    "thisMonthDays": 15,
    "heatmapData": [
      {
        "date": "2024-01-15",
        "time": "08:30:00"
      }
    ],
    "timeAnalysis": {
      "morningCount": 20,
      "afternoonCount": 15,
      "eveningCount": 8,
      "nightCount": 2,
      "riskLevel": "low",
      "suggestions": [
        "您的签到时间很规律，继续保持良好的作息习惯"
      ]
    }
  }
}
```

**字段说明**:
- `totalDays`: 总签到天数
- `consecutiveDays`: 连续签到天数
- `thisMonthDays`: 本月签到天数
- `heatmapData`: 最近365天的签到数据
- `timeAnalysis`: 签到时间分析
  - `morningCount`: 上午签到次数 (06:00-12:00)
  - `afternoonCount`: 下午签到次数 (12:00-18:00)
  - `eveningCount`: 晚上签到次数 (18:00-22:00)
  - `nightCount`: 深夜签到次数 (22:00-06:00)
  - `riskLevel`: 风险等级 (low/medium/high)
  - `suggestions`: 个性化建议

---

### 4. 获取今日签到状态

检查用户今天是否已经签到。

**接口地址**: `GET /checkins/today`

**认证**: 需要Bearer Token

**成功响应** (HTTP 200):
```json
{
  "status": "success",
  "data": {
    "hasCheckedIn": true,
    "checkin": {
      "id": 123,
      "userId": 456,
      "date": "2024-01-15",
      "time": "08:30:00",
      "deviceInfo": "iPhone 15 Pro Max",
      "locationAddress": "北京市朝阳区",
      "note": "今天状态很好，继续加油！"
    }
  }
}
```

**如果今天未签到**:
```json
{
  "status": "success",
  "data": {
    "hasCheckedIn": false,
    "checkin": null
  }
}
```

---

### 5. 获取签到分析数据

获取签到的分析数据，支持热力图等可视化数据。

**接口地址**: `GET /checkins/analysis`

**认证**: 需要Bearer Token

**查询参数**:
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| type | string | 否 | 分析类型，支持 'heatmap' |
| year | integer | 否 | 指定年份 |
| month | integer | 否 | 指定月份 |

**成功响应** (HTTP 200):
```json
{
  "status": "success",
  "data": {
    "heatmapData": [
      {
        "date": "2024-01-15",
        "time": "08:30:00",
        "value": 1
      }
    ]
  }
}
```

---

### 6. 获取签到历史记录 (别名)

**接口地址**: `GET /checkins/history`

**说明**: 这是 `GET /checkins` 的别名路由，功能完全相同。

---

## 错误码说明

| 状态码 | 错误类型 | 说明 |
|--------|----------|------|
| 400 | Bad Request | 请求参数错误或今天已签到 |
| 401 | Unauthorized | 未提供认证token或token无效 |
| 500 | Internal Server Error | 服务器内部错误或数据库不可用 |

## 认证机制

所有打卡API都需要在请求头中包含有效的JWT token：

```
Authorization: Bearer <your_jwt_token>
```

## 数据模型

### Checkin 签到记录

```javascript
{
  id: Integer,              // 签到记录ID
  userId: Integer,          // 用户ID
  date: String,             // 签到日期 (YYYY-MM-DD)
  time: String,             // 签到时间 (HH:mm:ss)
  deviceInfo: String,       // 设备信息
  ipAddress: String,        // IP地址
  locationLatitude: Float,  // 纬度
  locationLongitude: Float, // 经度
  locationAddress: String,  // 地址描述
  note: String,             // 签到备注
  createdAt: DateTime,      // 创建时间
  updatedAt: DateTime       // 更新时间
}
```

## 业务规则

### 签到限制
1. **每日限制**: 每个用户每天只能签到一次
2. **时间记录**: 系统自动记录签到的准确时间
3. **IP追踪**: 自动记录用户的IP地址
4. **字段限制**: 所有文本字段都有最大长度限制

### 连续签到计算
1. 从最近的签到日期开始向前计算
2. 如果今天未签到，从昨天开始计算
3. 遇到断签立即停止计算

### 风险等级评估
- **低风险 (low)**: 夜间签到比例 ≤ 15%
- **中风险 (medium)**: 夜间签到比例 15% - 30%
- **高风险 (high)**: 夜间签到比例 > 30%

## 使用示例

### 完整的签到流程

```javascript
// 1. 检查今日签到状态
const todayStatus = await fetch('/api/v1/checkins/today', {
  headers: {
    'Authorization': 'Bearer ' + token
  }
});

// 2. 如果未签到，执行签到
if (!todayStatus.data.hasCheckedIn) {
  const checkinResult = await fetch('/api/v1/checkins', {
    method: 'POST',
    headers: {
      'Authorization': 'Bearer ' + token,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      deviceInfo: 'iPhone 15 Pro Max',
      location: {
        latitude: 39.9042,
        longitude: 116.4074,
        address: '北京市朝阳区'
      },
      note: '今天状态很好！',
      mood: '积极'
    })
  });
}

// 3. 获取签到统计
const statistics = await fetch('/api/v1/checkins/statistics', {
  headers: {
    'Authorization': 'Bearer ' + token
  }
});
```

### 获取签到记录

```javascript
// 获取最近的签到记录
const recentCheckins = await fetch('/api/v1/checkins?page=1&limit=10', {
  headers: {
    'Authorization': 'Bearer ' + token
  }
});

// 获取指定日期范围的记录
const rangeCheckins = await fetch('/api/v1/checkins?startDate=2024-01-01&endDate=2024-01-31', {
  headers: {
    'Authorization': 'Bearer ' + token
  }
});
```

### 获取分析数据

```javascript
// 获取热力图数据
const heatmapData = await fetch('/api/v1/checkins/analysis?type=heatmap', {
  headers: {
    'Authorization': 'Bearer ' + token
  }
});

// 获取指定月份的数据
const monthlyData = await fetch('/api/v1/checkins/analysis?type=heatmap&year=2024&month=1', {
  headers: {
    'Authorization': 'Bearer ' + token
  }
});
```

## 安全特性

1. **认证保护**: 所有接口都需要有效的JWT token
2. **用户隔离**: 用户只能访问自己的签到数据
3. **参数验证**: 严格的输入参数验证
4. **重复检查**: 防止同一天重复签到
5. **IP记录**: 记录签到时的IP地址用于安全审计
6. **数据安全**: 使用raw查询避免序列化问题

## 开发支持

### 测试工具
项目提供了多个测试脚本用于API测试：
- `test-checkin-api.js`: 基础功能测试
- `test-checkin-with-real-code.js`: 真实验证码测试
- `test-checkin-automated.js`: 自动化测试

### 错误处理
所有API都提供详细的错误信息，包括：
- 错误状态码
- 错误消息
- 详细的错误描述（验证失败时）

### 性能优化
- 使用数据库索引优化查询性能
- 分页查询避免大量数据传输
- Raw查询避免ORM序列化开销

---

**文档版本**: v1.0  
**最后更新**: 2024年1月  
**维护团队**: 青禾计划开发团队