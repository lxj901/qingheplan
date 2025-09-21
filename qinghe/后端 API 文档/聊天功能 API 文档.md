# 青禾计划聊天系统 API 文档 - iOS 版

## 📋 目录
- [基础信息](#基础信息)
- [认证机制](#认证机制)
- [数据模型](#数据模型)
- [对话管理 API](#对话管理-api)
- [消息管理 API](#消息管理-api)
- [群聊管理 API](#群聊管理-api)
- [文件上传 API](#文件上传-api)
- [WebSocket 实时通信](#websocket-实时通信)
- [错误处理](#错误处理)
- [iOS 实现建议](#ios-实现建议)

## 🌐 基础信息

### 服务器地址
- **生产环境**: `https://api.qinghejihua.com.cn`
### API 版本
- **版本**: v1
- **基础路径**: `/api/v1`

### 请求格式
- **Content-Type**: `application/json`
- **字符编码**: UTF-8

## 🔐 认证机制

### JWT Token 认证
所有API请求都需要在请求头中包含JWT Token：

```http
Authorization: Bearer <your_jwt_token>
```

### Token 获取
通过登录接口获取Token：
```http
POST /api/v1/auth/login
```

## 📊 数据模型

### 对话 (Conversation)
```json
{
  "id": "uuid",
  "type": "private|group",
  "title": "对话标题",
  "description": "群聊描述",
  "avatar": "头像URL",
  "creatorId": 123,
  "lastMessageId": "uuid",
  "lastMessageAt": "2025-08-22T13:30:00.000Z",
  "membersCount": 5,
  "maxMembers": 500,
  "isActive": true,
  "createdAt": "2025-08-22T10:00:00.000Z",
  "updatedAt": "2025-08-22T13:30:00.000Z"
}
```

### 消息 (Message)
```json
{
  "id": "uuid",
  "conversationId": "uuid",
  "senderId": 123,
  "content": "消息内容",
  "type": "text|image|video|audio|file|system",
  "mediaUrl": "媒体文件URL",
  "mediaSize": 1024000,
  "mediaDuration": 30,
  "thumbnailUrl": "缩略图URL",
  "replyToMessageId": "uuid",
  "forwardFromMessageId": "uuid",
  "status": "sent|delivered|read",
  "isRecalled": false,
  "recalledAt": null,
  "isDeleted": false,
  "createdAt": "2025-08-22T13:30:00.000Z",
  "sender": {
    "id": 123,
    "nickname": "用户昵称",
    "avatar": "头像URL"
  }
}
```

### 对话成员 (ConversationMember)
```json
{
  "id": 456,
  "conversationId": "uuid",
  "userId": 123,
  "role": "owner|admin|member",
  "status": "active|left|kicked",
  "unreadCount": 5,
  "lastReadMessageId": "uuid",
  "lastReadAt": "2025-08-22T13:25:00.000Z",
  "isTop": false,
  "isMuted": false,
  "joinedAt": "2025-08-22T10:00:00.000Z"
}
```

## 💬 对话管理 API

### 1. 获取对话列表
```http
GET /api/v1/messages/conversations
```

**查询参数:**
- `tab` (string, optional): 筛选类型 (`all`, `unread`)
- `page` (int, optional): 页码，默认 1
- `limit` (int, optional): 每页数量，默认 20

**响应示例:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "type": "private",
        "title": "张三",
        "avatar": "https://example.com/avatar.jpg",
        "lastMessage": {
          "id": "uuid",
          "content": "你好",
          "type": "text",
          "createdAt": "2025-08-22T13:30:00.000Z",
          "sender": {
            "id": 456,
            "nickname": "张三"
          }
        },
        "lastMessageAt": "2025-08-22T13:30:00.000Z",
        "unreadCount": 3,
        "isTop": false,
        "isMuted": false,
        "membersCount": 2
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 50,
      "totalPages": 3,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

### 2. 创建私聊对话
```http
POST /api/v1/messages/conversations/private
```

**请求体:**
```json
{
  "recipientId": 456,
  "initialMessage": "你好！"
}
```

**响应示例:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "type": "private",
    "creatorId": 123,
    "membersCount": 2,
    "isActive": true,
    "createdAt": "2025-08-22T13:30:00.000Z"
  },
  "message": "对话创建成功"
}
```

### 3. 创建群聊
```http
POST /api/v1/messages/conversations/group
```

**请求体:**
```json
{
  "name": "群聊名称",
  "description": "群聊描述",
  "avatar": "群聊头像URL",
  "memberIds": [456, 789, 101]
}
```

### 4. 获取对话详情
```http
GET /api/v1/messages/conversations/{conversationId}
```

**响应示例:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "type": "group",
    "title": "开发团队",
    "description": "项目开发讨论群",
    "avatar": "https://example.com/group-avatar.jpg",
    "creator": {
      "id": 123,
      "nickname": "管理员",
      "avatar": "https://example.com/admin-avatar.jpg"
    },
    "memberRecords": [
      {
        "role": "owner",
        "user": {
          "id": 123,
          "nickname": "管理员",
          "avatar": "https://example.com/admin-avatar.jpg",
          "isVerified": true
        }
      }
    ],
    "membersCount": 5,
    "maxMembers": 500,
    "createdAt": "2025-08-22T10:00:00.000Z"
  }
}
```

### 5. 删除对话
```http
DELETE /api/v1/messages/conversations/{conversationId}
```

## 📨 消息管理 API

### 1. 发送消息
```http
POST /api/v1/messages/conversations/{conversationId}/messages
```

**请求体 (文本消息):**
```json
{
  "content": "你好，这是一条文本消息",
  "type": "text",
  "replyToMessageId": "uuid"
}
```

**请求体 (图片消息):**
```json
{
  "content": "发送了一张图片",
  "type": "image",
  "mediaUrl": "https://oss.example.com/images/photo.jpg",
  "thumbnailUrl": "https://oss.example.com/images/photo_thumb.jpg"
}
```

**请求体 (语音消息):**
```json
{
  "content": "发送了一段语音",
  "type": "audio",
  "mediaUrl": "https://oss.example.com/audios/voice.m4a",
  "mediaDuration": 15
}
```

**响应示例:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "conversationId": "uuid",
    "senderId": 123,
    "content": "你好，这是一条文本消息",
    "type": "text",
    "status": "sent",
    "createdAt": "2025-08-22T13:30:00.000Z",
    "sender": {
      "id": 123,
      "nickname": "我",
      "avatar": "https://example.com/my-avatar.jpg"
    },
    "replyToMessage": null
  },
  "message": "消息发送成功"
}
```

### 2. 获取消息历史
```http
GET /api/v1/messages/conversations/{conversationId}/messages
```

**查询参数:**
- `before` (string, optional): 获取指定消息ID之前的消息
- `limit` (int, optional): 每页数量，默认 20

**响应示例:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "conversationId": "uuid",
        "senderId": 456,
        "content": "你好",
        "type": "text",
        "status": "read",
        "createdAt": "2025-08-22T13:25:00.000Z",
        "sender": {
          "id": 456,
          "nickname": "张三",
          "avatar": "https://example.com/avatar.jpg"
        }
      }
    ],
    "hasMore": true
  }
}
```

### 3. 标记消息已读
```http
POST /api/v1/messages/conversations/{conversationId}/read
```

**请求体:**
```json
{
  "lastReadMessageId": "uuid"
}
```

### 4. 撤回消息
```http
DELETE /api/v1/messages/{messageId}/recall
```

### 5. 转发消息
```http
POST /api/v1/messages/{messageId}/forward
```

**请求体:**
```json
{
  "conversationIds": ["uuid1", "uuid2", "uuid3"]
}
```

## 👥 群聊管理 API

### 1. 添加群成员
```http
POST /api/v1/messages/groups/{groupId}/members
```

**请求体:**
```json
{
  "memberIds": [456, 789, 101]
}
```

### 2. 移除群成员
```http
DELETE /api/v1/messages/groups/{groupId}/members/{memberId}
```

### 3. 更新群信息
```http
PUT /api/v1/messages/groups/{groupId}
```

**请求体:**
```json
{
  "name": "新的群名称",
  "description": "新的群描述",
  "avatar": "新的群头像URL"
}
```

### 4. 退出群聊
```http
POST /api/v1/messages/groups/{groupId}/leave
```

## 📁 文件上传 API

### 1. 上传图片
```http
POST /api/v1/upload/image
Content-Type: multipart/form-data
```

**表单数据:**
- `image`: 图片文件 (最大10MB)

**响应示例:**
```json
{
  "success": true,
  "data": {
    "url": "https://qinghe-uploads.oss-cn-beijing.aliyuncs.com/images/photo.jpg",
    "thumbnails": {
      "small": "https://oss.example.com/photo?x-oss-process=image/resize,w_150,h_150",
      "medium": "https://oss.example.com/photo?x-oss-process=image/resize,w_300,h_300",
      "large": "https://oss.example.com/photo?x-oss-process=image/resize,w_800,h_600"
    },
    "filename": "images/1755868759715-042wyzac3.png",
    "originalName": "photo.jpg",
    "size": 1024000,
    "mimetype": "image/jpeg",
    "provider": "aliyun",
    "metadata": {
      "width": 1920,
      "height": 1080,
      "format": "jpeg"
    }
  },
  "message": "图片上传成功"
}
```

### 2. 上传语音
```http
POST /api/v1/upload/audio
Content-Type: multipart/form-data
```

**表单数据:**
- `audio`: 音频文件 (最大20MB)

### 3. 上传视频
```http
POST /api/v1/upload/video
Content-Type: multipart/form-data
```

**表单数据:**
- `video`: 视频文件 (最大100MB)

## 🔌 WebSocket 实时通信

### 连接地址
```
wss://api.qinghejihua.com.cn/ws?token=<your_jwt_token>
```

### 消息格式
所有WebSocket消息都使用JSON格式：

```json
{
  "type": "message_type",
  "data": {},
  "timestamp": "2025-08-22T13:30:00.000Z"
}
```

### 客户端发送消息类型

#### 1. 心跳包
```json
{
  "type": "ping",
  "data": {
    "timestamp": 1692705000000
  }
}
```

#### 2. 加入对话房间
```json
{
  "type": "join_conversation",
  "data": {
    "conversationId": "uuid"
  }
}
```

#### 3. 离开对话房间
```json
{
  "type": "leave_conversation",
  "data": {
    "conversationId": "uuid"
  }
}
```

#### 4. 用户状态更新
```json
{
  "type": "user_status",
  "data": {
    "status": "online|offline|away"
  }
}
```

### 服务器推送消息类型

#### 1. 心跳响应
```json
{
  "type": "pong",
  "data": {
    "timestamp": 1692705000000
  }
}
```

#### 2. 新消息通知
```json
{
  "type": "new_message",
  "data": {
    "message": {
      "id": "uuid",
      "conversationId": "uuid",
      "senderId": 456,
      "content": "你好",
      "type": "text",
      "createdAt": "2025-08-22T13:30:00.000Z",
      "sender": {
        "id": 456,
        "nickname": "张三",
        "avatar": "https://example.com/avatar.jpg"
      }
    }
  }
}
```

#### 3. 消息撤回通知
```json
{
  "type": "message_recalled",
  "data": {
    "messageId": "uuid",
    "conversationId": "uuid",
    "recalledBy": 456
  }
}
```

#### 4. 用户状态变化
```json
{
  "type": "user_status_changed",
  "data": {
    "userId": 456,
    "status": "online",
    "lastSeen": "2025-08-22T13:30:00.000Z"
  }
}
```

#### 5. 连接确认
```json
{
  "type": "connection",
  "data": {
    "userId": 123,
    "status": "connected",
    "timestamp": "2025-08-22T13:30:00.000Z"
  }
}
```

## ❌ 错误处理

### 标准错误响应格式
```json
{
  "success": false,
  "message": "错误描述",
  "code": "ERROR_CODE",
  "details": {}
}
```

### 常见错误码
- `400`: 请求参数错误
- `401`: 未授权，Token无效或过期
- `403`: 权限不足
- `404`: 资源不存在
- `429`: 请求频率限制
- `500`: 服务器内部错误

### 具体错误示例

#### 1. Token过期
```json
{
  "success": false,
  "message": "Token已过期，请重新登录",
  "code": "TOKEN_EXPIRED"
}
```

#### 2. 权限不足
```json
{
  "success": false,
  "message": "无权限访问此对话",
  "code": "PERMISSION_DENIED"
}
```

#### 3. 文件上传错误
```json
{
  "success": false,
  "message": "文件大小超过限制: 10.0MB",
  "code": "FILE_TOO_LARGE"
}
```

## 📱 iOS 实现建议

### 1. 网络层架构
```swift
// 使用 Alamofire 进行网络请求
import Alamofire

class ChatAPIManager {
    static let shared = ChatAPIManager()
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1"
    
    private var headers: HTTPHeaders {
        var headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
}
```

### 2. WebSocket 连接管理
```swift
// 使用 Starscream 进行 WebSocket 连接
import Starscream

class WebSocketManager: WebSocketDelegate {
    static let shared = WebSocketManager()
    private var socket: WebSocket?
    private var isConnected = false
    
    func connect() {
        guard let token = UserDefaults.standard.string(forKey: "jwt_token") else { return }
        
        var request = URLRequest(url: URL(string: "wss://api.qinghejihua.com.cn/ws?token=\(token)")!)
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    func sendMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: data, encoding: .utf8) else { return }
        
        socket?.write(string: jsonString)
    }
}
```

### 3. 数据模型定义
```swift
// 使用 Codable 进行 JSON 解析
struct Conversation: Codable {
    let id: String
    let type: ConversationType
    let title: String?
    let avatar: String?
    let lastMessage: Message?
    let lastMessageAt: Date?
    let unreadCount: Int
    let isTop: Bool
    let isMuted: Bool
    let membersCount: Int
}

struct Message: Codable {
    let id: String
    let conversationId: String
    let senderId: Int
    let content: String?
    let type: MessageType
    let mediaUrl: String?
    let mediaDuration: Int?
    let thumbnailUrl: String?
    let status: MessageStatus
    let isRecalled: Bool
    let createdAt: Date
    let sender: User
}

enum MessageType: String, Codable {
    case text, image, video, audio, file, system
}

enum MessageStatus: String, Codable {
    case sent, delivered, read
}
```

### 4. 图片上传实现
```swift
func uploadImage(_ image: UIImage, completion: @escaping (Result<UploadResponse, Error>) -> Void) {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        completion(.failure(APIError.invalidImage))
        return
    }
    
    AF.upload(multipartFormData: { multipartFormData in
        multipartFormData.append(imageData, withName: "image", fileName: "image.jpg", mimeType: "image/jpeg")
    }, to: "\(baseURL)/upload/image", headers: headers)
    .responseDecodable(of: APIResponse<UploadResponse>.self) { response in
        switch response.result {
        case .success(let apiResponse):
            if apiResponse.success {
                completion(.success(apiResponse.data))
            } else {
                completion(.failure(APIError.serverError(apiResponse.message)))
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
```

### 5. 消息缓存策略
```swift
// 使用 Core Data 进行本地缓存
import CoreData

class MessageCacheManager {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ChatDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        return container
    }()
    
    func saveMessage(_ message: Message) {
        let context = persistentContainer.viewContext
        // 保存消息到 Core Data
        try? context.save()
    }
    
    func fetchMessages(for conversationId: String, limit: Int = 20) -> [Message] {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "conversationId == %@", conversationId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = limit
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toMessage() }
        } catch {
            return []
        }
    }
}
```

### 6. 实时消息处理
```swift
extension WebSocketManager {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .text(let string):
            handleWebSocketMessage(string)
        case .connected:
            isConnected = true
            startHeartbeat()
        case .disconnected(let reason, let code):
            isConnected = false
            stopHeartbeat()
        default:
            break
        }
    }
    
    private func handleWebSocketMessage(_ message: String) {
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        
        switch type {
        case "new_message":
            handleNewMessage(json["data"] as? [String: Any])
        case "message_recalled":
            handleMessageRecalled(json["data"] as? [String: Any])
        case "user_status_changed":
            handleUserStatusChanged(json["data"] as? [String: Any])
        default:
            break
        }
    }
}
```

### 7. 推荐的第三方库
- **网络请求**: Alamofire
- **WebSocket**: Starscream
- **图片加载**: Kingfisher
- **JSON解析**: 系统自带 Codable
- **本地存储**: Core Data
- **音频播放**: AVAudioPlayer
- **图片选择**: PHPickerViewController

---

## 📞 技术支持

如有任何问题，请联系开发团队：
- **邮箱**: dev@qinghejihua.com.cn
- **技术文档**: https://docs.qinghejihua.com.cn

## 🔍 高级功能 API

### 1. 搜索消息
```http
GET /api/v1/messages/search
```

**查询参数:**
- `q` (string, required): 搜索关键词
- `conversationId` (string, optional): 限定搜索的对话ID
- `page` (int, optional): 页码，默认 1

**响应示例:**
```json
{
  "success": true,
  "data": {
    "keyword": "你好",
    "items": [
      {
        "id": "uuid",
        "conversationId": "uuid",
        "content": "你好，最近怎么样？",
        "type": "text",
        "createdAt": "2025-08-22T13:30:00.000Z",
        "sender": {
          "id": 456,
          "nickname": "张三",
          "avatar": "https://example.com/avatar.jpg"
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 5,
      "totalPages": 1,
      "hasNext": false,
      "hasPrev": false
    }
  }
}
```

### 2. 导出聊天记录
```http
GET /api/v1/messages/conversations/{conversationId}/export
```

**查询参数:**
- `format` (string, optional): 导出格式 (`json`, `txt`, `download`)
- `startDate` (string, optional): 开始日期 (ISO 8601)
- `endDate` (string, optional): 结束日期 (ISO 8601)

### 3. 获取聊天统计
```http
GET /api/v1/messages/conversations/{conversationId}/statistics
```

**响应示例:**
```json
{
  "success": true,
  "data": {
    "totalMessages": 1250,
    "messageTypes": {
      "text": 1000,
      "image": 150,
      "video": 50,
      "audio": 30,
      "file": 20
    },
    "timeRange": {
      "firstMessage": "2025-01-01T00:00:00.000Z",
      "lastMessage": "2025-08-22T13:30:00.000Z"
    }
  }
}
```

### 4. 清空聊天记录
```http
DELETE /api/v1/messages/conversations/{conversationId}/messages
```

**请求体:**
```json
{
  "clearType": "soft"
}
```

## 📊 实时状态 API

### 1. 获取在线状态
```http
GET /api/v1/online-status/users/{userId}
```

**响应示例:**
```json
{
  "success": true,
  "data": {
    "userId": 456,
    "status": "online",
    "lastSeen": "2025-08-22T13:30:00.000Z",
    "connectionCount": 2
  }
}
```

### 2. 批量获取用户状态
```http
POST /api/v1/online-status/batch
```

**请求体:**
```json
{
  "userIds": [456, 789, 101]
}
```

## 🎯 iOS 实现最佳实践

### 1. 消息列表优化
```swift
// 使用 UITableViewDiffableDataSource 进行高效更新
class MessageListViewController: UIViewController {
    private var dataSource: UITableViewDiffableDataSource<Section, Message>!

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, Message>(
            tableView: tableView
        ) { tableView, indexPath, message in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: message.type.cellIdentifier,
                for: indexPath
            ) as! MessageCell
            cell.configure(with: message)
            return cell
        }
    }

    private func updateMessages(_ messages: [Message]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Message>()
        snapshot.appendSections([.main])
        snapshot.appendItems(messages)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
```

### 2. 图片消息处理
```swift
class ImageMessageCell: UITableViewCell {
    @IBOutlet weak var imageMessageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!

    func configure(with message: Message) {
        guard let imageUrl = message.mediaUrl else { return }

        // 使用 Kingfisher 加载图片
        imageMessageView.kf.setImage(
            with: URL(string: imageUrl),
            placeholder: UIImage(named: "image_placeholder"),
            options: [
                .transition(.fade(0.3)),
                .cacheOriginalImage
            ]
        ) { [weak self] result in
            switch result {
            case .success:
                self?.progressView.isHidden = true
            case .failure(let error):
                print("图片加载失败: \(error)")
            }
        }
    }
}
```

### 3. 语音消息播放
```swift
import AVFoundation

class AudioMessageManager: NSObject {
    static let shared = AudioMessageManager()
    private var audioPlayer: AVAudioPlayer?
    private var currentPlayingMessage: Message?

    func playAudio(from message: Message) {
        guard let audioUrl = message.mediaUrl,
              let url = URL(string: audioUrl) else { return }

        // 下载并播放音频
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else { return }

            DispatchQueue.main.async {
                do {
                    self?.audioPlayer = try AVAudioPlayer(data: data)
                    self?.audioPlayer?.delegate = self
                    self?.audioPlayer?.play()
                    self?.currentPlayingMessage = message
                } catch {
                    print("音频播放失败: \(error)")
                }
            }
        }.resume()
    }
}

extension AudioMessageManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentPlayingMessage = nil
        // 更新UI状态
        NotificationCenter.default.post(
            name: .audioPlaybackFinished,
            object: nil
        )
    }
}
```

### 4. 消息发送状态管理
```swift
enum MessageSendingState {
    case sending
    case sent
    case delivered
    case read
    case failed
}

class MessageSendingManager {
    static let shared = MessageSendingManager()
    private var pendingMessages: [String: Message] = [:]

    func sendMessage(_ message: Message, to conversationId: String) {
        // 添加到待发送队列
        pendingMessages[message.id] = message

        // 立即显示在UI中（显示发送中状态）
        NotificationCenter.default.post(
            name: .newMessageAdded,
            object: message
        )

        // 发送到服务器
        ChatAPIManager.shared.sendMessage(message, to: conversationId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let sentMessage):
                    self?.pendingMessages.removeValue(forKey: message.id)
                    // 更新消息状态
                    NotificationCenter.default.post(
                        name: .messageStatusUpdated,
                        object: sentMessage
                    )
                case .failure(let error):
                    // 标记发送失败
                    var failedMessage = message
                    failedMessage.sendingState = .failed
                    NotificationCenter.default.post(
                        name: .messageStatusUpdated,
                        object: failedMessage
                    )
                }
            }
        }
    }
}
```

### 5. 离线消息同步
```swift
class OfflineMessageSyncManager {
    static let shared = OfflineMessageSyncManager()

    func syncOfflineMessages() {
        guard NetworkReachabilityManager()?.isReachable == true else { return }

        // 获取最后同步时间
        let lastSyncTime = UserDefaults.standard.object(forKey: "last_message_sync") as? Date ?? Date.distantPast

        // 同步所有对话的新消息
        ChatAPIManager.shared.getConversations { [weak self] result in
            switch result {
            case .success(let conversations):
                for conversation in conversations.items {
                    self?.syncMessages(for: conversation.id, since: lastSyncTime)
                }
            case .failure(let error):
                print("同步对话列表失败: \(error)")
            }
        }
    }

    private func syncMessages(for conversationId: String, since date: Date) {
        // 获取指定时间后的消息
        ChatAPIManager.shared.getMessages(
            for: conversationId,
            since: date
        ) { result in
            switch result {
            case .success(let messages):
                // 保存到本地数据库
                MessageCacheManager.shared.saveMessages(messages.items)

                // 通知UI更新
                NotificationCenter.default.post(
                    name: .messagesUpdated,
                    object: conversationId,
                    userInfo: ["messages": messages.items]
                )
            case .failure(let error):
                print("同步消息失败: \(error)")
            }
        }
    }
}
```

## 🔔 推送通知集成

### 1. APNs 配置
```swift
import UserNotifications

class PushNotificationManager: NSObject {
    static let shared = PushNotificationManager()

    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            guard granted else { return }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        guard let messageData = userInfo["message"] as? [String: Any],
              let conversationId = messageData["conversationId"] as? String else { return }

        // 如果当前正在查看该对话，标记为已读
        if let currentConversationId = getCurrentConversationId(),
           currentConversationId == conversationId {
            ChatAPIManager.shared.markAsRead(conversationId: conversationId)
        }

        // 更新角标数字
        updateBadgeCount()
    }
}

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 在前台显示通知
        completionHandler([.alert, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 处理通知点击
        handleRemoteNotification(response.notification.request.content.userInfo)
        completionHandler()
    }
}
```

---

*最后更新时间: 2025-08-22*
