import Foundation
import SwiftUI

// MARK: - 图片上传响应模型
struct HealthImageUploadResponse: Codable {
    let success: Bool
    let data: HealthImageData
    let message: String?
    
    struct HealthImageData: Codable {
        let url: String
        let thumbnails: Thumbnails?
        let filename: String
        let originalName: String?
        let size: Int
        let mimetype: String
        let provider: String?
        let metadata: ImageMetadata?
        let category: String?
        
        struct Thumbnails: Codable {
            let small: String?
            let medium: String?
            let large: String?
        }
        
        struct ImageMetadata: Codable {
            let width: Int?
            let height: Int?
            let format: String?
        }
    }
}

// MARK: - 舌诊面诊响应模型（实际API格式）
struct ActualAnalysisResponse: Codable {
    let code: Int
    let success: Bool
    let msg: String
    let data: AnalysisData
    
    struct AnalysisData: Codable {
        let score: Int
        let physiqueName: String
        let physiqueAnalysis: String
        let typicalSymptom: String
        let riskWarning: String
        let features: [Feature]
        let syndromeName: String
        let syndromeIntroduction: String
        let tfDetectMatches: TfDetectMatches?
        let physiqueDistribution: [PhysiqueDistribution]
        let primaryConstitution: ConstitutionItem?
        let secondaryConstitutions: [ConstitutionItem]
        let tongueDetails: TongueDetails? // 可选，仅舌诊返回
        let advices: [String: AdviceValue] // 简化为字符串或数组
        let goods: [String]
        let originalImageUrl: String
        let analyzedAt: String
        let analysisStatus: String
        let apiProvider: String
        
        private enum CodingKeys: String, CodingKey {
            case score, features
            case physiqueName = "physique_name"
            case physiqueAnalysis = "physique_analysis"
            case typicalSymptom = "typical_symptom"
            case riskWarning = "risk_warning"
            case syndromeName = "syndrome_name"
            case syndromeIntroduction = "syndrome_introduction"
            case tfDetectMatches = "tf_detect_matches"
            case physiqueDistribution = "physique_distribution"
            case primaryConstitution, secondaryConstitutions, tongueDetails, advices, goods
            case originalImageUrl, analyzedAt, analysisStatus, apiProvider
        }
    }
    
    struct Feature: Codable {
        let name: String
        let value: String
        let desc: String
        let status: String
    }

    // 体质项：兼容字符串或对象两种格式
    struct ConstitutionItem: Codable {
        let name: String
        let score: Int?
        let confidence: Double?

        init(name: String, score: Int? = nil, confidence: Double? = nil) {
            self.name = name
            self.score = score
            self.confidence = confidence
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let name = try? container.decode(String.self) {
                self.init(name: name)
                return
            }
            if let obj = try? container.decode([String: CodableValue].self) {
                let name = obj["name"]?.string ?? "--"
                let score = obj["score"]?.int
                let confidence = obj["confidence"]?.double
                self.init(name: name, score: score, confidence: confidence)
                return
            }
            self.init(name: "--")
        }
    }

    // 小型动态解码辅助
    private struct CodableValue: Codable {
        let string: String?
        let int: Int?
        let double: Double?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let v = try? container.decode(String.self) { string = v; int = nil; double = nil; return }
            if let v = try? container.decode(Int.self) { string = nil; int = v; double = nil; return }
            if let v = try? container.decode(Double.self) { string = nil; int = nil; double = v; return }
            string = nil; int = nil; double = nil
        }
    }
    
    struct TfDetectMatches: Codable {
        let x: Double?
        let y: Double?
        let w: Double?
        let h: Double?
    }
    
    struct PhysiqueDistribution: Codable {
        let name: String
        let score: Int
    }
    
    struct TongueDetails: Codable {
        let bodyColor: String
        let coatingColor: String
        let coatingThickness: String
        let moisture: String
        let teethMarks: String
        let cracks: String
    }
}

// 用于处理动态建议结构的辅助类型
enum AdviceValue: Codable {
    case string(String)
    case stringArray([String])
    case dictionary([String: [String]])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([String].self) {
            self = .stringArray(arrayValue)
        } else if let dictValue = try? container.decode([String: [String]].self) {
            self = .dictionary(dictValue)
        } else {
            // 如果都失败了，尝试解析为空数组
            self = .stringArray([])
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .stringArray(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        }
    }
    
    var stringArray: [String]? {
        switch self {
        case .stringArray(let array):
            return array
        case .string(let string):
            return [string]
        default:
            return nil
        }
    }
    
    var dictionary: [String: [String]]? {
        switch self {
        case .dictionary(let dict):
            return dict
        default:
            return nil
        }
    }
}

// MARK: - 原有模型（向后兼容）
struct TongueAnalysisResponse: Codable {
    let analysisId: Int
    let analyzedAt: String
}

struct FaceAnalysisResponse: Codable {
    let analysisId: Int
    let analyzedAt: String
}

struct TongueAnalysisDetail: Codable {
    let id: String?
    let userId: Int?
    let originalImageUrl: String
    let analysisStatus: String
    let constitutionAnalysis: String?
    let tongueCharacteristics: String?
    let syndromeAnalysis: String?
    let treatmentAdvice: String?
    let primaryConstitution: String?
    let constitutionScore: String?
    let apiProvider: String?
    let analyzedAt: String
}

struct FaceAnalysisDetail: Codable {
    let id: String?
    let userId: Int?
    let originalImageUrl: String?
    let analysisStatus: String
    let constitutionAnalysis: String?
    let faceCharacteristics: String?
    let syndromeAnalysis: String?
    let treatmentAdvice: String?
    let primaryConstitution: String?
    let constitutionScore: String?
    let apiProvider: String?
    let analyzedAt: String
}

// MARK: - 历史记录响应模型
struct TongueHistoryRecord: Codable {
    let id: Int
    let originalImageUrl: String?
    let analysisStatus: String
    let analyzedAt: String?
    let created_at: String?
    let apiProvider: String?
    let constitutionAnalysis: String?
    let constitutionScore: String?
    let primaryConstitution: String?
    let treatmentAdvice: String?
    let syndromeAnalysis: String?
    
    // 自定义解码器处理 id 可能是 Int 或 String 的情况
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 尝试解析 id，支持 Int 或 String
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            self.id = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id),
                  let idInt = Int(idString) {
            self.id = idInt
        } else {
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "ID must be an Int or a String convertible to Int"
            ))
        }
        
        self.originalImageUrl = try? container.decode(String.self, forKey: .originalImageUrl)
        self.analysisStatus = try container.decode(String.self, forKey: .analysisStatus)
        self.analyzedAt = try? container.decode(String.self, forKey: .analyzedAt)
        self.created_at = try? container.decode(String.self, forKey: .created_at)
        self.apiProvider = try? container.decode(String.self, forKey: .apiProvider)
        self.constitutionAnalysis = try? container.decode(String.self, forKey: .constitutionAnalysis)
        self.constitutionScore = try? container.decode(String.self, forKey: .constitutionScore)
        self.primaryConstitution = try? container.decode(String.self, forKey: .primaryConstitution)
        self.treatmentAdvice = try? container.decode(String.self, forKey: .treatmentAdvice)
        self.syndromeAnalysis = try? container.decode(String.self, forKey: .syndromeAnalysis)
    }
}

struct FaceHistoryRecord: Codable {
    let id: Int
    let originalImageUrl: String?
    let analysisStatus: String
    let analyzedAt: String?
    let created_at: String?
    let apiProvider: String?
    let constitutionAnalysis: String?
    let constitutionScore: String?
    let primaryConstitution: String?
    let treatmentAdvice: String?
    let syndromeAnalysis: String?
    
    // 自定义解码器处理 id 可能是 Int 或 String 的情况
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 尝试解析 id，支持 Int 或 String
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            self.id = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id),
                  let idInt = Int(idString) {
            self.id = idInt
        } else {
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "ID must be an Int or a String convertible to Int"
            ))
        }
        
        self.originalImageUrl = try? container.decode(String.self, forKey: .originalImageUrl)
        self.analysisStatus = try container.decode(String.self, forKey: .analysisStatus)
        self.analyzedAt = try? container.decode(String.self, forKey: .analyzedAt)
        self.created_at = try? container.decode(String.self, forKey: .created_at)
        self.apiProvider = try? container.decode(String.self, forKey: .apiProvider)
        self.constitutionAnalysis = try? container.decode(String.self, forKey: .constitutionAnalysis)
        self.constitutionScore = try? container.decode(String.self, forKey: .constitutionScore)
        self.primaryConstitution = try? container.decode(String.self, forKey: .primaryConstitution)
        self.treatmentAdvice = try? container.decode(String.self, forKey: .treatmentAdvice)
        self.syndromeAnalysis = try? container.decode(String.self, forKey: .syndromeAnalysis)
    }
}

struct HistoryResponse<T: Codable>: Codable {
    let success: Bool
    let data: HistoryData<T>
    
    struct HistoryData<T: Codable>: Codable {
        let records: [T]
        let page: Int?
        let limit: Int?
    }
}

// MARK: - 健康档案API响应模型
struct HealthAPIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

// MARK: - 健康档案模型
struct HealthProfile: Codable {
    let userId: Int?
    let height: Double?
    let weight: Double?
    let bloodType: String?
    let primaryConstitution: String?
    let overallHealthScore: Int?
    let healthLevel: String?
    let lastUpdated: String?
    
    // 用于解析API返回的复杂健康档案数据
    let id: String?
    let secondaryConstitution: String?
    let constitutionScore: String?
    let healthMetrics: HealthMetrics?
    let latestTongueAnalysis: LatestAnalysis?
    let latestFaceAnalysis: LatestAnalysis?
    let fiveElementsMatch: FiveElementsMatch?
    
    private enum CodingKeys: String, CodingKey {
        case userId, height, weight, bloodType, primaryConstitution
        case overallHealthScore, healthLevel, lastUpdated
        case id, secondaryConstitution, constitutionScore
        case healthMetrics, latestTongueAnalysis, latestFaceAnalysis, fiveElementsMatch
    }
    
    // Memberwise initializer
    init(userId: Int? = nil,
         height: Double? = nil,
         weight: Double? = nil,
         bloodType: String? = nil,
         primaryConstitution: String? = nil,
         overallHealthScore: Int? = nil,
         healthLevel: String? = nil,
         lastUpdated: String? = nil,
         id: String? = nil,
         secondaryConstitution: String? = nil,
         constitutionScore: String? = nil,
         healthMetrics: HealthMetrics? = nil,
         latestTongueAnalysis: LatestAnalysis? = nil,
         latestFaceAnalysis: LatestAnalysis? = nil,
         fiveElementsMatch: FiveElementsMatch? = nil) {
        self.userId = userId
        self.height = height
        self.weight = weight
        self.bloodType = bloodType
        self.primaryConstitution = primaryConstitution
        self.overallHealthScore = overallHealthScore
        self.healthLevel = healthLevel
        self.lastUpdated = lastUpdated
        self.id = id
        self.secondaryConstitution = secondaryConstitution
        self.constitutionScore = constitutionScore
        self.healthMetrics = healthMetrics
        self.latestTongueAnalysis = latestTongueAnalysis
        self.latestFaceAnalysis = latestFaceAnalysis
        self.fiveElementsMatch = fiveElementsMatch
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 基础字段
        self.userId = try? container.decode(Int.self, forKey: .userId)
        self.bloodType = try? container.decode(String.self, forKey: .bloodType)
        self.primaryConstitution = try? container.decode(String.self, forKey: .primaryConstitution)
        self.overallHealthScore = try? container.decode(Int.self, forKey: .overallHealthScore)
        self.healthLevel = try? container.decode(String.self, forKey: .healthLevel)
        self.lastUpdated = try? container.decode(String.self, forKey: .lastUpdated)
        
        // 兼容height字段：可能是字符串或数字
        if let doubleVal = try? container.decode(Double.self, forKey: .height) {
            self.height = doubleVal
        } else if let stringVal = try? container.decode(String.self, forKey: .height), 
                  let doubleVal = Double(stringVal) {
            self.height = doubleVal
        } else {
            self.height = nil
        }
        
        // 兼容weight字段：可能是字符串或数字
        if let doubleVal = try? container.decode(Double.self, forKey: .weight) {
            self.weight = doubleVal
        } else if let stringVal = try? container.decode(String.self, forKey: .weight),
                  let doubleVal = Double(stringVal) {
            self.weight = doubleVal
        } else {
            self.weight = nil
        }
        
        // 复杂数据字段
        self.id = try? container.decode(String.self, forKey: .id)
        self.secondaryConstitution = try? container.decode(String.self, forKey: .secondaryConstitution)
        self.constitutionScore = try? container.decode(String.self, forKey: .constitutionScore)
        self.healthMetrics = try? container.decode(HealthMetrics.self, forKey: .healthMetrics)
        self.latestTongueAnalysis = try? container.decode(LatestAnalysis.self, forKey: .latestTongueAnalysis)
        self.latestFaceAnalysis = try? container.decode(LatestAnalysis.self, forKey: .latestFaceAnalysis)
        self.fiveElementsMatch = try? container.decode(FiveElementsMatch.self, forKey: .fiveElementsMatch)
    }
    
    struct HealthMetrics: Codable {
        let age: Int?
        let bmi: Double?
        let gender: String?
        let sleepScore: Int?
        let overallScore: Int?
        let activityLevel: String?
        let exerciseScore: Int?
        let lastCalculated: String?
        let sleepQualityLevel: String?
        
        private enum CodingKeys: String, CodingKey {
            case age, bmi, gender, sleepScore, overallScore
            case activityLevel, exerciseScore, lastCalculated, sleepQualityLevel
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.age = try? container.decode(Int.self, forKey: .age)
            self.gender = try? container.decode(String.self, forKey: .gender)
            self.sleepScore = try? container.decode(Int.self, forKey: .sleepScore)
            self.overallScore = try? container.decode(Int.self, forKey: .overallScore)
            self.activityLevel = try? container.decode(String.self, forKey: .activityLevel)
            self.exerciseScore = try? container.decode(Int.self, forKey: .exerciseScore)
            self.lastCalculated = try? container.decode(String.self, forKey: .lastCalculated)
            self.sleepQualityLevel = try? container.decode(String.self, forKey: .sleepQualityLevel)
            
            // 兼容bmi字段：可能是字符串或数字
            if let doubleVal = try? container.decode(Double.self, forKey: .bmi) {
                self.bmi = doubleVal
            } else if let stringVal = try? container.decode(String.self, forKey: .bmi),
                      let doubleVal = Double(stringVal) {
                self.bmi = doubleVal
            } else {
                self.bmi = nil
            }
        }
    }
    
    struct LatestAnalysis: Codable {
        let analyzedAt: String?
    }
    
    struct FiveElementsMatch: Codable {
        let analysisId: Int?
        let lastUpdated: String?
        let analysisDate: String?
        let fiveMovements: FiveMovements?
        let sixQi: SixQi?
        
        struct FiveMovements: Codable {
            let nature: String?
            let element: String?
            let influence: String?
        }
        
        struct SixQi: Codable {
            let qi: String?
            let season: String?
            let influence: String?
        }
    }
}

// MARK: - 完整健康档案响应模型
struct ComprehensiveHealthProfile: Codable {
    let healthProfile: HealthProfile?
    let latestTongueAnalysis: TongueAnalysisDetail?
    let latestFaceAnalysis: FaceAnalysisDetail?
    
    struct TongueAnalysisDetail: Codable {
        let id: String?
        let userId: Int?
        let originalImageUrl: String?
        let analysisStatus: String?
        let constitutionAnalysis: ConstitutionAnalysis?
        let analyzedAt: String?
        
        struct ConstitutionAnalysis: Codable {
            let score: Int?
            let constitution: String?
            let syndrome: Syndrome?
            
            struct Syndrome: Codable {
                let name: String?
                let introduction: String?
            }
        }
    }
    
    struct FaceAnalysisDetail: Codable {
        let id: String?
        let userId: Int?
        let analysisStatus: String?
        let analyzedAt: String?
    }
}

// MARK: - 五运六气数据模型
struct FiveElementsAnalysis: Codable {
    let analysisId: Int?
    let currentSolarTerm: String? // 修改为字符串类型
    let fiveMovements: FiveMovements?
    let sixQi: SixQi?
    let personalizedAdvice: PersonalizedAdvice?
    let constitutionMatch: ConstitutionMatch?
    let userConstitution: String?
    // 服务器额外返回的数据（可选解析，避免类型不匹配导致解码失败）
    let hostGuestMovements: HostGuestMovements?
    let hostGuestQi: HostGuestQi?
    let qiMovementCombination: QiMovementCombination?
    let lunarInfo: LunarInfo?
    let solarTermCharacteristics: SolarTermCharacteristics?
    
    struct FiveMovements: Codable {
        let element: String?
        let nature: String?
        let influence: String?
        let characteristics: Characteristics?
        
        struct Characteristics: Codable {
            let traits: [String]?
            let symptoms: [String]?
        }
    }
    
    struct SixQi: Codable {
        let qi: String?
        let season: String?
        let influence: String?
        let characteristics: Characteristics?
        
        struct Characteristics: Codable {
            let nature: String?
            let traits: [String]?
            let organs: [String]?
        }
    }

    // MARK: - 个性化建议（对象）
    struct PersonalizedAdvice: Codable {
        let dietTherapy: DietTherapy?
        let diseaseRiskPrediction: DiseaseRiskPrediction?
        let emotionalCare: EmotionalCare?
        let exerciseAdvice: ExerciseAdvice?
        let healthTips: HealthTips?
        let lifestyleAdvice: LifestyleAdvice?

        struct DietTherapy: Codable {
            let comprehensive: [String]?
            let constitutionBased: [String]?
            let relationBased: [String]?
            let seasonal: [String]?

            enum CodingKeys: String, CodingKey {
                case comprehensive
                case constitutionBased = "constitution_based"
                case relationBased = "relation_based"
                case seasonal
            }
        }

        struct DiseaseRiskPrediction: Codable {
            let constitutionRisks: [String]?
            let preventionAdvice: [String]?
            let relationRisks: [String]?
            let seasonalRisks: [String]?

            enum CodingKeys: String, CodingKey {
                case constitutionRisks = "constitution_risks"
                case preventionAdvice = "prevention_advice"
                case relationRisks = "relation_risks"
                case seasonalRisks = "seasonal_risks"
            }
        }

        struct EmotionalCare: Codable {
            let constitutionAdvice: [String]?
            let meditation: [String]?
            let musicTherapy: [String]?
            let seasonalAdvice: [String]?

            enum CodingKeys: String, CodingKey {
                case constitutionAdvice = "constitution_advice"
                case meditation
                case musicTherapy = "music_therapy"
                case seasonalAdvice = "seasonal_advice"
            }
        }

        struct ExerciseAdvice: Codable {
            let constitutionBased: [String]?
            let intensity: String?
            let recommendedTime: String?
            let seasonal: [String]?

            enum CodingKeys: String, CodingKey {
                case constitutionBased = "constitution_based"
                case intensity
                case recommendedTime = "recommended_time"
                case seasonal
            }
        }

        struct HealthTips: Codable {
            let constitutionTips: [String]?
            let dailyTips: [String]?
            let fiveElementsTips: [String]?
            let seasonalTips: [String]?

            enum CodingKeys: String, CodingKey {
                case constitutionTips = "constitution_tips"
                case dailyTips = "daily_tips"
                case fiveElementsTips = "five_elements_tips"
                case seasonalTips = "seasonal_tips"
            }
        }

        struct LifestyleAdvice: Codable {
            let dailyRoutine: [String]?
            let environment: [String]?
            let seasonalCare: [String]?
            let sleepSchedule: String?

            enum CodingKeys: String, CodingKey {
                case dailyRoutine = "daily_routine"
                case environment
                case seasonalCare = "seasonal_care"
                case sleepSchedule = "sleep_schedule"
            }
        }
    }

    // MARK: - 体质与运气匹配（对象）
    struct ConstitutionMatch: Codable {
        let constitution: String?
        let constitutionElement: String?
        let overallLevel: String?
        let overallScore: Int?
        let recommendations: [String]?
        let movementMatch: MatchDetail?
        let qiMatch: MatchDetail?

        struct MatchDetail: Codable {
            let element: String?
            let relation: String?
            let score: Int?
            let description: String?
        }
    }

    // MARK: - 主客运（可选）
    struct HostGuestMovements: Codable {
        let guestMovement: MovementDetail?
        let hostMovements: [HostMovement]?

        struct MovementDetail: Codable {
            let element: String?
            let influence: String?
            let nature: String?
        }

        struct HostMovement: Codable {
            let duration: String?
            let element: String?
            let nature: String?
            let period: String?
        }
    }

    // MARK: - 主客气（可选）
    struct HostGuestQi: Codable {
        let guestQi: GuestQiDetail?
        let hostQi: [HostQiItem]?

        struct GuestQiDetail: Codable {
            let name: String?
            let influence: String?
            let characteristics: Characteristics?

            struct Characteristics: Codable {
                let nature: String?
                let organs: [String]?
                let traits: [String]?
            }
        }

        struct HostQiItem: Codable {
            let name: String?
            let period: String?
            let season: String?
        }
    }

    // MARK: - 运气组合影响（可选）
    struct QiMovementCombination: Codable {
        let movementElement: String?
        let qiElement: String?
        let relation: Relation?
        let healthImpact: HealthImpact?
        let influence: String?

        struct Relation: Codable {
            let type: String?
            let description: String?
        }

        struct HealthImpact: Codable {
            let level: String?
            let advice: String?
        }
    }

    // MARK: - 农历信息（可选）
    struct LunarInfo: Codable {
        let year: Int?
        let month: Int?
        let day: Int?
        let yearStem: String?
        let yearBranch: String?
        let monthStem: String?
        let monthBranch: String?
        let dayStem: String?
        let dayBranch: String?
    }

    // MARK: - 节气特征（可选）
    struct SolarTermCharacteristics: Codable {
        let element: String?
        let nature: String?
        let advice: String?
    }
}

// MARK: - 健康档案数据管理器
@MainActor
final class HealthProfileDataManager: ObservableObject {
    static let shared = HealthProfileDataManager()
    
    @Published var healthProfile: HealthProfile?
    @Published var comprehensiveProfile: ComprehensiveHealthProfile?
    @Published var fiveElementsAnalysis: FiveElementsAnalysis?
    @Published var healthReport: HealthReport?
    @Published var isLoading: Bool = false
    @Published var lastUpdateTime: Date?
    @Published var lastError: String?
    
    // 计算属性
    var primaryConstitution: String {
        // 最优先使用健康档案主字段的体质（这是API返回的权威数据）
        if let constitution = healthProfile?.primaryConstitution,
           !constitution.isEmpty && constitution != "unknown" {
            return constitution
        }
        // 备选:使用舌诊分析中的体质结果
        if let tongueConstitution = comprehensiveProfile?.latestTongueAnalysis?.constitutionAnalysis?.constitution {
            return tongueConstitution
        }
        return "--"
    }
    
    var overallHealthScore: Int {
        // 优先使用健康档案中的评分
        if let score = healthProfile?.overallHealthScore {
            return score
        }
        // 备选:使用健康指标中的总分
        if let score = healthProfile?.healthMetrics?.overallScore {
            return score
        }
        return 0
    }
    
    var healthLevel: String {
        // 使用健康档案中的健康等级
        let level = healthProfile?.healthLevel
        switch level {
        case "excellent": return "优秀"
        case "good": return "良好" 
        case "fair": return "一般"
        case "poor": return "较差"
        default: return "--"
        }
    }
    
    var currentSolarTerm: String {
        // 使用五运六气分析中的节气信息
        if let term = fiveElementsAnalysis?.currentSolarTerm {
            let df = DateFormatter()
            df.dateFormat = "MM-dd"
            df.locale = Locale(identifier: "zh_CN")
            return "\(term) · \(df.string(from: Date()))"
        }
        return SolarTermCalculator.currentTerm(for: Date()).chineseAssetName
    }
    
    var fiveMovementsText: String {
        // 使用五运六气分析
        if let movements = fiveElementsAnalysis?.fiveMovements {
            let element = movements.element ?? "未知"
            let nature = movements.nature ?? "未知"
            return "\(element)运\(nature) / 当前 \(element)运"
        }
        return "金运不及 / 当前 金运"
    }
    
    var sixQiText: String {
        // 使用五运六气分析
        if let qi = fiveElementsAnalysis?.sixQi {
            let qiName = qi.qi ?? "未知"
            let season = qi.season ?? "未知"
            return "主气：\(qiName) · 客气：\(season)"
        }
        return "主气：厥阴风木 · 客气：立夏"
    }
    
    private init() {}
    
    // MARK: - API 调用方法
    
    /// 获取基础健康档案
    func fetchHealthProfile() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        do {
            let response: HealthAPIResponse<ComprehensiveHealthProfile> = try await NetworkManager.shared.get(
                endpoint: "/health/profile",
                parameters: nil,
                headers: nil,
                responseType: HealthAPIResponse<ComprehensiveHealthProfile>.self
            )
            
            if response.success, let data = response.data {
                comprehensiveProfile = data
                healthProfile = data.healthProfile
                lastUpdateTime = Date()
                
                // 【调试日志】打印数据来源和最终显示的体质
                let apiConstitution = data.healthProfile?.primaryConstitution ?? "nil"
                let displayedConstitution = primaryConstitution
                print("✅ 健康档案获取成功")
                print("   📥 API返回体质: \(apiConstitution)")
                print("   📺 最终显示体质: \(displayedConstitution)")
                if apiConstitution != displayedConstitution {
                    print("   ⚠️  注意:显示体质与API返回不一致,可能使用了其他数据源")
                }
            } else {
                lastError = response.error ?? response.message ?? "获取健康档案失败"
                print("❌ 健康档案获取失败: \(lastError ?? "未知错误")")
            }
        } catch {
            lastError = error.localizedDescription
            print("❌ 健康档案获取异常: \(error)")
            // 设置默认值以避免界面异常
            healthProfile = HealthProfile(
                userId: nil,
                height: nil,
                weight: nil,
                bloodType: nil,
                primaryConstitution: nil,
                overallHealthScore: nil,
                healthLevel: nil,
                lastUpdated: nil,
                id: nil,
                secondaryConstitution: nil,
                constitutionScore: nil,
                healthMetrics: nil,
                latestTongueAnalysis: nil,
                latestFaceAnalysis: nil,
                fiveElementsMatch: nil
            )
        }
    }
    
    /// 获取完整健康档案
    func fetchComprehensiveProfile() async {
        // 实际上基础API已经返回了完整信息，直接调用基础方法
        await fetchHealthProfile()
    }
    
    /// 获取五运六气分析
    func fetchFiveElementsAnalysis() async {
        do {
            let response: HealthAPIResponse<FiveElementsAnalysis> = try await NetworkManager.shared.get(
                endpoint: "/health/five-elements/current",
                parameters: nil,
                headers: nil,
                responseType: HealthAPIResponse<FiveElementsAnalysis>.self
            )
            
            if response.success, let data = response.data {
                fiveElementsAnalysis = data
                print("✅ 五运六气分析获取成功")
            } else {
                print("❌ 五运六气分析获取失败: \(response.error ?? response.message ?? "未知错误")")
            }
        } catch {
            print("❌ 五运六气分析获取异常: \(error)")
        }
    }
    
    /// 生成健康报告
    func generateHealthReport() async {
        // 🔧 乐观更新：立即在日历上标记今天有报告
        let today = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current // 确保使用本地时区
        let todayStart = calendar.startOfDay(for: today)
        
        print("🔄 HealthProfileDataManager 乐观更新日期: \(formatDateForAPI(todayStart))")
        
        // 通知 HealthReportManager 进行乐观更新
        await HealthReportManager.shared.optimisticallyAddReportDate(todayStart)
        
        do {
            let response: HealthAPIResponse<HealthReport> = try await NetworkManager.shared.post(
                endpoint: "/health/report/generate",
                parameters: ["reportType": "comprehensive"],
                headers: nil,
                responseType: HealthAPIResponse<HealthReport>.self
            )
            
            if response.success, let data = response.data {
                healthReport = data
                print("✅ 健康报告生成成功: \(data.reportId)")
                
                // 🔧 确认报告生成成功，通知 HealthReportManager 确认日期
                if let reportId = data.reportId {
                    await HealthReportManager.shared.confirmReportDate(todayStart, reportId: reportId)
                } else {
                    print("⚠️ 报告生成成功但reportId为空")
                }
                
                // 重新加载可用日期以保持与后端同步
                await HealthReportManager.shared.loadAvailableReportDates()
            } else {
                lastError = response.error ?? response.message ?? "生成健康报告失败"
                print("❌ 健康报告生成失败: \(lastError ?? "未知错误")")
                
                // 🔧 生成失败，回滚乐观更新
                await HealthReportManager.shared.rollbackOptimisticUpdate(todayStart)
            }
        } catch {
            lastError = error.localizedDescription
            print("❌ 健康报告生成异常: \(error)")
            
            // 🔧 异常情况，回滚乐观更新
            await HealthReportManager.shared.rollbackOptimisticUpdate(todayStart)
        }
    }
    
    // MARK: - 辅助方法
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    /// 获取健康报告历史
    func fetchHealthReportHistory() async {
        do {
            let response: HealthAPIResponse<HealthReportHistory> = try await NetworkManager.shared.get(
                endpoint: "/health/report/history",
                parameters: nil,
                headers: nil,
                responseType: HealthAPIResponse<HealthReportHistory>.self
            )
            
            if response.success, let data = response.data {
                print("✅ 健康报告历史获取成功: \(data.reports.count) 条记录")
            } else {
                print("❌ 健康报告历史获取失败: \(response.error ?? response.message ?? "未知错误")")
            }
        } catch {
            print("❌ 健康报告历史获取异常: \(error)")
        }
    }
    
    /// 刷新所有数据
    func refreshAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchHealthProfile()
            }
            group.addTask {
                await self.fetchFiveElementsAnalysis()
            }
            group.addTask {
                await self.generateHealthReport()
            }
        }
    }
}

// MARK: - 健康报告模型（超简化版，只解析核心字段）
struct HealthReport: Codable {
    let reportId: String?
    let reportType: String?
    let generatedAt: String?
    let healthOverview: HealthOverview?
    let detailedAnalysis: DetailedAnalysis?
    
    struct HealthOverview: Codable {
        let overallScore: Int?
        let healthLevel: String?
        let primaryConstitution: String?
        let currentSolarTerm: String?
    }
    
    struct DetailedAnalysis: Codable {
        let constitution: ConstitutionAnalysis?
        let fiveElements: FiveElementsAnalysis?
        let healthMetrics: HealthMetrics?
        
        struct ConstitutionAnalysis: Codable {
            let primaryConstitution: String?
            let secondaryConstitution: String?
            let analyzedAt: String?
            let confidence: Double?
            let score: Int?
            let physiqueAnalysis: String?
            let recommendations: [String]?
            
            // 使用自定义解析来处理不同类型
            private enum CodingKeys: String, CodingKey {
                case primaryConstitution, secondaryConstitution, analyzedAt, confidence, score, physiqueAnalysis, recommendations
            }
        }
        
        struct FiveElementsAnalysis: Codable {
            let currentSolarTerm: String?
            let fiveMovements: FiveMovements?
            let sixQi: SixQi?
            
            struct FiveMovements: Codable {
                let element: String?
                let nature: String?
                let influence: String?
            }
            
            struct SixQi: Codable {
                let qi: String?
                let influence: String?
            }
        }
        
        struct HealthMetrics: Codable {
            let constitution: Int?
            let sleep: Int?
            let exercise: Int?
        }
    }
}

struct HealthReportHistory: Codable {
    let reports: [HealthReportItem]
    
    struct HealthReportItem: Codable {
        let reportId: String
        let reportType: String
        let generatedAt: String
        let overallScore: Int
        let healthLevel: String
        let summary: String
    }
}

// MARK: - 健康档案 API 服务
final class HealthProfileAPIService {
    static let shared = HealthProfileAPIService()

    private init() {}

    func getHealthProfile() async throws -> HealthProfile? {
        let response: HealthAPIResponse<HealthProfile> = try await NetworkManager.shared.get(
            endpoint: "/health/profile",
            parameters: nil,
            headers: nil,
            responseType: HealthAPIResponse<HealthProfile>.self
        )
        
        guard response.success else {
            throw NSError(domain: "HealthProfileAPI", code: 1, userInfo: [
                NSLocalizedDescriptionKey: response.error ?? response.message ?? "获取健康档案失败"
            ])
        }
        
        return response.data
    }
    
    func getComprehensiveProfile() async throws -> ComprehensiveHealthProfile? {
        let response: HealthAPIResponse<ComprehensiveHealthProfile> = try await NetworkManager.shared.get(
            endpoint: "/health/profile/comprehensive",
            parameters: nil,
            headers: nil,
            responseType: HealthAPIResponse<ComprehensiveHealthProfile>.self
        )
        
        guard response.success else {
            throw NSError(domain: "HealthProfileAPI", code: 1, userInfo: [
                NSLocalizedDescriptionKey: response.error ?? response.message ?? "获取完整健康档案失败"
            ])
        }
        
        return response.data
    }
    
    func getCurrentFiveElementsAnalysis() async throws -> FiveElementsAnalysis? {
        let response: HealthAPIResponse<FiveElementsAnalysis> = try await NetworkManager.shared.get(
            endpoint: "/health/five-elements/current",
            parameters: nil,
            headers: nil,
            responseType: HealthAPIResponse<FiveElementsAnalysis>.self
        )
        
        guard response.success else {
            throw NSError(domain: "HealthProfileAPI", code: 1, userInfo: [
                NSLocalizedDescriptionKey: response.error ?? response.message ?? "获取五运六气分析失败"
            ])
        }
        
        return response.data
    }
    
    // MARK: - 图片上传方法
    
    /// 上传健康分析图片
    func uploadHealthImage(_ image: UIImage, compressionQuality: CGFloat = 0.8) async throws -> String {
        let uploadResponse = try await NetworkManager.shared.uploadHealthImage(image, compressionQuality: compressionQuality)
        return uploadResponse.data.url
    }
    
    // MARK: - 舌诊面诊 API（更新版本）
    
    /// 舌诊分析（新版API）
    func analyzeTongueV2(imageUrl: String, description: String? = nil) async throws -> ActualAnalysisResponse.AnalysisData {
        let parameters: [String: Any] = [
            "imageUrl": imageUrl,
            "description": description ?? "iOS客户端舌诊分析"
        ]
        
        let response: ActualAnalysisResponse = try await NetworkManager.shared.post(
            endpoint: "/health/tongue/analyze",
            parameters: parameters,
            headers: nil,
            responseType: ActualAnalysisResponse.self
        )
        
        // 检查业务逻辑层面的成功/失败
        if !response.success || response.code != 0 {
            throw NSError(domain: "TongueAnalysisAPI", code: response.code, userInfo: [
                NSLocalizedDescriptionKey: response.msg.isEmpty ? "舌诊分析失败" : response.msg
            ])
        }
        
        return response.data
    }
    
    /// 面诊分析（新版API）
    func analyzeFaceV2(imageUrl: String, description: String? = nil) async throws -> ActualAnalysisResponse.AnalysisData {
        let parameters: [String: Any] = [
            "imageUrl": imageUrl,
            "description": description ?? "iOS客户端面诊分析"
        ]
        
        let response: ActualAnalysisResponse = try await NetworkManager.shared.post(
            endpoint: "/health/face/analyze",
            parameters: parameters,
            headers: nil,
            responseType: ActualAnalysisResponse.self
        )
        
        // 检查业务逻辑层面的成功/失败
        if !response.success || response.code != 0 {
            throw NSError(domain: "FaceAnalysisAPI", code: response.code, userInfo: [
                NSLocalizedDescriptionKey: response.msg.isEmpty ? "面诊分析失败" : response.msg
            ])
        }
        
        return response.data
    }
    
    // MARK: - 原有API方法（向后兼容）
    
    /// 舌诊分析
    func analyzeTongue(imageUrl: String, description: String? = nil) async throws -> TongueAnalysisResponse {
        let parameters: [String: Any] = [
            "imageUrl": imageUrl,
            "description": description ?? "iOS客户端舌诊分析"
        ]
        
        let response: HealthAPIResponse<TongueAnalysisResponse> = try await NetworkManager.shared.post(
            endpoint: "/health/tongue/analyze",
            parameters: parameters,
            headers: nil,
            responseType: HealthAPIResponse<TongueAnalysisResponse>.self
        )
        
        guard response.success, let data = response.data else {
            throw NSError(domain: "TongueAnalysisAPI", code: 1, userInfo: [
                NSLocalizedDescriptionKey: response.error ?? response.message ?? "舌诊分析失败"
            ])
        }
        
        return data
    }
    
    /// 面诊分析
    func analyzeFace(imageUrl: String, description: String? = nil) async throws -> FaceAnalysisResponse {
        let parameters: [String: Any] = [
            "imageUrl": imageUrl,
            "description": description ?? "iOS客户端面诊分析"
        ]
        
        let response: HealthAPIResponse<FaceAnalysisResponse> = try await NetworkManager.shared.post(
            endpoint: "/health/face/analyze",
            parameters: parameters,
            headers: nil,
            responseType: HealthAPIResponse<FaceAnalysisResponse>.self
        )
        
        guard response.success, let data = response.data else {
            throw NSError(domain: "FaceAnalysisAPI", code: 1, userInfo: [
                NSLocalizedDescriptionKey: response.error ?? response.message ?? "面诊分析失败"
            ])
        }
        
        return data
    }
    
    /// 获取舌诊详情（v2完整格式）
    func getTongueAnalysisDetail(id: String) async throws -> ActualAnalysisResponse.AnalysisData {
        print("🌐 API请求: GET /health/tongue/\(id)")
        let response: ActualAnalysisResponse = try await NetworkManager.shared.get(
            endpoint: "/health/tongue/\(id)",
            parameters: nil,
            headers: nil,
            responseType: ActualAnalysisResponse.self
        )

        print("📥 API响应: success=\(response.success), code=\(response.code), msg=\(response.msg)")

        // 检查业务逻辑层面的成功/失败
        if !response.success || response.code != 0 {
            let errorMessage = response.msg.isEmpty ? "获取舌诊详情失败" : response.msg
            print("❌ 舌诊详情获取失败: \(errorMessage)")
            throw NSError(domain: "TongueAnalysisAPI", code: response.code, userInfo: [
                NSLocalizedDescriptionKey: errorMessage
            ])
        }

        print("✅ 舌诊详情获取成功")
        return response.data
    }
    
    /// 获取面诊详情（v2完整格式）
    func getFaceAnalysisDetail(id: String) async throws -> ActualAnalysisResponse.AnalysisData {
        print("🌐 API请求: GET /health/face/\(id)")
        let response: ActualAnalysisResponse = try await NetworkManager.shared.get(
            endpoint: "/health/face/\(id)",
            parameters: nil,
            headers: nil,
            responseType: ActualAnalysisResponse.self
        )

        print("📥 API响应: success=\(response.success), code=\(response.code), msg=\(response.msg)")

        // 检查业务逻辑层面的成功/失败
        if !response.success || response.code != 0 {
            let errorMessage = response.msg.isEmpty ? "获取面诊详情失败" : response.msg
            print("❌ 面诊详情获取失败: \(errorMessage)")
            throw NSError(domain: "FaceAnalysisAPI", code: response.code, userInfo: [
                NSLocalizedDescriptionKey: errorMessage
            ])
        }

        print("✅ 面诊详情获取成功")
        return response.data
    }
    
    /// 获取舌诊历史记录
    func getTongueHistory() async throws -> [TongueHistoryRecord] {
        print("🌐 API请求: GET /health/tongue/history")
        let response: HistoryResponse<TongueHistoryRecord> = try await NetworkManager.shared.get(
            endpoint: "/health/tongue/history",
            parameters: nil,
            headers: nil,
            responseType: HistoryResponse<TongueHistoryRecord>.self
        )

        print("📥 舌诊历史API响应: success=\(response.success)")

        guard response.success else {
            print("❌ 获取舌诊历史记录失败")
            throw NSError(domain: "TongueAnalysisAPI", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "获取舌诊历史记录失败"
            ])
        }

        print("✅ 舌诊历史记录获取成功，共 \(response.data.records.count) 条记录")
        return response.data.records
    }
    
    /// 获取面诊历史记录
    func getFaceHistory() async throws -> [FaceHistoryRecord] {
        print("🌐 API请求: GET /health/face/history")
        let response: HistoryResponse<FaceHistoryRecord> = try await NetworkManager.shared.get(
            endpoint: "/health/face/history",
            parameters: nil,
            headers: nil,
            responseType: HistoryResponse<FaceHistoryRecord>.self
        )

        print("📥 面诊历史API响应: success=\(response.success)")

        guard response.success else {
            print("❌ 获取面诊历史记录失败")
            throw NSError(domain: "FaceAnalysisAPI", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "获取面诊历史记录失败"
            ])
        }

        print("✅ 面诊历史记录获取成功，共 \(response.data.records.count) 条记录")
        return response.data.records
    }
}
