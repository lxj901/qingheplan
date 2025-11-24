import SwiftUI

// MARK: - AI题库主页面
struct AIQuestionBankView: View {
    @StateObject private var viewModel = AIQuestionViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showAnswerView = false
    @State private var showGenerateView = false
    @State private var showStatsView = false
    @State private var showFilterSheet = false
    
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

                // 轮询状态提示
                if viewModel.isPolling {
                    pollingView
                }

                // 内容区域
                if viewModel.isLoading && viewModel.questions.isEmpty {
                    loadingView
                } else if viewModel.questions.isEmpty && !viewModel.isPolling {
                    emptyView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 统计卡片
                            if let stats = viewModel.stats {
                                statsCard(stats: stats)
                            }

                            // 筛选栏
                            filterBar

                            // 题目列表
                            questionList
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .enableSwipeBack() // 启用系统原生滑动返回手势
        .fullScreenCover(isPresented: $showAnswerView) {
            AIQuestionAnswerView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showGenerateView) {
            AIQuestionGenerateView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showStatsView) {
            if let stats = viewModel.stats {
                AIQuestionStatsView(stats: stats)
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            filterSheet
        }
        .onAppear {
            // 使用真实 API 加载数据
            Task {
                print("📚 AI题库：开始加载题目列表")
                await viewModel.loadQuestions()
                print("📊 AI题库：开始加载统计数据")
                await viewModel.loadStats()
            }

            // 开发测试时可以使用 Mock 数据
            // viewModel.loadMockData()
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
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

            // 标题
            Text("AI题库")
                .font(AppFont.kangxi(size: 20))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

            Spacer()

            // 生成题目按钮
            Button(action: { showGenerateView = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                    Text("生成")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.7, green: 0.5, blue: 0.3),
                            Color(red: 0.6, green: 0.4, blue: 0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.3))
    }
    
    // MARK: - Stats Card
    private func statsCard(stats: QuestionStats) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("答题统计")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                
                Spacer()
                
                Button(action: { showStatsView = true }) {
                    Text("查看详情")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                }
            }
            
            HStack(spacing: 20) {
                statItem(title: "总题数", value: "\(stats.totalAttempts)", color: Color(red: 0.2, green: 0.55, blue: 0.45))
                statItem(title: "正确率", value: stats.displayAccuracyRate, color: Color(red: 0.9, green: 0.6, blue: 0.2))
                statItem(title: "平均分", value: stats.displayAvgScore, color: Color(red: 0.6, green: 0.4, blue: 0.8))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
    
    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color.gray)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部题目
                filterChip(
                    title: "全部题目",
                    isSelected: viewModel.selectedQuestionType == nil && viewModel.selectedDifficulty == nil,
                    action: { viewModel.clearFilters() }
                )
                
                // 按题型筛选
                ForEach(QuestionType.allCases, id: \.self) { type in
                    filterChip(
                        title: type.displayName,
                        icon: type.icon,
                        isSelected: viewModel.selectedQuestionType == type,
                        action: {
                            viewModel.selectedQuestionType = viewModel.selectedQuestionType == type ? nil : type
                            // 筛选条件改变后重新加载数据
                            Task {
                                await viewModel.loadQuestions()
                            }
                        }
                    )
                }
                
                // 筛选按钮
                Button(action: { showFilterSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("筛选")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.6, green: 0.4, blue: 0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
    }
    
    private func filterChip(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(.system(size: 14))
            }
            .foregroundColor(isSelected ? .white : Color(red: 0.6, green: 0.4, blue: 0.2))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color.white)
                    .shadow(color: Color.black.opacity(isSelected ? 0.1 : 0.05), radius: 4, y: 2)
            )
        }
    }
    
    // MARK: - Question List
    private var questionList: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(viewModel.questions.enumerated()), id: \.element.id) { index, question in
                questionCard(question: question, index: index)
            }
        }
    }
    
    private func questionCard(question: AIQuestion, index: Int) -> some View {
        Button(action: {
            viewModel.goToQuestion(at: index)
            viewModel.startAnswering()
            showAnswerView = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // 题目头部
                HStack {
                    // 题型标签
                    HStack(spacing: 4) {
                        Image(systemName: question.questionType.icon)
                            .font(.system(size: 12))
                        Text(question.questionType.displayName)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                    )
                    
                    // 难度标签
                    let difficultyColor = question.difficulty.color
                    Text(question.difficulty.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: difficultyColor.red, green: difficultyColor.green, blue: difficultyColor.blue))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(red: difficultyColor.red, green: difficultyColor.green, blue: difficultyColor.blue).opacity(0.15))
                        )
                    
                    Spacer()

                    // 正确率
                    if let rateString = question.accuracyRate, let rate = Double(rateString) {
                        Text(String(format: "%.0f%%", rate))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.45))
                    }
                }
                
                // 题目内容
                Text(question.question)
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // 底部信息
                HStack {
                    if let attempts = question.totalAttempts {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                                .font(.system(size: 12))
                            Text("\(attempts)人答过")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Color.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color.gray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("加载中...")
                .font(.system(size: 14))
                .foregroundColor(Color.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Polling View
    private var pollingView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.9)

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI正在生成题目")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                    Text(viewModel.pollingMessage)
                        .font(.system(size: 13))
                        .foregroundColor(Color.gray)
                }

                Spacer()

                Button(action: {
                    viewModel.stopPolling()
                }) {
                    Text("取消")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(red: 0.6, green: 0.4, blue: 0.2), lineWidth: 1)
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 1.0, green: 0.95, blue: 0.85))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("暂无题目")
                .font(.system(size: 16))
                .foregroundColor(Color.gray)
            
            Text("请尝试调整筛选条件")
                .font(.system(size: 14))
                .foregroundColor(Color.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Filter Sheet
    private var filterSheet: some View {
        NavigationView {
            List {
                // 难度筛选
                Section("难度") {
                    ForEach(QuestionDifficulty.allCases, id: \.self) { difficulty in
                        Button(action: {
                            viewModel.selectedDifficulty = viewModel.selectedDifficulty == difficulty ? nil : difficulty
                            // 筛选条件改变后重新加载数据
                            Task {
                                await viewModel.loadQuestions()
                            }
                        }) {
                            HStack {
                                Text(difficulty.displayName)
                                Spacer()
                                if viewModel.selectedDifficulty == difficulty {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("筛选条件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showFilterSheet = false
                    }
                }
            }
        }
    }
}

