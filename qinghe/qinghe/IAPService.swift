import Foundation
import StoreKit
import UIKit

// 自定义错误类型，用于更精确地处理购买流程中的各种情况
enum IAPError: LocalizedError {
    case userCancelled
    case purchaseInProgress
    case productNotFound
    case receiptVerificationFailed(String)
    case networkError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "用户取消了购买"
        case .purchaseInProgress:
            return "购买正在处理中，请稍候"
        case .productNotFound:
            return "未找到匹配的内购产品"
        case .receiptVerificationFailed(let message):
            return "收据验证失败: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
}

@MainActor
class IAPService: ObservableObject {
    static let shared = IAPService()

    // 后端配置的产品清单
    @Published private(set) var backendProducts: [AppleProductItem] = []
    // StoreKit 2 的产品对象缓存
    private var storeProductsById: [String: Product] = [:]
    
    // 购买状态锁，防止重复购买
    private var isPurchasing = false

    private init() {}

    // 拉取后端产品列表并加载 StoreKit 产品信息
    func loadProducts() async {
        do {
            print("📦 开始加载产品列表...")
            let resp: AppleProductsResponse = try await NetworkManager.shared.get(
                endpoint: APIEndpoints.appleProducts,
                parameters: nil,
                headers: nil,
                responseType: AppleProductsResponse.self
            )
            guard resp.isSuccess, let items = resp.data, !items.isEmpty else {
                print("❌ 后端产品列表为空或请求失败")
                return
            }
            self.backendProducts = items
            print("✅ 后端返回 \(items.count) 个产品")
            for item in items {
                print("  - \(item.productId) -> planCode: \(item.membershipPlan?.planCode ?? "nil")")
            }
            
            let ids = items.map { $0.productId }
            print("🔍 从 StoreKit 请求 \(ids.count) 个产品: \(ids)")

            // 添加详细的环境信息
            #if targetEnvironment(simulator)
            print("🖥️ 运行环境: 模拟器")
            #else
            print("📱 运行环境: 真机")
            #endif

            let products = try await Product.products(for: ids)
            print("✅ StoreKit 返回 \(products.count) 个产品")

            if products.isEmpty {
                print("⚠️ StoreKit 返回空列表！")
                print("⚠️ 可能原因:")
                print("   1. 模拟器: StoreKit 配置文件未正确加载")
                print("   2. 真机: App Store Connect 中产品未创建或未同步")
                print("   3. 产品ID不匹配")
            }

            for p in products {
                print("  - \(p.id): \(p.displayName) - \(p.displayPrice)")
                storeProductsById[p.id] = p
            }
        } catch {
            print("❌ IAPService.loadProducts error: \(error)")
            print("❌ 错误详情: \(error.localizedDescription)")
        }
    }

    // 根据 planCode 查找对应的 StoreKit Product
    func product(for planCode: String) -> Product? {
        print("🔍 查找产品 planCode: \(planCode)")
        print("🔍 后端产品数量: \(backendProducts.count)")
        print("🔍 StoreKit 产品数量: \(storeProductsById.count)")

        for item in backendProducts {
            print("  - 后端产品: \(item.productId), planCode: \(item.membershipPlan?.planCode ?? "nil")")
        }

        print("🔍 StoreKit 已加载的产品:")
        for (productId, product) in storeProductsById {
            print("  - StoreKit产品: \(productId) -> \(product.displayName)")
        }

        if let item = backendProducts.first(where: { $0.membershipPlan?.planCode == planCode }) {
            print("✅ 找到匹配的后端产品: \(item.productId)")
            if let product = storeProductsById[item.productId] {
                print("✅ 找到对应的 StoreKit 产品: \(product.displayName)")
                return product
            } else {
                print("❌ 未找到对应的 StoreKit 产品")
                print("❌ 可能原因: StoreKit 配置文件中缺少产品 \(item.productId)")
            }
        } else {
            print("❌ 未找到匹配的后端产品")
            print("❌ 请检查后端返回的 planCode 是否正确")
        }
        return nil
    }

    // 购买某个计划
    func purchase(plan: MembershipPlan) async throws {
        // 防止重复购买
        guard !isPurchasing else {
            print("⚠️ 购买流程正在进行中，忽略重复请求")
            throw IAPError.purchaseInProgress
        }

        isPurchasing = true
        defer { isPurchasing = false }

        print("🛒 开始购买流程...")
        print("📦 计划代码: \(plan.planCode)")

        // 确保产品已加载
        if backendProducts.isEmpty {
            print("⚠️ 产品列表为空，重新加载...")
            await loadProducts()
        }

        let planCode = plan.planCode
        guard let product = product(for: planCode) else {
            print("❌ 未找到匹配的内购产品: \(planCode)")
            throw IAPError.productNotFound
        }

        print("✅ 找到产品: \(product.id) - \(product.displayName)")
        print("💰 价格: \(product.displayPrice)")
        print("🔄 开始调用 StoreKit 购买...")

        do {
            let result = try await product.purchase()
            print("📱 StoreKit 返回结果...")
            print("🔍 结果类型: \(result)")

            try await handlePurchaseResult(result)
        } catch {
            print("❌ StoreKit purchase() 抛出异常: \(error)")
            print("❌ 异常类型: \(type(of: error))")
            print("❌ 异常描述: \(error.localizedDescription)")

            // 检查是否是用户取消
            if let storeError = error as? StoreKitError {
                print("🔍 StoreKitError 详情: \(storeError)")
                switch storeError {
                case .userCancelled:
                    print("✅ 确认：用户取消了购买")
                    throw IAPError.userCancelled
                default:
                    print("❌ 其他 StoreKit 错误")
                    throw IAPError.unknown("购买失败: \(error.localizedDescription)")
                }
            }

            // 其他类型的错误
            throw IAPError.unknown("购买失败: \(error.localizedDescription)")
        }
    }

    // 处理购买结果
    private func handlePurchaseResult(_ result: Product.PurchaseResult) async throws {
        print("🔍 开始处理购买结果...")

        switch result {
        case .success(let verification):
            print("✅ 购买成功，开始验证交易...")
            let transaction = try checkVerified(verification)
            print("✅ 交易验证通过")
            print("🆔 交易ID: \(transaction.id)")
            print("📦 产品ID: \(transaction.productID)")

            // 读取并上传收据
            print("📄 读取收据...")

            #if targetEnvironment(simulator)
            // 模拟器环境：使用模拟交易数据
            print("🖥️ 模拟器环境：使用交易信息验证...")
            print("📦 交易信息:")
            print("   - ID: \(transaction.id)")
            print("   - 产品ID: \(transaction.productID)")
            print("   - 购买日期: \(transaction.purchaseDate)")
            print("   - 原始ID: \(transaction.originalID)")

            // 构造模拟收据数据（包含交易信息的JSON）
            let mockReceiptData: [String: Any] = [
                "environment": "Xcode",
                "transaction_id": String(transaction.id),
                "original_transaction_id": String(transaction.originalID),
                "product_id": transaction.productID,
                "purchase_date": ISO8601DateFormatter().string(from: transaction.purchaseDate),
                "quantity": 1
            ]

            if let jsonData = try? JSONSerialization.data(withJSONObject: mockReceiptData),
               let mockReceipt = String(data: jsonData, encoding: .utf8) {
                let mockReceiptBase64 = Data(mockReceipt.utf8).base64EncodedString()
                print("✅ 生成模拟收据，长度: \(mockReceiptBase64.count)")

                print("🔄 向后端验证（模拟器模式）...")
                try await verifyWithServer(receiptData: mockReceiptBase64, transactionId: String(transaction.id))
                print("✅ 后端验证成功")
            } else {
                print("❌ 无法生成模拟收据")
                throw NetworkManager.NetworkError.networkError("模拟器环境：无法生成收据数据")
            }
            #else
            // 真机环境：优先尝试真实收据，失败则使用交易信息
            do {
                let receipt = try await currentReceiptBase64()
                print("✅ 收据已获取，长度: \(receipt.count)")

                print("🔄 向后端验证收据...")
                try await verifyWithServer(receiptData: receipt, transactionId: String(transaction.id))
                print("✅ 后端验证成功")
            } catch {
                print("❌ 收据获取失败: \(error.localizedDescription)")
                print("💡 沙盒环境收据生成失败，改用交易信息验证...")
                
                // 沙盒环境降级方案：使用交易信息验证
                let fallbackReceiptData: [String: Any] = [
                    "environment": "Sandbox",
                    "transaction_id": String(transaction.id),
                    "original_transaction_id": String(transaction.originalID),
                    "product_id": transaction.productID,
                    "purchase_date": ISO8601DateFormatter().string(from: transaction.purchaseDate),
                    "quantity": 1,
                    "note": "Receipt not available, using transaction data"
                ]
                
                if let jsonData = try? JSONSerialization.data(withJSONObject: fallbackReceiptData),
                   let fallbackReceipt = String(data: jsonData, encoding: .utf8) {
                    let fallbackReceiptBase64 = Data(fallbackReceipt.utf8).base64EncodedString()
                    print("✅ 生成降级收据数据，长度: \(fallbackReceiptBase64.count)")
                    
                    print("🔄 向后端验证（交易信息模式）...")
                    try await verifyWithServer(receiptData: fallbackReceiptBase64, transactionId: String(transaction.id))
                    print("✅ 后端验证成功（降级模式）")
                } else {
                    print("❌ 无法生成降级收据数据")
                    throw error
                }
            }
            #endif

            print("✅ 完成交易...")
            await transaction.finish()
            print("🎉 购买流程完成！")

        case .userCancelled:
            print("❌ 用户取消购买")
            throw IAPError.userCancelled

        case .pending:
            print("⏳ 订单待处理")
            throw IAPError.unknown("订单待处理，请稍后查看")

        @unknown default:
            print("❌ 未知的购买结果")
            throw IAPError.unknown("未知的购买结果")
        }
    }

    // 展示系统订阅管理
    func showManageSubscriptions() async {
        if #available(iOS 15.0, *) {
            do {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    try await AppStore.showManageSubscriptions(in: scene)
                } else {
                    // 回退：直接打开订阅页面
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        await UIApplication.shared.open(url)
                    }
                }
                return
            } catch {
                print("❌ showManageSubscriptions 失败: \(error)")
            }
        }
        // Fallback: 打开 App Store 订阅页面
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            await UIApplication.shared.open(url)
        }
    }

    // MARK: - Helpers
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NetworkManager.NetworkError.serverMessage("交易未通过验证")
        case .verified(let safe):
            return safe
        }
    }

    private func currentReceiptBase64() async throws -> String {
        // 1) 直接读取，如已存在则返回
        if let url = Bundle.main.appStoreReceiptURL,
           let data = try? Data(contentsOf: url), !data.isEmpty {
            print("✅ 收据已存在，直接读取")
            return data.base64EncodedString()
        }

        // 2) 轮询等待收据写入（购买后 StoreKit 会自动生成收据）
        print("⏳ 等待收据生成...")
        let maxAttempts = 15  // 增加等待次数
        for attempt in 1...maxAttempts {
            if let url2 = Bundle.main.appStoreReceiptURL,
               let data2 = try? Data(contentsOf: url2), !data2.isEmpty {
                print("✅ 收据已生成（等待 \(attempt) 次，共 \(Double(attempt) * 0.5)秒）")
                return data2.base64EncodedString()
            }
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        }

        // 3) 最后尝试 AppStore.sync()（可能触发登录）
        print("⚠️ 收据未自动生成，尝试手动同步...")
        print("🧾 调用 AppStore.sync()...")
        do {
            try await AppStore.sync()
            print("✅ AppStore.sync() 完成")
            
            // 再次尝试读取
            if let url3 = Bundle.main.appStoreReceiptURL,
               let data3 = try? Data(contentsOf: url3), !data3.isEmpty {
                print("✅ 同步后收据已生成")
                return data3.base64EncodedString()
            }
        } catch {
            print("❌ AppStore.sync() 失败: \(error)")
            print("💡 可能原因: 沙盒账号未登录或网络问题")
        }

        throw NetworkManager.NetworkError.networkError("未能获取收据。请确认：\n1. 已在 设置→App Store→沙盒账户 中登录\n2. 网络连接正常\n3. 重启设备后重试")
    }

    // 恢复购买：同步收据并调用后端刷新订阅状态
    func restorePurchases() async throws {
        print("🔄 开始恢复购买...")
        
        // 1. 同步 StoreKit 收据
        print("🔄 同步 StoreKit 收据...")
        try await AppStore.sync()
        print("✅ StoreKit 收据同步完成")
        
        // 2. 调用后端刷新订阅状态
        print("🔄 调用后端刷新订阅状态...")
        try await refreshSubscriptionWithServer()
        print("✅ 恢复购买完成")
    }
    
    // 调用后端 API 刷新订阅状态
    private func refreshSubscriptionWithServer() async throws {
        let resp: AppleRefreshResponse = try await NetworkManager.shared.post(
            endpoint: APIEndpoints.appleRefresh,
            parameters: nil,
            headers: nil,
            responseType: AppleRefreshResponse.self
        )
        
        guard resp.isSuccess else {
            let errorMsg = resp.message ?? "刷新订阅状态失败"
            print("❌ 刷新失败: \(errorMsg)")
            throw NetworkManager.NetworkError.serverMessage(errorMsg)
        }
        
        // 打印刷新结果
        if let data = resp.data {
            print("✅ 订阅状态已刷新:")
            print("   - 会员激活: \(data.isActive ?? false)")
            print("   - 到期时间: \(data.expiresDate ?? "N/A")")
            print("   - 自动续费: \(data.autoRenewStatus ?? false)")
            if let membership = data.membership, let planName = membership.currentPlan?.planName {
                print("   - 会员套餐: \(planName)")
            }
        }
    }

    private func verifyWithServer(receiptData: String, transactionId: String?) async throws {
        let req = AppleVerifyRequest(receiptData: receiptData, transactionId: transactionId)
        let encoder = JSONEncoder()
        guard let body = try? JSONSerialization.jsonObject(with: try encoder.encode(req)) as? [String: Any] else {
            throw NetworkManager.NetworkError.networkError("编码收据失败")
        }
        let resp: AppleVerifyResponse = try await NetworkManager.shared.post(
            endpoint: APIEndpoints.appleVerify,
            parameters: body,
            headers: nil,
            responseType: AppleVerifyResponse.self
        )
        guard resp.isSuccess else {
            throw IAPError.receiptVerificationFailed(resp.message ?? "收据验证失败")
        }
    }
    
    // MARK: - 获取会员状态（Apple IAP API）
    /// 从苹果内购专用API获取用户会员状态
    func getAppleIAPStatus() async throws -> AppleIAPStatusResponse {
        print("🔍 获取苹果IAP会员状态...")
        let response: AppleIAPStatusResponse = try await NetworkManager.shared.get(
            endpoint: APIEndpoints.appleStatus,
            parameters: nil,
            headers: nil,
            responseType: AppleIAPStatusResponse.self
        )
        
        guard response.isSuccess else {
            let errorMsg = response.status ?? "获取会员状态失败"
            print("❌ 获取状态失败: \(errorMsg)")
            throw NetworkManager.NetworkError.serverMessage(errorMsg)
        }
        
        // 打印状态信息
        if let data = response.data {
            print("✅ 会员状态:")
            print("   - 是否会员: \(data.isMember ?? false)")
            if let membership = data.membership {
                print("   - 套餐: \(membership.planName ?? "N/A")")
                print("   - 到期时间: \(membership.expiresAt ?? "N/A")")
                print("   - 激活状态: \(membership.isActive ?? false)")
                print("   - 自动续费: \(membership.autoRenew ?? false)")
            }
        }
        
        return response
    }
    
    // MARK: - 获取订阅历史（Apple IAP API）
    /// 从苹果内购专用API获取用户订阅历史
    func getAppleSubscriptions() async throws -> AppleSubscriptionsResponse {
        print("📜 获取苹果IAP订阅历史...")
        let response: AppleSubscriptionsResponse = try await NetworkManager.shared.get(
            endpoint: APIEndpoints.appleSubscriptions,
            parameters: nil,
            headers: nil,
            responseType: AppleSubscriptionsResponse.self
        )
        
        guard response.isSuccess else {
            let errorMsg = response.status ?? "获取订阅历史失败"
            print("❌ 获取历史失败: \(errorMsg)")
            throw NetworkManager.NetworkError.serverMessage(errorMsg)
        }
        
        // 打印订阅历史
        if let transactions = response.transactions {
            print("✅ 订阅历史 (\(transactions.count)条):")
            for (index, transaction) in transactions.enumerated() {
                print("   [\(index + 1)] 产品: \(transaction.productId ?? "N/A")")
                print("       交易ID: \(transaction.transactionId ?? "N/A")")
                print("       购买日期: \(transaction.purchaseDate ?? "N/A")")
                print("       到期日期: \(transaction.expiresDate ?? "N/A")")
                print("       激活状态: \(transaction.isActive ?? false)")
                if let membership = transaction.membership {
                    print("       套餐: \(membership.planName ?? "N/A") - ¥\(membership.price ?? 0)")
                }
            }
        } else {
            print("✅ 无订阅历史")
        }
        
        return response
    }
}
