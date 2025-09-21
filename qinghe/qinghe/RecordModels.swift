import SwiftUI
import Foundation

// MARK: - 扩展现有的情绪类型
extension EmotionType {
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .excited: return "🤩"
        case .calm: return "😌"
        case .frustrated: return "😞"
        case .content: return "😌"
        }
    }
    
    var chineseDisplayName: String {
        switch self {
        case .happy: return "开心"
        case .sad: return "悲伤"
        case .angry: return "愤怒"
        case .anxious: return "焦虑"
        case .excited: return "兴奋"
        case .calm: return "平静"
        case .frustrated: return "沮丧"
        case .content: return "满足"
        }
    }
}

// MARK: - 扩展现有的诱惑类型
extension TemptationType {
    var emoji: String {
        switch self {
        case .smoking: return "🚬"
        case .drinking: return "🍺"
        case .stayingUp: return "🌙"
        case .phoneScrolling: return "📱"
        case .junkFood: return "🍔"
        case .shopping: return "🛒"
        case .gaming: return "🎮"
        case .socialMedia: return "📱"
        }
    }
    
    var color: Color {
        switch self {
        case .smoking: return .red
        case .drinking: return .orange
        case .stayingUp: return .purple
        case .phoneScrolling: return .cyan
        case .junkFood: return .brown
        case .shopping: return .pink
        case .gaming: return .blue
        case .socialMedia: return .green
        }
    }
}

// MARK: - 扩展现有的抵抗结果类型
extension ResistanceResult {
    var emoji: String {
        switch self {
        case .resisted: return "✅"
        case .failed: return "❌"
        }
    }
    
    var color: Color {
        switch self {
        case .resisted: return .green
        case .failed: return .red
        }
    }
    
    var description: String {
        switch self {
        case .resisted: return "成功抵抗"
        case .failed: return "未能抵抗"
        }
    }
}

// MARK: - 情绪记录请求模型
struct EmotionRecordRequest: Codable {
    let type: String
    let intensity: Int
    let trigger: String?
    let note: String?
    let tags: [String]?
    let weather: String?
    let recordedAt: String?
}

// MARK: - 诱惑记录请求模型
struct TemptationRecordRequest: Codable {
    let type: String
    let intensity: Int
    let result: String
    let note: String?
    let strategies: [String]?
    let recordTime: String?
}

// MARK: - 情绪记录 ViewModel
@MainActor
class EmotionRecordViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let emotionService = EmotionService.shared
    
    /// 保存情绪记录
    func saveEmotionRecord(_ request: EmotionRecordRequest) async {
        isLoading = true
        
        do {
            // 使用现有的 EmotionService 创建情绪记录
            let emotionRequest = EmotionRequestNew(
                type: request.type,
                intensity: request.intensity,
                note: request.note,
                tags: request.tags,
                trigger: request.trigger,
                recordTime: request.recordedAt
            )

            let _ = try await emotionService.createEmotion(emotionRequest)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - 诱惑记录 ViewModel
@MainActor
class TemptationRecordViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let temptationService = TemptationService.shared
    
    /// 保存诱惑记录
    func saveTemptationRecord(_ request: TemptationRecordRequest) async {
        isLoading = true
        
        do {
            // 使用现有的 TemptationService 创建诱惑记录
            let temptationRequest = TemptationRequestNew(
                type: request.type,
                intensity: request.intensity,
                result: request.result,
                note: request.note,
                strategies: request.strategies,
                recordTime: request.recordTime
            )

            let _ = try await temptationService.createTemptation(temptationRequest)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - 扩展的诱惑类型（包含更多类型）
enum ExtendedTemptationType: String, CaseIterable, Codable {
    case smoking = "抽烟"
    case drinking = "喝酒"
    case stayingUpLate = "熬夜"
    case overeating = "暴饮暴食"
    case shoppingImpulse = "购物冲动"
    case gameAddiction = "游戏沉迷"
    case phoneScrolling = "刷手机"
    case procrastination = "拖延症"
    case snacking = "吃零食"
    case other = "其他"
    
    var emoji: String {
        switch self {
        case .smoking: return "🚬"
        case .drinking: return "🍺"
        case .stayingUpLate: return "🌙"
        case .overeating: return "🍔"
        case .shoppingImpulse: return "🛒"
        case .gameAddiction: return "🎮"
        case .phoneScrolling: return "📱"
        case .procrastination: return "⏰"
        case .snacking: return "🍿"
        case .other: return "❓"
        }
    }
    
    var color: Color {
        switch self {
        case .smoking: return .red
        case .drinking: return .orange
        case .stayingUpLate: return .purple
        case .overeating: return .brown
        case .shoppingImpulse: return .pink
        case .gameAddiction: return .blue
        case .phoneScrolling: return .cyan
        case .procrastination: return .yellow
        case .snacking: return .green
        case .other: return .gray
        }
    }
}

// MARK: - 扩展的情绪类型（包含更多类型）
enum ExtendedEmotionType: String, CaseIterable, Codable {
    case happy = "开心"
    case sad = "悲伤"
    case upset = "难过"
    case angry = "愤怒"
    case anxious = "焦虑"
    case calm = "平静"
    case excited = "兴奋"
    case depressed = "沮丧"
    case nervous = "紧张"
    case relaxed = "放松"
    case satisfied = "满足"
    case confused = "困惑"
    case other = "其他"
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .upset: return "😔"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .calm: return "😌"
        case .excited: return "🤩"
        case .depressed: return "😞"
        case .nervous: return "😬"
        case .relaxed: return "😎"
        case .satisfied: return "😌"
        case .confused: return "😕"
        case .other: return "🤔"
        }
    }
    
    var color: Color {
        switch self {
        case .happy: return .yellow
        case .sad: return .blue
        case .upset: return .indigo
        case .angry: return .red
        case .anxious: return .orange
        case .calm: return .green
        case .excited: return .pink
        case .depressed: return .purple
        case .nervous: return .orange
        case .relaxed: return .mint
        case .satisfied: return .green
        case .confused: return .gray
        case .other: return .secondary
        }
    }
}
