//
//  ReviewModels.swift
//  qinghe
//
//  Created by Augment Agent on 2025-10-20.
//  复习计划数据模型

import Foundation

// MARK: - 复习项目
struct ReviewItem: Identifiable, Codable {
    let id: String
    let userId: Int
    let sectionId: String
    let bookId: String
    let chapterId: String
    let firstLearnedAt: String
    let lastReviewedAt: String?
    let nextReviewAt: String
    let reviewCount: Int
    let reviewInterval: Int  // 后端返回的是 reviewInterval，不是 interval
    let masteryLevel: String
    let difficulty: Double
    let isCompleted: Bool
    let created_at: String
    let updated_at: String

    // 关联的章节信息（用于显示）
    let section: SectionDetail?

    // 计算属性：原文（从 section 中获取）
    var original: String {
        section?.original ?? ""
    }

    // 计算属性：下次复习时间
    var nextReviewDate: Date? {
        // 后端返回的时间格式是 "2025-10-21 22:03:19"，不是 ISO8601
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: nextReviewAt)
    }

    // 计算属性：是否今日待复习
    var isDueToday: Bool {
        guard let reviewDate = nextReviewDate else { return false }
        return Calendar.current.isDateInToday(reviewDate) || reviewDate < Date()
    }

    // 计算属性：距离现在的天数
    var daysFromNow: Int {
        guard let reviewDate = nextReviewDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: reviewDate).day ?? 0
        return days
    }

    // 计算属性：日期分组标题
    var dateGroupTitle: String {
        guard let reviewDate = nextReviewDate else { return "未知" }

        let calendar = Calendar.current
        if calendar.isDateInToday(reviewDate) {
            return "今天"
        } else if calendar.isDateInTomorrow(reviewDate) {
            return "明天"
        } else {
            let days = daysFromNow
            if days > 0 {
                return "\(days)天后"
            } else if days == 0 {
                return "今天"
            } else {
                return "已过期"
            }
        }
    }
}

// MARK: - 章节详情（从后端返回的 section 对象）
struct SectionDetail: Codable {
    let id: String
    let bookId: String
    let chapterId: String
    let sectionId: Int
    let original: String
    let pinyin: String?
    let translation: String?
    let annotation: String?
    let audioUrl: String?
    let audioDuration: String?
    let order: Int
    let created_at: String
    let updated_at: String
}

// MARK: - 复习章节信息
struct ReviewSection: Codable {
    let bookId: String
    let chapterId: String
    let bookTitle: String
    let chapterTitle: String
}

// MARK: - 复习完成请求
struct ReviewCompleteRequest: Codable {
    let userId: Int
    let sectionId: String
    let quality: Int  // 1-5: 1=完全忘记, 5=完全记住
}

// MARK: - 复习完成响应
struct ReviewCompleteResponse: Codable {
    let nextReviewAt: String
    let interval: Int
    let reviewCount: Int
    
    // 计算属性：下次复习时间
    var nextReviewDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: nextReviewAt)
    }
    
    // 计算属性：下次复习时间描述
    var nextReviewDescription: String {
        guard let reviewDate = nextReviewDate else { return "未知" }
        
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: reviewDate).day ?? 0
        
        if days == 0 {
            return "今天"
        } else if days == 1 {
            return "明天"
        } else {
            return "\(days)天后"
        }
    }
}

// MARK: - 复习统计数据（后端 API 响应结构）

// 本周复习数据
struct WeeklyReviewData: Codable {
    let date: String        // 日期，格式：yyyy-MM-dd
    let dayName: String     // 星期名称，如"周一"
    let count: Int          // 复习次数
}

// 复习数据统计
struct ReviewDataStats: Codable {
    let totalReviews: Int       // 总复习次数
    let avgQuality: Double      // 平均质量评分
    let consecutiveDays: Int    // 连续复习天数
}

// 质量评分分布
struct QualityDistribution: Codable {
    let quality: Int        // 质量等级 0-5
    let label: String       // 质量标签
    let count: Int          // 该质量等级的复习次数
}

// 艾宾浩斯曲线数据点
struct EbbinghausCurvePoint: Codable {
    let intervalDays: Int       // 间隔天数
    let avgQuality: Double?     // 平均质量（可能为 null）
    let count: Int              // 复习次数
    let retentionRate: Double?  // 记忆保持率（百分比，可能为 null）
}

// 完整统计数据（对应后端 /api/v1/classics/review/statistics 接口）
struct ReviewStatistics: Codable {
    let weekly: [WeeklyReviewData]              // 本周复习情况
    let data: ReviewDataStats                   // 数据统计
    let qualityDistribution: [QualityDistribution]  // 质量分布
    let ebbinghausCurve: [EbbinghausCurvePoint]    // 艾宾浩斯曲线
}

// MARK: - 复习统计数据（旧版本，用于向后兼容）
struct ReviewStats: Codable {
    let totalReviews: Int           // 总复习次数
    let averageQuality: Double      // 平均质量评分
    let consecutiveDays: Int        // 连续复习天数
    let weeklyReviews: [Int]        // 本周每天的复习次数 [周一, 周二, ..., 周日]
    let qualityDistribution: [Int]  // 质量评分分布 [1星次数, 2星次数, ..., 5星次数]

    // 计算属性：本周总复习次数
    var weeklyTotal: Int {
        weeklyReviews.reduce(0, +)
    }

    // 计算属性：最高单日复习次数
    var maxDailyReviews: Int {
        weeklyReviews.max() ?? 0
    }

    // 从新的 ReviewStatistics 转换为旧的 ReviewStats
    static func from(_ statistics: ReviewStatistics) -> ReviewStats {
        // 转换本周数据为简单的 Int 数组
        let weeklyReviews = statistics.weekly.map { $0.count }

        // 转换质量分布为简单的 Int 数组（只取 count）
        let qualityDistribution = statistics.qualityDistribution.map { $0.count }

        return ReviewStats(
            totalReviews: statistics.data.totalReviews,
            averageQuality: statistics.data.avgQuality,
            consecutiveDays: statistics.data.consecutiveDays,
            weeklyReviews: weeklyReviews,
            qualityDistribution: qualityDistribution
        )
    }
}

// MARK: - 复习质量等级
enum ReviewQuality: Int, CaseIterable {
    case forgotten = 1      // 完全忘记
    case vague = 2          // 模糊记忆
    case basic = 3          // 基本记住
    case clear = 4          // 清晰记忆
    case perfect = 5        // 完全掌握
    
    var title: String {
        switch self {
        case .forgotten: return "完全忘记"
        case .vague: return "模糊记忆"
        case .basic: return "基本记住"
        case .clear: return "清晰记忆"
        case .perfect: return "完全掌握"
        }
    }
    
    var icon: String {
        switch self {
        case .forgotten: return "xmark.circle.fill"
        case .vague: return "questionmark.circle.fill"
        case .basic: return "checkmark.circle.fill"
        case .clear: return "star.circle.fill"
        case .perfect: return "star.fill"
        }
    }
    
    var color: (red: Double, green: Double, blue: Double) {
        switch self {
        case .forgotten: return (0.86, 0.39, 0.31)  // 红色
        case .vague: return (0.95, 0.61, 0.31)      // 橙色
        case .basic: return (0.95, 0.77, 0.31)      // 黄色
        case .clear: return (0.51, 0.78, 0.45)      // 浅绿色
        case .perfect: return (0.31, 0.63, 0.45)    // 深绿色
        }
    }
}

// MARK: - 日期分组的复习项目
struct ReviewDateGroup: Identifiable {
    let id = UUID()
    let title: String           // "今天"、"明天"、"3天后"
    let date: Date?             // 实际日期
    let items: [ReviewItem]     // 该日期的复习项目
    let isDueToday: Bool        // 是否今日待复习
    
    var count: Int {
        items.count
    }
}

// MARK: - API 响应包装
struct ReviewListResponse: Codable {
    let code: Int
    let message: String
    let data: [ReviewItem]
}

struct ReviewCompleteAPIResponse: Codable {
    let code: Int
    let message: String
    let data: ReviewCompleteResponse
}

struct ReviewStatisticsResponse: Codable {
    let code: Int
    let message: String
    let data: ReviewStatistics
}

// MARK: - Mock 数据扩展
extension ReviewItem {
    static var mockData: [ReviewItem] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return [
            ReviewItem(
                id: "review-1",
                userId: 1,
                sectionId: "section-1",
                bookId: "lunyu",
                chapterId: "xueer",
                firstLearnedAt: formatter.string(from: Date().addingTimeInterval(-604800)),
                lastReviewedAt: formatter.string(from: Date().addingTimeInterval(-86400)),
                nextReviewAt: formatter.string(from: Date()),
                reviewCount: 3,
                reviewInterval: 7,
                masteryLevel: "learning",
                difficulty: 2.5,
                isCompleted: false,
                created_at: formatter.string(from: Date().addingTimeInterval(-604800)),
                updated_at: formatter.string(from: Date().addingTimeInterval(-86400)),
                section: SectionDetail(
                    id: "section-1",
                    bookId: "lunyu",
                    chapterId: "xueer",
                    sectionId: 1,
                    original: "子曰：「学而时习之，不亦说乎？有朋自远方来，不亦乐乎？人不知而不愠，不亦君子乎？」",
                    pinyin: "zi3 yue1...",
                    translation: "孔子说：学习并时常温习，不也很愉快吗？",
                    annotation: "字词解释...",
                    audioUrl: nil,
                    audioDuration: nil,
                    order: 1,
                    created_at: formatter.string(from: Date()),
                    updated_at: formatter.string(from: Date())
                )
            ),
            ReviewItem(
                id: "review-2",
                userId: 1,
                sectionId: "section-2",
                bookId: "lunyu",
                chapterId: "xueer",
                firstLearnedAt: formatter.string(from: Date().addingTimeInterval(-259200)),
                lastReviewedAt: formatter.string(from: Date().addingTimeInterval(-86400)),
                nextReviewAt: formatter.string(from: Date()),
                reviewCount: 2,
                reviewInterval: 3,
                masteryLevel: "learning",
                difficulty: 2.5,
                isCompleted: false,
                created_at: formatter.string(from: Date().addingTimeInterval(-259200)),
                updated_at: formatter.string(from: Date().addingTimeInterval(-86400)),
                section: SectionDetail(
                    id: "section-2",
                    bookId: "lunyu",
                    chapterId: "xueer",
                    sectionId: 2,
                    original: "有子曰：「其为人也孝弟，而好犯上者，鲜矣；不好犯上，而好作乱者，未之有也。」",
                    pinyin: "you3 zi3 yue1...",
                    translation: "有子说：孝顺父母、敬爱兄长的人，却喜欢冒犯上级的，很少见...",
                    annotation: "字词解释...",
                    audioUrl: nil,
                    audioDuration: nil,
                    order: 2,
                    created_at: formatter.string(from: Date()),
                    updated_at: formatter.string(from: Date())
                )
            ),
            ReviewItem(
                id: "review-3",
                userId: 1,
                sectionId: "section-3",
                bookId: "daodejing",
                chapterId: "chapter-1",
                firstLearnedAt: formatter.string(from: Date().addingTimeInterval(-86400)),
                lastReviewedAt: nil,
                nextReviewAt: formatter.string(from: Date().addingTimeInterval(86400)),
                reviewCount: 1,
                reviewInterval: 1,
                masteryLevel: "learning",
                difficulty: 2.5,
                isCompleted: false,
                created_at: formatter.string(from: Date().addingTimeInterval(-86400)),
                updated_at: formatter.string(from: Date().addingTimeInterval(-86400)),
                section: SectionDetail(
                    id: "section-3",
                    bookId: "daodejing",
                    chapterId: "chapter-1",
                    sectionId: 1,
                    original: "道可道，非常道；名可名，非常名。无名天地之始，有名万物之母。",
                    pinyin: "dao4 ke3 dao4...",
                    translation: "可以说出来的道，就不是永恒的道...",
                    annotation: "字词解释...",
                    audioUrl: nil,
                    audioDuration: nil,
                    order: 1,
                    created_at: formatter.string(from: Date()),
                    updated_at: formatter.string(from: Date())
                )
            )
        ]
    }
}

extension ReviewStats {
    static var mockData: ReviewStats {
        ReviewStats(
            totalReviews: 42,
            averageQuality: 4.2,
            consecutiveDays: 7,
            weeklyReviews: [3, 5, 8, 6, 9, 7, 4],
            qualityDistribution: [2, 5, 8, 15, 12]
        )
    }
}

// MARK: - 复习计划标记（用于阅读页面显示）
struct ReviewPlanMark: Identifiable, Codable {
    let id: String
    let text: String
    let range: NSRange
    let nextReviewAt: String
    let reviewCount: Int
    let isCompleted: Bool  // 是否已完成复习

    var nextReviewDate: Date? {
        ISO8601DateFormatter().date(from: nextReviewAt)
    }

    var isDue: Bool {
        guard let reviewDate = nextReviewDate else { return false }
        return reviewDate <= Date()
    }

    enum CodingKeys: String, CodingKey {
        case id, text, nextReviewAt, reviewCount, isCompleted
        case rangeLocation = "range_location"
        case rangeLength = "range_length"
    }

    init(id: String, text: String, range: NSRange, nextReviewAt: String, reviewCount: Int, isCompleted: Bool = false) {
        self.id = id
        self.text = text
        self.range = range
        self.nextReviewAt = nextReviewAt
        self.reviewCount = reviewCount
        self.isCompleted = isCompleted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        nextReviewAt = try container.decode(String.self, forKey: .nextReviewAt)
        reviewCount = try container.decode(Int.self, forKey: .reviewCount)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        let location = try container.decode(Int.self, forKey: .rangeLocation)
        let length = try container.decode(Int.self, forKey: .rangeLength)
        range = NSRange(location: location, length: length)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(nextReviewAt, forKey: .nextReviewAt)
        try container.encode(reviewCount, forKey: .reviewCount)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(range.location, forKey: .rangeLocation)
        try container.encode(range.length, forKey: .rangeLength)
    }
}

