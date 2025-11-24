import SwiftUI
import AVFoundation

// MARK: - 测试题目模型
struct ReciteQuestion: Identifiable {
    let id = UUID()
    let original: String          // 原句
    let display: String           // 显示给用户的内容（填空时为遮挡文本，其他类型为提示）
    let answerKey: String         // 正确答案（用于比对）
    let audioUrl: String?         // 阿里云 TTS 音频 URL（用于听写和听力测试）
    var userAnswer: String = ""   // 用户作答
}

// MARK: - 测试进行页
struct ReciteTestRunView: View {
    let type: ReciteTestType
    let sections: [ClassicsSectionAPI]  // 使用 sections 数据（包含 audioUrl）
    let bookId: String?  // 书籍ID（用于刷新音频URL）
    let chapterId: String?  // 章节ID（用于刷新音频URL）
    let onFinish: (([ReciteQuestion], Int, Int) -> Void)? // (题目列表, 用时秒, 总时长秒)

    @State private var questions: [ReciteQuestion] = []
    @State private var currentIndex: Int = 0
    @State private var totalSeconds: Int = 180
    @State private var remaining: Int = 180
    @State private var timerActive = true
    @State private var showSubmitConfirm = false
    @Environment(\.dismiss) private var dismiss

    // 音频播放器
    @State private var audioPlayer: AVPlayer?
    @State private var isPlayingAudio = false

    var body: some View {
        ZStack {
            // 背景渐变 - 古典雅致
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.93),
                    Color(red: 0.94, green: 0.92, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 主内容
            VStack(spacing: 0) {
                // 导航栏
                customNavigationBar

                ScrollView {
                    VStack(spacing: 16) {
                        // 顶部信息卡片
                        headerCard

                        // 进度指示器
                        progressSection

                        // 题目区域
                        questionCard

                        // 答题区域
                        answerCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }

            // 底部操作栏（悬浮）
            VStack {
                Spacer()
                floatingActionBar
            }
        }
        // 隐藏系统导航栏，避免出现大标题造成的顶部额外高度
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            buildQuestionsIfNeeded()
            // 所有测试类型都不启动计时器，用户可以自由控制答题节奏
            // startTimer() // 已禁用时间限制
        }
        .onDisappear { stopAudio() }
        .alert("提交答卷？", isPresented: $showSubmitConfirm) {
            Button("取消", role: .cancel) {}
            Button("提交", role: .destructive) { submit() }
        } message: {
            Text("确认提交后将无法修改答案")
        }
    }

    // MARK: - UI 片段

    // 自定义导航栏
    private var customNavigationBar: some View {
        HStack(spacing: 16) {
            // 退出按钮
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("退出")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.7))
                )
            }

            Spacer()

            // 测试类型标题
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

            Spacer()

            // 占位，保持居中
            Color.clear.frame(width: 70)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .frame(height: 44)
        .background(Color.white.opacity(0.3))
    }

    // 顶部信息卡片
    private var headerCard: some View {
        HStack(spacing: 0) {
            // 题目进度 - 居中显示
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("第")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
                Text("\(currentIndex + 1)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.45))
                Text("题")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
                Text("/ 共 \(questions.count) 题")
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 70)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                // 装饰性竹简纹理
                HStack(spacing: 40) {
                    ForEach(0..<5) { _ in
                        Rectangle()
                            .fill(Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.03))
                            .frame(width: 2)
                    }
                }
            }
        )
    }

    // 进度条区域
    private var progressSection: some View {
        VStack(spacing: 12) {
            // 进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 背景轨道
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(red: 0.9, green: 0.88, blue: 0.85))
                        .frame(height: 12)

                    // 进度填充
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.6, blue: 0.5),
                                    Color(red: 0.15, green: 0.5, blue: 0.42)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth(in: geo.size.width), height: 12)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentIndex)

                    // 进度点
                    HStack(spacing: 0) {
                        ForEach(0..<questions.count, id: \.self) { index in
                            Circle()
                                .fill(index <= currentIndex ? Color.white : Color.clear)
                                .frame(width: 8, height: 8)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .frame(height: 12)

            // 进度文字
            HStack {
                Text("已完成 \(currentIndex + 1) 题")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                Spacer()
                Text("还剩 \(questions.count - currentIndex - 1) 题")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
            }
        }
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard questions.count > 0 else { return 0 }
        let ratio = CGFloat(currentIndex + 1) / CGFloat(questions.count)
        return totalWidth * ratio
    }

    // 题目卡片
    private var questionCard: some View {
        Group {
            if questions.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // 题目标题
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.45))
                        Text("题目内容")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                        Spacer()
                    }

                    // 题目内容区域
                    if type == .fillBlank {
                        // 填空题 - 显示遮挡文本
                        Text(questions[currentIndex].display)
                            .font(.system(size: 19, weight: .medium))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                            .lineSpacing(8)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.98, green: 0.97, blue: 0.95))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.2), lineWidth: 1.5)
                            )
                    } else if type == .dictation || type == .listening {
                        // 听写/听力题 - 播放按钮
                        VStack(spacing: 16) {
                            Button(action: speakCurrent) {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: isPlayingAudio ? [
                                                        Color(red: 0.8, green: 0.4, blue: 0.3),
                                                        Color(red: 0.7, green: 0.3, blue: 0.2)
                                                    ] : [
                                                        Color(red: 0.2, green: 0.6, blue: 0.5),
                                                        Color(red: 0.15, green: 0.5, blue: 0.42)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 80, height: 80)
                                            .shadow(color: Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.3), radius: 8, x: 0, y: 4)

                                        Image(systemName: isPlayingAudio ? "pause.fill" : "play.fill")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.white)
                                    }

                                    Text(isPlayingAudio ? "播放中..." : (type == .dictation ? "点击播放音频" : "听音后填写原文"))
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.98, green: 0.97, blue: 0.95))
                            )
                        }
                    } else {
                        // 默写题 - 提示文字
                        VStack(spacing: 12) {
                            Image(systemName: "pencil.and.outline")
                                .font(.system(size: 40))
                                .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.6))

                            Text("默写：请在下方输入原文")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.98, green: 0.97, blue: 0.95))
                        )
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                )
            }
        }
    }

    // 答题卡片
    private var answerCard: some View {
        Group {
            if questions.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // 答题区标题
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.45))
                        Text("答题区")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                        Spacer()

                        // 字数统计
                        Text("\(questions[currentIndex].userAnswer.count) 字")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    }

                    // 输入框
                    ZStack(alignment: .topLeading) {
                        if questions[currentIndex].userAnswer.isEmpty {
                            Text("请在此输入答案...")
                                .font(.system(size: 17))
                                .foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.6))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                        }

                        TextEditor(text: Binding(
                            get: { questions[currentIndex].userAnswer },
                            set: { updateAnswer($0) }
                        ))
                        .font(.system(size: 17))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 150)
                        .padding(8)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.98, green: 0.97, blue: 0.95))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.2), lineWidth: 1.5)
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                )
            }
        }
    }

    // 悬浮操作栏
    private var floatingActionBar: some View {
        VStack(spacing: 0) {
            // 渐变遮罩
            LinearGradient(
                colors: [
                    Color.clear,
                    Color(red: 0.96, green: 0.95, blue: 0.93).opacity(0.8),
                    Color(red: 0.96, green: 0.95, blue: 0.93)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)

            // 按钮区域
            HStack(spacing: 12) {
                // 上一题
                Button(action: prev) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("上一题")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(currentIndex == 0 ? Color.gray.opacity(0.2) : Color.white)
                            .shadow(color: Color.black.opacity(currentIndex == 0 ? 0 : 0.08), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.2, green: 0.55, blue: 0.45).opacity(currentIndex == 0 ? 0.2 : 0.5), lineWidth: 1.5)
                    )
                    .foregroundColor(currentIndex == 0 ? Color.gray : Color(red: 0.2, green: 0.55, blue: 0.45))
                }
                .disabled(currentIndex == 0)

                // 下一题
                Button(action: next) {
                    HStack(spacing: 6) {
                        Text("下一题")
                            .font(.system(size: 16, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(currentIndex >= questions.count - 1 ? Color.gray.opacity(0.2) : Color.white)
                            .shadow(color: Color.black.opacity(currentIndex >= questions.count - 1 ? 0 : 0.08), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.2, green: 0.55, blue: 0.45).opacity(currentIndex >= questions.count - 1 ? 0.2 : 0.5), lineWidth: 1.5)
                    )
                    .foregroundColor(currentIndex >= questions.count - 1 ? Color.gray : Color(red: 0.2, green: 0.55, blue: 0.45))
                }
                .disabled(currentIndex >= questions.count - 1)

                // 提交
                Button(action: { showSubmitConfirm = true }) {
                    Text("提交答卷")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.6, blue: 0.5),
                                    Color(red: 0.15, green: 0.5, blue: 0.42)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(red: 0.96, green: 0.95, blue: 0.93))
        }
    }

    // MARK: - 行为
    private var title: String {
        switch type { case .fillBlank: return "填空"; case .dictation: return "听写"; case .memory: return "默写"; case .listening: return "听力" }
    }

    private func buildQuestionsIfNeeded() {
        guard questions.isEmpty else { return }

        // 使用 sections 数据生成题目（每个 section 对应一道题）
        let limited = Array(sections.prefix(10))
        var built: [ReciteQuestion] = []

        print("🔍 生成题目 - sections 数量: \(sections.count), 限制: \(limited.count)")

        for (index, section) in limited.enumerated() {
            let original = section.original.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !original.isEmpty else { continue }

            print("📝 题目 \(index + 1) - audioUrl: \(section.audioUrl ?? "nil")")

            switch type {
            case .fillBlank:
                let (masked, key) = makeFillBlank(from: original)
                built.append(ReciteQuestion(
                    original: original,
                    display: masked,
                    answerKey: key,
                    audioUrl: section.audioUrl
                ))
            case .dictation, .memory, .listening:
                built.append(ReciteQuestion(
                    original: original,
                    display: "",
                    answerKey: original,
                    audioUrl: section.audioUrl
                ))
            }
        }

        questions = built
        print("✅ 题目生成完成 - 总数: \(questions.count)")
    }

    private func makeFillBlank(from sentence: String) -> (String, String) {
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 4 else { return ("____", trimmed) }
        let mid = trimmed.index(trimmed.startIndex, offsetBy: trimmed.count / 3)
        let end = trimmed.index(mid, offsetBy: min(2, max(1, trimmed.count / 6)), limitedBy: trimmed.endIndex) ?? trimmed.endIndex
        let key = String(trimmed[mid..<end])
        let masked = trimmed.replacingOccurrences(of: key, with: "__\(String(repeating: "_", count: max(0, key.count - 2)))__", options: .caseInsensitive, range: mid..<end)
        return (masked, key)
    }

    // 播放当前题目的阿里云 TTS 音频
    private func speakCurrent() {
        guard !questions.isEmpty else { return }

        let currentQuestion = questions[currentIndex]

        print("🔊 准备播放题目 \(currentIndex + 1) - audioUrl: \(currentQuestion.audioUrl ?? "nil")")

        // 检查音频URL是否过期
        Task {
            var audioUrlToPlay = currentQuestion.audioUrl

            // 如果URL过期，尝试刷新
            if ClassicsAudioURLManager.shared.isAudioUrlExpired(audioUrlToPlay),
               let bookId = bookId,
               let chapterId = chapterId,
               currentIndex < sections.count {

                let section = sections[currentIndex]
                print("🔄 音频URL过期，正在刷新...")

                audioUrlToPlay = await ClassicsAudioURLManager.shared.ensureValidAudioUrl(
                    currentUrl: audioUrlToPlay,
                    bookId: bookId,
                    chapterId: chapterId,
                    sectionId: section.id,
                    voice: nil
                )

                // 更新题目中的audioUrl
                if let newUrl = audioUrlToPlay {
                    questions[currentIndex] = ReciteQuestion(
                        original: currentQuestion.original,
                        display: currentQuestion.display,
                        answerKey: currentQuestion.answerKey,
                        audioUrl: newUrl,
                        userAnswer: currentQuestion.userAnswer
                    )
                }
            }

            // 播放音频
            await MainActor.run {
                if let audioUrlString = audioUrlToPlay,
                   !audioUrlString.isEmpty,
                   let audioUrl = URL(string: audioUrlString) {
                    print("✅ 使用阿里云 TTS: \(audioUrl.absoluteString.prefix(100))...")
                    playAliyunTTS(url: audioUrl)
                } else {
                    // 禁用系统 TTS 兜底，避免提交答卷后触发播放
                    print("⚠️ audioUrl 无效，已禁用系统 TTS")
                    isPlayingAudio = false
                }
            }
        }
    }

    // 播放阿里云 TTS 音频
    private func playAliyunTTS(url: URL) {
        // 停止当前播放
        stopAudio()

        // 创建新的播放器
        let player = AVPlayer(url: url)
        audioPlayer = player
        isPlayingAudio = true

        // 监听播放完成
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            Task { @MainActor in
                self.isPlayingAudio = false
                print("✅ 音频播放完成")
            }
        }

        // 监听播放失败
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { notification in
            Task { @MainActor in
                self.isPlayingAudio = false
                print("❌ 音频播放失败: \(notification)")
                // 禁用系统TTS兜底，避免提交答卷后触发播放
            }
        }

        // 开始播放
        player.play()

        print("🔊 播放阿里云 TTS 音频: \(url.absoluteString.prefix(100))...")
    }

    // 停止音频播放
    private func stopAudio() {
        // 停止 AVPlayer
        audioPlayer?.pause()
        audioPlayer = nil

        isPlayingAudio = false

        // 移除所有通知监听
        NotificationCenter.default.removeObserver(self)
    }

    private func updateAnswer(_ text: String) {
        questions[currentIndex].userAnswer = text
    }

    private func prev() { if currentIndex > 0 { currentIndex -= 1 } }
    private func next() { if currentIndex < questions.count - 1 { currentIndex += 1 } }

    private func submit() {
        timerActive = false
        onFinish?(questions, totalSeconds - remaining, totalSeconds)
    }

    private func startTimer() {
        remaining = totalSeconds
        timerActive = true
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if !timerActive { t.invalidate(); return }
            remaining -= 1
            if remaining <= 0 { t.invalidate(); submit() }
        }
    }

    private func format(_ sec: Int) -> String {
        let m = max(0, sec) / 60, s = max(0, sec) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - 结果页
struct ReciteTestResultView: View {
    let type: ReciteTestType
    let questions: [ReciteQuestion]
    let usedSeconds: Int
    let totalSeconds: Int

    @Environment(\.dismiss) private var dismiss

    private var correctCount: Int {
        questions.filter { normalize($0.userAnswer) == normalize($0.answerKey) }.count
    }
    private var score: Int { Int((Double(correctCount) / Double(max(questions.count,1))) * 100.0) }

    private var passRate: Double {
        Double(correctCount) / Double(max(questions.count, 1))
    }

    var body: some View {
        ZStack {
            // 背景渐变 - 与测试页面一致
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.93),
                    Color(red: 0.94, green: 0.92, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 自定义导航栏
                customNavigationBar

                ScrollView {
                    VStack(spacing: 16) {
                        // 成绩卡片
                        scoreCard

                        // 统计卡片
                        statisticsCard

                        // 答题详情
                        detailsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
        }
        // 隐藏系统导航栏，避免出现大标题造成的顶部额外高度
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    // 自定义导航栏
    private var customNavigationBar: some View {
        HStack(spacing: 16) {
            // 返回按钮
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.7))
                )
            }

            Spacer()

            // 标题
            Text("测试结果")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

            Spacer()

            // 占位，保持居中
            Color.clear.frame(width: 70)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .frame(height: 44)
        .background(Color.white.opacity(0.3))
    }

    // 成绩卡片
    private var scoreCard: some View {
        VStack(spacing: 20) {
            // 分数圆环
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(Color(red: 0.9, green: 0.88, blue: 0.85), lineWidth: 12)
                    .frame(width: 160, height: 160)

                // 进度圆环
                Circle()
                    .trim(from: 0, to: passRate)
                    .stroke(
                        LinearGradient(
                            colors: passRate >= 0.6 ? [
                                Color(red: 0.2, green: 0.6, blue: 0.5),
                                Color(red: 0.15, green: 0.5, blue: 0.42)
                            ] : [
                                Color(red: 0.9, green: 0.4, blue: 0.3),
                                Color(red: 0.8, green: 0.3, blue: 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                // 分数文字
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(passRate >= 0.6 ? Color(red: 0.2, green: 0.55, blue: 0.45) : Color(red: 0.9, green: 0.4, blue: 0.3))
                    Text("分")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                }
            }
            .padding(.top, 20)

            // 评价文字
            Text(scoreComment)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))

            // 鼓励语
            Text(encouragementText)
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }

    // 统计卡片
    private var statisticsCard: some View {
        HStack(spacing: 0) {
            // 正确数
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.5))
                Text("\(correctCount)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.45))
                Text("答对")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
            }
            .frame(maxWidth: .infinity)

            // 分隔线
            Rectangle()
                .fill(Color(red: 0.85, green: 0.82, blue: 0.78))
                .frame(width: 1, height: 80)

            // 错误数
            VStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.3))
                Text("\(questions.count - correctCount)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.3))
                Text("答错")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
            }
            .frame(maxWidth: .infinity)

            // 分隔线
            Rectangle()
                .fill(Color(red: 0.85, green: 0.82, blue: 0.78))
                .frame(width: 1, height: 80)

            // 总题数
            VStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(red: 0.6, green: 0.55, blue: 0.5))
                Text("\(questions.count)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
                Text("总题数")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    // 答题详情区域
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.45))
                Text("答题详情")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // 题目列表
            VStack(spacing: 12) {
                ForEach(Array(questions.enumerated()), id: \.element.id) { index, q in
                    questionDetailCard(question: q, index: index)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    // 单个题目详情卡片
    private func questionDetailCard(question: ReciteQuestion, index: Int) -> some View {
        let isCorrect = normalize(question.userAnswer) == normalize(question.answerKey)

        return VStack(alignment: .leading, spacing: 12) {
            // 题目标题
            HStack(spacing: 8) {
                // 题号
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isCorrect ? Color(red: 0.2, green: 0.55, blue: 0.45) : Color(red: 0.9, green: 0.4, blue: 0.3))
                    )

                // 原文（截断）
                Text(truncate(question.original))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .lineLimit(1)

                Spacer()

                // 对错图标
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isCorrect ? Color(red: 0.2, green: 0.6, blue: 0.5) : Color(red: 0.9, green: 0.4, blue: 0.3))
            }

            // 题干（仅填空题显示）
            if type == .fillBlank {
                VStack(alignment: .leading, spacing: 4) {
                    Text("题干")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    Text(question.display)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)  // 允许垂直扩展
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.98, green: 0.97, blue: 0.95))
                        )
                }
            }

            // 你的答案
            VStack(alignment: .leading, spacing: 4) {
                Text("你的答案")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                Text(question.userAnswer.isEmpty ? "(未作答)" : question.userAnswer)
                    .font(.system(size: 14))
                    .foregroundColor(isCorrect ? Color(red: 0.2, green: 0.55, blue: 0.45) : Color(red: 0.9, green: 0.4, blue: 0.3))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isCorrect ? Color(red: 0.2, green: 0.6, blue: 0.5).opacity(0.1) : Color(red: 0.9, green: 0.4, blue: 0.3).opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isCorrect ? Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.3) : Color(red: 0.9, green: 0.4, blue: 0.3).opacity(0.3), lineWidth: 1)
                    )
            }

            // 正确答案（仅错误时显示）
            if !isCorrect {
                VStack(alignment: .leading, spacing: 4) {
                    Text("正确答案")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    Text(question.answerKey)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.45))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.2, green: 0.6, blue: 0.5).opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.2, green: 0.55, blue: 0.45).opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.99, green: 0.98, blue: 0.97))
        )
    }

    // 评价文字
    private var scoreComment: String {
        switch score {
        case 90...100: return "优秀！"
        case 80..<90: return "良好！"
        case 60..<80: return "及格"
        default: return "需要加油"
        }
    }

    // 鼓励语
    private var encouragementText: String {
        switch score {
        case 90...100: return "你对经典的理解非常深刻，继续保持！"
        case 80..<90: return "掌握得不错，再接再厉！"
        case 60..<80: return "基础尚可，多加练习会更好"
        default: return "温故而知新，多读多背必有收获"
        }
    }

    private func normalize(_ s: String) -> String {
        let set = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        return s.components(separatedBy: set).joined()
    }

    private func truncate(_ s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.count > 15 ? String(t.prefix(15)) + "…" : t
    }
}

// MARK: - 按钮样式
struct MainPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(configuration.isPressed ? Color(red: 0.2, green: 0.5, blue: 0.4).opacity(0.9) : Color(red: 0.2, green: 0.55, blue: 0.45))
            )
    }
}

struct MainGhostButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Color(red: 0.2, green: 0.55, blue: 0.45))
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.2, green: 0.55, blue: 0.45), lineWidth: 1)
            )
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.clear)
            )
    }
}
