import Foundation
import SwiftUI

/// AI题库ViewModel
@MainActor
class AIQuestionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var questions: [AIQuestion] = []
    @Published var currentQuestion: AIQuestion?
    @Published var currentQuestionIndex: Int = 0
    @Published var userAnswer: String = ""
    @Published var answerResult: SubmitAnswerResponse?
    @Published var stats: QuestionStats?
    @Published var answerRecords: [AnswerRecord] = []
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // 筛选条件
    @Published var selectedBookId: String?
    @Published var selectedChapterId: String?
    @Published var selectedQuestionType: QuestionType?
    @Published var selectedDifficulty: QuestionDifficulty?

    // 答题状态
    @Published var isAnswering: Bool = false
    @Published var answerStartTime: Date?
    @Published var hasSubmitted: Bool = false

    // 最近生成的批次ID
    @Published var lastGeneratedBatchId: String?

    // 轮询状态
    @Published var isPolling: Bool = false
    @Published var pollingMessage: String = ""

    private let apiService = AIQuestionAPIService.shared
    private var pollingTask: Task<Void, Never>?
    
    // MARK: - 生成题目
    func generateQuestions(
        bookId: String,
        chapterId: String,
        questionTypes: [QuestionType],
        difficulty: QuestionDifficulty,
        countPerType: Int,
        batchName: String?
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            let request = GenerateQuestionsRequest(
                bookId: bookId,
                chapterId: chapterId,
                questionTypes: questionTypes,
                difficulty: difficulty,
                countPerType: countPerType,
                batchName: batchName
            )

            let response = try await apiService.generateQuestions(request: request)

            // 保存批次ID
            lastGeneratedBatchId = response.batchId

            // 处理异步生成模式
            if let status = response.status, status == "generating" {
                print("✅ 题目生成任务已启动，批次ID: \(response.batchId)")
                if let message = response.message {
                    print("📝 提示: \(message)")
                }

                // 开始轮询查询题目（保持 isLoading = true）
                await startPollingForQuestions(batchId: response.batchId)
            } else if let totalGenerated = response.totalGenerated {
                print("✅ 成功生成 \(totalGenerated) 道题目，批次ID: \(response.batchId)")
                isLoading = false
            } else {
                print("✅ 题目生成请求已提交，批次ID: \(response.batchId)")
                isLoading = false
            }
        } catch {
            errorMessage = "生成题目失败: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }

    // MARK: - 加载题目列表
    func loadQuestions(limit: Int = 100, offset: Int = 0, batchId: String? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.getQuestions(
                bookId: selectedBookId,
                chapterId: selectedChapterId,
                questionType: selectedQuestionType,
                difficulty: selectedDifficulty,
                batchId: batchId,
                limit: limit,
                offset: offset
            )

            questions = response.questions

            // 如果有题目，设置第一题为当前题目
            if !questions.isEmpty {
                currentQuestion = questions[0]
                currentQuestionIndex = 0
            }

            isLoading = false
        } catch {
            errorMessage = "加载题目失败: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }
    
    // MARK: - 加载单个题目
    func loadQuestion(questionId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let question = try await apiService.getQuestion(questionId: questionId)
            currentQuestion = question
            isLoading = false
        } catch {
            errorMessage = "加载题目失败: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }
    
    // MARK: - 提交答案
    func submitAnswer() async {
        guard let question = currentQuestion else { return }
        guard !userAnswer.isEmpty else {
            errorMessage = "请先作答"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        // 计算答题用时
        let answerTime = calculateAnswerTime()

        do {
            let result = try await apiService.submitAnswer(
                questionId: question.id,
                userAnswer: userAnswer,
                answerTime: answerTime
            )

            answerResult = result
            hasSubmitted = true

            // 保存答题记录
            let record = AnswerRecord(
                questionId: question.id,
                question: question.question,
                userAnswer: userAnswer,
                correctAnswer: result.correctAnswer,
                isCorrect: result.isAnswerCorrect,  // 使用计算属性
                score: result.score,
                answerTime: answerTime,
                timestamp: Date(),
                analysis: result.analysis,  // 字段名改为 analysis
                aiEvaluation: result.aiEvaluation
            )
            answerRecords.append(record)

            // ⭐ 如果答对了，重新加载题目列表（会自动过滤掉已答对的题目）
            if result.isAnswerCorrect {
                // 延迟一下，让用户看到答题结果
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                await loadQuestions(batchId: lastGeneratedBatchId)
            }

            isLoading = false
        } catch {
            errorMessage = "提交答案失败: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }
    
    // MARK: - 加载统计数据
    func loadStats() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let statsData = try await apiService.getStats(
                bookId: selectedBookId,
                chapterId: selectedChapterId
            )
            
            stats = statsData
            isLoading = false
        } catch {
            errorMessage = "加载统计数据失败: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }
    
    // MARK: - 题目导航
    func nextQuestion() {
        guard currentQuestionIndex < questions.count - 1 else { return }
        currentQuestionIndex += 1
        currentQuestion = questions[currentQuestionIndex]
        resetAnswerState()
    }
    
    func previousQuestion() {
        guard currentQuestionIndex > 0 else { return }
        currentQuestionIndex -= 1
        currentQuestion = questions[currentQuestionIndex]
        resetAnswerState()
    }
    
    func goToQuestion(at index: Int) {
        guard index >= 0 && index < questions.count else { return }
        currentQuestionIndex = index
        currentQuestion = questions[index]
        resetAnswerState()
    }
    
    // MARK: - 答题状态管理
    func startAnswering() {
        isAnswering = true
        answerStartTime = Date()
        hasSubmitted = false
        userAnswer = ""
        answerResult = nil
    }
    
    func resetAnswerState() {
        userAnswer = ""
        answerResult = nil
        hasSubmitted = false
        answerStartTime = nil
        isAnswering = false
    }
    
    private func calculateAnswerTime() -> Int {
        guard let startTime = answerStartTime else { return 0 }
        return Int(Date().timeIntervalSince(startTime))
    }
    
    // MARK: - 筛选条件
    func applyFilter(
        bookId: String? = nil,
        chapterId: String? = nil,
        questionType: QuestionType? = nil,
        difficulty: QuestionDifficulty? = nil
    ) {
        selectedBookId = bookId
        selectedChapterId = chapterId
        selectedQuestionType = questionType
        selectedDifficulty = difficulty
        
        Task {
            await loadQuestions()
        }
    }
    
    func clearFilters() {
        selectedBookId = nil
        selectedChapterId = nil
        selectedQuestionType = nil
        selectedDifficulty = nil
        
        Task {
            await loadQuestions()
        }
    }
    
    // MARK: - 使用Mock数据（开发测试）
    func loadMockData() {
        questions = AIQuestion.mockQuestions
        if !questions.isEmpty {
            currentQuestion = questions[0]
            currentQuestionIndex = 0
        }
        stats = QuestionStats.mockStats
    }
    
    // MARK: - 计算属性
    var hasNextQuestion: Bool {
        currentQuestionIndex < questions.count - 1
    }
    
    var hasPreviousQuestion: Bool {
        currentQuestionIndex > 0
    }
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex + 1) / Double(questions.count)
    }
    
    var progressText: String {
        guard !questions.isEmpty else { return "0/0" }
        return "\(currentQuestionIndex + 1)/\(questions.count)"
    }

    // MARK: - 轮询查询题目
    /// 开始轮询查询题目
    /// - Parameter batchId: 批次ID
    private func startPollingForQuestions(batchId: String) async {
        // 取消之前的轮询任务
        pollingTask?.cancel()

        isPolling = true
        pollingMessage = "正在生成题目，请稍候..."

        let maxAttempts = 300  // 最多轮询300次（10分钟）
        let pollingInterval: UInt64 = 2_000_000_000  // 2秒（纳秒）

        pollingTask = Task {
            for attempt in 1...maxAttempts {
                // 检查任务是否被取消
                if Task.isCancelled {
                    print("⚠️ 轮询任务已取消")
                    break
                }

                print("🔄 第 \(attempt) 次查询题目（批次ID: \(batchId)）")
                pollingMessage = "正在生成题目... (\(attempt)/\(maxAttempts))"

                do {
                    // 查询题目（使用较大的 limit 以获取所有题目）
                    let response = try await apiService.getQuestions(
                        batchId: batchId,
                        limit: 100,
                        offset: 0
                    )

                    if !response.questions.isEmpty {
                        // 成功获取到题目
                        print("✅ 成功获取到 \(response.questions.count) 道题目")
                        questions = response.questions

                        if !questions.isEmpty {
                            currentQuestion = questions[0]
                            currentQuestionIndex = 0
                        }

                        isPolling = false
                        isLoading = false  // ✅ 生成完成，停止加载动画
                        pollingMessage = ""
                        return
                    } else {
                        print("⏳ 题目还在生成中，等待 2 秒后重试...")
                    }
                } catch {
                    print("❌ 查询题目失败: \(error.localizedDescription)")
                }

                // 等待2秒后重试
                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: pollingInterval)
                }
            }

            // 超时
            print("⚠️ 轮询超时，题目可能还在生成中")
            isPolling = false
            isLoading = false  // ✅ 超时也要停止加载动画
            pollingMessage = ""
            errorMessage = "题目生成超时，请稍后手动刷新查看"
            showError = true
        }
    }

    /// 停止轮询
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isPolling = false
        isLoading = false  // ✅ 取消时也要停止加载动画
        pollingMessage = ""
    }
}

