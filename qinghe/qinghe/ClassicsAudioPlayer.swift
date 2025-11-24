import Foundation
import AVFoundation
import Combine

/// 国学经典音频播放器
/// 支持播放列表、进度控制、播放速度调整等功能
@MainActor
class ClassicsAudioPlayer: NSObject, ObservableObject {
    // MARK: - Singleton
    static let shared = ClassicsAudioPlayer()

    // MARK: - Published Properties

    /// 当前播放时间（秒）
    @Published var currentTime: Double = 0

    /// 总时长（秒）
    @Published var duration: Double = 0

    /// 是否正在播放
    @Published var isPlaying: Bool = false

    /// 播放速度
    @Published var playbackSpeed: Float = 1.0 {
        didSet {
            player?.rate = isPlaying ? playbackSpeed : 0
        }
    }

    /// 当前播放索引（用于文稿跟随）
    @Published var currentPlaylistIndex: Int = 0

    // MARK: - Private Properties

    /// AVPlayer 实例
    private var player: AVPlayer?

    /// 播放列表
    private var playlist: [URL] = []

    /// 当前播放索引（内部使用）
    private var currentIndex: Int = 0 {
        didSet {
            currentPlaylistIndex = currentIndex
        }
    }

    /// 时间观察器
    private var timeObserver: Any?

    /// 播放结束观察器
    private var playbackEndObserver: NSObjectProtocol?

    // MARK: - Initialization

    private override init() {
        super.init()
        setupAudioSession()
    }
    
    deinit {
        // deinit 中不能调用 MainActor 隔离的方法
        // 资源清理将在 cleanup() 方法中处理
    }
    
    // MARK: - Setup
    
    /// 配置音频会话
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio)
            try audioSession.setActive(true)
            print("✅ 音频会话配置成功")
        } catch {
            print("❌ 音频会话配置失败: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    /// 加载播放列表
    /// - Parameter urls: 音频URL列表
    func loadPlaylist(urls: [URL]) async {
        cleanup()
        
        playlist = urls
        currentIndex = 0
        
        guard !urls.isEmpty else {
            print("⚠️ 播放列表为空")
            return
        }
        
        await loadCurrentItem()
    }
    
    /// 播放
    func play() {
        guard let player = player else {
            print("⚠️ 播放器未初始化")
            return
        }

        // 确保播放器有有效的播放项
        guard player.currentItem != nil else {
            print("⚠️ 没有可播放的内容")
            return
        }

        player.rate = playbackSpeed
        isPlaying = true

        // 更新全局管理器状态
        ClassicsAudioPlayerManager.shared.updatePlayingState(isPlaying: true)

        print("▶️ 开始播放")
    }
    
    /// 暂停
    func pause() {
        player?.pause()
        isPlaying = false

        // 更新全局管理器状态
        ClassicsAudioPlayerManager.shared.updatePlayingState(isPlaying: false)

        print("⏸️ 暂停播放")
    }
    
    /// 停止
    func stop() {
        pause()
        player?.seek(to: .zero)
        currentTime = 0
        print("⏹️ 停止播放")
    }
    
    /// 跳转到指定时间
    /// - Parameter time: 目标时间（秒）
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime) { [weak self] finished in
            if finished {
                Task { @MainActor in
                    self?.currentTime = time
                }
            }
        }
    }
    
    /// 播放下一个
    func playNext() async {
        guard currentIndex < playlist.count - 1 else {
            print("⚠️ 已是最后一个")
            return
        }
        
        currentIndex += 1
        await loadCurrentItem()
        play()
    }
    
    /// 播放上一个
    func playPrevious() async {
        guard currentIndex > 0 else {
            print("⚠️ 已是第一个")
            return
        }
        
        currentIndex -= 1
        await loadCurrentItem()
        play()
    }
    
    // MARK: - Private Methods
    
    /// 加载当前播放项
    private func loadCurrentItem() async {
        guard currentIndex < playlist.count else { return }
        
        let url = playlist[currentIndex]
        print("📀 加载音频: \(url.lastPathComponent)")
        
        // 移除旧的观察器
        removeObservers()
        
        // 创建新的播放器项
        let playerItem = AVPlayerItem(url: url)
        
        // 创建或更新播放器
        if let existingPlayer = player {
            existingPlayer.replaceCurrentItem(with: playerItem)
        } else {
            player = AVPlayer(playerItem: playerItem)
        }
        
        // 等待播放器准备就绪
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 更新时长
        if let duration = player?.currentItem?.duration, duration.isNumeric {
            self.duration = duration.seconds
        } else {
            self.duration = 0
        }
        
        // 重置当前时间
        currentTime = 0
        
        // 添加观察器
        addObservers()
        
        print("✅ 音频加载完成，时长: \(formatTime(duration))")
    }
    
    /// 添加观察器
    private func addObservers() {
        guard let player = player else { return }
        
        // 时间观察器
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds
            }
        }
        
        // 播放结束观察器
        playbackEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handlePlaybackEnd()
            }
        }
    }
    
    /// 移除观察器
    private func removeObservers() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        if let playbackEndObserver = playbackEndObserver {
            NotificationCenter.default.removeObserver(playbackEndObserver)
            self.playbackEndObserver = nil
        }
    }
    
    /// 处理播放结束
    private func handlePlaybackEnd() async {
        print("⏭️ 当前音频播放完成")
        
        // 自动播放下一个
        if currentIndex < playlist.count - 1 {
            await playNext()
        } else {
            // 播放列表结束
            isPlaying = false
            print("✅ 播放列表播放完成")
        }
    }
    
    /// 清理资源
    private func cleanup() {
        removeObservers()
        player?.pause()
        player = nil
        currentTime = 0
        duration = 0
        isPlaying = false
    }
    
    /// 格式化时间
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

