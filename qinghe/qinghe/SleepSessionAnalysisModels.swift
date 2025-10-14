//
//  SleepSessionAnalysisModels.swift
//  qinghe
//
//  Created on 2025-10-09
//  单次睡眠会话分析数据模型
//

import Foundation

// MARK: - 单次会话分析响应

/// 单次会话质量分析响应
struct SingleSessionQualityResponse: Codable {
    let status: String
    let data: SingleSessionQualityData
}

/// 单次会话质量分析数据
struct SingleSessionQualityData: Codable {
    let sessionId: String
    let qualityAnalysis: SessionQualityAnalysis
}

/// 会话质量分析详情
struct SessionQualityAnalysis: Codable {
    let overallScore: Int
    let qualityLevel: String
    let keyMetrics: SessionKeyMetrics
    let insights: [SessionInsight]
    let recommendations: [SessionRecommendation]
}

/// 会话关键指标
struct SessionKeyMetrics: Codable {
    let sleepEfficiency: String
    let deepSleepPercentage: String
    let remSleepPercentage: String
    let sleepLatency: Int
}

/// 会话洞察
struct SessionInsight: Codable {
    let type: String  // warning, info, success
    let title: String
    let description: String
}

/// 会话建议
struct SessionRecommendation: Codable {
    let text: String
    let priority: String  // high, medium, low
    let description: String
}

// MARK: - 质量等级扩展

extension SessionQualityAnalysis {
    /// 获取质量等级的中文文本
    var qualityLevelText: String {
        switch qualityLevel {
        case "excellent":
            return "优秀"
        case "good":
            return "良好"
        case "fair":
            return "一般"
        case "poor":
            return "较差"
        default:
            return "未知"
        }
    }
    
    /// 获取质量等级对应的颜色
    var qualityColor: (red: Double, green: Double, blue: Double) {
        switch qualityLevel {
        case "excellent":
            return (0.2, 0.8, 0.4)  // 绿色
        case "good":
            return (0.3, 0.6, 1.0)  // 蓝色
        case "fair":
            return (1.0, 0.6, 0.2)  // 橙色
        case "poor":
            return (1.0, 0.3, 0.3)  // 红色
        default:
            return (0.5, 0.5, 0.5)  // 灰色
        }
    }
    
    /// 获取质量等级对应的图标
    var qualityIcon: String {
        switch qualityLevel {
        case "excellent":
            return "star.fill"
        case "good":
            return "checkmark.circle.fill"
        case "fair":
            return "moon.fill"
        case "poor":
            return "exclamationmark.triangle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - 洞察类型扩展

extension SessionInsight {
    /// 获取洞察类型对应的图标
    var iconName: String {
        switch type {
        case "warning":
            return "exclamationmark.triangle.fill"
        case "info":
            return "info.circle.fill"
        case "success":
            return "checkmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    /// 获取洞察类型对应的颜色
    var iconColor: (red: Double, green: Double, blue: Double) {
        switch type {
        case "warning":
            return (1.0, 0.6, 0.2)  // 橙色
        case "info":
            return (0.3, 0.6, 1.0)  // 蓝色
        case "success":
            return (0.2, 0.8, 0.4)  // 绿色
        default:
            return (0.5, 0.5, 0.5)  // 灰色
        }
    }
}

// MARK: - 建议优先级扩展

extension SessionRecommendation {
    /// 获取优先级对应的图标
    var priorityIcon: String {
        switch priority {
        case "high":
            return "exclamationmark.circle.fill"
        case "medium":
            return "info.circle.fill"
        case "low":
            return "checkmark.circle.fill"
        default:
            return "circle.fill"
        }
    }
    
    /// 获取优先级对应的颜色
    var priorityColor: (red: Double, green: Double, blue: Double) {
        switch priority {
        case "high":
            return (1.0, 0.3, 0.3)  // 红色
        case "medium":
            return (1.0, 0.6, 0.2)  // 橙色
        case "low":
            return (0.2, 0.8, 0.4)  // 绿色
        default:
            return (0.5, 0.5, 0.5)  // 灰色
        }
    }
}


