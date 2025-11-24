import SwiftUI

// MARK: - AI题目答题页面
struct AIQuestionAnswerView: View {
    @ObservedObject var viewModel: AIQuestionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOptions: Set<String> = []
    @State private var textAnswer: String = ""
    @State private var showResult = false
    
    // 背景渐变色
    private let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 245/255, green: 242/255, blue: 237/255),
            Color(red: 239/255, green: 235/255, blue: 224/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            // 背景
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // 导航栏
                navigationBar

                // 进度条
                progressBar

                // 内容区域
                if let question = viewModel.currentQuestion {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 题目卡片
                            questionCard(question: question)

                            // 答题区域
                            if !viewModel.hasSubmitted {
                                answerArea(question: question)
                            } else if let result = viewModel.answerResult {
                                resultArea(result: result, question: question)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                }
            }
            
        }
        // 使用 safeAreaInset 固定底部操作栏，避免被拉伸或错位
        .safeAreaInset(edge: .bottom) { bottomActionBar }
        // 隐藏系统导航栏，避免出现大标题造成的顶部额外高度
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            resetAnswerState()
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack(spacing: 12) {
            // 返回按钮
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                    Text("返回")
                        .font(.system(size: 15))
                }
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.6))
                )
            }

            Spacer()

            // 题号
            Text(viewModel.progressText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

            Spacer()

            // 占位
            Color.clear.frame(width: 70)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .frame(height: 44)
        .background(Color.white.opacity(0.3))
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                // 进度
                Rectangle()
                    .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                    .frame(width: geometry.size.width * viewModel.progress)
            }
        }
        .frame(height: 4)
    }
    
    // MARK: - Question Card
    private func questionCard(question: AIQuestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 题型和难度标签
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: question.questionType.icon)
                        .font(.system(size: 12))
                    Text(question.questionType.displayName)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                )
                
                let difficultyColor = question.difficulty.color
                Text(question.difficulty.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: difficultyColor.red, green: difficultyColor.green, blue: difficultyColor.blue))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: difficultyColor.red, green: difficultyColor.green, blue: difficultyColor.blue).opacity(0.15))
                    )
                
                Spacer()
            }
            
            // 题目内容
            Text(question.question)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                .lineSpacing(6)
            
            // 相关原文
            if let relatedContent = question.relatedContent {
                VStack(alignment: .leading, spacing: 8) {
                    Text("相关原文")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.gray)
                    
                    Text(relatedContent)
                        .font(AppFont.kangxi(size: 14))
                        .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                        .lineSpacing(4)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.95, green: 0.93, blue: 0.90))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
    
    // MARK: - Answer Area
    private func answerArea(question: AIQuestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("请作答")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            
            switch question.questionType {
            case .choice, .trueFalse:
                singleChoiceOptions(question: question)
            case .multipleChoice:
                multipleChoiceOptions(question: question)
            case .fillBlank, .shortAnswer:
                textAnswerInput()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
    
    // 单选题选项
    private func singleChoiceOptions(question: AIQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(question.displayOptions, id: \.self) { option in
                Button(action: {
                    selectedOptions = [option]
                    // 提取选项字母（如 "A. xxx" -> "A"）
                    textAnswer = extractOptionLetter(from: option)
                }) {
                    HStack {
                        Text(option)
                            .font(.system(size: 15))
                            .foregroundColor(selectedOptions.contains(option) ? .white : Color(red: 0.2, green: 0.15, blue: 0.1))

                        Spacer()

                        if selectedOptions.contains(option) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedOptions.contains(option) ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color(red: 0.95, green: 0.93, blue: 0.90))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // 多选题选项
    private func multipleChoiceOptions(question: AIQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(question.displayOptions, id: \.self) { option in
                Button(action: {
                    if selectedOptions.contains(option) {
                        selectedOptions.remove(option)
                    } else {
                        selectedOptions.insert(option)
                    }
                    // 提取所有选中选项的字母并排序（如 "ABC"）
                    let letters = selectedOptions.map { extractOptionLetter(from: $0) }.sorted()
                    textAnswer = letters.joined()
                }) {
                    HStack {
                        Text(option)
                            .font(.system(size: 15))
                            .foregroundColor(selectedOptions.contains(option) ? .white : Color(red: 0.2, green: 0.15, blue: 0.1))

                        Spacer()

                        Image(systemName: selectedOptions.contains(option) ? "checkmark.square.fill" : "square")
                            .foregroundColor(selectedOptions.contains(option) ? .white : Color.gray)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedOptions.contains(option) ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color(red: 0.95, green: 0.93, blue: 0.90))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // 文本答案输入
    private func textAnswerInput() -> some View {
        TextEditor(text: $textAnswer)
            .font(.system(size: 15))
            .frame(minHeight: 120)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.95, green: 0.93, blue: 0.90))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
    
    // MARK: - Result Area
    private func resultArea(result: SubmitAnswerResponse, question: AIQuestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 结果标题
            HStack {
                Image(systemName: result.isAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(result.isAnswerCorrect ? Color(red: 0.2, green: 0.7, blue: 0.4) : Color(red: 0.9, green: 0.3, blue: 0.3))

                Text(result.isAnswerCorrect ? "回答正确" : "回答错误")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(result.isAnswerCorrect ? Color(red: 0.2, green: 0.7, blue: 0.4) : Color(red: 0.9, green: 0.3, blue: 0.3))

                Spacer()

                Text("\(result.score)分")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
            }

            Divider()

            // 你的答案
            VStack(alignment: .leading, spacing: 8) {
                Text("你的答案")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.gray)

                Text(textAnswer)
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            }

            // 正确答案
            VStack(alignment: .leading, spacing: 8) {
                Text("正确答案")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.gray)

                Text(result.correctAnswer)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.4))
            }

            // 答案解析
            VStack(alignment: .leading, spacing: 8) {
                Text("答案解析")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.gray)

                Text(result.analysis)
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .lineSpacing(4)
            }

            // AI评价（问答题）
            if let aiEvaluation = result.aiEvaluation {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI评价")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.gray)

                    Text(aiEvaluation)
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        .lineSpacing(4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 上一题
                Button(action: {
                    viewModel.previousQuestion()
                    resetAnswerState()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("上一题")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(viewModel.hasPreviousQuestion ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                    )
                }
                .disabled(!viewModel.hasPreviousQuestion)

                // 提交/下一题
                Button(action: {
                    if viewModel.hasSubmitted {
                        viewModel.nextQuestion()
                        resetAnswerState()
                    } else {
                        submitAnswer()
                    }
                }) {
                    Text(viewModel.hasSubmitted ? "下一题" : "提交答案")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canSubmit ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color.gray)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                        )
                }
                .disabled(!canSubmit && !viewModel.hasSubmitted)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .background(
            Color.white.opacity(0.95)
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: -2)
        )
    }
    
    // MARK: - Helper Methods
    private var canSubmit: Bool {
        !textAnswer.isEmpty || !selectedOptions.isEmpty
    }
    
    private func resetAnswerState() {
        selectedOptions = []
        textAnswer = ""
        showResult = false
    }
    
    private func submitAnswer() {
        viewModel.userAnswer = textAnswer
        Task {
            await viewModel.submitAnswer()
        }
    }

    /// 从选项文本中提取字母（如 "A. 选项内容" -> "A"）
    private func extractOptionLetter(from option: String) -> String {
        // 判断题特殊处理
        if option == "正确" {
            return "正确"
        } else if option == "错误" {
            return "错误"
        }

        // 选择题：提取字母部分（如 "A. xxx" -> "A"）
        if let dotIndex = option.firstIndex(of: ".") {
            let letter = option[..<dotIndex].trimmingCharacters(in: .whitespaces)
            return letter
        }

        // 如果没有找到点号，返回原文本
        return option
    }
}
