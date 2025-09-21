# 青禾计划 - 登录功能API文档
# 青禾计划 - 登录功能API文档

## 概述

青禾计划的认证系统提供了多种登录方式和用户管理功能，包括短信验证码登录、测试登录、用户信息管理等。

## 基础信息

- **基础URL**: `https://api.qinghejihua.com.cn/api/v1`
- **认证方式**: Bearer Token (JWT)
- **响应格式**: JSON

## API接口列表

### 1. 发送短信验证码

发送短信验证码到指定手机号。

**接口地址**: `POST /auth/send-sms-code`

**请求参数**:
```json
{
  "phone": "19820722496"
}
```

**参数说明**:
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| phone | string | 是 | 手机号码，格式：1[3-9]xxxxxxxxx |

**成功响应**:
```json
{
  "status": "success",
  "message": "验证码发送成功",
  "data": {
    "phone": "19820722496",
    "requestId": "sms_request_id_123",
    "code": "123456"  // 仅开发环境返回
  }
}
```

**错误响应**:
```json
{
  "status": "error",
  "message": "发送过于频繁，请1分钟后再试"
}
```

**限制说明**:
- 同一手机号1分钟内只能发送一次
- 验证码有效期10分钟
- 受到严格的频率限制

---

### 2. 短信验证码登录/注册

使用手机号和短信验证码进行登录或注册。

**接口地址**: `POST /auth/login-sms`

**请求参数**:
```json
{
  "phone": "19820722496",
  "code": "123456"
}
```

**参数说明**:
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| phone | string | 是 | 手机号码 |
| code | string | 是 | 6位数字验证码 |

**成功响应**:
```json
{
  "status": "success",
  "message": "登录成功",
  "data": {
    "user": {
      "id": 1,
      "phone": "19820722496",
      "nickname": "用户2496",
      "avatar": null,
      "status": "active"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": "7d"
  }
}
```

**错误响应**:
```json
{
  "status": "error",
  "message": "验证码不正确"
}
```

**功能说明**:
- 如果手机号不存在，自动注册新用户
- 如果手机号已存在，直接登录
- Token有效期7天

---

### 3. 测试登录（开发环境）

仅用于开发测试的简化登录接口。

**接口地址**: `POST /auth/login`

**请求参数**:
```json
{
  "phone": "19820722496",
  "password": "test123456"
}
```

**参数说明**:
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| phone | string | 是 | 测试手机号 |
| password | string | 是 | 测试密码 |

**成功响应**:
```json
{
  "status": "success",
  "message": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "phone": "19820722496",
      "nickname": "测试用户",
      "avatar": null
    }
  }
}
```

**注意事项**:
- 仅限特定测试账号使用
- 主要用于开发和测试环境

---

### 4. 获取当前用户信息

获取当前登录用户的详细信息。

**接口地址**: `GET /auth/me`

**请求头**:
```
Authorization: Bearer {token}
```

**成功响应**:
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": 1,
      "phone": "19820722496",
      "nickname": "测试用户",
      "avatar": "https://example.com/avatar.jpg",
      "status": "active",
      "lastLoginTime": "2024-01-15T10:30:00.000Z",
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  }
}
```

**错误响应**:
```json
{
  "status": "error",
  "message": "用户不存在"
}
```

---

### 5. 更新用户资料

更新当前用户的个人资料信息。

**接口地址**: `PUT /auth/profile`

**请求头**:
```
Authorization: Bearer {token}
```

**请求参数**:
```json
{
  "nickname": "新昵称",
  "avatar": "https://example.com/new-avatar.jpg"
}
```

**参数说明**:
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| nickname | string | 否 | 用户昵称，1-20个字符 |
| avatar | string | 否 | 头像URL地址 |

**成功响应**:
```json
{
  "status": "success",
  "message": "用户信息更新成功",
  "data": {
    "user": {
      "id": 1,
      "phone": "19820722496",
      "nickname": "新昵称",
      "avatar": "https://example.com/new-avatar.jpg",
      "status": "active"
    }
  }
}
```

---

### 6. 刷新Token

刷新当前用户的访问令牌。

**接口地址**: `POST /auth/refresh-token`

**请求头**:
```
Authorization: Bearer {token}
```

**成功响应**:
```json
{
  "status": "success",
  "message": "令牌刷新成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": "7d"
  }
}
```

---

### 7. 用户登出

用户登出，清除服务器端的token。

**接口地址**: `POST /auth/logout`

**请求头**:
```
Authorization: Bearer {token}
```

**成功响应**:
```json
{
  "status": "success",
  "message": "登出成功"
}
```

## 错误码说明

| HTTP状态码 | 错误类型 | 说明 |
|------------|----------|------|
| 400 | Bad Request | 请求参数错误或验证失败 |
| 401 | Unauthorized | 未授权或token无效 |
| 404 | Not Found | 用户不存在 |
| 429 | Too Many Requests | 请求过于频繁 |
| 500 | Internal Server Error | 服务器内部错误 |

## 认证机制

### JWT Token

- **算法**: HS256
- **有效期**: 7天
- **包含信息**: userId, phone
- **使用方式**: 在请求头中添加 `Authorization: Bearer {token}`

### Token验证

所有需要认证的接口都需要在请求头中携带有效的JWT token：

```javascript
// 请求示例
fetch('/api/v1/auth/me', {
  headers: {
    'Authorization': 'Bearer ' + token,
    'Content-Type': 'application/json'
  }
})
```

## 安全特性

1. **频率限制**: 短信发送和登录接口都有严格的频率限制
2. **验证码过期**: 短信验证码10分钟后自动过期
3. **一次性使用**: 验证码使用后立即失效
4. **Token过期**: JWT token 7天后自动过期
5. **安全登出**: 登出时清除服务器端token

## 使用示例

### 完整登录流程

```javascript
// 1. 发送验证码
const sendSms = async (phone) => {
  const response = await fetch('/api/v1/auth/send-sms-code', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone })
  });
  return response.json();
};

// 2. 验证码登录
const login = async (phone, code) => {
  const response = await fetch('/api/v1/auth/login-sms', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone, code })
  });
  const result = await response.json();
  
  if (result.status === 'success') {
    // 保存token
    localStorage.setItem('token', result.data.token);
  }
  
  return result;
};

// 3. 获取用户信息
const getUserInfo = async () => {
  const token = localStorage.getItem('token');
  const response = await fetch('/api/v1/auth/me', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  return response.json();
};
```

### 测试登录流程

```javascript
// 开发环境快速登录
const testLogin = async () => {
  const response = await fetch('/api/v1/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      phone: '19820722496',
      password: 'test123456'
    })
  });
  
  const result = await response.json();
  if (result.status === 'success') {
    localStorage.setItem('token', result.data.token);
  }
  
  return result;
};
```

## 注意事项

1. **生产环境**: 建议使用短信验证码登录方式3. **Token管理**: 客户端需要妥善保存和管理JWT token
4. **错误处理**: 需要根据不同的错误码进行相应的错误处理
5. **安全性**: 不要在客户端代码中硬编码敏感信息

## 更新日志

- **v1.0.0**: 初始版本，支持短信登录和基础用户管理
- **v1.1.0**: 添加测试登录接口，优化错误处理
- **v1.2.0**: 增加token刷新功能，完善安全机制