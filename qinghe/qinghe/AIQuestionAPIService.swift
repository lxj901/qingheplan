import Foundation

/// AI题库API服务
class AIQuestionAPIService: ObservableObject {
    static let shared = AIQuestionAPIService()
    
    private let networkManager = NetworkManager.shared
    private let authManager = AuthManager.shared
    
    private init() {}
    
    // MARK: - API端点
    private enum Endpoint {
        static let generate = "/classics/ai-questions/generate"
        static let questions = "/classics/ai-questions"
        static func question(id: String) -> String { "/classics/ai-questions/\(id)" }
        static func submit(id: String) -> String { "/classics/ai-questions/\(id)/submit" }
        static func stats(userId: Int) -> String { "/classics/ai-questions/stats/\(userId)" }
    }
    
    // MARK: - 生成AI题目
    /// 生成AI题目
    /// - Parameter request: 生成请求参数
    /// - Returns: 生成结果
    func generateQuestions(request: GenerateQuestionsRequest) async throws -> GenerateQuestionsResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        let parameters: [String: Any] = [
            "bookId": request.bookId,
            "chapterId": request.chapterId as Any,
            "questionTypes": request.questionTypes.map { $0.rawValue },
            "difficulty": request.difficulty.rawValue,
            "countPerType": request.countPerType,
            "batchName": request.batchName as Any
        ]
        
        let response: AIQuestionAPIResponse<GenerateQuestionsResponse> = try await networkManager.post(
            endpoint: Endpoint.generate,
            parameters: parameters,
            headers: authHeaders,
            responseType: AIQuestionAPIResponse<GenerateQuestionsResponse>.self
        )
        
        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message)
        }
        
        return data
    }
    
    // MARK: - 获取题目列表
    /// 获取题目列表
    /// - Parameters:
    ///   - bookId: 书籍ID（可选）
    ///   - chapterId: 章节ID（可选）
    ///   - questionType: 题目类型（可选）
    ///   - difficulty: 难度（可选）
    ///   - batchId: 批次ID（可选）
    ///   - limit: 每页数量
    ///   - offset: 偏移量
    /// - Returns: 题目列表
    func getQuestions(
        bookId: String? = nil,
        chapterId: String? = nil,
        questionType: QuestionType? = nil,
        difficulty: QuestionDifficulty? = nil,
        batchId: String? = nil,
        limit: Int = 10,
        offset: Int = 0
    ) async throws -> QuestionListResponse {
        var parameters: [String: Any] = [
            "limit": limit,
            "offset": offset
        ]

        if let bookId = bookId {
            parameters["bookId"] = bookId
        }
        if let chapterId = chapterId {
            parameters["chapterId"] = chapterId
        }
        if let questionType = questionType {
            parameters["questionType"] = questionType.rawValue
        }
        if let difficulty = difficulty {
            parameters["difficulty"] = difficulty.rawValue
        }
        if let batchId = batchId {
            parameters["batchId"] = batchId
        }

        // ⭐ 添加 userId 参数以过滤已回答正确的题目
        if let userId = authManager.getCurrentUserId() {
            parameters["userId"] = userId
        }

        let response: AIQuestionAPIResponse<QuestionListResponse> = try await networkManager.get(
            endpoint: Endpoint.questions,
            parameters: parameters,
            responseType: AIQuestionAPIResponse<QuestionListResponse>.self
        )

        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message)
        }

        return data
    }
    
    // MARK: - 获取单个题目
    /// 获取单个题目详情
    /// - Parameter questionId: 题目ID
    /// - Returns: 题目详情
    func getQuestion(questionId: String) async throws -> AIQuestion {
        let response: AIQuestionAPIResponse<AIQuestion> = try await networkManager.get(
            endpoint: Endpoint.question(id: questionId),
            responseType: AIQuestionAPIResponse<AIQuestion>.self
        )
        
        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message)
        }
        
        return data
    }
    
    // MARK: - 提交答案
    /// 提交答案
    /// - Parameters:
    ///   - questionId: 题目ID
    ///   - userAnswer: 用户答案
    ///   - answerTime: 答题用时（秒）
    /// - Returns: 答题结果
    func submitAnswer(
        questionId: String,
        userAnswer: String,
        answerTime: Int
    ) async throws -> SubmitAnswerResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        guard let userId = authManager.getCurrentUserId() else {
            throw NetworkManager.NetworkError.networkError("无法获取用户ID")
        }
        
        let parameters: [String: Any] = [
            "userId": userId,
            "userAnswer": userAnswer,
            "answerTime": answerTime
        ]
        
        let response: AIQuestionAPIResponse<SubmitAnswerResponse> = try await networkManager.post(
            endpoint: Endpoint.submit(id: questionId),
            parameters: parameters,
            headers: authHeaders,
            responseType: AIQuestionAPIResponse<SubmitAnswerResponse>.self
        )
        
        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message)
        }
        
        return data
    }
    
    // MARK: - 获取答题统计
    /// 获取用户答题统计
    /// - Parameters:
    ///   - userId: 用户ID（可选，默认使用当前用户）
    ///   - bookId: 书籍ID（可选）
    ///   - chapterId: 章节ID（可选）
    /// - Returns: 答题统计
    func getStats(
        userId: Int? = nil,
        bookId: String? = nil,
        chapterId: String? = nil
    ) async throws -> QuestionStats {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        let targetUserId = userId ?? authManager.getCurrentUserId() ?? 0
        
        var parameters: [String: Any] = [:]
        if let bookId = bookId {
            parameters["bookId"] = bookId
        }
        if let chapterId = chapterId {
            parameters["chapterId"] = chapterId
        }
        
        let response: AIQuestionAPIResponse<QuestionStats> = try await networkManager.get(
            endpoint: Endpoint.stats(userId: targetUserId),
            parameters: parameters,
            headers: authHeaders,
            responseType: AIQuestionAPIResponse<QuestionStats>.self
        )
        
        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message)
        }
        
        return data
    }
}

