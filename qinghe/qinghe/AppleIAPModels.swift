import Foundation

// MARK: - Apple IAP 产品
struct AppleProductsResponse: Codable {
    let success: Bool?
    let status: String?
    let data: [AppleProductItem]?
    var isSuccess: Bool { success ?? (status?.lowercased() == "success") }
}

struct AppleProductItem: Codable, Identifiable {
    let id: Int
    let productId: String
    let productName: String
    let productDescription: String?
    let productType: String?
    let displayPrice: Double?
    let price: Double?
    let currency: String?
    let subscriptionPeriod: String?
    let subscriptionDuration: Int?
    let hasFreeTrial: Bool?
    let freeTrialDuration: Int?
    let isRecommended: Bool?
    let recommendedTag: String?
    let membershipPlan: AppleMembershipPlanRef?

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case productName = "product_name"
        case productDescription = "product_description"
        case productType = "product_type"
        case displayPrice = "display_price"
        case price
        case currency
        case subscriptionPeriod = "subscription_period"
        case subscriptionDuration = "subscription_duration"
        case hasFreeTrial = "has_free_trial"
        case freeTrialDuration = "free_trial_duration"
        case isRecommended = "is_recommended"
        case recommendedTag = "recommended_tag"
        case membershipPlan = "membership_plan"
    }
}

struct AppleMembershipPlanRef: Codable {
    let id: Int?
    let planCode: String?
    let planName: String?
    let price: Double?
    let durationType: String?
    let durationMonths: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case planCode = "plan_code"
        case planName = "plan_name"
        case price
        case durationType = "duration_type"
        case durationMonths = "duration_months"
    }
}

// MARK: - Apple IAP 验证
struct AppleVerifyRequest: Codable {
    let receiptData: String
    let transactionId: String?
}

struct AppleVerifyResponse: Codable {
    let success: Bool?
    let status: String?
    let message: String?
    let membership: MembershipStatusData?
    var isSuccess: Bool { success ?? (status?.lowercased() == "success") }
}

// MARK: - Apple IAP 恢复购买/刷新订阅
struct AppleRefreshResponse: Codable {
    let success: Bool?
    let status: String?
    let message: String?
    let data: AppleRefreshData?
    var isSuccess: Bool { success ?? (status?.lowercased() == "success") }
}

struct AppleRefreshData: Codable {
    let isActive: Bool?
    let expiresDate: String?
    let autoRenewStatus: Bool?
    let membership: MembershipStatusData?
    let latestTransaction: AppleTransactionInfo?
    
    enum CodingKeys: String, CodingKey {
        case isActive
        case expiresDate = "expires_date"
        case autoRenewStatus = "auto_renew_status"
        case membership
        case latestTransaction = "latest_transaction"
    }
}

struct AppleTransactionInfo: Codable {
    let transactionId: String?
    let originalTransactionId: String?
    let productId: String?
    let purchaseDate: String?
    let expiresDate: String?
    let autoRenewStatus: Bool?
    
    enum CodingKeys: String, CodingKey {
        case transactionId = "transaction_id"
        case originalTransactionId = "original_transaction_id"
        case productId = "product_id"
        case purchaseDate = "purchase_date"
        case expiresDate = "expires_date"
        case autoRenewStatus = "auto_renew_status"
    }
}

// MARK: - Apple IAP 会员状态
struct AppleIAPStatusResponse: Codable {
    let success: Bool?
    let status: String?
    let data: AppleIAPStatusData?
    var isSuccess: Bool { success ?? (status?.lowercased() == "success") }
}

struct AppleIAPStatusData: Codable {
    let isMember: Bool?
    let membership: AppleIAPMembershipInfo?
    let latestTransaction: AppleTransactionInfo?
    
    enum CodingKeys: String, CodingKey {
        case isMember
        case membership
        case latestTransaction = "latest_transaction"
    }
}

struct AppleIAPMembershipInfo: Codable {
    let userId: Int?
    let planCode: String?
    let planName: String?
    let expiresAt: String?
    let isActive: Bool?
    let autoRenew: Bool?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case planCode = "plan_code"
        case planName = "plan_name"
        case expiresAt = "expires_at"
        case isActive = "is_active"
        case autoRenew = "auto_renew"
    }
}

// MARK: - Apple IAP 订阅历史
struct AppleSubscriptionsResponse: Codable {
    let success: Bool?
    let status: String?
    let transactions: [AppleSubscriptionTransaction]?
    var isSuccess: Bool { success ?? (status?.lowercased() == "success") }
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId
        case transactionId
        case purchaseDate
        case expiresDate
        case isActive
        case autoRenewStatus
        case membership
    }
}

struct AppleSubscriptionMembershipInfo: Codable {
    let planName: String?
    let price: Double?
    
    enum CodingKeys: String, CodingKey {
        case planName = "plan_name"
        case price
    }
}

