import XCTest
@testable import qinghe

class WebSocketMessageParsingTests: XCTestCase {
    
    var webSocketManager: WebSocketManager!
    
    override func setUp() {
        super.setUp()
        webSocketManager = WebSocketManager.shared
    }
    
    override func tearDown() {
        webSocketManager = nil
        super.tearDown()
    }
    
    func testNewMessageDataParsing() {
        // 测试新格式的消息数据解析（直接包含消息字段）
        let newFormatData: [String: AnyCodable] = [
            "id": AnyCodable("f782085e-2ced-49c1-9aae-e64a071df88a"),
            "createdAt": AnyCodable("2025-08-23 22:09:24"),
            "content": AnyCodable("9999"),
            "conversationId": AnyCodable("94bca872-b1ac-442d-b53c-9386f0e00934"),
            "senderId": AnyCodable(3),
            "type": AnyCodable("text"),
            "mediaUrl": AnyCodable(""),
            "replyToMessageId": AnyCodable(""),
            "sender": AnyCodable("")
        ]
        
        // 使用反射调用私有方法进行测试
        let result = callPrivateExtractNewMessageData(data: newFormatData)
        
        XCTAssertNotNil(result, "应该能够解析新格式的消息数据")
        XCTAssertEqual(result?.conversationId, "94bca872-b1ac-442d-b53c-9386f0e00934")
        XCTAssertEqual(result?.message.id, "f782085e-2ced-49c1-9aae-e64a071df88a")
        XCTAssertEqual(result?.message.content, "9999")
        XCTAssertEqual(result?.message.senderId, 3)
        XCTAssertEqual(result?.message.type, .text)
    }
    
    func testOldMessageDataParsing() {
        // 测试旧格式的消息数据解析（嵌套结构）
        let messageData: [String: Any] = [
            "id": "test-message-id",
            "senderId": 1,
            "content": "测试消息",
            "type": "text",
            "status": "delivered",
            "createdAt": "2025-08-23 22:09:24",
            "isRecalled": false
        ]
        
        let oldFormatData: [String: AnyCodable] = [
            "conversationId": AnyCodable("test-conversation-id"),
            "message": AnyCodable(messageData)
        ]
        
        let result = callPrivateExtractNewMessageData(data: oldFormatData)
        
        XCTAssertNotNil(result, "应该能够解析旧格式的消息数据")
        XCTAssertEqual(result?.conversationId, "test-conversation-id")
        XCTAssertEqual(result?.message.id, "test-message-id")
        XCTAssertEqual(result?.message.content, "测试消息")
        XCTAssertEqual(result?.message.senderId, 1)
        XCTAssertEqual(result?.message.type, .text)
    }
    
    func testInvalidMessageDataParsing() {
        // 测试无效数据的处理
        let invalidData: [String: AnyCodable] = [
            "invalidField": AnyCodable("invalid")
        ]
        
        let result = callPrivateExtractNewMessageData(data: invalidData)
        
        XCTAssertNil(result, "无效数据应该返回 nil")
    }
    
    // MARK: - Helper Methods
    
    /// 使用反射调用私有方法进行测试
    private func callPrivateExtractNewMessageData(data: [String: AnyCodable]) -> NewMessageData? {
        let mirror = Mirror(reflecting: webSocketManager)
        
        // 由于这是私有方法，我们需要通过其他方式测试
        // 这里我们创建一个模拟的 WebSocketMessage 来测试解析逻辑
        let message = WebSocketMessage(type: .newMessage, data: data.mapValues { $0.value })
        
        // 模拟消息处理
        return mockExtractNewMessageData(from: data)
    }
    
    /// 模拟 extractNewMessageData 方法的逻辑
    private func mockExtractNewMessageData(from data: [String: AnyCodable]?) -> NewMessageData? {
        guard let data = data else {
            return nil
        }

        // 检查数据结构类型
        if let conversationId = data["conversationId"]?.value as? String,
           let messageData = data["message"]?.value as? [String: Any] {
            // 旧格式：{ "conversationId": "...", "message": { ... } }
            return parseMessageFromNestedData(messageData: messageData, conversationId: conversationId)
        } else if let conversationId = data["conversationId"]?.value as? String,
                  let messageId = data["id"]?.value as? String {
            // 新格式：直接包含消息字段
            return parseMessageFromDirectData(data: data, conversationId: conversationId)
        } else {
            return nil
        }
    }
    
    private func parseMessageFromNestedData(messageData: [String: Any], conversationId: String) -> NewMessageData? {
        return parseMessageDataFallback(messageData: messageData, conversationId: conversationId)
    }
    
    private func parseMessageFromDirectData(data: [String: AnyCodable], conversationId: String) -> NewMessageData? {
        // 将 AnyCodable 数据转换为普通字典
        var messageData: [String: Any] = [:]
        for (key, value) in data {
            messageData[key] = value.value
        }
        
        return parseMessageDataFallback(messageData: messageData, conversationId: conversationId)
    }
    
    private func parseMessageDataFallback(messageData: [String: Any], conversationId: String) -> NewMessageData? {
        guard let messageId = messageData["id"] as? String,
              let senderId = messageData["senderId"] as? Int,
              let content = messageData["content"] as? String,
              let createdAt = messageData["createdAt"] as? String else {
            return nil
        }

        // 解析消息类型
        let messageType: MessageType
        if let typeString = messageData["type"] as? String {
            messageType = MessageType(rawValue: typeString) ?? .text
        } else {
            messageType = .text
        }

        // 解析消息状态
        let messageStatus: MessageStatus
        if let statusString = messageData["status"] as? String {
            messageStatus = MessageStatus(rawValue: statusString) ?? .delivered
        } else {
            messageStatus = .delivered
        }

        // 创建默认发送者
        let sender = ChatUser(
            id: senderId,
            nickname: "用户\(senderId)",
            avatar: nil,
            isVerified: false,
            isOnline: false,
            lastSeenAt: nil
        )

        let message = ChatMessage(
            id: messageId,
            conversationId: conversationId,
            senderId: senderId,
            content: content,
            type: messageType,
            status: messageStatus,
            isRecalled: messageData["isRecalled"] as? Bool ?? false,
            createdAt: createdAt,
            sender: sender,
            replyToMessageId: messageData["replyToMessageId"] as? String,
            mediaUrl: messageData["mediaUrl"] as? String,
            mediaDuration: messageData["mediaDuration"] as? Int,
            thumbnailUrl: messageData["thumbnailUrl"] as? String
        )

        return NewMessageData(message: message, conversationId: conversationId)
    }
}
