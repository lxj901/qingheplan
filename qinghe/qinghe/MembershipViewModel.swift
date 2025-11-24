import Foundation
import Combine

@MainActor
class MembershipViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var isPurchasing: Bool = false
    @Published var isRestoring: Bool = false
    @Published var errorMessage: String?
    @Published var purchaseSuccess: Bool = false  // 标识购买是否成功

    @Published var status: MembershipStatusData?
    @Published var plans: [MembershipPlan] = []
    @Published var history: [MembershipHistoryItem] = []
    
    // Apple IAP 专用状态和历史（可选）
    @Published var appleIAPStatus: AppleIAPStatusData?
    @Published var appleSubscriptions: [AppleSubscriptionTransaction] = []

    // UI 辅助
    var isActiveMember: Bool { status?.hasMembership == true && status?.status == "active" }
    var daysRemainingText: String {
        if let days = status?.daysRemaining, days >= 0 {
            return "剩余\(days)天"
        }
        return "—"
    }

    func load() async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let statusResp = MembershipAPIService.shared.getStatus()
            async let plansResp = MembershipAPIService.shared.getPlans()
            let (sResp, pResp) = try await (statusResp, plansResp)
            self.status = sResp.data
            self.plans = pResp.data?.plans ?? []
            print("📋 会员计划列表:")
            for plan in self.plans {
                print("  - \(plan.planCode): \(plan.planName) - ¥\(plan.price) - duration: \(plan.duration ?? 0) \(plan.durationType ?? "unknown")")
            }
            // 加载 IAP 产品（无需阻塞前两者）
            updateAdFreeEntitlement(status: self.status, plans: self.plans)
            // 加载 IAP 产品（无需阻塞前两者）
            await IAPService.shared.loadProducts()
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func refreshHistory() async {
        if isRefreshing { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let resp = try await MembershipAPIService.shared.getHistory(page: 1, limit: 10)
            self.history = resp.data?.memberships ?? []
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func cancelAutoRenew() async {
        do {
            let resp = try await MembershipAPIService.shared.cancelAutoRenew()
            if resp.isSuccess {
                // 成功后更新状态
                await load()
            } else {
                self.errorMessage = resp.message ?? "取消自动续费失败"
            }
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func purchase(plan: MembershipPlan) async {
        if isPurchasing { return }
        isPurchasing = true
        purchaseSuccess = false  // 重置购买成功标志
        defer { isPurchasing = false }
        do {
            try await IAPService.shared.purchase(plan: plan)
            await load() // 购买成功后刷新状态
            purchaseSuccess = true  // 标记购买成功
        } catch let iapError as IAPError {
            // 处理自定义的 IAP 错误
            switch iapError {
            case .userCancelled:
                // 用户取消，无需提示错误，但也不显示成功
                print("用户取消了购买，不显示任何提示")
                purchaseSuccess = false  // 明确标记未成功
                return
            default:
                self.errorMessage = iapError.errorDescription
                purchaseSuccess = false
            }
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            purchaseSuccess = false
        }
    }

    func restorePurchases() async {
        if isRestoring { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await IAPService.shared.restorePurchases()
            await load()
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
    
    // MARK: - Apple IAP 专用API
    
    /// 从 Apple IAP API 获取会员状态
    func loadAppleIAPStatus() async {
        do {
            let response = try await IAPService.shared.getAppleIAPStatus()
            self.appleIAPStatus = response.data
            
            // 同步到通用状态（如果需要）
            if let iapData = response.data, let membership = iapData.membership {
                // 将 Apple IAP 状态映射到通用会员状态
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
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
    
    /// 从 Apple IAP API 获取订阅历史
    func loadAppleSubscriptions() async {
        do {
            let response = try await IAPService.shared.getAppleSubscriptions()
            self.appleSubscriptions = response.transactions ?? []
            
            // 同步到通用历史（如果需要）
            let historyItems = self.appleSubscriptions.map { transaction -> MembershipHistoryItem in
                MembershipHistoryItem(
                    id: transaction.id,
                    planName: transaction.membership?.planName,
                    planCode: "apple_iap",
                    status: transaction.isActive == true ? "active" : "expired",
                    startDate: transaction.purchaseDate,
                    endDate: transaction.expiresDate,
                    source: "apple",
                    paidAmount: transaction.membership?.price,
                    createdAt: transaction.purchaseDate
                )
            }
            self.history = historyItems
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
    
    /// 使用 Apple IAP API 加载所有信息
    func loadWithAppleIAP() async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // 并行加载状态、计划和IAP产品
            async let statusTask = IAPService.shared.getAppleIAPStatus()
            async let plansResp = MembershipAPIService.shared.getPlans()
            
            let (statusResp, pResp) = try await (statusTask, plansResp)
            
            // 处理 Apple IAP 状态
            self.appleIAPStatus = statusResp.data
            if let iapData = statusResp.data, let membership = iapData.membership {
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
            
            // 处理计划
            self.plans = pResp.data?.plans ?? []
            print("📋 会员计划列表:")
            for plan in self.plans {
                print("  - \(plan.planCode): \(plan.planName) - ¥\(plan.price)")
            }
                        updateAdFreeEntitlement(status: self.status, plans: self.plans)

            // 加载 IAP 产品（无需阻塞）
            await IAPService.shared.loadProducts()
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - 去广告权益落盘（供广告管理器读取）
    private func updateAdFreeEntitlement(status: MembershipStatusData?, plans: [MembershipPlan]) {
        var enabled = false
        defer {
            UserDefaults.standard.set(enabled, forKey: "ad_free_enabled")
            print("🔧 去广告权益更新: \(enabled ? "启用" : "未启用")")
        }

        // 优先读状态特性
        if let ad = status?.features?.adFree, ad == true {
            enabled = true
            return
        }
        // 基于当前计划匹配计划表
        if let code = status?.currentPlan?.planCode,
           let plan = plans.first(where: { $0.planCode == code }),
           plan.features?.adFree == true {
            enabled = true
            return
        }
        // 兜底：任意有效会员均启用去广告（若后端未显式返回 features.adFree）
        if (status?.hasMembership == true) && (status?.status == "active") {
            enabled = true
            return
        }
        enabled = false
    }
}
