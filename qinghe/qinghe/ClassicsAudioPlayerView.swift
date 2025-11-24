import SwiftUI
import AVFoundation

// MARK: - 国学经典听书播放器页面
struct ClassicsAudioPlayerView: View {
    let book: ClassicsBook
    let bookId: String?  // 书籍ID（用于API调用）
    let initialChapterId: String?  // 初始章节ID

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var audioPlayer = ClassicsAudioPlayer.shared

    // 播放状态
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0  // 当前单个音频的播放时间
    @State private var duration: Double = 0     // 当前单个音频的时长
    @State private var totalDuration: Double = 0  // 整个播放列表的总时长
    @State private var accumulatedTime: Double = 0  // 已播放完成的音频累计时长
    @State private var playbackSpeed: Double = 1.0
    @State private var showSpeedMenu: Bool = false
    @State private var showPlaylist: Bool = false
    @State private var showVoicePicker: Bool = false
    @State private var showTimerPicker: Bool = false

    // 下拉手势
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    // 数据加载
    @State private var chapters: [ClassicsChapterAPI] = []
    @State private var currentChapterIndex: Int = 0
    @State private var currentChapterDetail: ClassicsChapterDetail?
    @State private var isLoadingChapter: Bool = true  // 初始状态为加载中
    @State private var errorMessage: String?

    // TTS音色
    @State private var availableVoices: [TTSVoice] = []
    @State private var selectedVoice: TTSVoice?

    // 定时器
    @State private var timerMinutes: Int = 0  // 0表示不定时

    // 文稿跟随
    @State private var currentSectionIndex: Int = 0  // 当前播放的句段索引
    @State private var playlistItems: [PlaylistItem] = []  // 播放列表项

    private var currentChapter: ClassicsChapterAPI? {
        guard currentChapterIndex < chapters.count else { return nil }
        return chapters[currentChapterIndex]
    }

    init(book: ClassicsBook, bookId: String? = nil, initialChapterId: String? = nil) {
        self.book = book
        self.bookId = bookId
        self.initialChapterId = initialChapterId
    }

    // MARK: - 子视图组件

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: book.coverColors),
            startPoint: .top,
            endPoint: .bottom
        )
        .opacity(isDragging ? max(0.3, 1 - dragOffset / 300) : 1)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var mainContent: some View {
        if isLoadingChapter {
            loadingView
        } else if let errorMessage = errorMessage {
            errorView(message: errorMessage)
        } else {
            playerView
        }
    }

    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            Text("加载中...")
                .foregroundColor(.white)
                .padding(.top, 16)
        }
    }

    private func errorView(message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.7))
            Text(message)
                .foregroundColor(.white)
                .padding(.top, 16)
            Button("重试") {
                Task {
                    await loadInitialData()
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
            .padding(.top, 16)
        }
    }

    private var playerView: some View {
        VStack(spacing: 0) {
            topNavigationBar

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    manuscriptView
                    Spacer(minLength: 280)
                }
                .padding(.top, 20)
            }

            Spacer()

            bottomControlsSection
        }
        .offset(y: dragOffset)
    }

    private var bottomControlsSection: some View {
        VStack(spacing: 0) {
            actionButtons
            playbackControls
        }
        .background(bottomGradientBackground)
    }

    private var bottomGradientBackground: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.clear, location: 0.0),
                .init(color: (book.coverColors.last ?? Color.black).opacity(0.3), location: 0.3),
                .init(color: (book.coverColors.last ?? Color.black).opacity(0.7), location: 0.6),
                .init(color: (book.coverColors.last ?? Color.black).opacity(0.95), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            backgroundGradient
            mainContent

            // 倍速选择菜单
            if showSpeedMenu {
                speedMenuOverlay
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadInitialData()
        }
        .onReceive(audioPlayer.$currentTime) { time in
            currentTime = time
            // 更新全局管理器
            ClassicsAudioPlayerManager.shared.updateCurrentTime(time)
        }
        .onReceive(audioPlayer.$duration) { dur in
            duration = dur
        }
        .onReceive(audioPlayer.$isPlaying) { playing in
            isPlaying = playing
            // 更新全局管理器
            ClassicsAudioPlayerManager.shared.updatePlayingState(isPlaying: playing)
        }
        .onReceive(audioPlayer.$currentPlaylistIndex) { index in
            // 直接使用播放器的索引更新当前句段
            if currentSectionIndex != index {
                currentSectionIndex = index
                print("📖 当前播放句段: \(index + 1)/\(playlistItems.count)")

                // 更新累计时间：计算前面所有音频的总时长
                updateAccumulatedTime(upToIndex: index)
            }
        }
        .sheet(isPresented: $showPlaylist) {
            playlistSheet
        }
        .sheet(isPresented: $showVoicePicker) {
            voicePickerSheet
        }
        .sheet(isPresented: $showTimerPicker) {
            timerPickerSheet
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    // 只允许向下拖动
                    if value.translation.height > 0 {
                        isDragging = true
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    isDragging = false
                    // 如果拖动超过 150pt，关闭页面（音频继续播放）
                    if value.translation.height > 150 {
                        dismiss()
                    } else {
                        // 否则回弹
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            // 设置全局管理器的播放信息
            let manager = ClassicsAudioPlayerManager.shared
            manager.setPlayingInfo(
                book: book,
                bookId: bookId,
                chapterTitle: currentChapter?.chapterTitle ?? ""
            )
        }
    }
    
    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        HStack(spacing: 16) {
            // 返回按钮 - 根据拖动状态改变图标（音频继续播放）
            Button(action: {
                dismiss()
            }) {
                Image(systemName: isDragging && dragOffset > 50 ? "chevron.up" : "chevron.down")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 32, height: 32)
            }

            // 标题
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let chapter = currentChapter {
                    Text(chapter.chapterTitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    // MARK: - 文稿内容
    private var manuscriptView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 章节标题
            if let chapter = currentChapter {
                Text(chapter.chapterTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
            }

            // 文稿内容 - 显示所有句段，根据播放进度高亮
            if let detail = currentChapterDetail {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(detail.sections.enumerated()), id: \.element.id) { index, section in
                        Text(section.original)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(getSectionTextColor(for: index))
                            .lineSpacing(10)
                            .padding(.vertical, 6)
                            .animation(.easeInOut(duration: 0.3), value: currentSectionIndex)
                    }
                }
                .padding(.horizontal, 20)
            } else {
                Text("加载文稿中...")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - 计算属性

    /// 总播放时间 = 累计时间 + 当前音频播放时间
    private var totalPlayedTime: Double {
        return accumulatedTime + currentTime
    }

    // MARK: - 获取句段文字颜色
    /// 根据句段索引返回对应的文字颜色
    /// - Parameter index: 句段索引
    /// - Returns: 文字颜色
    private func getSectionTextColor(for index: Int) -> Color {
        if index < currentSectionIndex {
            // 已播放：白色
            return .white
        } else if index == currentSectionIndex {
            // 正在播放：白色高亮
            return .white
        } else {
            // 未播放：半透明灰色
            return .white.opacity(0.4)
        }
    }

    // MARK: - 更新累计时间
    /// 更新已播放完成的音频累计时长
    /// - Parameter upToIndex: 当前播放的音频索引
    private func updateAccumulatedTime(upToIndex index: Int) {
        var accumulated: Double = 0

        // 累加前面所有音频的时长
        for i in 0..<index {
            if i < playlistItems.count {
                accumulated += playlistItems[i].duration ?? 0
            }
        }

        accumulatedTime = accumulated
        print("⏱️ 累计时间更新: \(formatTime(accumulatedTime))")

        // 更新全局管理器
        ClassicsAudioPlayerManager.shared.updateAccumulatedTime(accumulated)
        ClassicsAudioPlayerManager.shared.updateTotalDuration(totalDuration)
    }


    
    // MARK: - 播放控制区域
    private var playbackControls: some View {
        VStack(spacing: 12) {
            // 进度条
            VStack(spacing: 8) {
                // 进度滑块
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景轨道
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 3)

                        // 已播放进度
                        ZStack(alignment: .trailing) {
                            Capsule()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: geometry.size.width * CGFloat(totalPlayedTime / max(totalDuration, 0.1)), height: 3)
                                .animation(.linear(duration: 0.2), value: totalPlayedTime)

                            // 进度圆点
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                                .animation(.linear(duration: 0.2), value: totalPlayedTime)
                        }
                    }
                }
                .frame(height: 10)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // TODO: 实现拖动跳转（需要计算跳转到哪个音频文件）
                            let percent = value.location.x / (UIScreen.main.bounds.width - 40)
                            let targetTime = totalDuration * Double(max(0, min(1, percent)))
                            print("⏩ 尝试跳转到: \(formatTime(targetTime))")
                        }
                )

                // 时间标签
                HStack {
                    Text(formatTime(totalPlayedTime))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text(formatTime(totalDuration))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // 主控制按钮
            HStack(spacing: 0) {
                // 播放列表
                Button(action: { showPlaylist = true }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                }

                // 上一章
                Button(action: { previousChapter() }) {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                }
                .disabled(currentChapterIndex == 0)
                .opacity(currentChapterIndex == 0 ? 0.5 : 1.0)

                // 播放/暂停
                Button(action: { togglePlayPause() }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 70, height: 70)

                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26, weight: .light))
                            .foregroundColor(.white)
                            .offset(x: isPlaying ? 0 : 2)
                    }
                    .frame(maxWidth: .infinity)
                }

                // 下一章
                Button(action: { nextChapter() }) {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                }
                .disabled(currentChapterIndex >= chapters.count - 1)
                .opacity(currentChapterIndex >= chapters.count - 1 ? 0.5 : 1.0)

                // 倍速按钮
                Button(action: { showSpeedMenu.toggle() }) {
                    Text(String(format: "%.1fx", playbackSpeed))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
    }

    // MARK: - 操作按钮栏（定时和音色）
    private var actionButtons: some View {
        HStack(spacing: 0) {
            Spacer()

            // 定时按钮
            Button(action: { showTimerPicker = true }) {
                VStack(spacing: 4) {
                    Image(systemName: timerMinutes > 0 ? "timer.circle.fill" : "timer")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.white.opacity(0.8))
                    Text(timerMinutes > 0 ? "\(timerMinutes)分钟" : "定时")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(width: 60)
            }

            Spacer()

            // 音色显示（仅展示，不可点击）
            VStack(spacing: 4) {
                Image(systemName: "waveform")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                Text("墨讲师")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            .frame(width: 60)

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.top, 8)
    }
    
    // MARK: - 播放列表
    private var playlistSheet: some View {
        NavigationView {
            List {
                ForEach(Array(chapters.enumerated()), id: \.offset) { index, chapter in
                    Button(action: {
                        currentChapterIndex = index
                        showPlaylist = false
                        Task {
                            await loadChapter(index: index)
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
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                            }
                        }
                    }
                }
            }
            .navigationTitle("播放列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        showPlaylist = false
                    }
                }
            }
        }
    }

    // MARK: - 音色选择器
    private var voicePickerSheet: some View {
        NavigationView {
            List {
                // 推荐音色
                Section(header: Text("推荐音色")) {
                    ForEach(availableVoices.filter { $0.isRecommended }) { voice in
                        Button(action: {
                            selectedVoice = voice
                            showVoicePicker = false
                            // 重新加载当前章节以使用新音色
                            Task {
                                await loadChapter(index: currentChapterIndex)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(voice.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                                    Text(voice.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                                }

                                Spacer()

                                if selectedVoice?.voiceId == voice.voiceId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                                }
                            }
                        }
                    }
                }

                // 方言音色
                Section(header: Text("方言音色")) {
                    ForEach(availableVoices.filter { !$0.isRecommended }) { voice in
                        Button(action: {
                            selectedVoice = voice
                            showVoicePicker = false
                            // 重新加载当前章节以使用新音色
                            Task {
                                await loadChapter(index: currentChapterIndex)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(voice.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                                    Text(voice.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                                }

                                Spacer()

                                if selectedVoice?.voiceId == voice.voiceId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择音色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        showVoicePicker = false
                    }
                }
            }
        }
    }

    // MARK: - 定时器选择器
    private var timerPickerSheet: some View {
        NavigationView {
            List {
                ForEach([0, 15, 30, 45, 60], id: \.self) { minutes in
                    Button(action: {
                        timerMinutes = minutes
                        showTimerPicker = false
                        if minutes > 0 {
                            // 设置定时器
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(minutes * 60)) {
                                if timerMinutes == minutes {  // 确保定时器没有被更改
                                    audioPlayer.pause()
                                    timerMinutes = 0
                                }
                            }
                        }
                    }) {
                        HStack {
                            Text(minutes == 0 ? "不定时" : "\(minutes) 分钟")
                                .font(.system(size: 16))
                                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                            Spacer()

                            if timerMinutes == minutes {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                            }
                        }
                    }
                }
            }
            .navigationTitle("定时关闭")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        showTimerPicker = false
                    }
                }
            }
        }
    }

    // MARK: - 倍速选择菜单
    private var speedMenuOverlay: some View {
        ZStack {
            speedMenuBackground
            speedMenuCard
        }
    }

    private var speedMenuBackground: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSpeedMenu = false
                }
            }
    }

    private var speedMenuCard: some View {
        VStack(spacing: 0) {
            speedMenuHeader
            Divider()
            speedOptionsList
            speedMenuCancelButton
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 40)
        .transition(.scale.combined(with: .opacity))
    }

    private var speedMenuHeader: some View {
        Text("播放速度")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            .padding(.top, 20)
            .padding(.bottom, 16)
    }

    private var speedOptionsList: some View {
        ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
            VStack(spacing: 0) {
                speedOptionButton(speed: speed)
                if speed != 2.0 {
                    Divider()
                }
            }
        }
    }

    private func speedOptionButton(speed: Double) -> some View {
        Button(action: {
            playbackSpeed = speed
            audioPlayer.playbackSpeed = Float(speed)
            withAnimation(.easeInOut(duration: 0.2)) {
                showSpeedMenu = false
            }
        }) {
            HStack {
                Text(String(format: "%.2fx", speed))
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                Spacer()

                if abs(playbackSpeed - speed) < 0.01 {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var speedMenuCancelButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showSpeedMenu = false
            }
        }) {
            Text("取消")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 辅助方法
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func previousChapter() {
        guard currentChapterIndex > 0 else { return }
        currentChapterIndex -= 1
        Task {
            await loadChapter(index: currentChapterIndex)
        }
    }

    private func nextChapter() {
        guard currentChapterIndex < chapters.count - 1 else { return }
        currentChapterIndex += 1
        Task {
            await loadChapter(index: currentChapterIndex)
        }
    }

    private func togglePlayPause() {
        print("🎵 togglePlayPause 被调用，当前状态: \(isPlaying ? "播放中" : "暂停")")

        if isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }

        // 强制刷新按钮状态
        DispatchQueue.main.async {
            self.isPlaying = self.audioPlayer.isPlaying
        }
    }

    // MARK: - 数据加载

    /// 加载初始数据
    private func loadInitialData() async {
        print("🎵 开始加载听书数据...")
        print("📚 bookId: \(bookId ?? "nil")")
        print("📖 initialChapterId: \(initialChapterId ?? "nil")")

        guard let bookId = bookId else {
            await MainActor.run {
                errorMessage = "缺少书籍ID"
                isLoadingChapter = false
                print("❌ 缺少书籍ID")
            }
            return
        }

        await MainActor.run {
            isLoadingChapter = true
            errorMessage = nil
        }

        do {
            // 1. 加载书籍详情（获取章节列表）
            print("📥 正在加载书籍详情...")
            let bookDetail = try await ClassicsAPIService.shared.getBookDetail(bookId: bookId)

            await MainActor.run {
                self.chapters = bookDetail.chapters
                print("✅ 成功加载 \(bookDetail.chapters.count) 个章节")
            }

            // 2. 加载TTS音色列表（失败不影响主流程）
            do {
                let voices = try await ClassicsAPIService.shared.getTTSVoices()
                await MainActor.run {
                    self.availableVoices = voices
                    // 默认选择第一个推荐音色
                    self.selectedVoice = voices.first { $0.isRecommended }
                    print("✅ 成功加载 \(voices.count) 个音色，默认音色: \(self.selectedVoice?.name ?? "无")")
                }
            } catch {
                print("⚠️ 加载音色列表失败: \(error.localizedDescription)")
                // 音色加载失败不影响听书功能，继续执行
            }

            // 3. 确定要加载的章节索引
            var chapterIndexToLoad = 0
            if let initialChapterId = initialChapterId,
               let index = chapters.firstIndex(where: { $0.chapterId == initialChapterId }) {
                chapterIndexToLoad = index
            }

            await MainActor.run {
                self.currentChapterIndex = chapterIndexToLoad
            }

            // 4. 加载章节内容
            await loadChapter(index: chapterIndexToLoad)

        } catch {
            await MainActor.run {
                self.errorMessage = "加载失败: \(error.localizedDescription)"
                self.isLoadingChapter = false
                print("❌ 加载失败: \(error)")
            }
        }
    }

    /// 加载指定章节
    private func loadChapter(index: Int) async {
        guard index < chapters.count, let bookId = bookId else { return }

        let chapter = chapters[index]

        await MainActor.run {
            isLoadingChapter = true
            errorMessage = nil
        }

        do {
            // 1. 加载章节详情
            let chapterDetail = try await ClassicsAPIService.shared.getChapterDetail(
                bookId: bookId,
                chapterId: chapter.chapterId
            )

            await MainActor.run {
                self.currentChapterDetail = chapterDetail
                print("✅ 成功加载章节: \(chapterDetail.chapter.chapterTitle)")
            }

            // 2. 获取播放列表
            let playlist = try await ClassicsAPIService.shared.getChapterPlaylist(
                bookId: bookId,
                chapterId: chapter.chapterId
            )

            // 3. 保存播放列表项（用于文稿跟随）
            await MainActor.run {
                self.playlistItems = playlist.items
                self.currentSectionIndex = 0  // 重置句段索引

                // 使用动画平滑过渡重置累计时间和总时长
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.accumulatedTime = 0  // 重置累计时间
                    self.currentTime = 0  // 重置当前时间

                    // 使用后端返回的总时长（如果没有则前端计算）
                    if let backendTotalDuration = playlist.totalDuration {
                        self.totalDuration = backendTotalDuration
                        print("⏱️ 章节总时长（后端）: \(formatTime(self.totalDuration))")
                    } else {
                        // 降级方案：前端计算
                        self.totalDuration = playlist.items.reduce(0) { sum, item in
                            sum + (item.duration ?? 0)
                        }
                        print("⏱️ 章节总时长（前端计算）: \(formatTime(self.totalDuration))")
                    }
                }
            }

            // 4. 准备音频URL列表
            var audioURLs: [URL] = []
            for item in playlist.items {
                if let audioUrlString = item.audioUrl,
                   let url = URL(string: audioUrlString) {
                    audioURLs.append(url)
                } else {
                    print("⚠️ 句段 \(item.sectionId) 没有音频URL")
                }
            }

            await MainActor.run {
                self.isLoadingChapter = false
            }

            // 5. 加载音频到播放器
            if !audioURLs.isEmpty {
                await audioPlayer.loadPlaylist(urls: audioURLs)
                print("✅ 成功加载 \(audioURLs.count) 个音频")
            } else {
                await MainActor.run {
                    self.errorMessage = "该章节暂无音频"
                }
            }

        } catch {
            await MainActor.run {
                self.errorMessage = "加载章节失败: \(error.localizedDescription)"
                self.isLoadingChapter = false
                print("❌ 加载章节失败: \(error)")
            }
        }
    }
}

// MARK: - 预览
#Preview {
    ClassicsAudioPlayerView(
        book: ClassicsBook(
            title: "论语",
            author: "孔子及其弟子",
            category: .confucian,
            coverColors: [Color(red: 0.8, green: 0.3, blue: 0.2), Color(red: 0.6, green: 0.2, blue: 0.1)],
            introduction: "儒家经典",
            description: nil,
            hasVernacular: true,
            isProofread: true
        ),
        bookId: "lunyu",
        initialChapterId: "xueer"
    )
}

// MARK: - Double 扩展：时长格式化

extension Double {
    /// 将秒数格式化为 "MM:SS" 格式
    func formatAsTime() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 将秒数格式化为中文 "X分X秒" 格式
    func formatAsChineseTime() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60

        if minutes > 0 {
            if seconds > 0 {
                return "\(minutes)分\(seconds)秒"
            } else {
                return "\(minutes)分钟"
            }
        } else {
            return "\(seconds)秒"
        }
    }

    /// 将秒数格式化为长时间 "X小时X分" 格式
    func formatAsLongTime() -> String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)小时\(minutes)分"
            } else {
                return "\(hours)小时"
            }
        } else if minutes > 0 {
            return "\(minutes)分钟"
        } else {
            return "\(Int(self))秒"
        }
    }
}
