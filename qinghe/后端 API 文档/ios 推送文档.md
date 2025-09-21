# 青禾计划 iOS APNs推送通知集成文档

## 📋 概述

本文档详细说明了青禾计划iOS应用如何集成Apple Push Notification Service (APNs)推送通知功能。

### 🎯 目标
- 用户能够接收实时消息推送
- 用户能够接收好友请求推送  
- 用户能够接收系统通知推送
- 支持前台和后台推送处理
- 支持推送点击跳转

### 📊 当前后端配置状态
- ✅ APNs服务已配置完成
- ✅ Bundle ID: `com.qinghe.qinghe`
- ✅ Team ID: `7CHR3URQ44`
- ✅ Key ID: `YKAAABX5H4`
- ✅ 生产环境已启用

---

## 🔧 1. 项目配置

### 1.1 Bundle ID配置
确保iOS项目中的Bundle ID与后端一致：

```
Bundle Identifier: com.qinghe.qinghe
```

**配置位置：**
- Xcode → Project Settings → Targets → General → Identity → Bundle Identifier

### 1.2 推送通知能力启用
在Xcode中启用推送通知功能：

1. 选择项目Target
2. 进入 `Signing & Capabilities`
3. 点击 `+ Capability`
4. 添加 `Push Notifications`

### 1.3 必要的导入
在需要使用推送功能的文件中导入：

```swift
import UserNotifications
import UIKit
```

---

## 📱 2. 权限请求与设备Token获取

### 2.1 请求推送权限

在 `AppDelegate.swift` 或 `SceneDelegate.swift` 中添加：

```swift
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 设置推送通知代理
        UNUserNotificationCenter.current().delegate = self
        
        // 请求推送权限
        requestNotificationPermission()
        
        return true
    }
    
    // 请求推送通知权限
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ 推送通知权限已授权")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ 推送通知权限被拒绝")
                if let error = error {
                    print("权限请求错误: \(error)")
                }
            }
        }
    }
}
```

### 2.2 获取设备Token

```swift
extension AppDelegate {
    
    // 成功获取设备Token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 设备Token: \(tokenString)")
        
        // 保存Token到本地
        UserDefaults.standard.set(tokenString, forKey: "deviceToken")
        
        // 上传Token到后端服务器
        uploadDeviceToken(tokenString)
    }
    
    // 获取Token失败
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ 获取设备Token失败: \(error)")
    }
    
    // 上传设备Token到后端
    func uploadDeviceToken(_ token: String) {
        guard let userId = getCurrentUserId() else {
            print("⚠️ 用户未登录，暂不上传设备Token")
            return
        }

        let url = URL(string: "https://api.qinghejihua.com.cn/api/device-token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证头
        if let authToken = getAuthToken() {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        let body = [
            "deviceToken": token,
            "userId": userId,
            "platform": "ios"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ 上传设备Token失败: \(error)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("✅ 设备Token上传成功")
                    } else {
                        print("⚠️ 设备Token上传失败，状态码: \(httpResponse.statusCode)")
                    }
                }
            }.resume()
            
        } catch {
            print("❌ 序列化请求数据失败: \(error)")
        }
    }
    
    // 获取当前用户ID（需要根据实际情况实现）
    func getCurrentUserId() -> String? {
        // 从本地存储或用户管理器获取当前用户ID
        return UserDefaults.standard.string(forKey: "currentUserId")
    }
    
    // 获取认证Token（需要根据实际情况实现）
    func getAuthToken() -> String? {
        // 从本地存储获取认证Token
        return UserDefaults.standard.string(forKey: "authToken")
    }
}
```

---

## 🔔 3. 推送通知处理

### 3.1 实现UNUserNotificationCenterDelegate

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // 应用在前台时收到推送通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              willPresent notification: UNNotification, 
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print("📨 前台收到推送通知: \(userInfo)")
        
        // 解析推送内容
        handlePushNotificationData(userInfo)
        
        // 在前台也显示通知（可选）
        completionHandler([.alert, .badge, .sound])
    }
    
    // 用户点击推送通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              didReceive response: UNNotificationResponse, 
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        print("👆 用户点击推送通知: \(userInfo)")
        
        // 处理推送通知跳转
        handlePushNotificationTap(userInfo)
        
        completionHandler()
    }
}
```

### 3.2 推送数据处理

```swift
extension AppDelegate {
    
    // 处理推送通知数据
    func handlePushNotificationData(_ userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else {
            print("⚠️ 推送通知缺少type字段")
            return
        }
        
        switch type {
        case "new_message":
            handleNewMessageNotification(userInfo)
        case "friend_request":
            handleFriendRequestNotification(userInfo)
        case "system":
            handleSystemNotification(userInfo)
        default:
            print("⚠️ 未知的推送通知类型: \(type)")
        }
    }
    
    // 处理新消息推送
    func handleNewMessageNotification(_ userInfo: [AnyHashable: Any]) {
        guard let conversationId = userInfo["conversationId"] as? String,
              let senderName = userInfo["senderName"] as? String,
              let content = userInfo["content"] as? String else {
            print("⚠️ 新消息推送数据不完整")
            return
        }
        
        print("💬 收到新消息: \(senderName) - \(content)")
        
        // 更新应用角标
        updateAppBadge()
        
        // 如果应用在前台，可以显示内部通知或直接更新UI
        NotificationCenter.default.post(name: .newMessageReceived, object: nil, userInfo: [
            "conversationId": conversationId,
            "senderName": senderName,
            "content": content
        ])
    }
    
    // 处理好友请求推送
    func handleFriendRequestNotification(_ userInfo: [AnyHashable: Any]) {
        guard let senderName = userInfo["senderName"] as? String else {
            print("⚠️ 好友请求推送数据不完整")
            return
        }
        
        print("👥 收到好友请求: \(senderName)")
        
        // 更新应用角标
        updateAppBadge()
        
        // 发送本地通知
        NotificationCenter.default.post(name: .friendRequestReceived, object: nil, userInfo: [
            "senderName": senderName
        ])
    }
    
    // 处理系统通知推送
    func handleSystemNotification(_ userInfo: [AnyHashable: Any]) {
        guard let title = userInfo["title"] as? String,
              let message = userInfo["message"] as? String else {
            print("⚠️ 系统通知推送数据不完整")
            return
        }
        
        print("🔔 收到系统通知: \(title) - \(message)")
        
        // 发送本地通知
        NotificationCenter.default.post(name: .systemNotificationReceived, object: nil, userInfo: [
            "title": title,
            "message": message
        ])
    }
}
```

---

## 🧭 4. 推送跳转处理

### 4.1 跳转逻辑实现

```swift
extension AppDelegate {
    
    // 处理推送通知点击跳转
    func handlePushNotificationTap(_ userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else {
            return
        }
        
        // 延迟执行跳转，确保应用完全启动
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            switch type {
            case "new_message":
                self.navigateToChat(userInfo)
            case "friend_request":
                self.navigateToFriendRequests()
            case "system":
                self.navigateToSystemNotifications()
            default:
                break
            }
        }
    }
    
    // 跳转到聊天页面
    func navigateToChat(_ userInfo: [AnyHashable: Any]) {
        guard let conversationId = userInfo["conversationId"] as? String else {
            print("⚠️ 缺少conversationId，无法跳转到聊天页面")
            return
        }
        
        print("🧭 跳转到聊天页面: \(conversationId)")
        
        // 获取根视图控制器
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ 无法获取根视图控制器")
            return
        }
        
        // 根据你的应用架构进行跳转
        // 示例：如果使用TabBarController + NavigationController
        if let tabBarController = rootViewController as? UITabBarController {
            // 切换到聊天Tab
            tabBarController.selectedIndex = 1 // 假设聊天在第2个Tab
            
            if let navController = tabBarController.selectedViewController as? UINavigationController {
                // 跳转到具体聊天页面
                // let chatVC = ChatViewController(conversationId: conversationId)
                // navController.pushViewController(chatVC, animated: true)
            }
        }
    }
    
    // 跳转到好友请求页面
    func navigateToFriendRequests() {
        print("🧭 跳转到好友请求页面")
        
        // 实现跳转逻辑
        // 类似上面的聊天跳转逻辑
    }
    
    // 跳转到系统通知页面
    func navigateToSystemNotifications() {
        print("🧭 跳转到系统通知页面")
        
        // 实现跳转逻辑
        // 类似上面的聊天跳转逻辑
    }
}
```

### 4.2 通知名称定义

在合适的位置定义通知名称：

```swift
extension Notification.Name {
    static let newMessageReceived = Notification.Name("newMessageReceived")
    static let friendRequestReceived = Notification.Name("friendRequestReceived")
    static let systemNotificationReceived = Notification.Name("systemNotificationReceived")
}
```

---

## 🔢 5. 应用角标管理

### 5.1 角标更新

```swift
extension AppDelegate {
    
    // 更新应用角标
    func updateAppBadge() {
        // 从服务器获取未读消息数量
        fetchUnreadCount { [weak self] count in
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        }
    }
    
    // 清除应用角标
    func clearAppBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    // 从服务器获取未读消息数量
    func fetchUnreadCount(completion: @escaping (Int) -> Void) {
        // 实现获取未读消息数量的API调用
        // 这里是示例代码
        let url = URL(string: "https://api.qinghejihua.com.cn/api/unread-count")!
        var request = URLRequest(url: url)
        
        if let authToken = getAuthToken() {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let count = json["unreadCount"] as? Int {
                completion(count)
            } else {
                completion(0)
            }
        }.resume()
    }
}
```

---

## 🧪 6. 测试与调试

### 6.1 测试检查清单

- [ ] **真机测试** - 推送通知只能在真实iOS设备上测试
- [ ] **权限授权** - 测试用户同意和拒绝推送权限的情况
- [ ] **设备Token获取** - 确保能正确获取并上传设备Token
- [ ] **前台推送** - 测试应用在前台时收到推送的处理
- [ ] **后台推送** - 测试应用在后台时收到推送的处理
- [ ] **推送跳转** - 测试点击推送通知的页面跳转
- [ ] **角标更新** - 测试应用角标的显示和清除

### 6.2 调试技巧

```swift
// 添加详细的日志输出
func debugPushNotification(_ userInfo: [AnyHashable: Any]) {
    print("🐛 推送通知调试信息:")
    print("完整数据: \(userInfo)")
    
    for (key, value) in userInfo {
        print("  \(key): \(value)")
    }
    
    // 检查必要字段
    if userInfo["type"] == nil {
        print("⚠️ 缺少type字段")
    }
    
    if userInfo["aps"] == nil {
        print("⚠️ 缺少aps字段")
    }
}
```

### 6.3 常见问题排查

1. **设备Token获取失败**
   - 检查Bundle ID是否正确
   - 检查推送证书配置
   - 确保在真机上测试

2. **推送通知不显示**
   - 检查用户是否授权推送权限
   - 检查应用是否在前台（前台需要特殊处理）
   - 检查推送内容格式是否正确

3. **跳转不生效**
   - 检查跳转逻辑是否正确
   - 确保在主线程执行UI操作
   - 添加延迟确保应用完全启动

---

## 📚 7. API接口文档

### 7.0 基础配置

**API基础URL：** `https://api.qinghejihua.com.cn`

**完整接口地址示例：**
```
https://api.qinghejihua.com.cn/api/device-token
https://api.qinghejihua.com.cn/api/push/new-message
https://api.qinghejihua.com.cn/api/unread-count
```

**请求头通用配置：**
```
Content-Type: application/json
Authorization: Bearer {authToken}
```

### 7.1 上传设备Token

**接口地址：** `POST /api/device-token`
**完整URL：** `https://api.qinghejihua.com.cn/api/device-token`

**请求头：**
```
Content-Type: application/json
Authorization: Bearer {authToken}
```

**请求体：**
```json
{
  "deviceToken": "设备Token字符串",
  "userId": "用户ID",
  "platform": "ios"
}
```

**响应：**
```json
{
  "success": true,
  "message": "设备Token保存成功"
}
```

### 7.2 获取未读消息数量

**接口地址：** `GET /api/unread-count`
**完整URL：** `https://api.qinghejihua.com.cn/api/unread-count`

**请求头：**
```
Authorization: Bearer {authToken}
```

**响应：**
```json
{
  "success": true,
  "unreadCount": 5
}
```

### 7.3 后端推送服务API

#### 7.3.1 发送新消息推送

**接口地址：** `POST /api/push/new-message`
**完整URL：** `https://api.qinghejihua.com.cn/api/push/new-message`

**请求头：**
```
Content-Type: application/json
Authorization: Bearer {authToken}
```

**请求体：**
```json
{
  "receiverId": "接收者用户ID",
  "senderName": "发送者昵称",
  "content": "消息内容",
  "conversationId": "会话ID"
}
```

**响应：**
```json
{
  "success": true,
  "message": "推送发送成功",
  "pushResult": {
    "sent": 1,
    "failed": 0
  }
}
```

#### 7.3.2 发送好友请求推送

**接口地址：** `POST /api/push/friend-request`
**完整URL：** `https://api.qinghejihua.com.cn/api/push/friend-request`

**请求头：**
```
Content-Type: application/json
Authorization: Bearer {authToken}
```

**请求体：**
```json
{
  "receiverId": "接收者用户ID",
  "senderName": "发送者昵称",
  "message": "好友请求消息"
}
```

**响应：**
```json
{
  "success": true,
  "message": "好友请求推送发送成功"
}
```

#### 7.3.3 发送系统通知推送

**接口地址：** `POST /api/push/system-notification`
**完整URL：** `https://api.qinghejihua.com.cn/api/push/system-notification`

**请求头：**
```
Content-Type: application/json
Authorization: Bearer {authToken}
```

**请求体：**
```json
{
  "userId": "用户ID",
  "title": "通知标题",
  "message": "通知内容"
}
```

**响应：**
```json
{
  "success": true,
  "message": "系统通知推送发送成功"
}
```

#### 7.3.4 批量推送

**接口地址：** `POST /api/push/batch`
**完整URL：** `https://api.qinghejihua.com.cn/api/push/batch`

**请求头：**
```
Content-Type: application/json
Authorization: Bearer {authToken}
```

**请求体：**
```json
{
  "userIds": ["用户ID1", "用户ID2", "用户ID3"],
  "notification": {
    "title": "推送标题",
    "body": "推送内容",
    "badge": 1,
    "sound": "default",
    "data": {
      "type": "batch_notification",
      "timestamp": "2025-08-23T14:19:06.551Z"
    }
  }
}
```

**响应：**
```json
{
  "success": true,
  "message": "批量推送发送完成",
  "results": {
    "successCount": 2,
    "failedCount": 1,
    "details": [
      {
        "userId": "用户ID1",
        "success": true
      },
      {
        "userId": "用户ID2",
        "success": true
      },
      {
        "userId": "用户ID3",
        "success": false,
        "error": "设备Token无效"
      }
    ]
  }
}
```

### 7.4 推送通知数据格式

#### 7.4.1 新消息推送格式

```json
{
  "aps": {
    "alert": {
      "title": "发送者昵称",
      "body": "消息内容"
    },
    "badge": 1,
    "sound": "default"
  },
  "type": "new_message",
  "conversationId": "会话ID",
  "senderName": "发送者昵称",
  "content": "消息内容",
  "timestamp": "2025-08-23T14:19:06.551Z"
}
```

#### 7.4.2 好友请求推送格式

```json
{
  "aps": {
    "alert": {
      "title": "好友请求",
      "body": "发送者昵称 想要添加你为好友"
    },
    "badge": 1,
    "sound": "default"
  },
  "type": "friend_request",
  "senderName": "发送者昵称",
  "message": "想要添加你为好友",
  "timestamp": "2025-08-23T14:19:06.551Z"
}
```

#### 7.4.3 系统通知推送格式

```json
{
  "aps": {
    "alert": {
      "title": "系统通知",
      "body": "你的账户信息已更新"
    },
    "badge": 1,
    "sound": "default"
  },
  "type": "system",
  "title": "系统通知",
  "message": "你的账户信息已更新",
  "timestamp": "2025-08-23T14:19:06.551Z"
}
```

---

## � 8. 后端服务集成

### 8.1 后端APNs服务状态

当前后端APNs推送服务已完全配置并正常运行：

- ✅ **服务状态**: 正常运行
- ✅ **Bundle ID**: `com.qinghe.qinghe`
- ✅ **Team ID**: `7CHR3URQ44`
- ✅ **Key ID**: `YKAAABX5H4`
- ✅ **环境**: 生产环境
- ✅ **连接测试**: 与苹果APNs服务器连接正常

### 8.2 自动推送触发机制

后端已集成以下自动推送触发：

#### 8.2.1 新消息自动推送
```javascript
// 发送消息时自动触发推送
async function sendMessage(senderId, receiverId, content, conversationId) {
  // 1. 保存消息到数据库
  const message = await Message.create({
    senderId,
    receiverId,
    content,
    conversationId
  });

  // 2. 发送WebSocket实时消息
  websocketService.notifyNewMessage(message);

  // 3. 自动发送APNs推送通知
  const receiver = await User.findByPk(receiverId);
  if (receiver && receiver.deviceToken) {
    const sender = await User.findByPk(senderId);
    await apnService.sendNewMessageNotification(receiver.deviceToken, {
      senderName: sender.nickname,
      content: content,
      conversationId: conversationId
    });
  }
}
```

#### 8.2.2 好友请求自动推送
```javascript
// 发送好友请求时自动触发推送
async function sendFriendRequest(senderId, receiverId) {
  // 1. 创建好友请求记录
  const friendRequest = await FriendRequest.create({
    senderId,
    receiverId,
    status: 'pending'
  });

  // 2. 自动发送APNs推送通知
  const receiver = await User.findByPk(receiverId);
  const sender = await User.findByPk(senderId);

  if (receiver && receiver.deviceToken) {
    await apnService.sendFriendRequestNotification(receiver.deviceToken, {
      senderName: sender.nickname,
      message: '想要添加你为好友'
    });
  }
}
```

### 8.3 推送服务方法

后端提供的APNs推送服务方法：

```javascript
// 1. 发送新消息推送
await apnService.sendNewMessageNotification(deviceToken, {
  senderName: '发送者昵称',
  content: '消息内容',
  conversationId: '会话ID'
});

// 2. 发送好友请求推送
await apnService.sendFriendRequestNotification(deviceToken, {
  senderName: '发送者昵称',
  message: '想要添加你为好友'
});

// 3. 发送系统通知推送
await apnService.sendSystemNotification(deviceToken, {
  title: '系统通知',
  message: '通知内容'
});

// 4. 发送自定义推送
await apnService.sendNotification(deviceToken, {
  title: '推送标题',
  body: '推送内容',
  badge: 1,
  sound: 'default',
  data: {
    type: 'custom',
    customData: 'value'
  }
});

// 5. 批量推送
await apnService.sendBatchNotifications(deviceTokens, notification);
```

### 8.4 数据库表结构

确保数据库包含以下字段：

```sql
-- 用户表添加设备Token字段
ALTER TABLE users ADD COLUMN device_token VARCHAR(255);
ALTER TABLE users ADD COLUMN push_enabled BOOLEAN DEFAULT true;
ALTER TABLE users ADD COLUMN last_push_time TIMESTAMP;

-- 推送日志表（可选）
CREATE TABLE push_logs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  device_token VARCHAR(255),
  push_type VARCHAR(50),
  title VARCHAR(255),
  content TEXT,
  success BOOLEAN,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 8.5 环境变量配置

后端已配置的环境变量：

```env
NODE_ENV=production
APN_KEY_PATH=./config/apns/AuthKey_YKAAABX5H4.p8
APN_KEY_ID=YKAAABX5H4
APN_TEAM_ID=7CHR3URQ44
APN_BUNDLE_ID=com.qinghe.qinghe
```

---

## �🚀 9. 部署注意事项

### 9.1 生产环境配置
- 确保使用生产环境的推送证书
- Bundle ID必须与Apple Developer账号中的App ID一致
- 后端APNs配置必须使用生产环境

### 9.2 App Store审核
- 推送权限请求要有明确的用途说明
- 不要在应用启动时立即请求推送权限
- 提供关闭推送通知的设置选项

### 9.3 上线前检查清单

#### 前端检查
- [ ] Bundle ID配置正确 (`com.qinghe.qinghe`)
- [ ] 推送权限请求代码已实现
- [ ] 设备Token获取和上传功能正常
- [ ] 推送通知处理逻辑完整
- [ ] 页面跳转功能测试通过
- [ ] 应用角标管理正常
- [ ] 真机测试推送功能正常

#### 后端检查
- [ ] APNs服务配置正确
- [ ] 环境变量设置完整
- [ ] 数据库表结构更新
- [ ] 设备Token保存API正常
- [ ] 推送服务API正常
- [ ] 自动推送触发机制正常
- [ ] 推送日志记录完整

#### 联调测试
- [ ] 前后端设备Token同步正常
- [ ] 新消息推送端到端测试通过
- [ ] 好友请求推送测试通过
- [ ] 系统通知推送测试通过
- [ ] 推送跳转功能测试通过
- [ ] 批量推送功能测试通过

---

## 📞 10. 技术支持

### 10.1 联系方式
如有问题，请联系开发团队或查看：
- Apple官方推送通知文档
- 青禾计划后端API文档
- 项目技术文档

### 10.2 常见问题FAQ

**Q: 推送通知不显示怎么办？**
A: 检查用户是否授权推送权限，确保在真机上测试，检查Bundle ID配置。

**Q: 设备Token获取失败？**
A: 确保在真机上测试，检查推送证书配置，确保Bundle ID正确。

**Q: 推送跳转不生效？**
A: 检查跳转逻辑，确保在主线程执行，添加适当延迟。

**Q: 后端推送发送失败？**
A: 检查设备Token是否有效，确认APNs服务配置正确。

### 10.3 调试工具

- **Xcode Console**: 查看设备Token和推送日志
- **服务器日志**: 监控推送发送状态
- **APNs测试工具**: 使用第三方工具测试推送

---

**文档版本：** v2.0
**更新时间：** 2025-08-23
**适用版本：** iOS 13.0+
**后端服务版本：** 已集成APNs v1.0
