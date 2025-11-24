import SwiftUI
import AVFoundation

// MARK: - 全局音频播放管理器（单例）
@MainActor
class ClassicsAudioPlayerManager: ObservableObject {
    static let shared = ClassicsAudioPlayerManager()

    // MARK: - Published Properties

    /// 是否正在播放
    @Published var isPlaying: Bool = false

    /// 当前播放的书籍
    @Published var currentBook: ClassicsBook?

    /// 当前章节索引
    @Published var currentChapterIndex: Int = 0

    /// 当前章节标题
    @Published var currentChapterTitle: String = ""

    /// 当前句段索引
    @Published var currentSectionIndex: Int = 0

    /// 当前播放时间
    @Published var currentTime: Double = 0

    /// 总时长
    @Published var totalDuration: Double = 0

    /// 累计时间
    @Published var accumulatedTime: Double = 0

    /// 是否显示悬浮球
    @Published var showFloatingButton: Bool = false

    /// 书籍ID
    var bookId: String?

    /// 初始章节ID
    var initialChapterId: String?

    private init() {}

    // MARK: - Public Methods

    /// 设置当前播放信息（从播放器页面调用）
    func setPlayingInfo(book: ClassicsBook, bookId: String?, chapterTitle: String) {
        self.currentBook = book
        self.bookId = bookId
        self.currentChapterTitle = chapterTitle
    }

    /// 更新播放状态
    func updatePlayingState(isPlaying: Bool) {
        self.isPlaying = isPlaying
    }

    /// 更新当前时间
    func updateCurrentTime(_ time: Double) {
        self.currentTime = time
    }

    /// 更新总时长
    func updateTotalDuration(_ duration: Double) {
        self.totalDuration = duration
    }

    /// 更新累计时间
    func updateAccumulatedTime(_ time: Double) {
        self.accumulatedTime = time
    }

    /// 显示悬浮球
    func showFloating() {
        showFloatingButton = true
    }

    /// 隐藏悬浮球
    func hideFloating() {
        showFloatingButton = false
    }

    /// 总播放时间
    var totalPlayedTime: Double {
        return accumulatedTime + currentTime
    }

    /// 格式化时间
    func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

