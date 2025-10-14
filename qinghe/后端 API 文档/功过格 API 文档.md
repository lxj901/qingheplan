# 青禾计划 iOS API 接口文档

## 📋 目录
- [基础信息](#基础信息)
- [认证说明](#认证说明)
- [用户模块](#用户模块)
- [功过格模块](#功过格模块)
- [错误码说明](#错误码说明)
- [Swift代码示例](#swift代码示例)

---

## 基础信息

### 服务器信息
- **生产环境**: `https://api.qinghejihua.com.cn/api/v1`
- **内容类型**: `application/json`
- **字符编码**: `UTF-8`

### 通用响应格式

**成功响应**:
```json
{
  "code": 200,
  "message": "操作成功",
  "data": { ... }
}
```

**失败响应**:
```json
{
  "code": 400,
  "message": "错误描述信息",
  "data": null
}
```

---

## 认证说明

### Token 认证
除了登录和注册接口外，所有API请求都需要在请求头中携带Token：

```
Authorization: Bearer <your_token_here>
```

### Token 获取
通过登录接口获取Token，Token有效期为7天。

---

## 用户模块

### 获取当前用户信息

**接口**: `GET /users/me`

**请求头**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**成功响应** (200):
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "id": 1,
    "phone": "19820722496",
    "username": "用户昵称",
    "avatar": "https://example.com/avatar.jpg",
    "createdAt": "2025-10-06T10:00:00.000Z"
  }
}
```

---

## 功过格模块

### 1. 获取标准条目列表

**接口**: `GET /merits/standard-items`

**请求头**:
```
Authorization: Bearer <token>
```

**查询参数**:
- `type` (可选): `merit` (功/善行) 或 `demerit` (过/过失)
- `category` (可选): 分类名称，如 "助人"、"勤学" 等
- `page` (可选): 页码，默认1
- `pageSize` (可选): 每页数量，默认20

**请求示例**:
```
GET /merits/standard-items?type=merit&category=助人&page=1&pageSize=10
```

**成功响应** (200):
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "merits": [
      {
        "id": 1,
        "type": "merit",
        "category": "助人",
        "title": "救助急难",
        "description": "救助他人于危难之中",
        "points": 5,
        "icon": "🆘"
      },
      {
        "id": 2,
        "type": "merit",
        "category": "助人",
        "title": "扶危济困",
        "description": "帮助困难的人",
        "points": 3,
        "icon": "🤝"
      }
    ],
    "demerits": [],
    "pagination": {
      "total": 100,
      "page": 1,
      "pageSize": 10,
      "totalPages": 10
    },
    "categories": {
      "merit": ["助人", "勤学", "孝亲", "守信", "慈幼", "护生", "敬长", "礼让", "节俭", "诚信"],
      "demerit": ["不敬", "伤生", "偷盗", "失信", "妄语", "懒惰", "扰众", "毁谤", "浪费", "邪淫"]
    }
  }
}
```

**cURL 示例**:
```bash
curl -X GET "https://api.qinghejihua.com.cn/api/v1/merits/standard-items?type=merit" \
  -H "Authorization: Bearer <token>"
```

---

### 2. 创建功过记录

**接口**: `POST /api/merits`

**请求头**:
```
Authorization: Bearer <token>
Content-Type: application/json
```

**请求体**:
```json
{
  "type": "merit",
  "category": "孝亲",
  "title": "晨起问安",
  "points": 2,
  "date": "2025-10-06",
  "notes": "早起向父母问安"
}
```

**字段说明**:
- `type` (必填): `merit` 或 `demerit`
- `category` (必填): 分类名称
- `title` (必填): 标题
- `points` (必填): 分值 (1-10)
- `date` (可选): 日期，格式 YYYY-MM-DD，默认今天
- `notes` (可选): 备注说明

**成功响应** (201):
```json
{
  "code": 201,
  "message": "创建成功",
  "data": {
    "id": 5,
    "userId": 1,
    "type": "merit",
    "category": "孝亲",
    "title": "晨起问安",
    "points": 2,
    "date": "2025-10-06",
    "notes": "早起向父母问安",
    "createdAt": "2025-10-06T10:00:00.000Z",
    "updatedAt": "2025-10-06T10:00:00.000Z"
  }
}
```

**失败响应** (400):
```json
{
  "code": 400,
  "message": "分值必须在1-10之间",
  "data": null
}
```

**cURL 示例**:
```bash
curl -X POST https://api.qinghejihua.com.cn/api/v1/merits \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "merit",
    "category": "孝亲",
    "title": "晨起问安",
    "points": 2,
    "notes": "早起向父母问安"
  }'
```

---

### 3. 获取功过记录列表

**接口**: `GET /api/merits`

**请求头**:
```
Authorization: Bearer <token>
```

**查询参数**:
- `page` (可选): 页码，默认1
- `pageSize` (可选): 每页数量，默认20
- `type` (可选): `merit` 或 `demerit`
- `category` (可选): 分类筛选
- `startDate` (可选): 开始日期 (YYYY-MM-DD)
- `endDate` (可选): 结束日期 (YYYY-MM-DD)

**请求示例**:
```
GET /api/merits?page=1&pageSize=10&type=merit&startDate=2025-10-01&endDate=2025-10-31
```

**成功响应** (200):
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "records": [
      {
        "id": 6,
        "userId": 1,
        "type": "demerit",
        "category": "懒惰",
        "title": "拖延",
        "points": 1,
        "date": "2025-10-06",
        "notes": "工作拖延",
        "createdAt": "2025-10-06T11:00:00.000Z",
        "updatedAt": "2025-10-06T11:00:00.000Z"
      },
      {
        "id": 5,
        "userId": 1,
        "type": "merit",
        "category": "孝亲",
        "title": "晨起问安",
        "points": 2,
        "date": "2025-10-06",
        "notes": "早起向父母问安",
        "createdAt": "2025-10-06T10:00:00.000Z",
        "updatedAt": "2025-10-06T10:00:00.000Z"
      }
    ],
    "pagination": {
      "total": 6,
      "page": 1,
      "pageSize": 10,
      "totalPages": 1
    }
  }
}
```

---

### 4. 获取每日功过记录

**接口**: `GET /api/merits/daily`

**请求头**:
```
Authorization: Bearer <token>
```

**查询参数**:
- `date` (可选): 日期，格式 YYYY-MM-DD，默认今天

**请求示例**:
```
GET /api/merits/daily?date=2025-10-06
```

**成功响应** (200):
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "date": "2025-10-06",
    "merits": {
      "count": 3,
      "totalPoints": 8,
      "records": [
        {
          "id": 5,
          "type": "merit",
          "category": "孝亲",
          "title": "晨起问安",
          "points": 3,
          "notes": "早起向父母问安",
          "createdAt": "2025-10-06T10:00:00.000Z"
        }
      ]
    },
    "demerits": {
      "count": 3,
      "totalPoints": 3,
      "records": [
        {
          "id": 6,
          "type": "demerit",
          "category": "懒惰",
          "title": "拖延",
          "points": 1,
          "notes": "工作拖延",
          "createdAt": "2025-10-06T11:00:00.000Z"
        }
      ]
    },
    "netScore": 5,
    "summary": "今日记录良好，继续保持！"
  }
}
```

---

### 5. 获取月度汇总

**接口**: `GET /api/merits/monthly`

**请求头**:
```
Authorization: Bearer <token>
```

**查询参数**:
- `year` (可选): 年份，默认今年
- `month` (可选): 月份 (1-12)，默认本月

**请求示例**:
```
GET /api/merits/monthly?year=2025&month=10
```

**成功响应** (200):
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "year": 2025,
    "month": 10,
    "merits": {
      "count": 3,
      "totalPoints": 8
    },
    "demerits": {
      "count": 3,
      "totalPoints": 3
    },
    "netScore": 5,
    "recordDays": 1,
    "dailyRecords": [
      {
        "date": "2025-10-06",
        "meritPoints": 8,
        "demeritPoints": 3,
        "netScore": 5
      }
    ]
  }
}
```

---

### 6. 获取统计数据

**接口**: `GET /api/merits/statistics`

**请求头**:
```
Authorization: Bearer <token>
```

**查询参数**:
- `days` (可选): 统计天数，默认30

**请求示例**:
```
GET /api/merits/statistics?days=30
```

**成功响应** (200):
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "period": {
      "days": 30,
      "startDate": "2025-09-06",
      "endDate": "2025-10-06"
    },
    "totals": {
      "meritCount": 3,
      "meritPoints": 8,
      "demeritCount": 3,
      "demeritPoints": 3,
      "netScore": 5
    },
    "averages": {
      "dailyNetScore": 5.0,
      "dailyMeritPoints": 8.0,
      "dailyDemeritPoints": 3.0
    },
    "streaks": {
      "current": 1,
      "longest": 1
    },
    "categoryBreakdown": {
      "merits": [
        {
          "category": "孝亲",
          "count": 3,
          "totalPoints": 8,
          "percentage": 100.0
        }
      ],
      "demerits": [
        {
          "category": "懒惰",
          "count": 3,
          "totalPoints": 3,
          "percentage": 100.0
        }
      ]
    },
    "dailyTrend": [
      {
        "date": "2025-10-06",
        "meritPoints": 8,
        "demeritPoints": 3,
        "netScore": 5
      }
    ]
  }
}
```

---

### 7. 更新功过记录

**接口**: `PUT /api/merits/:id`

**请求头**:
```
Authorization: Bearer <token>
Content-Type: application/json
```

**URL参数**:
- `id`: 记录ID

**请求体** (所有字段可选):
```json
{
  "category": "孝亲",
  "title": "晨起问安",
  "points": 3,
  "date": "2025-10-06",
  "notes": "早起向父母问安，并询问身体状况"
}
```

**成功响应** (200):
```json
{
  "code": 200,
  "message": "更新成功",
  "data": {
    "id": 5,
    "userId": 1,
    "type": "merit",
    "category": "孝亲",
    "title": "晨起问安",
    "points": 3,
    "date": "2025-10-06",
    "notes": "早起向父母问安，并询问身体状况",
    "createdAt": "2025-10-06T10:00:00.000Z",
    "updatedAt": "2025-10-06T12:00:00.000Z"
  }
}
```

---

### 8. 删除功过记录

**接口**: `DELETE /api/merits/:id`

**请求头**:
```
Authorization: Bearer <token>
```

**URL参数**:
- `id`: 记录ID

**成功响应** (200):
```json
{
  "code": 200,
  "message": "删除成功",
  "data": null
}
```

---

### 9. 获取分类列表

**接口**: `GET /api/merits/categories`

**请求头**:
```
Authorization: Bearer <token>
```

**成功响应** (200):
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "merits": [
      {
        "name": "助人",
        "description": "帮助他人，行善积德",
        "defaultPoints": 2,
        "count": 10,
        "icon": "🤝"
      },
      {
        "name": "勤学",
        "description": "勤奋学习，不懈努力",
        "defaultPoints": 1,
        "count": 10,
        "icon": "📚"
      }
    ],
    "demerits": [
      {
        "name": "不敬",
        "description": "对长辈不敬",
        "defaultPoints": 2,
        "count": 10,
        "icon": "😤"
      },
      {
        "name": "伤生",
        "description": "伤害生命",
        "defaultPoints": 5,
        "count": 10,
        "icon": "🔪"
      }
    ]
  }
}
```

---

## 错误码说明

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| 200 | 请求成功 | - |
| 201 | 创建成功 | - |
| 400 | 请求参数错误 | 检查请求参数格式和内容 |
| 401 | 未授权/Token无效 | 重新登录获取新Token |
| 403 | 禁止访问 | 检查权限 |
| 404 | 资源不存在 | 检查请求的资源ID |
| 500 | 服务器错误 | 联系技术支持 |

---

## Swift 代码示例

### 1. 网络请求基础类

```swift
import Foundation

class APIClient {
    static let shared = APIClient()
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1"
    private var token: String?
    
    func setToken(_ token: String) {
        self.token = token
        UserDefaults.standard.set(token, forKey: "authToken")
    }
    
    func getToken() -> String? {
        if let token = self.token {
            return token
        }
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    func clearToken() {
        self.token = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        completion: @escaping (Result<APIResponse<T>, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证Token
        if let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 添加请求体
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let response = try decoder.decode(APIResponse<T>.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// 通用响应结构
struct APIResponse<T: Decodable>: Decodable {
    let code: Int
    let message: String
    let data: T?
}
```

### 2. 数据模型

```swift
// 用户模型
struct User: Codable {
    let id: Int
    let phone: String
    let username: String?
    let avatar: String?
    let createdAt: Date
}

// 登录响应
struct LoginResponse: Codable {
    let token: String
    let user: User
}

// 功过记录
struct MeritRecord: Codable, Identifiable {
    let id: Int
    let userId: Int
    let type: String  // "merit" 或 "demerit"
    let category: String
    let title: String
    let points: Int
    let date: String
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    var isMerit: Bool {
        return type == "merit"
    }
}

// 标准条目
struct StandardItem: Codable, Identifiable {
    let id: Int
    let type: String
    let category: String
    let title: String
    let description: String?
    let points: Int
    let icon: String?
}

// 分类
struct Category: Codable {
    let name: String
    let description: String
    let defaultPoints: Int
    let count: Int
    let icon: String?
}

// 统计数据
struct Statistics: Codable {
    let period: Period
    let totals: Totals
    let averages: Averages
    let streaks: Streaks
    let categoryBreakdown: CategoryBreakdown
    let dailyTrend: [DailyTrend]
    
    struct Period: Codable {
        let days: Int
        let startDate: String
        let endDate: String
    }
    
    struct Totals: Codable {
        let meritCount: Int
        let meritPoints: Int
        let demeritCount: Int
        let demeritPoints: Int
        let netScore: Int
    }
    
    struct Averages: Codable {
        let dailyNetScore: Double
        let dailyMeritPoints: Double
        let dailyDemeritPoints: Double
    }
    
    struct Streaks: Codable {
        let current: Int
        let longest: Int
    }
    
    struct CategoryBreakdown: Codable {
        let merits: [CategoryStat]
        let demerits: [CategoryStat]
    }
    
    struct CategoryStat: Codable {
        let category: String
        let count: Int
        let totalPoints: Int
        let percentage: Double
    }
    
    struct DailyTrend: Codable {
        let date: String
        let meritPoints: Int
        let demeritPoints: Int
        let netScore: Int
    }
}
```

### 3. API 服务类

```swift
class MeritService {
    static let shared = MeritService()
    private let client = APIClient.shared
    
    // 登录
    func login(phone: String, password: String, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        let body: [String: Any] = [
            "phone": phone,
            "password": password
        ]
        
        client.request(endpoint: "/auth/login", method: "POST", body: body) { (result: Result<APIResponse<LoginResponse>, Error>) in
            switch result {
            case .success(let response):
                if response.code == 200, let data = response.data {
                    // 保存Token
                    self.client.setToken(data.token)
                    completion(.success(data))
                } else {
                    completion(.failure(NSError(domain: "", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // 获取标准条目列表
    func getStandardItems(type: String? = nil, category: String? = nil, completion: @escaping (Result<StandardItemsResponse, Error>) -> Void) {
        var endpoint = "/merits/standard-items?"
        if let type = type {
            endpoint += "type=\(type)&"
        }
        if let category = category {
            endpoint += "category=\(category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&"
        }
        
        client.request(endpoint: endpoint, method: "GET") { (result: Result<APIResponse<StandardItemsResponse>, Error>) in
            switch result {
            case .success(let response):
                if response.code == 200, let data = response.data {
                    completion(.success(data))
                } else {
                    completion(.failure(NSError(domain: "", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // 创建功过记录
    func createRecord(type: String, category: String, title: String, points: Int, notes: String? = nil, completion: @escaping (Result<MeritRecord, Error>) -> Void) {
        var body: [String: Any] = [
            "type": type,
            "category": category,
            "title": title,
            "points": points
        ]
        if let notes = notes {
            body["notes"] = notes
        }
        
        client.request(endpoint: "/merits", method: "POST", body: body) { (result: Result<APIResponse<MeritRecord>, Error>) in
            switch result {
            case .success(let response):
                if response.code == 201, let data = response.data {
                    completion(.success(data))
                } else {
                    completion(.failure(NSError(domain: "", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // 获取记录列表
    func getRecords(page: Int = 1, pageSize: Int = 20, type: String? = nil, completion: @escaping (Result<RecordsResponse, Error>) -> Void) {
        var endpoint = "/merits?page=\(page)&pageSize=\(pageSize)"
        if let type = type {
            endpoint += "&type=\(type)"
        }
        
        client.request(endpoint: endpoint, method: "GET") { (result: Result<APIResponse<RecordsResponse>, Error>) in
            switch result {
            case .success(let response):
                if response.code == 200, let data = response.data {
                    completion(.success(data))
                } else {
                    completion(.failure(NSError(domain: "", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // 获取统计数据
    func getStatistics(days: Int = 30, completion: @escaping (Result<Statistics, Error>) -> Void) {
        let endpoint = "/merits/statistics?days=\(days)"
        
        client.request(endpoint: endpoint, method: "GET") { (result: Result<APIResponse<Statistics>, Error>) in
            switch result {
            case .success(let response):
                if response.code == 200, let data = response.data {
                    completion(.success(data))
                } else {
                    completion(.failure(NSError(domain: "", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // 删除记录
    func deleteRecord(id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let endpoint = "/merits/\(id)"
        
        client.request(endpoint: endpoint, method: "DELETE") { (result: Result<APIResponse<EmptyResponse>, Error>) in
            switch result {
            case .success(let response):
                if response.code == 200 {
                    completion(.success(()))
                } else {
                    completion(.failure(NSError(domain: "", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// 辅助响应结构
struct StandardItemsResponse: Codable {
    let merits: [StandardItem]
    let demerits: [StandardItem]
    let categories: Categories
    
    struct Categories: Codable {
        let merit: [String]
        let demerit: [String]
    }
}

struct RecordsResponse: Codable {
    let records: [MeritRecord]
    let pagination: Pagination
    
    struct Pagination: Codable {
        let total: Int
        let page: Int
        let pageSize: Int
        let totalPages: Int
    }
}

struct EmptyResponse: Codable {}
```

### 4. SwiftUI 使用示例

```swift
import SwiftUI

// 登录视图
struct LoginView: View {
    @State private var phone = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isLoggedIn = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("青禾计划")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                TextField("手机号", text: $phone)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
                
                SecureField("密码", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: login) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("登录")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading)
            }
            .padding()
            .navigationTitle("登录")
        }
        .fullScreenCover(isPresented: $isLoggedIn) {
            MainTabView()
        }
    }
    
    func login() {
        isLoading = true
        errorMessage = nil
        
        MeritService.shared.login(phone: phone, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let loginResponse):
                    print("登录成功: \(loginResponse.user.username ?? "用户")")
                    isLoggedIn = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// 主标签视图
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
            
            RecordsView()
                .tabItem {
                    Label("记录", systemImage: "list.bullet")
                }
            
            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
        }
    }
}

// 记录列表视图
struct RecordsView: View {
    @State private var records: [MeritRecord] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(records) { record in
                    RecordRow(record: record)
                }
            }
            .navigationTitle("功过记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 添加记录
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadRecords()
            }
            .refreshable {
                loadRecords()
            }
        }
    }
    
    func loadRecords() {
        isLoading = true
        MeritService.shared.getRecords { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    records = response.records
                case .failure(let error):
                    print("获取记录失败: \(error.localizedDescription)")
                }
            }
        }
    }
}

// 记录行视图
struct RecordRow: View {
    let record: MeritRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.headline)
                Text(record.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(record.isMerit ? "+" : "-")\(record.points)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(record.isMerit ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}
```

---

## 测试账号

**手机号**: `19820722496`  
**密码**: `123456`

---

## 联系方式

如有问题，请联系技术支持。

**文档更新日期**: 2025-10-06


