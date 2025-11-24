import SwiftUI

/// 内联问卷视图（在消息气泡内显示）
struct InlineQuestionnaireView: View {
    let questions: [Question]
    let diagnosisType: String
    let conversationId: String
    let onComplete: () -> Void

    @State private var currentQuestionIndex = 0
    @State private var answers: [String: String] = [:]  // 单选答案
    @State private var multipleAnswers: [String: Set<String>] = [:]  // 多选答案
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isCompleted = false

    private var currentQuestion: Question {
        questions[currentQuestionIndex]
    }

    private var isLastQuestion: Bool {
        currentQuestionIndex == questions.count - 1
    }

    private var canProceed: Bool {
        if currentQuestion.required {
            // 检查问题类型
            if currentQuestion.type == "multiple_choice" {
                // 多选题：至少选择一个选项
                return multipleAnswers[currentQuestion.id]?.isEmpty == false
            } else {
                // 单选题或文本题
                return answers[currentQuestion.id] != nil
            }
        }
        return true
    }

    var body: some View {
        if isCompleted {
            completedView
        } else {
            VStack(alignment: .leading, spacing: 12) {
                // 进度指示器
                progressIndicator

                // 问题卡片
                questionCard

                // 导航按钮
                navigationButtons
            }
            .alert("提示", isPresented: $showError) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - 完成视图
    private var completedView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)

                Text("问卷已完成")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }

            Text("正在为您生成拍照指引...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - 进度指示器
    private var progressIndicator: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("问题 \(currentQuestionIndex + 1)/\(questions.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(currentQuestionIndex + 1) / CGFloat(questions.count), height: 4)
                        .animation(.spring(response: 0.3), value: currentQuestionIndex)
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: - 问题卡片
    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 问题标题
            HStack(alignment: .top, spacing: 4) {
                Text(currentQuestion.question)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                if currentQuestion.required {
                    Text("*")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.red)
                }
            }

            // 选项
            if let options = currentQuestion.options {
                VStack(spacing: 8) {
                    ForEach(options) { option in
                        optionButton(option)
                    }
                }
            }
        }
    }

    // MARK: - 选项按钮
    private func optionButton(_ option: QuestionOption) -> some View {
        let isMultipleChoice = currentQuestion.type == "multiple_choice"
        let isSelected: Bool

        if isMultipleChoice {
            isSelected = multipleAnswers[currentQuestion.id]?.contains(option.value) ?? false
        } else {
            isSelected = answers[currentQuestion.id] == option.value
        }

        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                if isMultipleChoice {
                    // 多选逻辑
                    if multipleAnswers[currentQuestion.id] == nil {
                        multipleAnswers[currentQuestion.id] = []
                    }

                    if multipleAnswers[currentQuestion.id]!.contains(option.value) {
                        multipleAnswers[currentQuestion.id]!.remove(option.value)
                    } else {
                        multipleAnswers[currentQuestion.id]!.insert(option.value)
                    }
                } else {
                    // 单选逻辑
                    answers[currentQuestion.id] = option.value
                }
            }
        }) {
            HStack(spacing: 10) {
                // 选择指示器
                ZStack {
                    if isMultipleChoice {
                        // 多选：方形复选框
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 18, height: 18)

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    } else {
                        // 单选：圆形单选框
                        Circle()
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 18, height: 18)

                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 10, height: 10)
                        }
                    }
                }

                Text(option.label)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .primary : .secondary)

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color.gray.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 导航按钮
    private var navigationButtons: some View {
        HStack(spacing: 10) {
            // 上一题按钮
            if currentQuestionIndex > 0 {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        currentQuestionIndex -= 1
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("上一题")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.12))
                    )
                    .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // 下一题/提交按钮
            Button(action: {
                if isLastQuestion {
                    submitQuestionnaire()
                } else {
                    if canProceed {
                        withAnimation(.spring(response: 0.3)) {
                            currentQuestionIndex += 1
                        }
                    } else {
                        errorMessage = "请回答当前问题"
                        showError = true
                    }
                }
            }) {
                HStack(spacing: 4) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    } else {
                        Text(isLastQuestion ? "提交" : "下一题")
                            .font(.system(size: 14, weight: .medium))
                        if !isLastQuestion {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(canProceed ? Color.blue : Color.gray.opacity(0.3))
                )
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canProceed || isSubmitting)
        }
    }

    // MARK: - 提交问卷
    private func submitQuestionnaire() {
        guard !isSubmitting else { return }

        // 检查所有必填题是否已回答
        for question in questions where question.required {
            if question.type == "multiple_choice" {
                // 多选题：检查是否至少选择了一个选项
                if multipleAnswers[question.id]?.isEmpty != false {
                    errorMessage = "请完成所有必填问题"
                    showError = true
                    return
                }
            } else {
                // 单选题或文本题
                if answers[question.id] == nil {
                    errorMessage = "请完成所有必填问题"
                    showError = true
                    return
                }
            }
        }

        isSubmitting = true

        Task {
            do {
                // 合并单选和多选答案
                var finalAnswers = answers

                // 将多选答案转换为逗号分隔的字符串
                for (questionId, selectedOptions) in multipleAnswers {
                    if !selectedOptions.isEmpty {
                        finalAnswers[questionId] = selectedOptions.sorted().joined(separator: ",")
                    }
                }

                // 保存问卷答案
                let response = try await HealthChatAPIService.shared.saveQuestionnaireAnswers(
                    conversationId: conversationId,
                    answers: finalAnswers
                )

                print("✅ 问卷保存成功: \(response.data?.message ?? "")")

                // 调用问卷完成 API 获取拍照卡片
                let completedResponse = try await HealthChatAPIService.shared.questionnaireCompleted(
                    conversationId: conversationId,
                    diagnosisType: diagnosisType
                )

                print("✅ 问卷完成，获取到拍照卡片")

                await MainActor.run {
                    isSubmitting = false
                    isCompleted = true
                    onComplete()
                }
            } catch {
                print("❌ 提交问卷失败: \(error)")
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "提交失败，请重试"
                    showError = true
                }
            }
        }
    }
}

/// 交互式问卷视图（独立页面显示，保留用于其他场景）
struct InteractiveQuestionnaireView: View {
    let questions: [Question]
    let diagnosisType: String
    let conversationId: String
    let onComplete: () -> Void
    let onDismiss: () -> Void
    
    @State private var currentQuestionIndex = 0
    @State private var answers: [String: String] = [:]  // 单选答案
    @State private var multipleAnswers: [String: Set<String>] = [:]  // 多选答案
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var currentQuestion: Question {
        questions[currentQuestionIndex]
    }
    
    private var isLastQuestion: Bool {
        currentQuestionIndex == questions.count - 1
    }
    
    private var canProceed: Bool {
        if currentQuestion.required {
            // 检查问题类型
            if currentQuestion.type == "multiple_choice" {
                // 多选题：至少选择一个选项
                return multipleAnswers[currentQuestion.id]?.isEmpty == false
            } else {
                // 单选题或文本题
                return answers[currentQuestion.id] != nil
            }
        }
        return true
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 进度指示器
            progressIndicator
            
            // 问题卡片
            questionCard
            
            // 导航按钮
            navigationButtons
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .alert("提示", isPresented: $showError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - 进度指示器
    private var progressIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("问卷进度")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(currentQuestionIndex + 1)/\(questions.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(currentQuestionIndex + 1) / CGFloat(questions.count), height: 6)
                        .animation(.spring(response: 0.3), value: currentQuestionIndex)
                }
            }
            .frame(height: 6)
        }
    }
    
    // MARK: - 问题卡片
    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 问题标题
            HStack(alignment: .top, spacing: 6) {
                Text(currentQuestion.question)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                if currentQuestion.required {
                    Text("*")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            
            // 选项
            if let options = currentQuestion.options {
                VStack(spacing: 10) {
                    ForEach(options) { option in
                        optionButton(option)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 选项按钮
    private func optionButton(_ option: QuestionOption) -> some View {
        let isMultipleChoice = currentQuestion.type == "multiple_choice"
        let isSelected: Bool

        if isMultipleChoice {
            isSelected = multipleAnswers[currentQuestion.id]?.contains(option.value) ?? false
        } else {
            isSelected = answers[currentQuestion.id] == option.value
        }

        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                if isMultipleChoice {
                    // 多选逻辑
                    if multipleAnswers[currentQuestion.id] == nil {
                        multipleAnswers[currentQuestion.id] = []
                    }

                    if multipleAnswers[currentQuestion.id]!.contains(option.value) {
                        multipleAnswers[currentQuestion.id]!.remove(option.value)
                    } else {
                        multipleAnswers[currentQuestion.id]!.insert(option.value)
                    }
                } else {
                    // 单选逻辑
                    answers[currentQuestion.id] = option.value
                }
            }
        }) {
            HStack(spacing: 12) {
                // 选择指示器
                ZStack {
                    if isMultipleChoice {
                        // 多选：方形复选框
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    } else {
                        // 单选：圆形单选框
                        Circle()
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)

                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                        }
                    }
                }

                Text(option.label)
                    .font(.system(size: 15))
                    .foregroundColor(isSelected ? .primary : .secondary)

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 导航按钮
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // 上一题按钮
            if currentQuestionIndex > 0 {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        currentQuestionIndex -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("上一题")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.15))
                    )
                    .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 下一题/提交按钮
            Button(action: {
                if isLastQuestion {
                    submitQuestionnaire()
                } else {
                    if canProceed {
                        withAnimation(.spring(response: 0.3)) {
                            currentQuestionIndex += 1
                        }
                    } else {
                        errorMessage = "请回答当前问题"
                        showError = true
                    }
                }
            }) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(isLastQuestion ? "提交问卷" : "下一题")
                            .font(.system(size: 15, weight: .medium))
                        if !isLastQuestion {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(canProceed ? Color.blue : Color.gray.opacity(0.3))
                )
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canProceed || isSubmitting)
        }
    }
    
    // MARK: - 提交问卷
    private func submitQuestionnaire() {
        guard !isSubmitting else { return }

        // 检查所有必填题是否已回答
        for question in questions where question.required {
            if question.type == "multiple_choice" {
                // 多选题：检查是否至少选择了一个选项
                if multipleAnswers[question.id]?.isEmpty != false {
                    errorMessage = "请完成所有必填问题"
                    showError = true
                    return
                }
            } else {
                // 单选题或文本题
                if answers[question.id] == nil {
                    errorMessage = "请完成所有必填问题"
                    showError = true
                    return
                }
            }
        }

        isSubmitting = true

        Task {
            do {
                // 合并单选和多选答案
                var finalAnswers = answers

                // 将多选答案转换为逗号分隔的字符串
                for (questionId, selectedOptions) in multipleAnswers {
                    if !selectedOptions.isEmpty {
                        finalAnswers[questionId] = selectedOptions.sorted().joined(separator: ",")
                    }
                }

                // 保存问卷答案
                let response = try await HealthChatAPIService.shared.saveQuestionnaireAnswers(
                    conversationId: conversationId,
                    answers: finalAnswers
                )

                print("✅ 问卷保存成功: \(response.data?.message ?? "")")

                // 调用问卷完成 API 获取拍照卡片
                let completedResponse = try await HealthChatAPIService.shared.questionnaireCompleted(
                    conversationId: conversationId,
                    diagnosisType: diagnosisType
                )

                print("✅ 问卷完成，获取到拍照卡片")

                await MainActor.run {
                    isSubmitting = false
                    onComplete()
                }
            } catch {
                print("❌ 提交问卷失败: \(error)")
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "提交失败，请重试"
                    showError = true
                }
            }
        }
    }
}

// MARK: - 预览
#Preview {
    InteractiveQuestionnaireView(
        questions: [
            Question(
                id: "sleep_quality",
                question: "最近一周的睡眠质量如何？",
                type: "single_choice",
                options: [
                    QuestionOption(value: "excellent", label: "很好，睡眠充足"),
                    QuestionOption(value: "good", label: "较好，偶尔失眠"),
                    QuestionOption(value: "fair", label: "一般，经常失眠"),
                    QuestionOption(value: "poor", label: "很差，严重失眠")
                ],
                required: true
            ),
            Question(
                id: "diet_habits",
                question: "您的饮食习惯是怎样的？",
                type: "single_choice",
                options: [
                    QuestionOption(value: "balanced", label: "均衡饮食"),
                    QuestionOption(value: "irregular", label: "饮食不规律"),
                    QuestionOption(value: "heavy", label: "偏好重口味"),
                    QuestionOption(value: "light", label: "偏好清淡")
                ],
                required: true
            )
        ],
        diagnosisType: "tongue",
        conversationId: "CONV_TEST_123",
        onComplete: {
            print("问卷完成")
        },
        onDismiss: {
            print("关闭问卷")
        }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

