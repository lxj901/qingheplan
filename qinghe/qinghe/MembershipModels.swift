import Foundation

// MARK: - 通用辅助类型

/// 同时兼容字符串或数字的字段
enum JSONStringOrInt: Codable {
    case string(String)
    case int(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            self = .string("")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }

    var displayText: String {
        switch self {
        case .int(let value): return String(value)
        case .string(let value): return value
        }
    }
    
    var intValue: Int {
        switch self {
        case .int(let value): return value
        case .string(let value): return Int(value) ?? 0
        }
    }
}

// MARK: - 会员状态

struct MembershipStatusResponse: Codable {
    let success: Bool?
    let status: String?
    let message: String?
    let data: MembershipStatusData?

    var isSuccess: Bool { success ?? (status?.lowercased() == "success") }
}

struct MembershipStatusData: Codable {
    var hasMembership: Bool?
    var currentPlan: MembershipPlanRef?
    var status: String? // free/active/expired/cancelled
    var startDate: String?
    var endDate: String?
    var daysRemaining: Int?
    var autoRenew: Bool?
    var source: String? // apple/wechat/alipay/admin
    var features: MembershipFeatures?
    // 兼容两种返回：扁平数值键（aiChatDaily 等）或字符串
    var limits: [String: JSONStringOrInt]?

    enum CodingKeys: String, CodingKey {
        case hasMembership
        case currentPlan
        case status
        case startDate
        case endDate
        case daysRemaining
        case autoRenew
        case source
        case features
        case limits
        // 兼容字段
        case isMember
        case planCode
        case planName
        case planDescription
        case expiresAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // hasMembership 或 isMember(Int/Bool)
        if let has = try? container.decode(Bool.self, forKey: .hasMembership) {
            self.hasMembership = has
        } else if let isMemberInt = try? container.decode(Int.self, forKey: .isMember) {
            self.hasMembership = (isMemberInt != 0)
        } else if let isMemberBool = try? container.decode(Bool.self, forKey: .isMember) {
            self.hasMembership = isMemberBool
        } else {
            self.hasMembership = nil
        }

        // 当前计划：可能直接提供 planCode/planName
        if let plan = try? container.decode(MembershipPlanRef.self, forKey: .currentPlan) {
            self.currentPlan = plan
        } else {
            let planCode = try? container.decode(String.self, forKey: .planCode)
            let planName = try? container.decode(String.self, forKey: .planName)
            let planDescription = try? container.decode(String.self, forKey: .planDescription)
            if planCode != nil || planName != nil || planDescription != nil {
                self.currentPlan = MembershipPlanRef(
                    id: nil,
                    planCode: planCode,
                    planName: planName,
                    planDescription: planDescription
                )
            } else {
                self.currentPlan = nil
            }
        }

        // 状态：优先 status 字段，否则根据 planCode 推断（free -> free，否则 active）
        if let statusValue = try? container.decode(String.self, forKey: .status) {
            self.status = statusValue
        } else if let planCode = try? container.decode(String.self, forKey: .planCode) {
            self.status = (planCode == "free" ? "free" : "active")
        } else {
            self.status = nil
        }

        self.startDate = try? container.decode(String.self, forKey: .startDate)

        // endDate 或 expiresAt
        if let end = try? container.decode(String.self, forKey: .endDate) {
            self.endDate = end
        } else if let expires = try? container.decode(String.self, forKey: .expiresAt) {
            self.endDate = expires
        } else {
            self.endDate = nil
        }

        self.daysRemaining = try? container.decode(Int.self, forKey: .daysRemaining)
        self.autoRenew = try? container.decode(Bool.self, forKey: .autoRenew)
        self.source = try? container.decode(String.self, forKey: .source)
        self.features = try? container.decode(MembershipFeatures.self, forKey: .features)

        // limits: 扁平键值（Int 或 String）
        self.limits = try? container.decode([String: JSONStringOrInt].self, forKey: .limits)
    }

    init(
        hasMembership: Bool? = nil,
        currentPlan: MembershipPlanRef? = nil,
        status: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        daysRemaining: Int? = nil,
        autoRenew: Bool? = nil,
        source: String? = nil,
        features: MembershipFeatures? = nil,
        limits: [String: JSONStringOrInt]? = nil
    ) {
        self.hasMembership = hasMembership
        self.currentPlan = currentPlan
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.daysRemaining = daysRemaining
        self.autoRenew = autoRenew
        self.source = source
        self.features = features
        self.limits = limits
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(hasMembership, forKey: .hasMembership)
        try container.encodeIfPresent(currentPlan, forKey: .currentPlan)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encodeIfPresent(daysRemaining, forKey: .daysRemaining)
        try container.encodeIfPresent(autoRenew, forKey: .autoRenew)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encodeIfPresent(features, forKey: .features)
        try container.encodeIfPresent(limits, forKey: .limits)
    }
}

struct MembershipPlanRef: Codable {
    let id: Int?
    let planCode: String?
    let planName: String?
    let planDescription: String?
}

struct MembershipFeatures: Codable {
    let ai_chat: Bool?
    let tongue_diagnosis: Bool?
    let sleep_analysis: Bool?
    let ai_coach_voice: Bool?
    let adFree: Bool? // 去广告权益（后端可返回该字段）
}

struct MembershipUsageLimit: Codable {
    let dailyLimit: Int?
    let monthlyLimit: Int?
    let dailyUsed: Int?
    let monthlyUsed: Int?
    let dailyRemaining: JSONStringOrInt?
    let monthlyRemaining: JSONStringOrInt?
}

// MARK: - 套餐列表

struct MembershipPlansResponse: Codable {
    let success: Bool?
    let status: String?
    let message: String?
    let data: MembershipPlansData?

    var isSuccess: Bool { success ?? (status?.lowercased() == "success") }
}

struct MembershipPlansData: Codable {
    let plans: [MembershipPlan]
}

struct MembershipPlan: Codable, Identifiable {
    let id: Int
    let planCode: String
    let planName: String
    let planDescription: String?
    let price: Double
    let originalPrice: Double?
    let duration: Int?
    let durationType: String? // day/month/year/lifetime
    let isRecommended: Bool?
    let promotionTag: String?
    let limits: PlanLimits?
    let features: PlanFeatures?
}

struct PlanLimits: Codable {
    let aiChat: PlanLimitItem?
    let tongueDiagnosis: PlanLimitItem?
    let sleepAnalysis: PlanLimitItem?
    let aiCoachVoice: PlanLimitItem?
}

struct PlanLimitItem: Codable {
    let daily: Int?
    let monthly: Int?
}

struct PlanFeatures: Codable {
    let adFree: Bool?
    let prioritySupport: Bool?
    let exclusiveContent: Bool?
    let advancedAnalytics: Bool?
}

// MARK: - 订阅历史

struct MembershipHistoryResponse: Codable {
    let success: Bool?
    let status: String?
    let message: String?
    let data: MembershipHistoryData?

    var isSuccess: Bool { success ?? (status?.lowercased() == "success") }
}

struct MembershipHistoryData: Codable {
    let total: Int?
    let page: Int?
    let limit: Int?
    let memberships: [MembershipHistoryItem]?
}

struct MembershipHistoryItem: Codable, Identifiable {
    let id: Int
    let planName: String?
    let planCode: String?
    let status: String? // active/expired/cancelled/pending
    let startDate: String?
    let endDate: String?
    let source: String?
    let paidAmount: Double?
    let createdAt: String?
}

// MARK: - 取消自动续费

struct MembershipCancelAutoRenewResponse: Codable {
    let success: Bool?
    let status: String?
    let message: String?
    let data: MembershipCancelAutoRenewData?

    var isSuccess: Bool { success ?? (status?.lowercased() == "success") }
}

struct MembershipCancelAutoRenewData: Codable {
    let membershipId: Int?
    let autoRenew: Bool?
    let endDate: String?
    let note: String?
}
