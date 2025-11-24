import SwiftUI
import UIKit

// MARK: - 书籍阅读页面（支持API）
struct ClassicsReadingView: View {
    // 支持两种初始化方式
    let bookId: String?
    let bookTitle: String?
    let book: ClassicsBook?

    @Environment(\.dismiss) private var dismiss

    // API 数据状态
    @State private var bookDetail: ClassicsBookDetail?
    @State private var currentChapterDetail: ClassicsChapterDetail?
    @State private var isLoadingChapter = false
    @State private var errorMessage: String?
    @State private var userProgress: [ClassicsProgress] = []

    // 从 API 初始化
    init(bookId: String, bookTitle: String) {
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.book = nil
        // 初始化时设置为加载状态
        _isLoadingChapter = State(initialValue: true)
    }

    // 从本地 Book 初始化（兼容旧代码）
    init(book: ClassicsBook) {
        self.book = book
        self.bookId = nil
        self.bookTitle = nil
    }

    @State private var showSettings = false
    @State private var showChapterList = false
    @State private var showAudioPlayer = false
    @State private var currentChapterIndex = 0
    @State private var fontSize: CGFloat = 18
    @State private var lineSpacing: CGFloat = 8
    @State private var backgroundColor: Color = Color(.systemBackground)
    @State private var textColor: Color = Color(red: 0.2, green: 0.15, blue: 0.1)
    @State private var showPinyin: Bool = false
    @State private var showAnnotations: Bool = false
    @State private var showTranslation: Bool = false

    // 长按交互相关状态
    @State private var showTextActionMenu: Bool = false
    @State private var selectedText: String = ""
    @State private var showTextSelection: Bool = false
    @State private var isFavorite: Bool = false
    @State private var highlightColor: String? = nil  // yellow/green/blue/red
    @State private var showNoteInput: Bool = false
    @State private var noteText: String = ""
    @State private var showHighlightPicker: Bool = false
    @State private var viewingNote: AnnotatedNote? = nil
    // 背诵测试创建弹窗 + 配置
    @State private var showReciteSetup: Bool = false
    @State private var selectedTestType: ReciteTestType = .fillBlank
    // 仅保留测试类型
    @State private var showReciteRun: Bool = false
    @State private var lastResult: (type: ReciteTestType, questions: [ReciteQuestion], used: Int, total: Int)? = nil
    // 系统文本选择 + 自定义菜单
    @State private var coloredHighlights: [String: [ColoredHighlight]] = [:]  // 按 sectionId 存储高亮
    @State private var favorites: [AnnotatedExcerpt] = []
    @State private var notes: [String: [AnnotatedNote]] = [:]  // 按 sectionId 存储笔记
    @State private var reviewPlanMarks: [String: [ReviewPlanMark]] = [:]  // 按 sectionId 存储复习计划标记
    @State private var pendingRange: NSRange? = nil
    @State private var pendingExcerpt: String = ""
    @State private var currentSectionId: String? = nil  // 当前操作的 sectionId
    @State private var sectionMarks: [String: String] = [:]  // 每个 section 的标记 ID（sectionId -> markId）
    // Toast 提示
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    
    // 章节列表（支持API和本地数据）
    private var chapters: [ClassicsChapterAPI] {
        if let bookDetail = bookDetail {
            return bookDetail.chapters
        }
        // 兼容旧代码的默认章节
        return []
    }

    // 显示的书名
    private var displayBookTitle: String {
        if let bookDetail = bookDetail {
            return bookDetail.book.title
        } else if let bookTitle = bookTitle {
            return bookTitle
        } else if let book = book {
            return book.title
        }
        return "国学经典"
    }

    // 当前章节标题
    private var currentChapterTitle: String {
        if let detail = currentChapterDetail {
            return detail.chapter.chapterTitle
        }
        return "加载中..."
    }

    // 当前章节的 sections（用于背诵测试，包含音频 URL）
    private var currentChapterSections: [ClassicsSectionAPI] {
        guard let detail = currentChapterDetail else {
            return []
        }

        // 调试：打印每个 section 的 audioUrl
        print("📚 当前章节 sections 数量: \(detail.sections.count)")
        for (index, section) in detail.sections.enumerated() {
            print("  Section \(index + 1): audioUrl = \(section.audioUrl ?? "nil")")
        }

        return detail.sections
    }

    // 将拼音字符串（带数字声调）转换为标准拼音（带声调符号）
    private func convertPinyinTones(_ pinyin: String) -> String {
        let toneMap: [Character: [Character]] = [
            "a": ["ā", "á", "ǎ", "à", "a"],
            "e": ["ē", "é", "ě", "è", "e"],
            "i": ["ī", "í", "ǐ", "ì", "i"],
            "o": ["ō", "ó", "ǒ", "ò", "o"],
            "u": ["ū", "ú", "ǔ", "ù", "u"],
            "ü": ["ǖ", "ǘ", "ǚ", "ǜ", "ü"]
        ]

        var result = ""
        var currentSyllable = ""

        for char in pinyin {
            if char.isNumber {
                if let tone = Int(String(char)), tone >= 1 && tone <= 4 {
                    // 找到需要加声调的元音
                    var syllable = currentSyllable.lowercased()

                    // 声调规则：a/e 优先，否则 o，否则最后一个元音
                    if let aIndex = syllable.firstIndex(of: "a") {
                        let prefix = syllable[..<aIndex]
                        let suffix = syllable[syllable.index(after: aIndex)...]
                        if let toned = toneMap["a"]?[tone - 1] {
                            syllable = prefix + String(toned) + suffix
                        }
                    } else if let eIndex = syllable.firstIndex(of: "e") {
                        let prefix = syllable[..<eIndex]
                        let suffix = syllable[syllable.index(after: eIndex)...]
                        if let toned = toneMap["e"]?[tone - 1] {
                            syllable = prefix + String(toned) + suffix
                        }
                    } else if let oIndex = syllable.firstIndex(of: "o") {
                        let prefix = syllable[..<oIndex]
                        let suffix = syllable[syllable.index(after: oIndex)...]
                        if let toned = toneMap["o"]?[tone - 1] {
                            syllable = prefix + String(toned) + suffix
                        }
                    } else {
                        // 找最后一个元音
                        for vowel in ["u", "ü", "i"] {
                            if let vIndex = syllable.lastIndex(where: { String($0) == vowel }) {
                                let prefix = syllable[..<vIndex]
                                let suffix = syllable[syllable.index(after: vIndex)...]
                                if let toned = toneMap[Character(vowel)]?[tone - 1] {
                                    syllable = prefix + String(toned) + suffix
                                    break
                                }
                            }
                        }
                    }

                    result += syllable
                    currentSyllable = ""
                } else {
                    currentSyllable += String(char)
                }
            } else if char.isLetter {
                currentSyllable += String(char)
            } else {
                if !currentSyllable.isEmpty {
                    result += currentSyllable
                    currentSyllable = ""
                }
                result += String(char)
            }
        }

        if !currentSyllable.isEmpty {
            result += currentSyllable
        }

        return result
    }


    
    // 示例正文内容
    private var sampleContent: String {
        """
        合同编号：J-ZK75567202402140002房屋租赁合同
        
        同方方（出租方）：北京京融亦嘉科技有限公司乙方
        
        （承租方）：李旭杰
        
        北京市通州区房屋租赁合同
        
        根据《中华人民共和国民法典》等法律、法规的规定，甲乙双方经友好协商，在平等自愿的基础上，就房屋租赁有关事宜订立本合同。温馨提示：1.签署合同前,请仔细阅读合同中的条款，在知晓约定内容的情况下签署本合同，同时应当如实完成相关信息填写，并确保信息合法、真实、有效及完整。
        
        2.请勿私自向甲方工作人员个人支付任何钱款，经甲方同意向工作人员支付钱款的，乙方应要求甲方人员提供带有公司财务收据专用章的收款凭证。
        """
    }

    // 删除笔记
    private func deleteNote(_ note: AnnotatedNote) {
        // 从所有 section 的笔记中查找并删除
        var targetSectionId: String? = nil
        for (sectionId, var sectionNotes) in notes {
            if let index = sectionNotes.firstIndex(where: { $0.id == note.id }) {
                sectionNotes.remove(at: index)
                notes[sectionId] = sectionNotes
                targetSectionId = sectionId
                break
            }
        }
        viewingNote = nil

        // 调用 API 删除笔记
        if let sectionId = targetSectionId {
            Task {
                await deleteNoteFromAPI(sectionId: sectionId)
            }
        }
    }

    /// 从 API 删除笔记
    private func deleteNoteFromAPI(sectionId: String) async {
        guard AuthManager.shared.getCurrentUserId() != nil else {
            return
        }

        // 获取该段落的标记 ID
        guard let markId = sectionMarks[sectionId] else {
            print("⚠️ 未找到标记: sectionId=\(sectionId)")
            return
        }

        do {
            // 使用新的 deleteMark API
            try await ClassicsAPIService.shared.deleteMark(markId: markId)
            print("✅ 成功删除笔记: sectionId=\(sectionId)")
        } catch {
            await MainActor.run {
                toastMessage = "删除笔记失败: \(error.localizedDescription)"
                showToast = true
            }
        }
    }

    /// 从 API 删除高亮
    private func deleteHighlightFromAPI(sectionId: String) async {
        guard AuthManager.shared.getCurrentUserId() != nil else {
            return
        }

        // 获取该段落的标记 ID
        guard let markId = sectionMarks[sectionId] else {
            print("⚠️ 未找到标记: sectionId=\(sectionId)")
            return
        }

        do {
            // 使用新的 deleteMark API
            try await ClassicsAPIService.shared.deleteMark(markId: markId)
            await MainActor.run {
                toastMessage = "已删除高亮"
                showToast = true
            }
            print("✅ 成功删除高亮: sectionId=\(sectionId)")
        } catch {
            await MainActor.run {
                toastMessage = "删除高亮失败: \(error.localizedDescription)"
                showToast = true
            }
        }
    }

    /// 从 API 取消收藏
    private func deleteFavoriteFromAPI(sectionId: String) async {
        guard AuthManager.shared.getCurrentUserId() != nil else {
            return
        }

        // 获取该段落的标记 ID
        guard let markId = sectionMarks[sectionId] else {
            print("⚠️ 未找到标记: sectionId=\(sectionId)")
            return
        }

        do {
            // 使用新的 deleteMark API
            try await ClassicsAPIService.shared.deleteMark(markId: markId)
            await MainActor.run {
                isFavorite = false
                toastMessage = "已取消收藏"
                showToast = true
            }
            print("✅ 成功取消收藏: sectionId=\(sectionId)")
        } catch {
            await MainActor.run {
                toastMessage = "取消收藏失败: \(error.localizedDescription)"
                showToast = true
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            topNavigationBar

            // 阅读内容区域
            if isLoadingChapter {
                // 加载中状态
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color(red: 0.6, green: 0.4, blue: 0.2))

                    Text("正在加载章节...")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundColor)
            } else if let error = errorMessage {
                // 错误状态
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(Color(red: 0.8, green: 0.4, blue: 0.2))

                    Text(error)
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button(action: {
                        Task {
                            await loadCurrentChapter()
                        }
                    }) {
                        Text("重试")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.6, green: 0.4, blue: 0.2))
                            .cornerRadius(20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundColor)
            } else {
                // 正常阅读内容
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 章节标题
                        Text(currentChapterTitle)
                            .font(.system(size: fontSize + 6, weight: .bold))
                            .foregroundColor(textColor)
                            .padding(.top, 24)
                            .padding(.horizontal, 20)

                        // 正文内容
                        selectableContentView
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                    }
                }
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .background(backgroundColor)
            }

            // 底部工具栏
            bottomToolbar
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            // 页面加载时初始化数据
            await initializeData()
        }
        .sheet(isPresented: $showSettings) {
            readingSettingsSheet
        }
        .sheet(isPresented: $showChapterList) {
            chapterListSheet
        }
        .fullScreenCover(isPresented: $showAudioPlayer) {
            if let currentChapterDetail = currentChapterDetail,
               let audioBook = createAudioBook() {
                ClassicsAudioPlayerView(
                    book: audioBook,
                    bookId: bookId,
                    initialChapterId: currentChapterDetail.chapter.chapterId
                )
            }
        }
        // 旧的自定义覆盖菜单保留但不启用
        .overlay { EmptyView() }
        .sheet(isPresented: $showHighlightPicker) {
            highlightColorPickerSheet
        }
        .sheet(isPresented: $showNoteInput) {
            noteInputSheet
        }
        .sheet(item: $viewingNote) { note in
            noteDetailSheet(note)
        }
        .sheet(isPresented: $showReciteSetup) {
            reciteSetupSheet
        }
        .fullScreenCover(isPresented: $showReciteRun) {
            ReciteTestRunView(
                type: selectedTestType,
                sections: currentChapterSections,
                bookId: bookId,
                chapterId: currentChapterDetail?.chapter.chapterId
            ) { qs, used, total in
                showReciteRun = false
                lastResult = (selectedTestType, qs, used, total)
            }
        }
        // 可选：测试完成后，自动展示结果页
        .sheet(isPresented: Binding(get: { lastResult != nil }, set: { if !$0 { lastResult = nil } })) {
            if let r = lastResult {
                ReciteTestResultView(type: r.type, questions: r.questions, usedSeconds: r.used, totalSeconds: r.total)
            }
        }
        // Toast 提示
        .overlay(alignment: .top) {
            if showToast {
                ToastView(message: toastMessage, type: .success, onDismiss: {
                    showToast = false
                })
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            showToast = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // 返回按钮
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                        .frame(width: 32, height: 32)
                }

                // 书籍标题（支持API和本地数据）
                Text(displayBookTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .lineLimit(1)

                Spacer()

                // 右侧工具按钮
                HStack(spacing: 12) {
                    // 护眼模式
                    Button(action: { toggleEyeCareMode() }) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    }

                    // 章节列表
                    Button(action: { showChapterList = true }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    }

                    // 移除顶部朗读耳机图标（按需保留底部朗读）
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(backgroundColor)
        }
    }
    
    // MARK: - 底部工具栏
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // 听书
                Button(action: { showAudioPlayer.toggle() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 20, weight: .regular))
                        Text("听书")
                            .font(.system(size: 12, weight: .regular))
                    }
                    .foregroundColor(showAudioPlayer ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color(red: 0.5, green: 0.4, blue: 0.3))
                    .frame(maxWidth: .infinity)
                }

                // 背诵测试
                Button(action: { showReciteSetup = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 20, weight: .regular))
                        Text("背诵测试")
                            .font(.system(size: 12, weight: .regular))
                    }
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    .frame(maxWidth: .infinity)
                }

                // 阅读设置
                Button(action: { showSettings = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "textformat.size")
                            .font(.system(size: 20, weight: .regular))
                        Text("阅读设置")
                            .font(.system(size: 12, weight: .regular))
                    }
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)
            .background(backgroundColor)
        }
    }

    // MARK: - 阅读设置面板
    private var readingSettingsSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 字体大小
                VStack(alignment: .leading, spacing: 12) {
                    Text("字体大小")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    
                    HStack {
                        Text("A")
                            .font(.system(size: 14))
                        Slider(value: $fontSize, in: 14...28, step: 2)
                        Text("A")
                            .font(.system(size: 20, weight: .bold))
                    }
                }
                .padding(.horizontal, 20)
                
                // 行间距
                VStack(alignment: .leading, spacing: 12) {
                    Text("行间距")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    
                    Slider(value: $lineSpacing, in: 4...16, step: 2)
                }
                .padding(.horizontal, 20)
                
                // 背景颜色
                VStack(alignment: .leading, spacing: 12) {
                    Text("背景颜色")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    
                    HStack(spacing: 16) {
                        colorOption(color: Color(.systemBackground), name: "默认")
                        colorOption(color: Color(red: 0.98, green: 0.96, blue: 0.92), name: "护眼")
                        colorOption(color: Color(red: 0.95, green: 0.92, blue: 0.85), name: "米色")
                        colorOption(color: Color(red: 0.94, green: 0.96, blue: 0.90), name: "清茶")
                        colorOption(color: Color(red: 0.93, green: 0.89, blue: 0.80), name: "羊皮")
                        colorOption(color: Color(red: 0.15, green: 0.15, blue: 0.15), name: "夜间")
                    }
                }
                .padding(.horizontal, 20)

                // 显示选项
                VStack(alignment: .leading, spacing: 12) {
                    Text("显示选项")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                    Toggle("显示拼音", isOn: $showPinyin)
                        .tint(Color(red: 0.6, green: 0.4, blue: 0.2))
                    Toggle("显示翻译", isOn: $showTranslation)
                        .tint(Color(red: 0.6, green: 0.4, blue: 0.2))
                    Toggle("显示注释", isOn: $showAnnotations)
                        .tint(Color(red: 0.6, green: 0.4, blue: 0.2))
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("阅读设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showSettings = false
                    }
                }
            }
        }
    }

    // MARK: - 背诵测试创建面板（国风风格）
    private var reciteSetupSheet: some View {
        NavigationView {
            VStack(spacing: 18) {
                VStack(spacing: 16) {
                    // 测试类型
                    sectionHeader("测试类型")
                    testTypeGrid
                    // 其余选项已移除，仅保留测试类型
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.98, green: 0.96, blue: 0.93))
                        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 16)

                // 开始按钮（青绿色渐变 + 竹简风）
                Button(action: startReciteTest) {
                    Text("开始测试")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                LinearGradient(colors: [
                                    Color(red: 0.2, green: 0.6, blue: 0.5),
                                    Color(red: 0.15, green: 0.5, blue: 0.42)
                                ], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .clipShape(RoundedRectangle(cornerRadius: 14))

                                // 竹简风横纹
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                                VStack(spacing: 6) {
                                    ForEach(0..<3) { _ in
                                        Rectangle()
                                            .fill(Color.white.opacity(0.08))
                                            .frame(height: 1)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .padding(.top, 14)
            .navigationTitle("创建背诵测试")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(420)])
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.2))
            Spacer()
        }
    }

    // 测试类型卡片
    private var testTypeGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(ReciteTestType.allCases, id: \.self) { t in
                Button(action: { selectedTestType = t }) {
                    VStack(spacing: 6) {
                        Image(systemName: t.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(selectedTestType == t ? Color.white : Color(red: 0.45, green: 0.35, blue: 0.25))
                            .padding(12)
                            .background(
                                Circle().fill(
                                    selectedTestType == t ? Color(red: 0.2, green: 0.55, blue: 0.45) : Color.white.opacity(0.9)
                                )
                            )
                        Text(t.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.2))
                        if let sub = t.subtitle {
                            Text(sub)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTestType == t ? Color(red: 0.92, green: 0.96, blue: 0.94) : Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedTestType == t ? Color(red: 0.2, green: 0.55, blue: 0.45) : Color.black.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // 其他选项已删除（难度、遮挡模式）

    private func startReciteTest() {
        showReciteSetup = false
        // 延迟一点点以避免同时关闭/打开 sheet 的冲突
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showReciteRun = true
        }
    }
    
    // MARK: - 章节列表面板
    private var chapterListSheet: some View {
        NavigationView {
            List {
                ForEach(Array(chapters.enumerated()), id: \.offset) { index, chapter in
                    Button(action: {
                        currentChapterIndex = index
                        showChapterList = false

                        // 加载选中的章节
                        if let bookId = bookId {
                            Task {
                                await loadChapter(bookId: bookId, chapterId: chapter.chapterId)
                            }
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(chapter.chapterTitle)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                                Text("第 \(chapter.order) 章")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                            }

                            Spacer()

                            if index == currentChapterIndex {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                            }
                        }
                    }
                }
            }
            .navigationTitle("章节列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        showChapterList = false
                    }
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    private func colorOption(color: Color, name: String) -> some View {
        Button(action: {
            backgroundColor = color
            if name == "夜间" {
                textColor = Color(red: 0.9, green: 0.85, blue: 0.8)
            } else {
                textColor = Color(red: 0.2, green: 0.15, blue: 0.1)
            }
        }) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(backgroundColor == color ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color.clear, lineWidth: 3)
                    )
                
                Text(name)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
            }
        }
    }
    
    private func toggleEyeCareMode() {
        if backgroundColor == Color(.systemBackground) {
            backgroundColor = Color(red: 0.98, green: 0.96, blue: 0.92)
        } else {
            backgroundColor = Color(.systemBackground)
        }
    }

    // MARK: - 内容视图（拼音/注释/翻译）
    private var contentTextView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showPinyin {
                Text(toPinyin(sampleContent))
                    .font(.system(size: max(fontSize - 2, 12), weight: .regular))
                    .foregroundColor(textColor.opacity(0.8))
            }

            if showAnnotations {
                Text(annotatedContentAttributed)
                    .font(.system(size: fontSize, weight: .regular))
                    .foregroundColor(textColor)
                    .lineSpacing(lineSpacing)
                    .textSelection(.enabled)
                    .onLongPressGesture {
                        showTextSelection = true
                    }
            } else {
                Text(sampleContent)
                    .font(.system(size: fontSize, weight: .regular))
                    .foregroundColor(textColor)
                    .lineSpacing(lineSpacing)
                    .textSelection(.enabled)
                    .onLongPressGesture {
                        showTextSelection = true
                    }
            }

            if showTranslation {
                Divider()
                    .padding(.vertical, 6)
                Text("译文")
                    .font(.system(size: fontSize - 2, weight: .semibold))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                Text(sampleTranslation)
                    .font(.system(size: fontSize - 2, weight: .regular))
                    .foregroundColor(Color(red: 0.35, green: 0.3, blue: 0.25))
                    .lineSpacing(lineSpacing)
            }
        }
    }

    // 使用可选择文本 + 自定义菜单的内容视图（按小节显示）
    private var selectableContentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let detail = currentChapterDetail {
                // 按小节循环显示
                ForEach(Array(detail.sections.enumerated()), id: \.element.id) { index, section in
                VStack(alignment: .leading, spacing: 12) {
                    // 段落编号 + 原文
                    HStack(alignment: .top, spacing: 12) {
                        // 段落编号
                        Text("\(index + 1)")
                            .font(.system(size: fontSize - 2, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.45))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.1))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.3), lineWidth: 1.5)
                            )

                        // 原文（拼音 + 正文）
                        VStack(alignment: .leading, spacing: 4) {
                            // 拼音（如果开启）
                            if showPinyin, let pinyin = section.pinyin, !pinyin.isEmpty {
                                Text(convertPinyinTones(pinyin))
                                    .font(.system(size: max(fontSize * 0.5, 10), weight: .regular))
                                    .foregroundColor(textColor.opacity(0.6))
                                    .lineSpacing(lineSpacing * 0.5)
                            }

                            // 原文
                            createOriginalTextView(for: section)
                        }
                    }

                    // 2. 翻译（紧跟在原文后面，与原文对齐）
                    if showTranslation, let translation = section.translation, !translation.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            // 占位符（与编号对齐）
                            Spacer()
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("译文")
                                    .font(.system(size: fontSize - 4, weight: .semibold))
                                    .foregroundColor(Color(red: 0.5, green: 0.35, blue: 0.2))

                                Text(translation)
                                    .font(.system(size: fontSize - 2, weight: .regular))
                                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.25))
                                    .lineSpacing(lineSpacing * 0.8)
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.top, 4)
                    }

                    // 3. 注释（紧跟在翻译后面，与原文对齐）
                    if showAnnotations, let annotation = section.annotation, !annotation.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            // 占位符（与编号对齐）
                            Spacer()
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("注释")
                                    .font(.system(size: fontSize - 4, weight: .semibold))
                                    .foregroundColor(Color(red: 0.5, green: 0.35, blue: 0.2))

                                Text(annotation)
                                    .font(.system(size: fontSize - 3, weight: .regular))
                                    .foregroundColor(Color(red: 0.45, green: 0.35, blue: 0.3))
                                    .lineSpacing(lineSpacing * 0.7)
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.top, 4)
                    }

                    // 小节之间的分隔
                    if index < detail.sections.count - 1 {
                        Divider()
                            .padding(.vertical, 8)
                    }
                }
                }
            } else {
                Text("正在加载章节内容...")
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor.opacity(0.6))
            }
        }
    }

    // 创建原文文本视图
    private func createOriginalTextView(for section: ClassicsSectionAPI) -> some View {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing
        let attributedText = NSAttributedString(
            string: section.original,
            attributes: [
                .font: UIFont.systemFont(ofSize: fontSize),
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor(textColor)
            ]
        )

        // 获取当前 section 的高亮、笔记和复习计划标记
        let sectionHighlights = Binding<[ColoredHighlight]>(
            get: { coloredHighlights[section.id] ?? [] },
            set: { coloredHighlights[section.id] = $0 }
        )
        let sectionNotes = notes[section.id] ?? []
        let sectionReviewMarks = reviewPlanMarks[section.id] ?? []

        return SelectableTextView(
            attributedText: attributedText,
            coloredHighlights: sectionHighlights,
            notes: sectionNotes,
            reviewPlanMarks: sectionReviewMarks,
            onHighlight: { excerpt, range in
                // 保存当前 sectionId 和摘录信息
                currentSectionId = section.id
                pendingRange = range
                pendingExcerpt = excerpt
                showHighlightPicker = true
            },
            onFavorite: { excerpt, range in
                // 保存当前 sectionId 和摘录信息
                currentSectionId = section.id
                pendingRange = range
                pendingExcerpt = excerpt

                // 调用 API 添加收藏
                Task {
                    await addFavorite(sectionId: section.id)
                }
            },
            onNote: { excerpt, range in
                // 保存当前 sectionId 和摘录信息
                currentSectionId = section.id
                pendingRange = range
                pendingExcerpt = excerpt
                noteText = ""
                showNoteInput = true
            },
            onReviewPlan: { excerpt, range in
                // 传递 sectionId 到复习计划
                currentSectionId = section.id
                createReviewPlan(excerpt: excerpt, range: range, sectionId: section.id)
            },
            onTapNote: { note in
                viewingNote = note
            }
        )
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .id("\(section.id)-\(showPinyin)-\(fontSize)-\(lineSpacing)")  // 强制在设置改变时重新创建
    }

    // 示例翻译内容（实际可替换为服务端/本地数据）
    private var sampleTranslation: String {
        "本段为示例译文：对原文关键意思进行现代语言描述，便于快速理解原文含义。实际应用中可根据章节内容提供对应译文。"
    }

    // 将中文转换为拼音（不带声调）
    private func toPinyin(_ text: String) -> String {
        let mutable = NSMutableString(string: text) as CFMutableString
        CFStringTransform(mutable, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutable, nil, kCFStringTransformStripCombiningMarks, false)
        return mutable as String
    }

    // 带虚线下划线的注释示例：对部分关键词添加虚线
    private var annotatedAttributedContent: AttributedString {
        let keywords = ["合同", "租赁", "甲方", "乙方", "合同编号"]
        let attr = NSMutableAttributedString(string: sampleContent)
        let full = attr.string as NSString
        for key in keywords {
            var searchRange = NSRange(location: 0, length: full.length)
            while true {
                let found = full.range(of: key, options: [], range: searchRange)
                if found.location == NSNotFound { break }
                // 应用虚线下划线
                let style = NSUnderlineStyle.single.rawValue | NSUnderlineStyle.patternDash.rawValue
                attr.addAttributes([
                    .underlineStyle: style,
                    .underlineColor: UIColor.systemBrown
                ], range: found)
                let nextStart = found.location + found.length
                if nextStart >= full.length { break }
                searchRange = NSRange(location: nextStart, length: full.length - nextStart)
            }
        }
        // 兼容性：不使用 including: \.foundation，避免编译断行引发语法错误
        return (try? AttributedString(attr)) ?? AttributedString(sampleContent)
    }
    // 兼容版本：不指定 attribute scope 的构造，避免语法不兼容
    private var annotatedContentAttributed: AttributedString {
        let keywords = ["合同", "租赁", "甲方", "乙方", "合同编号"]
        let attr = NSMutableAttributedString(string: sampleContent)
        let full = attr.string as NSString
        for key in keywords {
            var searchRange = NSRange(location: 0, length: full.length)
            while true {
                let found = full.range(of: key, options: [], range: searchRange)
                if found.location == NSNotFound { break }
                let style = NSUnderlineStyle.single.rawValue | NSUnderlineStyle.patternDash.rawValue
                attr.addAttributes([
                    .underlineStyle: style,
                    .underlineColor: UIColor.systemBrown
                ], range: found)
                let nextStart = found.location + found.length
                if nextStart >= full.length { break }
                searchRange = NSRange(location: nextStart, length: full.length - nextStart)
            }
        }
        return (try? AttributedString(attr)) ?? AttributedString(sampleContent)
    }

    // MARK: - 长按文字交互菜单
    private var textActionMenuOverlay: some View {
        Group {
            if showTextSelection {
                VStack {
                    Spacer()
                        .frame(height: 120)

                    // 提示文字
                    Text("请选择要操作的文字")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

                    Spacer()

                    // 底部操作栏
                    HStack(spacing: 0) {
                        // 收藏按钮
                        Button(action: {
                            if let sectionId = currentSectionId {
                                if isFavorite {
                                    // 取消收藏
                                    Task {
                                        await deleteFavoriteFromAPI(sectionId: sectionId)
                                    }
                                } else {
                                    // 添加收藏
                                    Task {
                                        await addFavorite(sectionId: sectionId)
                                    }
                                }
                            }
                            showTextActionMenu = true
                            showTextSelection = false
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: isFavorite ? "star.fill" : "star")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundColor(isFavorite ? Color(red: 0.9, green: 0.7, blue: 0.2) : Color(red: 0.5, green: 0.4, blue: 0.3))
                                Text("收藏")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                            }
                            .frame(maxWidth: .infinity)
                        }

                        Divider()
                            .frame(height: 50)

                        // 高亮按钮
                        Button(action: {
                            showHighlightPicker = true
                            showTextSelection = false
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "highlighter")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundColor(highlightColorValue ?? Color(red: 0.5, green: 0.4, blue: 0.3))
                                Text("高亮")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                            }
                            .frame(maxWidth: .infinity)
                        }

                        Divider()
                            .frame(height: 50)

                        // 笔记按钮
                        Button(action: {
                            showNoteInput = true
                            showTextSelection = false
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                                Text("笔记")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                            }
                            .frame(maxWidth: .infinity)
                        }

                        Divider()
                            .frame(height: 50)

                        // 取消按钮
                        Button(action: {
                            showTextSelection = false
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                                Text("取消")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.98, green: 0.96, blue: 0.94))
                            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: -4)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom))
            }
        }
    }

    // 高亮颜色选择器
    private var highlightColorPickerSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("选择高亮颜色")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .padding(.top, 24)

                // 颜色选项
                HStack(spacing: 20) {
                    highlightColorOption(color: "yellow", displayColor: Color.yellow, name: "黄色")
                    highlightColorOption(color: "green", displayColor: Color.green, name: "绿色")
                    highlightColorOption(color: "blue", displayColor: Color.blue, name: "蓝色")
                    highlightColorOption(color: "red", displayColor: Color.red, name: "红色")
                }
                .padding(.horizontal, 20)

                // 删除高亮按钮
                if highlightColor != nil {
                    Button(action: {
                        if let sectionId = currentSectionId, let r = pendingRange {
                            // 从当前 section 的高亮数组中移除
                            var sectionHighlights = coloredHighlights[sectionId] ?? []
                            sectionHighlights.removeAll { $0.range.location == r.location && $0.range.length == r.length }
                            coloredHighlights[sectionId] = sectionHighlights

                            // 调用 API 删除高亮
                            Task {
                                await deleteHighlightFromAPI(sectionId: sectionId)
                            }
                        }
                        highlightColor = nil
                        showHighlightPicker = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                            Text("删除高亮")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showHighlightPicker = false
                    }
                }
            }
        }
        .presentationDetents([.height(280)])
    }

    // 高亮颜色选项
    private func highlightColorOption(color: String, displayColor: Color, name: String) -> some View {
        Button(action: {
            highlightColor = color

            // 只为当前 section 添加高亮
            if let sectionId = currentSectionId, let r = pendingRange {
                let uiColor: UIColor
                switch color {
                case "yellow": uiColor = .systemYellow
                case "green": uiColor = .systemGreen
                case "blue": uiColor = .systemBlue
                case "red": uiColor = .systemRed
                default: uiColor = .systemYellow
                }

                // 获取或创建当前 section 的高亮数组
                var sectionHighlights = coloredHighlights[sectionId] ?? []

                // 检查是否已存在相同位置的高亮
                if !sectionHighlights.contains(where: { $0.range.location == r.location && $0.range.length == r.length }) {
                    sectionHighlights.append(ColoredHighlight(range: r, color: uiColor))
                    coloredHighlights[sectionId] = sectionHighlights
                }

                // 调用 API 添加高亮
                Task {
                    await addHighlight(sectionId: sectionId, color: color)
                }
            }

            showHighlightPicker = false
        }) {
            VStack(spacing: 8) {
                Circle()
                    .fill(displayColor.opacity(0.6))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(highlightColor == color ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color.clear, lineWidth: 3)
                    )

                Text(name)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
            }
        }
    }

    // 笔记输入面板（重设计）
    private var noteInputSheet: some View {
        NavigationView {
            VStack(spacing: 14) {
                // 选中文本预览卡片
                VStack(alignment: .leading, spacing: 8) {
                    Text("选中内容")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    ScrollView {
                        Text(pendingExcerpt)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                    }.frame(maxHeight: 120)
                }
                .padding(.horizontal, 16)

                // 文本编辑区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("笔记内容")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(noteText.count)/300")
                            .font(.system(size: 12))
                            .foregroundColor(noteText.count > 300 ? .red : .secondary)
                    }
                    ZStack(alignment: .topLeading) {
                        if noteText.isEmpty {
                            Text("写点想法、释义或疑问…")
                                .foregroundColor(.secondary)
                                .padding(.top, 12)
                                .padding(.leading, 8)
                        }
                        TextEditor(text: $noteText)
                            .font(.system(size: 16))
                            .frame(minHeight: 180)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 0.8, green: 0.7, blue: 0.6), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showNoteInput = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty, trimmed.count <= 300, let r = pendingRange else { return }

                        // 调用 API 保存笔记
                        if let sectionId = currentSectionId {
                            Task {
                                await addNote(sectionId: sectionId, noteContent: trimmed)
                            }
                        } else {
                            // 如果没有 sectionId，仅保存到本地（使用临时 key）
                            let tempSectionId = "temp-\(UUID().uuidString)"
                            var sectionNotes = notes[tempSectionId] ?? []
                            sectionNotes.append(AnnotatedNote(text: pendingExcerpt, range: r, note: trimmed))
                            notes[tempSectionId] = sectionNotes
                        }

                        showNoteInput = false
                    }) {
                        Text("保存")
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || noteText.count > 300)
                }
            }
        }
        .presentationDetents([.height(420)])
    }

    // 笔记详情面板
    private func noteDetailSheet(_ note: AnnotatedNote) -> some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                Text("选中内容")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                ScrollView {
                    Text(note.text)
                        .font(.system(size: 16))
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                }.frame(maxHeight: 120)

                Text("笔记")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                ScrollView {
                    Text(note.note)
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("笔记详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("删除", role: .destructive) { deleteNote(note) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { viewingNote = nil }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // 获取高亮颜色值
    private var highlightColorValue: Color? {
        guard let color = highlightColor else { return nil }
        switch color {
        case "yellow": return Color.yellow
        case "green": return Color.green
        case "blue": return Color.blue
        case "red": return Color.red
        default: return nil
        }
    }

    // MARK: - 标记功能 API 对接

    /// 添加收藏
    private func addFavorite(sectionId: String) async {
        guard AuthManager.shared.getCurrentUserId() != nil else {
            await MainActor.run {
                toastMessage = "请先登录"
                showToast = true
            }
            return
        }

        do {
            // 构建 textRange（如果有选中文本）
            var textRange: TextRange? = nil
            if let range = pendingRange, !pendingExcerpt.isEmpty {
                textRange = TextRange(
                    startOffset: range.location,
                    endOffset: range.location + range.length,
                    text: pendingExcerpt
                )
            }

            let mark = try await ClassicsAPIService.shared.createMark(
                sectionId: sectionId,
                textRange: textRange,
                highlightColor: nil,
                note: nil,
                isFavorite: true
            )

            await MainActor.run {
                // 更新本地状态（保存标记 ID）
                sectionMarks[sectionId] = mark.id
                isFavorite = true

                // 添加到本地收藏列表
                if let range = pendingRange {
                    favorites.append(AnnotatedExcerpt(text: pendingExcerpt, range: range))
                }

                toastMessage = "已添加收藏"
                showToast = true
            }
        } catch {
            await MainActor.run {
                toastMessage = "收藏失败: \(error.localizedDescription)"
                showToast = true
            }
        }
    }

    /// 添加/更新高亮
    private func addHighlight(sectionId: String, color: String) async {
        guard AuthManager.shared.getCurrentUserId() != nil else {
            await MainActor.run {
                toastMessage = "请先登录"
                showToast = true
            }
            return
        }

        do {
            // 构建 textRange（如果有选中文本）
            var textRange: TextRange? = nil
            if let range = pendingRange, !pendingExcerpt.isEmpty {
                textRange = TextRange(
                    startOffset: range.location,
                    endOffset: range.location + range.length,
                    text: pendingExcerpt
                )
            }

            let mark = try await ClassicsAPIService.shared.createMark(
                sectionId: sectionId,
                textRange: textRange,
                highlightColor: color,
                note: nil,
                isFavorite: false
            )

            await MainActor.run {
                // 更新本地状态（保存标记 ID）
                sectionMarks[sectionId] = mark.id
                highlightColor = color

                toastMessage = "已添加高亮"
                showToast = true
            }
        } catch {
            await MainActor.run {
                toastMessage = "添加高亮失败: \(error.localizedDescription)"
                showToast = true
            }
        }
    }

    /// 添加/更新笔记
    private func addNote(sectionId: String, noteContent: String) async {
        guard AuthManager.shared.getCurrentUserId() != nil else {
            await MainActor.run {
                toastMessage = "请先登录"
                showToast = true
            }
            return
        }

        do {
            // 构建 textRange（如果有选中文本）
            var textRange: TextRange? = nil
            if let range = pendingRange, !pendingExcerpt.isEmpty {
                textRange = TextRange(
                    startOffset: range.location,
                    endOffset: range.location + range.length,
                    text: pendingExcerpt
                )
            }

            let mark = try await ClassicsAPIService.shared.createMark(
                sectionId: sectionId,
                textRange: textRange,
                highlightColor: nil,
                note: noteContent,
                isFavorite: false
            )

            await MainActor.run {
                // 更新本地状态（保存标记 ID）
                sectionMarks[sectionId] = mark.id

                // 添加到本地笔记列表（按 sectionId 存储）
                if let range = pendingRange {
                    var sectionNotes = notes[sectionId] ?? []
                    sectionNotes.append(AnnotatedNote(text: pendingExcerpt, range: range, note: noteContent))
                    notes[sectionId] = sectionNotes
                }

                toastMessage = "已保存笔记"
                showToast = true
            }
        } catch {
            await MainActor.run {
                toastMessage = "保存笔记失败: \(error.localizedDescription)"
                showToast = true
            }
        }
    }

    /// 加载复习计划数据
    private func loadReviewPlans(bookId: String) async {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            print("⚠️ 用户未登录，跳过加载复习计划")
            return
        }

        do {
            // 获取所有复习计划（不仅仅是到期的）
            let plans = try await ClassicsAPIService.shared.getReviewList(userId: userId, dueOnly: false)

            await MainActor.run {
                // 过滤当前书籍的复习计划，并按 sectionId 分组
                for plan in plans where plan.bookId == bookId {
                    let sectionId = plan.sectionId

                    // 转换为 ReviewPlanMark 格式
                    let mark = ReviewPlanMark(
                        id: plan.id,
                        text: plan.original ?? "",
                        range: NSRange(location: 0, length: plan.original?.count ?? 0),
                        nextReviewAt: plan.nextReviewAt,
                        reviewCount: plan.reviewCount,
                        isCompleted: false
                    )

                    // 添加到对应 sectionId 的数组中
                    var marks = reviewPlanMarks[sectionId] ?? []
                    marks.append(mark)
                    reviewPlanMarks[sectionId] = marks
                }

                print("✅ 成功加载复习计划: \(plans.filter { $0.bookId == bookId }.count) 条")
            }
        } catch {
            print("⚠️ 加载复习计划失败: \(error)")
        }
    }

    /// 加载用户标记数据
    private func loadUserMarks(bookId: String) async {
        guard AuthManager.shared.getCurrentUserId() != nil else {
            print("⚠️ 用户未登录，跳过加载标记数据")
            return
        }

        do {
            // 🔥 使用笔记中心 API 获取标记（支持最新的数据格式）
            let response = try await ClassicsAPIService.shared.getNotesCenterLatest(
                type: "all",
                bookId: bookId,
                limit: 1000,
                offset: 0
            )

            let marks = response.data

            await MainActor.run {
                // 🔥 按 sectionId 分组处理（不合并，而是正确处理多条笔记）
                var sectionGroups: [String: [ClassicsMark]] = [:]

                // 分组
                for mark in marks {
                    var group = sectionGroups[mark.sectionId] ?? []
                    group.append(mark)
                    sectionGroups[mark.sectionId] = group
                }

                // 处理每个段落的标记
                for (sectionId, marksInSection) in sectionGroups {
                    // 高亮：取最新的非空高亮
                    let highlight = marksInSection.compactMap { $0.highlightColor }.last

                    // 笔记：收集所有非空笔记
                    let notesList = marksInSection.compactMap { $0.note }.filter { !$0.isEmpty }

                    // 保存段落的标记 ID（用于删除操作）
                    if let firstMark = marksInSection.first {
                        sectionMarks[sectionId] = firstMark.id
                    }

                    // 转换高亮为 UI 状态
                    if let highlightColor = highlight {
                        let uiColor: UIColor
                        switch highlightColor {
                        case "yellow": uiColor = .systemYellow
                        case "green": uiColor = .systemGreen
                        case "blue": uiColor = .systemBlue
                        case "red": uiColor = .systemRed
                        case "pink": uiColor = .systemPink
                        case "purple": uiColor = .systemPurple
                        default: uiColor = .systemYellow
                        }

                        // 使用根级别的 original 字段
                        let originalText = marksInSection.first?.original ?? ""
                        var highlights = coloredHighlights[sectionId] ?? []
                        highlights.append(ColoredHighlight(
                            range: NSRange(location: 0, length: originalText.count),
                            color: uiColor
                        ))
                        coloredHighlights[sectionId] = highlights
                    }

                    // 转换所有笔记为 UI 状态
                    var sectionNotes: [AnnotatedNote] = []
                    for noteContent in notesList {
                        // 使用根级别的 original 字段
                        let originalText = marksInSection.first?.original ?? ""
                        sectionNotes.append(AnnotatedNote(
                            text: originalText,
                            range: NSRange(location: 0, length: originalText.count),
                            note: noteContent
                        ))
                    }
                    if !sectionNotes.isEmpty {
                        notes[sectionId] = sectionNotes
                    }
                }

                print("✅ 成功加载用户标记: \(marks.count) 条，涉及 \(sectionGroups.count) 个段落")
            }
        } catch {
            print("⚠️ 加载用户标记失败: \(error)")
        }
    }

    // MARK: - 创建复习计划
    private func createReviewPlan(excerpt: String, range: NSRange, sectionId: String) {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            toastMessage = "请先登录"
            showToast = true
            return
        }

        // 获取 bookId 和 chapterId
        guard let bookId = bookId,
              let chapterDetail = currentChapterDetail else {
            toastMessage = "缺少必要参数"
            showToast = true
            return
        }

        guard let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/classics/review/plan") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "userId": userId,
            "sectionId": sectionId,
            "bookId": bookId,
            "chapterId": chapterDetail.chapter.chapterId
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        print("📝 创建复习计划请求: userId=\(userId), sectionId=\(sectionId), bookId=\(bookId), chapterId=\(chapterDetail.chapter.chapterId)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    toastMessage = "创建失败：\(error.localizedDescription)"
                    showToast = true
                    return
                }

                guard let data = data else {
                    toastMessage = "创建失败：无响应数据"
                    showToast = true
                    return
                }

                // 打印原始响应用于调试
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📝 复习计划 API 响应: \(jsonString)")
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("📝 解析后的 JSON: \(json)")

                        guard let code = json["code"] as? Int else {
                            toastMessage = "响应格式错误：缺少 code 字段"
                            showToast = true
                            return
                        }

                        if code != 0 {
                            let message = json["message"] as? String ?? "未知错误"
                            toastMessage = "创建失败：\(message)"
                            showToast = true
                            return
                        }

                        guard let responseData = json["data"] as? [String: Any] else {
                            toastMessage = "响应格式错误：data 字段格式不正确"
                            showToast = true
                            print("❌ data 字段内容: \(json["data"] ?? "nil")")
                            return
                        }

                        guard let id = responseData["id"] as? String,
                              let nextReviewAt = responseData["nextReviewAt"] as? String,
                              let reviewCount = responseData["reviewCount"] as? Int else {
                            toastMessage = "响应格式错误：缺少必要字段"
                            showToast = true
                            print("❌ responseData 内容: \(responseData)")
                            return
                        }

                        // 创建复习计划标记，添加到对应的 section
                        let mark = ReviewPlanMark(
                            id: id,
                            text: excerpt,
                            range: range,
                            nextReviewAt: nextReviewAt,
                            reviewCount: reviewCount,
                            isCompleted: false
                        )

                        // 添加到对应 sectionId 的数组中
                        var marks = reviewPlanMarks[sectionId] ?? []
                        marks.append(mark)
                        reviewPlanMarks[sectionId] = marks

                        // 格式化下次复习时间
                        let formatter = DateFormatter()
                        formatter.dateFormat = "M月d日"
                        formatter.locale = Locale(identifier: "zh_CN")

                        let isoFormatter = ISO8601DateFormatter()
                        if let date = isoFormatter.date(from: nextReviewAt) {
                            let dateString = formatter.string(from: date)
                            toastMessage = "已加入复习计划，下次复习时间：\(dateString)"
                        } else {
                            toastMessage = "已加入复习计划"
                        }
                        showToast = true
                    } else {
                        toastMessage = "创建失败：响应格式错误"
                        showToast = true
                    }
                } catch {
                    toastMessage = "创建失败：\(error.localizedDescription)"
                    showToast = true
                }
            }
        }.resume()
    }

    // MARK: - API 数据加载方法

    /// 初始化数据
    private func initializeData() async {
        print("🔄 开始初始化数据...")
        // 如果是从 API 加载
        if let bookId = bookId {
            print("📚 BookID: \(bookId)")
            await loadBookDetail(bookId: bookId)
            await loadUserProgress(bookId: bookId)
            await loadUserMarks(bookId: bookId)        // 加载用户标记数据
            await loadReviewPlans(bookId: bookId)      // 加载复习计划数据

            // 加载第一个章节或用户上次阅读的章节
            if let firstChapter = chapters.first {
                print("📖 准备加载第一章: \(firstChapter.chapterTitle)")
                await loadChapterFromProgress(bookId: bookId, defaultChapterId: firstChapter.chapterId)
            } else {
                print("⚠️ 没有找到章节列表")
                await MainActor.run {
                    self.isLoadingChapter = false
                    self.errorMessage = "该书籍没有章节"
                }
            }
        } else {
            print("⚠️ 没有 bookId")
        }
    }

    /// 加载书籍详情
    private func loadBookDetail(bookId: String) async {
        print("🔄 开始加载书籍详情: \(bookId)")
        do {
            let detail = try await ClassicsAPIService.shared.getBookDetail(bookId: bookId)

            await MainActor.run {
                self.bookDetail = detail
                print("✅ 成功加载书籍详情: \(detail.book.title)")
                print("📚 章节数量: \(detail.chapters.count)")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载书籍详情失败: \(error.localizedDescription)"
                self.isLoadingChapter = false
                print("❌ 加载书籍详情失败: \(error)")
            }
        }
    }

    /// 加载用户学习进度
    private func loadUserProgress(bookId: String) async {
        guard let userId = AuthManager.shared.currentUser?.id else {
            print("⚠️ 用户未登录，跳过加载学习进度")
            return
        }

        do {
            let progressList = try await ClassicsAPIService.shared.getProgress(userId: userId, bookId: bookId)

            await MainActor.run {
                self.userProgress = progressList
                print("✅ 成功加载学习进度: \(progressList.count) 条记录")
            }
        } catch {
            print("⚠️ 加载学习进度失败: \(error)")
            // 不显示错误，因为这不是关键功能
        }
    }

    /// 根据学习进度加载章节（如果有进度则跳转到上次阅读位置）
    private func loadChapterFromProgress(bookId: String, defaultChapterId: String) async {
        var chapterIdToLoad = defaultChapterId

        // 查找最近的学习进度
        if let latestProgress = userProgress.sorted(by: { p1, p2 in
            guard let date1 = p1.lastReadAt, let date2 = p2.lastReadAt else { return false }
            return date1 > date2
        }).first {
            chapterIdToLoad = latestProgress.chapterId
            print("📖 找到上次阅读位置: \(latestProgress.chapterId)")
        }

        // 加载章节
        await loadChapter(bookId: bookId, chapterId: chapterIdToLoad)
    }

    /// 加载当前章节
    private func loadCurrentChapter() async {
        guard let bookId = bookId else { return }

        if currentChapterIndex < chapters.count {
            let chapterId = chapters[currentChapterIndex].chapterId
            await loadChapter(bookId: bookId, chapterId: chapterId)
        }
    }

    /// 加载指定章节
    private func loadChapter(bookId: String, chapterId: String) async {
        print("🔄 开始加载章节: bookId=\(bookId), chapterId=\(chapterId)")
        await MainActor.run {
            isLoadingChapter = true
            errorMessage = nil
        }

        do {
            let detail = try await ClassicsAPIService.shared.getChapterDetail(bookId: bookId, chapterId: chapterId)

            await MainActor.run {
                self.currentChapterDetail = detail
                self.isLoadingChapter = false
                print("✅ 成功加载章节: \(detail.chapter.chapterTitle)")
                print("📝 句段数量: \(detail.sections.count)")

                // 🔥 重要：每次加载章节时都重新加载标记数据
                Task {
                    // 先清空当前章节的标记数据
                    await clearCurrentChapterMarks(chapterId: chapterId)

                    // 重新加载标记数据
                    await loadUserMarks(bookId: bookId)
                    await loadReviewPlans(bookId: bookId)

                    // 记录学习进度
                    await recordReadingProgress(bookId: bookId, chapterId: chapterId)
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载章节失败: \(error.localizedDescription)"
                self.isLoadingChapter = false
                print("❌ 加载章节失败: \(error)")
                print("❌ 错误详情: \(error)")
            }
        }
    }

    /// 清空当前章节的标记数据
    private func clearCurrentChapterMarks(chapterId: String) async {
        await MainActor.run {
            // 清空高亮数据
            if let detail = currentChapterDetail {
                for section in detail.sections {
                    coloredHighlights[section.id] = []
                    notes[section.id] = []
                    reviewPlanMarks[section.id] = []
                }
            }

            print("🧹 已清空章节 \(chapterId) 的标记数据")
        }
    }

    /// 记录阅读进度
    private func recordReadingProgress(bookId: String, chapterId: String) async {
        guard let userId = AuthManager.shared.currentUser?.id else {
            print("⚠️ 用户未登录，跳过记录学习进度")
            return
        }

        guard let detail = currentChapterDetail,
              let firstSection = detail.sections.first else {
            print("⚠️ 没有章节内容，跳过记录学习进度")
            return
        }

        do {
            let progress = try await ClassicsAPIService.shared.recordProgress(
                userId: userId,
                bookId: bookId,
                chapterId: chapterId,
                sectionId: firstSection.id,
                mode: "read"
            )

            print("✅ 成功记录学习进度: \(progress.bookId) - \(progress.chapterId)")
        } catch {
            print("⚠️ 记录学习进度失败: \(error)")
            // 不显示错误，因为这不是关键功能
        }
    }
}

// MARK: - 背诵测试枚举
enum ReciteTestType: CaseIterable {
    case fillBlank   // 填空（部分遮挡）
    case dictation   // 听写（播放语音，不显示文字）
    case memory      // 默写（空白输入）
    case listening   // 听力（播放音频，答题区填写原文）

    var title: String {
        switch self {
        case .fillBlank: return "填空"
        case .dictation: return "听写"
        case .memory: return "默写"
        case .listening: return "听力"
        }
    }
    var subtitle: String? {
        switch self {
        case .fillBlank: return "遮挡部分文字进行填空"
        case .dictation: return "播放语音，不显示文字"
        case .memory: return "空白输入整段/全文"
        case .listening: return "播放音频，答题区填写原文"
        }
    }
    var icon: String {
        switch self {
        case .fillBlank: return "square.grid.3x3.fill"
        case .dictation: return "mic.circle.fill"
        case .memory: return "square.and.pencil"
        case .listening: return "ear"
        }
    }
}

// 仅保留 ReciteTestType，其余配置枚举移除

// MARK: - 辅助方法扩展
extension ClassicsReadingView {
    /// 创建用于听书页面的 ClassicsBook 对象
    private func createAudioBook() -> ClassicsBook? {
        if let book = book {
            // 使用已有的 book 对象
            return book
        } else if let bookDetail = bookDetail {
            // 从 API 数据创建临时 book 对象
            return ClassicsBook(
                title: bookDetail.book.title,
                author: bookDetail.book.author,
                category: mapCategory(bookDetail.book.category),
                coverColors: getCoverColors(for: bookDetail.book.category),
                introduction: nil,
                description: bookDetail.book.description,
                hasVernacular: false,
                isProofread: false
            )
        } else {
            // 创建默认 book 对象
            return ClassicsBook(
                title: displayBookTitle,
                author: nil,
                category: .confucian,
                coverColors: [Color(red: 0.8, green: 0.3, blue: 0.2), Color(red: 0.6, green: 0.2, blue: 0.1)],
                introduction: nil,
                description: nil,
                hasVernacular: false,
                isProofread: false
            )
        }
    }

    /// 映射 API 分类到本地分类
    private func mapCategory(_ apiCategory: String) -> ClassicsCategory {
        switch apiCategory {
        case "confucian": return .confucian
        case "taoist": return .taoist
        case "buddhist": return .buddhist
        case "poetry": return .poetry
        case "historical": return .historical
        case "medical": return .medical
        default: return .confucian
        }
    }

    /// 根据分类获取封面颜色
    private func getCoverColors(for category: String) -> [Color] {
        switch category {
        // 英文分类
        case "confucian":
            return [Color(red: 0.8, green: 0.3, blue: 0.2), Color(red: 0.6, green: 0.2, blue: 0.1)]
        case "taoist":
            return [Color(red: 0.4, green: 0.5, blue: 0.6), Color(red: 0.3, green: 0.4, blue: 0.5)]
        case "buddhist":
            return [Color(red: 0.7, green: 0.5, blue: 0.2), Color(red: 0.6, green: 0.4, blue: 0.1)]
        case "poetry":
            return [Color(red: 0.35, green: 0.45, blue: 0.55), Color(red: 0.25, green: 0.35, blue: 0.45)]
        case "historical":
            return [Color(red: 0.5, green: 0.4, blue: 0.3), Color(red: 0.4, green: 0.3, blue: 0.2)]
        case "medical":
            return [Color(red: 0.3, green: 0.5, blue: 0.4), Color(red: 0.2, green: 0.4, blue: 0.3)]
        // 中文分类（API返回的格式）
        case "儒家", "儒家经典":
            return [Color(red: 0.8, green: 0.3, blue: 0.2), Color(red: 0.6, green: 0.2, blue: 0.1)]
        case "道家", "道家经典":
            return [Color(red: 0.4, green: 0.5, blue: 0.6), Color(red: 0.3, green: 0.4, blue: 0.5)]
        case "佛家", "佛家经典":
            return [Color(red: 0.7, green: 0.5, blue: 0.2), Color(red: 0.6, green: 0.4, blue: 0.1)]
        case "诗词", "诗词歌赋", "诗歌经典":
            return [Color(red: 0.35, green: 0.45, blue: 0.55), Color(red: 0.25, green: 0.35, blue: 0.45)]
        case "史学", "史学经典":
            return [Color(red: 0.5, green: 0.4, blue: 0.3), Color(red: 0.4, green: 0.3, blue: 0.2)]
        case "医学", "医学经典":
            return [Color(red: 0.3, green: 0.5, blue: 0.4), Color(red: 0.2, green: 0.4, blue: 0.3)]
        default:
            return [Color(red: 0.8, green: 0.3, blue: 0.2), Color(red: 0.6, green: 0.2, blue: 0.1)]
        }
    }
}

// MARK: - 预览
#Preview {
    NavigationStack {
        ClassicsReadingView(book: ClassicsBook(
            title: "房屋租赁合同",
            author: "示例作者",
            category: .confucian,
            coverColors: [Color(red: 0.8, green: 0.3, blue: 0.2), Color(red: 0.6, green: 0.2, blue: 0.1)],
            introduction: "示例简介",
            description: nil,
            hasVernacular: true,
            isProofread: true
        ))
    }
}
