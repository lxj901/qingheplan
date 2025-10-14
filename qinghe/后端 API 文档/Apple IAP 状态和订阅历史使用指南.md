# Apple IAP 状态和订阅历史 - 使用指南

## 📱 概述

本文档说明如何在前端使用苹果内购专用的会员状态和订阅历史API。

---

## 🎯 功能实现状态

| 功能 | API接口 | 实现状态 | 说明 |
|------|---------|----------|------|
| 获取会员状态 | `GET /apple-iap/status` | ✅ 已实现 | 获取通过Apple IAP购买的会员状态 |
| 获取订阅历史 | `GET /apple-iap/subscriptions` | ✅ 已实现 | 获取所有Apple IAP订阅记录 |

---

## 📦 核心组件

### 1. API端点配置

文件：`NetworkManager.swift`

```swift
static let appleStatus = "/apple-iap/status"                 // 获取用户会员状态
static let appleSubscriptions = "/apple-iap/subscriptions"   // 获取用户订阅历史
```

### 2. 数据模型

文件：`AppleIAPModels.swift`

#### 会员状态响应
```swift
struct AppleIAPStatusResponse: Codable {
    let success: Bool?
    let status: String?
    let data: AppleIAPStatusData?
}

struct AppleIAPStatusData: Codable {
    let isMember: Bool?
    let membership: AppleIAPMembershipInfo?
    let latestTransaction: AppleTransactionInfo?
}

struct AppleIAPMembershipInfo: Codable {
    let userId: Int?
    let planCode: String?
    let planName: String?
    let expiresAt: String?
    let isActive: Bool?
    let autoRenew: Bool?
}
```

#### 订阅历史响应
```swift
struct AppleSubscriptionsResponse: Codable {
    let success: Bool?
    let status: String?
    let transactions: [AppleSubscriptionTransaction]?
}

struct AppleSubscriptionTransaction: Codable, Identifiable {
    let id: Int
    let productId: String?
    let transactionId: String?
    let purchaseDate: String?
    let expiresDate: String?
    let isActive: Bool?
    let autoRenewStatus: Bool?
    let membership: AppleSubscriptionMembershipInfo?
}
```

### 3. 服务层

文件：`IAPService.swift`

#### 获取会员状态
```swift
func getAppleIAPStatus() async throws -> AppleIAPStatusResponse {
    print("🔍 获取苹果IAP会员状态...")
    let response: AppleIAPStatusResponse = try await NetworkManager.shared.get(
        endpoint: APIEndpoints.appleStatus,
        parameters: nil,
        headers: nil,
        responseType: AppleIAPStatusResponse.self
    )
    
    guard response.isSuccess else {
        throw NetworkManager.NetworkError.serverMessage("获取会员状态失败")
    }
    
    return response
}
```

#### 获取订阅历史
```swift
func getAppleSubscriptions() async throws -> AppleSubscriptionsResponse {
    print("📜 获取苹果IAP订阅历史...")
    let response: AppleSubscriptionsResponse = try await NetworkManager.shared.get(
        endpoint: APIEndpoints.appleSubscriptions,
        parameters: nil,
        headers: nil,
        responseType: AppleSubscriptionsResponse.self
    )
    
    guard response.isSuccess else {
        throw NetworkManager.NetworkError.serverMessage("获取订阅历史失败")
    }
    
    return response
}
```

### 4. ViewModel层

文件：`MembershipViewModel.swift`

#### 加载会员状态
```swift
func loadAppleIAPStatus() async {
    do {
        let response = try await IAPService.shared.getAppleIAPStatus()
        self.appleIAPStatus = response.data
        
        // 同步到通用状态
        if let iapData = response.data, let membership = iapData.membership {
            var commonStatus = MembershipStatusData()
            commonStatus.hasMembership = iapData.isMember
            commonStatus.status = membership.isActive == true ? "active" : "expired"
            commonStatus.currentPlan = MembershipPlanRef(
                id: nil,
                planCode: membership.planCode,
                planName: membership.planName,
                planDescription: nil
            )
            commonStatus.endDate = membership.expiresAt
            commonStatus.autoRenew = membership.autoRenew
            commonStatus.source = "apple"
            self.status = commonStatus
        }
    } catch {
        self.errorMessage = error.localizedDescription
    }
}
```

#### 加载订阅历史
```swift
func loadAppleSubscriptions() async {
    do {
        let response = try await IAPService.shared.getAppleSubscriptions()
        self.appleSubscriptions = response.transactions ?? []
        
        // 转换为通用历史格式
        let historyItems = self.appleSubscriptions.map { transaction -> MembershipHistoryItem in
            var item = MembershipHistoryItem()
            item.id = transaction.id
            item.planCode = "apple_iap"
            item.planName = transaction.membership?.planName
            item.startDate = transaction.purchaseDate
            item.endDate = transaction.expiresDate
            item.status = transaction.isActive == true ? "active" : "expired"
            item.source = "apple"
            return item
        }
        self.history = historyItems
    } catch {
        self.errorMessage = error.localizedDescription
    }
}
```

---

## 💻 使用示例

### 场景1：在会员中心显示状态

```swift
import SwiftUI

struct MembershipCenterView: View {
    @StateObject private var viewModel = MembershipViewModel()
    
    var body: some View {
        ScrollView {
            VStack {
                // 显示会员状态
                if let status = viewModel.appleIAPStatus {
                    if status.isMember == true {
                        MembershipStatusCard(membership: status.membership)
                    } else {
                        Text("您还不是会员")
                    }
                }
            }
        }
        .onAppear {
            Task {
                // 使用Apple IAP API加载状态
                await viewModel.loadAppleIAPStatus()
            }
        }
    }
}

struct MembershipStatusCard: View {
    let membership: AppleIAPMembershipInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(membership?.planName ?? "会员")
                .font(.title2)
                .bold()
            
            if let expiresAt = membership?.expiresAt {
                Text("到期时间：\(formatDate(expiresAt))")
                    .font(.subheadline)
            }
            
            if membership?.autoRenew == true {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("自动续费中")
                }
                .font(.caption)
                .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    func formatDate(_ dateString: String) -> String {
        // 日期格式化逻辑
        return dateString
    }
}
```

### 场景2：显示订阅历史列表

```swift
struct SubscriptionHistoryView: View {
    @StateObject private var viewModel = MembershipViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.appleSubscriptions) { transaction in
                SubscriptionHistoryRow(transaction: transaction)
            }
        }
        .navigationTitle("订阅历史")
        .onAppear {
            Task {
                await viewModel.loadAppleSubscriptions()
            }
        }
    }
}

struct SubscriptionHistoryRow: View {
    let transaction: AppleSubscriptionTransaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(transaction.membership?.planName ?? "订阅")
                    .font(.headline)
                Spacer()
                Text(transaction.isActive == true ? "激活" : "已过期")
                    .font(.caption)
                    .padding(4)
                    .background(transaction.isActive == true ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            if let price = transaction.membership?.price {
                Text("¥\(String(format: "%.2f", price))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if let purchaseDate = transaction.purchaseDate {
                    Text("购买：\(formatShortDate(purchaseDate))")
                }
                Text("•")
                if let expiresDate = transaction.expiresDate {
                    Text("到期：\(formatShortDate(expiresDate))")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    func formatShortDate(_ dateString: String) -> String {
        // 简短日期格式化
        return dateString
    }
}
```

### 场景3：统一加载所有信息

```swift
struct ContentView: View {
    @StateObject private var viewModel = MembershipViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // 内容
            }
            .onAppear {
                Task {
                    // 使用统一的加载方法
                    await viewModel.loadWithAppleIAP()
                }
            }
        }
    }
}
```

---

## 🔄 与通用API的对比

### 通用API（适用所有支付方式）
- `GET /membership/status` - 获取会员状态（支持Apple/微信/支付宝）
- `GET /membership/history` - 获取订阅历史（所有来源）

### Apple IAP专用API（仅Apple内购）
- `GET /apple-iap/status` - 获取Apple IAP会员状态
- `GET /apple-iap/subscriptions` - 获取Apple IAP订阅历史

### 何时使用哪个API？

| 场景 | 推荐使用 | 原因 |
|------|----------|------|
| iOS App - 仅支持Apple IAP | Apple IAP API | 更精确的Apple订阅信息 |
| 多平台 - 支持多种支付 | 通用API | 统一的数据格式 |
| 需要交易详情 | Apple IAP API | 包含transactionId等详细信息 |
| 简单会员验证 | 通用API | 更轻量 |

### 当前实现策略

ViewModel同时支持两种API：
- **默认**：使用通用API（`load()`方法）
- **可选**：使用Apple IAP API（`loadWithAppleIAP()`方法）
- **灵活**：数据自动映射，UI层无需区分

---

## 🧪 测试建议

### 1. 测试会员状态获取

```swift
Task {
    do {
        let response = try await IAPService.shared.getAppleIAPStatus()
        print("是否会员：\(response.data?.isMember ?? false)")
        print("套餐：\(response.data?.membership?.planName ?? "N/A")")
        print("到期：\(response.data?.membership?.expiresAt ?? "N/A")")
    } catch {
        print("错误：\(error)")
    }
}
```

### 2. 测试订阅历史获取

```swift
Task {
    do {
        let response = try await IAPService.shared.getAppleSubscriptions()
        print("订阅数量：\(response.transactions?.count ?? 0)")
        for transaction in response.transactions ?? [] {
            print("- \(transaction.productId ?? "N/A"): \(transaction.isActive == true ? "激活" : "过期")")
        }
    } catch {
        print("错误：\(error)")
    }
}
```

### 3. 测试完整流程

```swift
Task {
    await viewModel.loadWithAppleIAP()
    
    print("会员状态：\(viewModel.isActiveMember ? "激活" : "未激活")")
    print("计划数量：\(viewModel.plans.count)")
    print("历史记录：\(viewModel.history.count)")
}
```

---

## 📝 注意事项

### 1. 认证要求
所有Apple IAP状态和订阅历史API都需要JWT Token认证。

### 2. 错误处理
```swift
func loadAppleIAPStatus() async {
    do {
        let response = try await IAPService.shared.getAppleIAPStatus()
        // 处理成功
    } catch let error as NetworkManager.NetworkError {
        switch error {
        case .unauthorized:
            // 未登录，跳转到登录页
            break
        case .serverMessage(let message):
            // 显示错误信息
            self.errorMessage = message
        default:
            self.errorMessage = "获取状态失败"
        }
    } catch {
        self.errorMessage = error.localizedDescription
    }
}
```

### 3. 数据同步
ViewModel自动将Apple IAP数据映射到通用格式，确保UI组件可以无缝使用。

### 4. 性能优化
- 使用`async let`并行加载多个接口
- 在`loadWithAppleIAP()`中同时获取状态和计划
- 避免重复请求（使用`isLoading`标志）

---

## 🎉 总结

✅ **已完成的功能：**
1. API端点配置
2. 完整的数据模型
3. IAPService服务层方法
4. MembershipViewModel集成
5. 通用数据映射

🚀 **可以开始使用：**
- 在会员中心显示Apple IAP状态
- 显示订阅历史列表
- 集成到现有UI组件

📚 **相关文档：**
- 主文档：`会员订阅与支付.md`
- 后端API：`https://api.qinghejihua.com.cn/api/v1/apple-iap/*`

---

**更新时间：** 2025-10-11


