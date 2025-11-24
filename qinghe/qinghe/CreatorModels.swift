import Foundation

// MARK: - 创作者数据模型

/// 作品概览数据
struct CreatorWorksOverview: Codable {
    let total: Int
    let published: Int
    let reviewing: Int
    let rejected: Int
    let `private`: Int
}

/// 创作者统计数据
struct CreatorStatisticsData: Codable {
    let overview: CreatorStatisticsOverview
    let timeRange: CreatorTimeRange
}

/// 统计概览
struct CreatorStatisticsOverview: Codable {
    let totalViews: Int
    let totalLikes: Int
    let totalComments: Int
    let totalShares: Int
    let followerViews: Int
    let followerLikes: Int
}

/// 时间范围
struct CreatorTimeRange: Codable {
    let type: String
    let startDate: String
    let endDate: String
}

/// 用户画像分析数据
struct AudienceAnalysisData: Codable {
    let totalViews: Int
    let gender: [GenderData]
    let age: [AgeData]
    let devicePrice: [DevicePriceData]
    let location: [LocationData]
}

/// 性别数据
struct GenderData: Codable {
    let gender: String
    let count: Int
    let percentage: String
}

/// 年龄数据
struct AgeData: Codable {
    let range: String
    let count: Int
    let percentage: String
}

/// 设备价格数据
struct DevicePriceData: Codable {
    let range: String
    let count: Int
    let percentage: String
}

/// 地域数据
struct LocationData: Codable {
    let location: String
    let count: Int
    let percentage: String
}

