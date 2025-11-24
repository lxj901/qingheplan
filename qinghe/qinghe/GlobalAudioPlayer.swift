//
//  GlobalAudioPlayer.swift
//  qinghe
//
//  全局音频播放管理器
//  支持后台播放、锁屏控制、倍速播放、定时关闭
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

class GlobalAudioPlayer: ObservableObject {
    static let shared = GlobalAudioPlayer()

    // MARK: - 播放器状态
    @Published var player: AVPlayer?
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var currentIndex: Int = 0

    // MARK: - 播放列表
    @Published var playlist: [PlaylistItem] = []
    @Published var bookTitle: String = ""
    @Published var chapterTitle: String = ""

    // MARK: - 播放设置
    @Published var playbackRate: Float = 1.0 {
        didSet {
            updatePlaybackRate()
            savePlaybackRate()
        }
    }

    @Published var selectedVoice: String = "Elias" {
        didSet {
            saveSelectedVoice()
        }
    }

    @Published var sleepTimer: Date? = nil {
        didSet {
            if sleepTimer != nil {
                startSleepTimer()
            }
        }
    }

    // MARK: - 内部状态
    private var timeObserver: Any?
    private var sleepTimerCancellable: AnyCancellable?

    // MARK: - 初始化
    private init() {
        loadSettings()
        setupAudioSession()
        setupRemoteControl()
        setupNotifications()
    }

    // MARK: - 音频会话配置
    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [])
            try audioSession.setActive(true)
            print("✅ 音频会话配置成功")
        } catch {
            print("❌ 音频会话配置失败: \(error)")
        }
    }

    // MARK: - 远程控制配置
    func setupRemoteControl() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // 播放
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        // 暂停
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        // 上一曲
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }

        // 下一曲
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }

        // 快进
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward(seconds: 15)
            return .success
        }

        // 快退
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward(seconds: 15)
            return .success
        }

        print("✅ 远程控制配置成功")
    }

    // MARK: - 通知配置
    func setupNotifications() {
        // 监听音频中断（来电等）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        // 监听音频路由变化（拔耳机等）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // 中断开始，暂停播放
            pause()
        case .ended:
            // 中断结束，可以选择恢复播放
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                play()
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .oldDeviceUnavailable:
            // 耳机被拔出，暂停播放
            pause()
        default:
            break
        }
    }

    // MARK: - 播放列表管理
    func loadPlaylist(_ items: [PlaylistItem], bookTitle: String, chapterTitle: String) {
        self.playlist = items
        self.bookTitle = bookTitle
        self.chapterTitle = chapterTitle
        self.currentIndex = 0

        if !items.isEmpty {
            playItem(at: 0)
        }
    }

    func playItem(at index: Int) {
        guard index >= 0 && index < playlist.count else { return }

        currentIndex = index
        let item = playlist[index]

        guard let audioUrlString = item.audioUrl,
              let url = URL(string: audioUrlString) else {
            print("❌ 无效的音频 URL")
            return
        }

        // 创建播放器
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // 设置倍速
        player?.rate = 0 // 先设为 0，等待播放指令

        // 添加时间观察器
        addTimeObserver()

        // 监听播放结束
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        // 更新锁屏信息
        updateNowPlaying()

        print("✅ 开始播放: \(item.original)")
    }

    @objc private func playerDidFinishPlaying() {
        // 播放完当前曲目，自动播放下一曲
        playNext()
    }

    // MARK: - 播放控制
    func play() {
        guard let player = player else { return }
        player.play()
        player.rate = playbackRate
        isPlaying = true
        updateNowPlaying()
        print("▶️ 播放")
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlaying()
        print("⏸️ 暂停")
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func playNext() {
        if currentIndex < playlist.count - 1 {
            playItem(at: currentIndex + 1)
            if isPlaying {
                play()
            }
        } else {
            print("⏹️ 已到达播放列表末尾")
        }
    }

    func playPrevious() {
        if currentIndex > 0 {
            playItem(at: currentIndex - 1)
            if isPlaying {
                play()
            }
        } else {
            // 如果在第一首，重新播放当前
            seek(to: 0)
        }
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        currentTime = time
        updateNowPlaying()
    }

    func skipForward(seconds: Double) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    func skipBackward(seconds: Double) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    // MARK: - 倍速控制
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
    }

    private func updatePlaybackRate() {
        if isPlaying {
            player?.rate = playbackRate
        }
        updateNowPlaying()
    }

    // MARK: - 定时关闭
    func setSleepTimer(minutes: Int) {
        sleepTimer = Date().addingTimeInterval(TimeInterval(minutes * 60))
        print("⏰ 设置定时关闭: \(minutes) 分钟")
    }

    func cancelSleepTimer() {
        sleepTimer = nil
        sleepTimerCancellable?.cancel()
        print("⏰ 取消定时关闭")
    }

    private func startSleepTimer() {
        sleepTimerCancellable?.cancel()

        sleepTimerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let sleepTimer = self.sleepTimer else { return }

                if Date() >= sleepTimer {
                    self.pause()
                    self.cancelSleepTimer()
                    print("⏰ 定时关闭触发")
                }
            }
    }

    // MARK: - 时间观察器
    private func addTimeObserver() {
        removeTimeObserver()

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds

            if let duration = self.player?.currentItem?.duration.seconds, duration.isFinite {
                self.duration = duration
            }
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    // MARK: - 锁屏信息更新
    func updateNowPlaying() {
        let currentItem = playlist[safe: currentIndex]

        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentItem?.original ?? ""
        nowPlayingInfo[MPMediaItemPropertyArtist] = chapterTitle
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = bookTitle
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? Double(playbackRate) : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - 设置持久化
    private func savePlaybackRate() {
        UserDefaults.standard.set(playbackRate, forKey: "playbackRate")
    }

    private func saveSelectedVoice() {
        UserDefaults.standard.set(selectedVoice, forKey: "selectedVoice")
    }

    private func loadSettings() {
        if let savedRate = UserDefaults.standard.object(forKey: "playbackRate") as? Float {
            playbackRate = savedRate
        }

        if let savedVoice = UserDefaults.standard.string(forKey: "selectedVoice") {
            selectedVoice = savedVoice
        }
    }

    // MARK: - 清理
    deinit {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
        sleepTimerCancellable?.cancel()
    }
}

// MARK: - 安全下标访问
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
