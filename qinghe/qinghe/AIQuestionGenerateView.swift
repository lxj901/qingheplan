import SwiftUI

// MARK: - AI题目生成视图
struct AIQuestionGenerateView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AIQuestionViewModel

    @State private var selectedBookId: String = ""
    @State private var selectedChapterId: String = ""
    @State private var selectedQuestionTypes: Set<QuestionType> = [.choice]
    @State private var selectedDifficulty: QuestionDifficulty = .easy
    @State private var countPerType: Int = 5
    @State private var batchName: String = ""

    @State private var showSuccess: Bool = false

    // 书籍和章节数据
    @State private var books: [ClassicsBookAPI] = []
    @State private var chapters: [ClassicsChapterAPI] = []
    @State private var isLoadingBooks: Bool = false
    @State private var isLoadingChapters: Bool = false
    @State private var errorMessage: String?
    
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

                // 内容区域
                if isLoadingBooks {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 书籍选择
                            bookSelectionSection

                            // 章节选择
                            if !selectedBookId.isEmpty {
                                chapterSelectionSection
                            }

                            // 题型选择
                            questionTypeSection

                            // 难度选择
                            difficultySection

                            // 数量设置
                            countSection

                            // 批次名称
                            batchNameSection

                            // 生成按钮
                            generateButton
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }

            // 成功提示
            if showSuccess {
                successOverlay
            }
        }
        // 隐藏系统导航栏，避免出现大标题造成的顶部额外高度
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            loadBooks()
        }
        .alert("错误", isPresented: .constant(errorMessage != nil)) {
            Button("确定", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
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
            Text("生成题目")
                .font(AppFont.kangxi(size: 20))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

            Spacer()

            // 占位，保持标题居中
            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .frame(height: 44)
        .background(Color.white.opacity(0.3))
    }
    
    // MARK: - Book Selection Section
    private var bookSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择书籍")
                .font(AppFont.kangxi(size: 16))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

            if books.isEmpty {
                Text("暂无书籍数据")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(books, id: \.id) { book in
                            bookButton(book: book)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        )
    }

    private func bookButton(book: ClassicsBookAPI) -> some View {
        Button(action: {
            selectedBookId = book.bookId
            selectedChapterId = "" // 重置章节选择
            loadChapters(bookId: book.bookId)
        }) {
            Text(book.title)
                .font(.system(size: 15))
                .foregroundColor(selectedBookId == book.bookId ? .white : Color(red: 0.6, green: 0.4, blue: 0.2))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedBookId == book.bookId ?
                              Color(red: 0.6, green: 0.4, blue: 0.2) :
                              Color(red: 0.95, green: 0.93, blue: 0.9))
                )
        }
    }
    
    // MARK: - Chapter Selection Section
    private var chapterSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择章节")
                .font(AppFont.kangxi(size: 16))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

            if isLoadingChapters {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if chapters.isEmpty {
                Text("暂无章节数据")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(chapters, id: \.id) { chapter in
                            chapterButton(chapter: chapter)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        )
    }

    private func chapterButton(chapter: ClassicsChapterAPI) -> some View {
        Button(action: { selectedChapterId = chapter.chapterId }) {
            Text(chapter.chapterTitle)
                .font(.system(size: 15))
                .foregroundColor(selectedChapterId == chapter.chapterId ? .white : Color(red: 0.6, green: 0.4, blue: 0.2))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedChapterId == chapter.chapterId ?
                              Color(red: 0.6, green: 0.4, blue: 0.2) :
                              Color(red: 0.95, green: 0.93, blue: 0.9))
                )
        }
    }
    
    // MARK: - Question Type Section
    private var questionTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择题型（可多选）")
                .font(AppFont.kangxi(size: 16))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            
            VStack(spacing: 10) {
                ForEach(QuestionType.allCases, id: \.self) { type in
                    questionTypeRow(type: type)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        )
    }
    
    private func questionTypeRow(type: QuestionType) -> some View {
        Button(action: {
            if selectedQuestionTypes.contains(type) {
                selectedQuestionTypes.remove(type)
            } else {
                selectedQuestionTypes.insert(type)
            }
        }) {
            HStack {
                Image(systemName: selectedQuestionTypes.contains(type) ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(selectedQuestionTypes.contains(type) ? 
                                   Color(red: 0.6, green: 0.4, blue: 0.2) : 
                                   Color.gray.opacity(0.5))
                
                Text(type.displayName)
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Difficulty Section
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择难度")
                .font(AppFont.kangxi(size: 16))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            
            HStack(spacing: 12) {
                ForEach(QuestionDifficulty.allCases, id: \.self) { difficulty in
                    difficultyButton(difficulty: difficulty)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        )
    }
    
    private func difficultyButton(difficulty: QuestionDifficulty) -> some View {
        Button(action: { selectedDifficulty = difficulty }) {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color(red: difficulty.color.red, green: difficulty.color.green, blue: difficulty.color.blue))
                    .frame(width: 24, height: 24)

                Text(difficulty.displayName)
                    .font(.system(size: 14))
                    .foregroundColor(selectedDifficulty == difficulty ? .white : Color(red: 0.6, green: 0.4, blue: 0.2))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedDifficulty == difficulty ?
                          Color(red: 0.6, green: 0.4, blue: 0.2) :
                          Color(red: 0.95, green: 0.93, blue: 0.9))
            )
        }
    }
    
    // MARK: - Count Section
    private var countSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("每种题型生成数量")
                    .font(AppFont.kangxi(size: 16))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                Spacer()

                Text("最多5道")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            HStack(spacing: 16) {
                Button(action: { if countPerType > 1 { countPerType -= 1 } }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(countPerType > 1 ? Color(red: 0.6, green: 0.4, blue: 0.2) : .gray.opacity(0.5))
                }
                .disabled(countPerType <= 1)

                Text("\(countPerType)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .frame(minWidth: 60)

                Button(action: { if countPerType < 5 { countPerType += 1 } }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(countPerType < 5 ? Color(red: 0.6, green: 0.4, blue: 0.2) : .gray.opacity(0.5))
                }
                .disabled(countPerType >= 5)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        )
    }
    
    // MARK: - Batch Name Section
    private var batchNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("批次名称（可选）")
                .font(AppFont.kangxi(size: 16))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            
            TextField("例如：论语学而测试", text: $batchName)
                .font(.system(size: 15))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.95, green: 0.93, blue: 0.9))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        )
    }
    
    // MARK: - Generate Button
    private var generateButton: some View {
        VStack(spacing: 8) {
            Button(action: generateQuestions) {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                    }

                    Text(viewModel.isLoading ? "生成中..." : "开始生成")
                        .font(AppFont.kangxi(size: 18))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.7, green: 0.5, blue: 0.3),
                                    Color(red: 0.6, green: 0.4, blue: 0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
                )
            }
            .disabled(isGenerateButtonDisabled)
            .opacity(isGenerateButtonDisabled ? 0.5 : 1.0)

            // 提示信息
            if !canGenerate {
                Text(generateButtonHint)
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.8))
            }
        }
    }

    // 生成按钮是否禁用
    private var isGenerateButtonDisabled: Bool {
        return viewModel.isLoading || !canGenerate
    }

    // 是否可以生成
    private var canGenerate: Bool {
        return !selectedBookId.isEmpty &&
               !selectedChapterId.isEmpty &&
               !selectedQuestionTypes.isEmpty &&
               countPerType >= 1 &&
               countPerType <= 5
    }

    // 生成按钮提示
    private var generateButtonHint: String {
        if selectedBookId.isEmpty {
            return "请选择书籍"
        } else if selectedChapterId.isEmpty {
            return "请选择章节"
        } else if selectedQuestionTypes.isEmpty {
            return "请至少选择一种题型"
        } else if countPerType < 1 || countPerType > 5 {
            return "每种题型数量必须在1-5之间"
        }
        return ""
    }
    
    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("生成成功！")
                    .font(AppFont.kangxi(size: 20))
                    .foregroundColor(.white)
                
                Text("已生成 \(selectedQuestionTypes.count * countPerType) 道题目")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.2, green: 0.15, blue: 0.1))
            )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSuccess = false
                dismiss()
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            Text("加载书籍列表...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
        }
    }

    // MARK: - Actions
    private func loadBooks() {
        guard books.isEmpty else { return }

        isLoadingBooks = true

        Task {
            do {
                let loadedBooks = try await ClassicsAPIService.shared.getBooks(limit: 100)
                await MainActor.run {
                    self.books = loadedBooks
                    self.isLoadingBooks = false

                    // 默认选择第一本书
                    if let firstBook = loadedBooks.first {
                        self.selectedBookId = firstBook.bookId
                        loadChapters(bookId: firstBook.bookId)
                    }

                    print("✅ 成功加载 \(loadedBooks.count) 本书籍")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载书籍失败: \(error.localizedDescription)"
                    self.isLoadingBooks = false
                    print("❌ 加载书籍失败: \(error)")
                }
            }
        }
    }

    private func loadChapters(bookId: String) {
        isLoadingChapters = true
        chapters = []

        Task {
            do {
                let bookDetail = try await ClassicsAPIService.shared.getBookDetail(bookId: bookId)
                await MainActor.run {
                    self.chapters = bookDetail.chapters
                    self.isLoadingChapters = false

                    // 默认选择第一个章节
                    if let firstChapter = bookDetail.chapters.first {
                        self.selectedChapterId = firstChapter.chapterId
                    }

                    print("✅ 成功加载 \(bookDetail.chapters.count) 个章节")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载章节失败: \(error.localizedDescription)"
                    self.isLoadingChapters = false
                    print("❌ 加载章节失败: \(error)")
                }
            }
        }
    }

    private func generateQuestions() {
        guard canGenerate else { return }

        Task {
            await viewModel.generateQuestions(
                bookId: selectedBookId,
                chapterId: selectedChapterId,
                questionTypes: Array(selectedQuestionTypes),
                difficulty: selectedDifficulty,
                countPerType: countPerType,
                batchName: batchName.isEmpty ? nil : batchName
            )

            // 生成完成后显示成功提示
            if !viewModel.questions.isEmpty {
                showSuccess = true
            }
        }
    }
}
