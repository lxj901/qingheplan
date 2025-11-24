import Foundation

// MARK: - AI题目类型
enum QuestionType: String, Codable, CaseIterable {
    case choice = "choice"                  // 单选题
    case multipleChoice = "multiple_choice" // 多选题
    case trueFalse = "true_false"          // 判断题
    case fillBlank = "fill_blank"          // 填空题
    case shortAnswer = "short_answer"      // 问答题
    
    var displayName: String {
        switch self {
        case .choice: return "单选题"
        case .multipleChoice: return "多选题"
        case .trueFalse: return "判断题"
        case .fillBlank: return "填空题"
        case .shortAnswer: return "问答题"
        }
    }
    
    var icon: String {
        switch self {
        case .choice: return "circle.circle"
        case .multipleChoice: return "checkmark.square"
        case .trueFalse: return "checkmark.circle"
        case .fillBlank: return "text.cursor"
        case .shortAnswer: return "text.alignleft"
        }
    }
}

// MARK: - 题目难度
enum QuestionDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String {
        switch self {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        }
    }
    
    var color: (red: Double, green: Double, blue: Double) {
        switch self {
        case .easy: return (0.2, 0.7, 0.4)    // 绿色
        case .medium: return (0.9, 0.6, 0.2)  // 橙色
        case .hard: return (0.9, 0.3, 0.3)    // 红色
        }
    }
}

// MARK: - AI题目
struct AIQuestion: Codable, Identifiable {
    let id: String
    let questionType: QuestionType
    let difficulty: QuestionDifficulty
    let question: String
    let options: [String]?              // 选择题选项
    let answer: String?                 // 正确答案（不在答题时返回）
    let answerAnalysis: String?         // 答案解析
    let relatedContent: String?         // 相关原文内容
    let totalAttempts: Int?             // 总答题次数
    let correctAttempts: Int?           // 正确次数
    let accuracyRate: String?           // 正确率（字符串格式，如 "80.00"）
    let bookId: String?
    let chapterId: String?
    let sectionId: String?
    let status: String?
    let createdAt: String?
    let updatedAt: String?

    // CodingKeys 用于映射后端的 snake_case 字段名
    enum CodingKeys: String, CodingKey {
        case id
        case questionType = "question_type"
        case difficulty
        case question
        case options
        case answer
        case answerAnalysis = "answer_analysis"
        case relatedContent = "related_content"
        case totalAttempts = "total_attempts"
        case correctAttempts = "correct_attempts"
        case accuracyRate = "accuracy_rate"
        case bookId = "book_id"
        case chapterId = "chapter_id"
        case sectionId = "section_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // 计算属性
    var displayAccuracyRate: String {
        guard let rate = accuracyRate, let rateValue = Double(rate) else { return "暂无数据" }
        return String(format: "%.1f%%", rateValue)
    }

    // 将字符串格式的正确率转换为 Double
    var accuracyRateValue: Double? {
        guard let rate = accuracyRate else { return nil }
        return Double(rate)
    }

    // 获取显示选项（如果是判断题且options为空，自动生成"正确"和"错误"选项）
    var displayOptions: [String] {
        if questionType == .trueFalse {
            // 判断题：如果options为空或nil，返回默认的"正确"和"错误"选项
            if let opts = options, !opts.isEmpty {
                return opts
            } else {
                return ["正确", "错误"]
            }
        } else {
            // 其他题型：返回原始options或空数组
            return options ?? []
        }
    }
}

// MARK: - 生成题目请求
struct GenerateQuestionsRequest: Codable {
    let bookId: String
    let chapterId: String?
    let questionTypes: [QuestionType]
    let difficulty: QuestionDifficulty
    let countPerType: Int
    let batchName: String?
}

// MARK: - 生成题目响应
struct GenerateQuestionsResponse: Codable {
    let batchId: String
    let message: String?
    let status: String?
    let totalGenerated: Int?
    let questions: [AIQuestion]?
}

// MARK: - 题目列表响应
struct QuestionListResponse: Codable {
    let questions: [AIQuestion]
    let total: Int
}

// MARK: - 提交答案请求
struct SubmitAnswerRequest: Codable {
    let userId: Int
    let userAnswer: String
    let answerTime: Int  // 答题用时（秒）
}

// MARK: - 提交答案响应
struct SubmitAnswerResponse: Codable {
    let recordId: String?           // 答题记录ID
    private let isCorrectValue: IsCorrectValue  // 内部存储，支持布尔值和整数
    let score: Int                  // 0-100分
    let correctAnswer: String
    let analysis: String            // 答案解析（后端字段名为 analysis 而非 answerAnalysis）
    let aiEvaluation: String?       // 问答题才有

    // 计算属性：将数字或布尔值转换为布尔值
    var isAnswerCorrect: Bool {
        switch isCorrectValue {
        case .bool(let value):
            return value
        case .int(let value):
            return value == 1
        }
    }

    // 兼容旧代码的计算属性
    var isCorrect: Int {
        return isAnswerCorrect ? 1 : 0
    }

    // 自定义解码，支持布尔值和整数两种格式
    enum CodingKeys: String, CodingKey {
        case recordId
        case isCorrect
        case score
        case correctAnswer
        case analysis
        case aiEvaluation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recordId = try container.decodeIfPresent(String.self, forKey: .recordId)

        // 尝试解码 score，支持整数和浮点数
        if let intScore = try? container.decode(Int.self, forKey: .score) {
            score = intScore
        } else if let doubleScore = try? container.decode(Double.self, forKey: .score) {
            score = Int(doubleScore.rounded())  // 四舍五入转换为整数
        } else {
            throw DecodingError.typeMismatch(
                Int.self,
                DecodingError.Context(
                    codingPath: container.codingPath + [CodingKeys.score],
                    debugDescription: "score must be either Int or Double"
                )
            )
        }

        correctAnswer = try container.decode(String.self, forKey: .correctAnswer)
        analysis = try container.decode(String.self, forKey: .analysis)
        aiEvaluation = try container.decodeIfPresent(String.self, forKey: .aiEvaluation)

        // 尝试解码 isCorrect，支持布尔值和整数
        if let boolValue = try? container.decode(Bool.self, forKey: .isCorrect) {
            isCorrectValue = .bool(boolValue)
        } else if let intValue = try? container.decode(Int.self, forKey: .isCorrect) {
            isCorrectValue = .int(intValue)
        } else {
            throw DecodingError.typeMismatch(
                Bool.self,
                DecodingError.Context(
                    codingPath: container.codingPath + [CodingKeys.isCorrect],
                    debugDescription: "isCorrect must be either Bool or Int"
                )
            )
        }
    }

    // 编码时统一使用整数格式
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(recordId, forKey: .recordId)
        try container.encode(isCorrect, forKey: .isCorrect)
        try container.encode(score, forKey: .score)
        try container.encode(correctAnswer, forKey: .correctAnswer)
        try container.encode(analysis, forKey: .analysis)
        try container.encodeIfPresent(aiEvaluation, forKey: .aiEvaluation)
    }
}

// MARK: - IsCorrect 值类型（支持布尔值和整数）
private enum IsCorrectValue {
    case bool(Bool)
    case int(Int)
}

// MARK: - 答题统计
struct QuestionStats: Codable {
    let totalAttempts: Int      // 总答题次数
    let correctCount: Int        // 正确次数
    let incorrectCount: Int      // 错误次数
    let accuracyRate: Double     // 正确率（百分比）
    private let avgScoreRaw: AvgScoreValue  // 内部存储，支持字符串和数字
    private let avgTimeRaw: AvgTimeValue    // 内部存储，支持字符串和数字

    // CodingKeys 用于映射后端的 snake_case 字段名
    enum CodingKeys: String, CodingKey {
        case totalAttempts = "totalAttempts"
        case correctCount = "correctCount"
        case incorrectCount = "incorrectCount"
        case accuracyRate = "accuracyRate"
        case avgScoreRaw = "avgScore"
        case avgTimeRaw = "avgTime"
    }

    // 普通初始化器（用于 Mock 数据和测试）
    init(totalAttempts: Int, correctCount: Int, incorrectCount: Int, accuracyRate: Double, avgScore: String, avgTime: String) {
        self.totalAttempts = totalAttempts
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.accuracyRate = accuracyRate
        self.avgScoreRaw = .string(avgScore)
        self.avgTimeRaw = .string(avgTime)
    }

    // 自定义解码，支持字符串和数字两种格式
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalAttempts = try container.decode(Int.self, forKey: .totalAttempts)
        correctCount = try container.decode(Int.self, forKey: .correctCount)
        incorrectCount = try container.decode(Int.self, forKey: .incorrectCount)
        accuracyRate = try container.decode(Double.self, forKey: .accuracyRate)

        // 解码 avgScore，支持字符串和数字
        if let stringValue = try? container.decode(String.self, forKey: .avgScoreRaw) {
            avgScoreRaw = .string(stringValue)
        } else if let doubleValue = try? container.decode(Double.self, forKey: .avgScoreRaw) {
            avgScoreRaw = .double(doubleValue)
        } else if let intValue = try? container.decode(Int.self, forKey: .avgScoreRaw) {
            avgScoreRaw = .double(Double(intValue))
        } else {
            avgScoreRaw = .double(0.0)
        }

        // 解码 avgTime，支持字符串和数字
        if let stringValue = try? container.decode(String.self, forKey: .avgTimeRaw) {
            avgTimeRaw = .string(stringValue)
        } else if let doubleValue = try? container.decode(Double.self, forKey: .avgTimeRaw) {
            avgTimeRaw = .double(doubleValue)
        } else if let intValue = try? container.decode(Int.self, forKey: .avgTimeRaw) {
            avgTimeRaw = .double(Double(intValue))
        } else {
            avgTimeRaw = .double(0.0)
        }
    }

    // 计算属性 - 统一转换为 Double
    var avgScoreValue: Double {
        switch avgScoreRaw {
        case .string(let value):
            return Double(value) ?? 0.0
        case .double(let value):
            return value
        }
    }

    var avgTimeValue: Double {
        switch avgTimeRaw {
        case .string(let value):
            return Double(value) ?? 0.0
        case .double(let value):
            return value
        }
    }

    // 兼容旧代码的字符串属性
    var avgScore: String {
        return String(format: "%.2f", avgScoreValue)
    }

    var avgTime: String {
        return String(format: "%.2f", avgTimeValue)
    }

    // 显示属性
    var displayAccuracyRate: String {
        return String(format: "%.1f%%", accuracyRate)
    }

    var displayAvgScore: String {
        return String(format: "%.1f", avgScoreValue)
    }

    var displayAvgTime: String {
        let timeValue = avgTimeValue
        let minutes = Int(timeValue) / 60
        let seconds = Int(timeValue) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(Int(timeValue))秒"
        }
    }

    // 自定义编码
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalAttempts, forKey: .totalAttempts)
        try container.encode(correctCount, forKey: .correctCount)
        try container.encode(incorrectCount, forKey: .incorrectCount)
        try container.encode(accuracyRate, forKey: .accuracyRate)
        try container.encode(avgScore, forKey: .avgScoreRaw)
        try container.encode(avgTime, forKey: .avgTimeRaw)
    }
}

// MARK: - AvgScore 和 AvgTime 值类型（支持字符串和数字）
private enum AvgScoreValue {
    case string(String)
    case double(Double)
}

private enum AvgTimeValue {
    case string(String)
    case double(Double)
}

// MARK: - 答题统计响应
struct QuestionStatsResponse: Codable {
    let code: Int
    let message: String
    let data: QuestionStats
}

// MARK: - API响应包装
struct AIQuestionAPIResponse<T: Codable>: Codable {
    let code: Int
    let message: String
    let data: T?
    
    var isSuccess: Bool {
        return code == 0
    }
}

// MARK: - 答题记录（本地使用）
struct AnswerRecord: Identifiable {
    let id = UUID()
    let questionId: String
    let question: String
    let userAnswer: String
    let correctAnswer: String
    let isCorrect: Bool
    let score: Int
    let answerTime: Int
    let timestamp: Date
    let analysis: String
    let aiEvaluation: String?
}

// MARK: - 题目筛选选项
enum QuestionFilterOption: String, CaseIterable {
    case all = "all"
    case byType = "by_type"
    case byDifficulty = "by_difficulty"
    case byBook = "by_book"
    
    var displayName: String {
        switch self {
        case .all: return "全部题目"
        case .byType: return "按题型"
        case .byDifficulty: return "按难度"
        case .byBook: return "按书籍"
        }
    }
}

// MARK: - 答题模式
enum AnswerMode {
    case practice      // 练习模式（立即显示答案）
    case exam          // 考试模式（完成后显示答案）
    case random        // 随机模式
}

// MARK: - Mock数据（用于开发测试）
extension AIQuestion {
    static let mockQuestions: [AIQuestion] = [
        AIQuestion(
            id: "q1",
            questionType: .choice,
            difficulty: .easy,
            question: "根据《论语》原文，下列哪项最能体现孔子对'仁'的理解？",
            options: ["A. 爱人", "B. 克己复礼", "C. 忠恕之道", "D. 以上都是"],
            answer: "D",
            answerAnalysis: "孔子的'仁'思想包含爱人、克己复礼、忠恕之道等多个方面。",
            relatedContent: "子曰：「学而时习之，不亦说乎？有朋自远方来，不亦乐乎？人不知而不愠，不亦君子乎？」",
            totalAttempts: 100,
            correctAttempts: 80,
            accuracyRate: "80.00",
            bookId: "lunyu",
            chapterId: "xueer",
            sectionId: nil,
            status: "active",
            createdAt: nil,
            updatedAt: nil
        ),
        AIQuestion(
            id: "q2",
            questionType: .trueFalse,
            difficulty: .medium,
            question: "孔子认为'学而不思则罔，思而不学则殆'，这句话强调了学习和思考的重要性。",
            options: ["对", "错"],
            answer: "对",
            answerAnalysis: "这句话确实强调了学习和思考相结合的重要性。",
            relatedContent: "子曰：「学而不思则罔，思而不学则殆。」",
            totalAttempts: 50,
            correctAttempts: 45,
            accuracyRate: "90.00",
            bookId: "lunyu",
            chapterId: "weizheng",
            sectionId: nil,
            status: "active",
            createdAt: nil,
            updatedAt: nil
        ),
        AIQuestion(
            id: "q3",
            questionType: .shortAnswer,
            difficulty: .hard,
            question: "请简述孔子'仁'的思想核心内容及其现代意义。",
            options: nil,
            answer: nil,
            answerAnalysis: "仁的核心是爱人，现代意义在于强调人文关怀和社会责任。",
            relatedContent: "子曰：「仁者爱人。」",
            totalAttempts: 30,
            correctAttempts: 20,
            accuracyRate: "66.70",
            bookId: "lunyu",
            chapterId: "yanyuan",
            sectionId: nil,
            status: "active",
            createdAt: nil,
            updatedAt: nil
        )
    ]
}

extension QuestionStats {
    static let mockStats = QuestionStats(
        totalAttempts: 180,
        correctCount: 145,
        incorrectCount: 35,
        accuracyRate: 80.56,
        avgScore: "85.50",
        avgTime: "25.30"
    )
}

