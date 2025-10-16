import Foundation
import AVFoundation
import Combine
import MediaPlayer
import UIKit

class WhiteNoisePlayer: NSObject, ObservableObject {
    static let shared = WhiteNoisePlayer()
    private let audioComponentId = "WhiteNoise"

    @Published var isPlaying = false
    @Published var currentWhiteNoise: WhiteNoise?
    @Published var progress: Double = 0.0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var sleepTimer: Int? = nil // 睡眠定时器（分钟）
    @Published var remainingTime: TimeInterval = 0 // 剩余时间（秒）

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var hasRecordedPlay = false
    private var sleepTimerWorkItem: DispatchWorkItem?
    private var playbackMonitorTimer: Timer?
    private var consecutiveFailures = 0 // 连续恢复失败次数
    private let maxConsecutiveFailures = 3 // 最大连续失败次数
    private var lastMonitorObservedTime: TimeInterval = -1
    private var bgTask: UIBackgroundTaskIdentifier = .invalid
    private var loadedArtworkUrl: String?
    private var stallConsecutiveCount = 0
    private var didAttemptBgReactivation = false
    private var wasPlayingBeforeInterruption = false
    private var didForceRouteRefreshOnce = false

    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteControls()
        setupNotifications()
    }

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()

            // 设置音频会话类别为播放，支持后台播放
            // 关键配置：
            // 1. 使用 .playback 类别（支持后台播放）
            // 2. 使用 .default 模式（适合纯音频后台播放）
            // 3. 不使用 .mixWithOthers 选项！
            //    - .mixWithOthers 会让系统认为这是"次要音频"，可能在后台被暂停
            //    - 白噪音是主要音频，应该独占音频会话
            //    - 这样系统会优先保证白噪音的后台播放
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: []
            )

            // 🔥 关键：设置音频会话的首选输入增益（确保音量正常）
            // 这可以防止系统将音量设置为 0
            if audioSession.isInputGainSettable {
                try audioSession.setInputGain(1.0)
            }

            // 设置音频会话为活跃状态，并通知其他应用
            try audioSession.setActive(true, options: [])

            print("🔊 白噪音播放器音频会话配置成功 - 支持后台播放（独占模式）")
        } catch {
            print("❌ 白噪音播放器音频会话配置失败: \(error)")
        }
    }

    private func activateAudioSession() {
        // 若当前由语音消息或录音占用，则跳过激活以避免类别拉锯
        if AudioOrchestrator.shared.currentRole == .voiceMessage || AudioOrchestrator.shared.currentRole == .recording {
            print("ℹ️ [WhiteNoisePlayer] 语音/录音占用会话，跳过白噪音会话激活")
            return
        }

        let audioSession = AVAudioSession.sharedInstance()

        do {
            // 检查当前音频会话的类别是否已经正确
            // 如果类别已经是 playback，则不需要重新设置（避免 -50 错误）
            if audioSession.category != .playback {
                // 使用与 setupAudioSession 相同的配置（独占模式）
                try audioSession.setCategory(
                    .playback,
                    mode: .default,
                    options: []
                )
                print("🔊 音频会话类别已更新为 playback（独占模式）")
            }

            // 激活音频会话（使用空选项，避免后台频繁 setActive 触发 561015905）
            do {
                try audioSession.setActive(true, options: [])
                print("🔊 音频会话已激活")
            } catch let e as NSError {
                if e.domain == NSOSStatusErrorDomain && e.code == 561015905 {
                    print("⚠️ 音频会话 setActive 忙(561015905)，忽略并继续")
                } else {
                    throw e
                }
            }

        } catch let error as NSError {
            print("❌ 音频会话激活失败: \(error), code: \(error.code)")

            // 在后台环境中，音频会话激活失败是正常的
            // 只要播放器继续播放，不需要强制激活
            // 只在必要时尝试恢复
        }
    }


    private func setupNotifications() {
        // 监听音频会话中断
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        // 监听路由变化（如拔出耳机）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )

        print("📢 音频会话通知已设置")

        // 应用前后台切换
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        // 监听"次要音频静音提示"
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSilenceHint(_:)),
            name: AVAudioSession.silenceSecondaryAudioHintNotification,
            object: AVAudioSession.sharedInstance()
        )

        // 监听媒体服务重置（音频服务被系统重置时需要重建）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaServicesReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: AVAudioSession.sharedInstance()
        )

        // 🆕 监听音频会话类别变更（关键修复！）
        // 当其他音频组件（录音、语音消息等）切换音频会话类别时，
        // 白噪音播放器会收到通知并重新断言 playback 类别
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionCategoryChange),
            name: AVAudioSession.routeChangeNotification,  // 使用路由变化作为代理
            object: AVAudioSession.sharedInstance()
        )

    }

    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // 中断开始：仅记录状态，交由系统处理，避免主动 pause 造成后台无法恢复
            wasPlayingBeforeInterruption = isPlaying
            print("🔇 音频会话被中断 (began). wasPlayingBeforeInterruption=\(wasPlayingBeforeInterruption)")

        case .ended:
            // 中断结束
            print("🔊 音频会话中断结束")

            // 关键修复：无论 shouldResume 标志如何，只要之前在播放，就恢复播放
            // 原因：通知铃声等系统音频可能不会设置 shouldResume 标志
            if wasPlayingBeforeInterruption {
                // 延迟一小段时间，确保系统音频完全结束
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else { return }

                    // 先重设类别再激活音频会话，然后恢复播放（关键步骤！）
                    do {
                        let s = AVAudioSession.sharedInstance()
                        try s.setCategory(.playback, mode: .default, options: [])
                        try s.setActive(true, options: [])
                        print("🔊 音频会话已重新激活并重设类别")
                    } catch {
                        print("❌ 重新激活音频会话失败: \(error)")
                    }

                    // 恢复播放
                    self.resume()

                    // 兜底：短延迟检测仍无声则软重启
                    self.softRestartIfNoSound()

                    // 多次确保播放（保险措施）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                        self?.player?.play()
                        self?.player?.rate = 1.0
                        print("✅ 中断后恢复播放完成 - rate: \(self?.player?.rate ?? 0)")
                    }
                }
            } else {
                print("ℹ️ 音频会话中断结束，但之前未在播放，不恢复")
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
            // 设备断开（如拔出耳机）
            print("🎧 音频设备断开，重新断言会话并尝试恢复播放")
            reassertPlaybackSessionAndResume()
            softRestartIfNoSound()
        case .categoryChange:
            print("🎚️ 音频路由变化（类别切换）: \(reason.rawValue)")
            // 后台避免重新激活/刷新路由，前台才重新断言会话
            if UIApplication.shared.applicationState == .background {
                print("🎚️ 类别切换发生于后台，避免重新激活/刷新路由，仅确保播放器继续播放")
                self.player?.play()
                self.player?.rate = 1.0
            } else {
                reassertPlaybackSessionAndResume()
            }

        default:
            break
        }
    }

    // 强制刷新音频路由（一次性）：切到 PlayAndRecord+Speaker 再切回 Playback
    // 某些机型上可“唤醒”后台路由，解决看似在播但无声的问题
    private func forceRouteRefresh() {
        let session = AVAudioSession.sharedInstance()
        print("🛠️ 尝试强制刷新音频路由...")
        do {
            // 暂切到可强制外放的类别
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true, options: [])
            // 确保播放器不静音
            player?.isMuted = false
            player?.volume = 1.0
            player?.play()
            player?.rate = 1.0

            // 短延迟后切回播放类别（独占模式）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self else { return }
                do {
                    try session.setCategory(.playback, mode: .default, options: [])
                    try session.setActive(true, options: [])
                    self.player?.isMuted = false
                    self.player?.volume = 1.0
                    self.player?.play()
                    self.player?.rate = 1.0
                    self.updateNowPlayingInfo()
                    self.logAudioSessionState(context: "after forceRouteRefresh")
                    print("✅ 强制刷新音频路由完成")
                } catch let err {
                    print("❌ 强制刷新音频路由失败(切回): \(err)")
                }
            }
        } catch let err {
            print("❌ 强制刷新音频路由失败(切出): \(err)")
        }
    }

    private func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // 播放命令
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            // 避免在后台频繁 setActive 触发 561015905，统一走内部恢复流程
            self.reassertPlaybackSessionAndResume()
            return .success
        }

        // 暂停命令
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        // 切换播放/暂停命令
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.pause()
            } else {
                // 避免后台频繁 setActive 触发 561015905，统一走内部恢复流程
                self.reassertPlaybackSessionAndResume()
            }
            return .success
        }

        print("🎮 远程控制已设置")
    }

    func play(whiteNoise: WhiteNoise) {
        // 如果是同一个音频，则继续播放
        if currentWhiteNoise?.id == whiteNoise.id {
            // 确保音频会话激活
            activateAudioSession()
            player?.play()
            isPlaying = true
            updateNowPlayingInfo()
            startPlaybackMonitor()
            // 标记白噪音为活跃，避免其他模块释放会话
            AudioSessionManager.shared.markActive(componentId: audioComponentId)
            return
        }

        // 停止当前播放
        stop()

        // 设置新的白噪音
        currentWhiteNoise = whiteNoise
        hasRecordedPlay = false

        // 🔥 关键修复：优先使用缓存的音频，避免后台网络限制
        if let cachedData = AudioCacheManager.shared.getCachedAudio(for: whiteNoise.audioUrl) {
            print("✅ 使用缓存的白噪音音频: \(whiteNoise.title)")
            playFromCachedData(cachedData, whiteNoise: whiteNoise)
            return
        }

        guard let url = URL(string: whiteNoise.audioUrl) else {
            print("Invalid audio URL: \(whiteNoise.audioUrl)")
            return
        }

        // 后台下载并缓存音频（不阻塞播放）
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                AudioCacheManager.shared.cacheAudio(data, for: whiteNoise.audioUrl)
                print("✅ 白噪音音频已缓存: \(whiteNoise.title)")
            } catch {
                print("⚠️ 白噪音音频缓存失败: \(error)")
            }
        }

        // 使用网络流播放
        playFromNetworkURL(url)
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopPlaybackMonitor()
        updateNowPlayingInfo()
    }

    // 从缓存数据播放（避免后台网络限制）
    private func playFromCachedData(_ data: Data, whiteNoise: WhiteNoise) {
        // 由 Orchestrator 统一保证会话类别
        AudioOrchestrator.shared.ensurePlaybackForWhiteNoise()
        activateAudioSession()

        // 🔥 关键修复：使用持久化目录而不是临时目录，避免后台被系统清理
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let whiteNoiseDir = cacheDir.appendingPathComponent("WhiteNoise", isDirectory: true)

        // 确保目录存在
        try? FileManager.default.createDirectory(at: whiteNoiseDir, withIntermediateDirectories: true)

        // 使用音频 URL 的 MD5 作为文件名，确保同一音频使用同一文件
        let fileName = whiteNoise.audioUrl.md5 + ".m4a"
        let fileURL = whiteNoiseDir.appendingPathComponent(fileName)

        do {
            // 如果文件不存在，写入数据
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                try data.write(to: fileURL)
                print("💾 白噪音缓存文件已保存: \(fileName)")
            }

            // 使用本地文件创建播放器
            let asset = AVURLAsset(url: fileURL)
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.preferredForwardBufferDuration = 30
            player = AVPlayer(playerItem: playerItem)

            // 配置播放器
            player?.automaticallyWaitsToMinimizeStalling = false
            player?.actionAtItemEnd = .none
            player?.preventsDisplaySleepDuringVideoPlayback = false
            player?.allowsExternalPlayback = true
            player?.usesExternalPlaybackWhileExternalScreenIsActive = true
            player?.volume = 1.0
            player?.isMuted = false

            // 🔥🔥🔥 关键：强制播放器在后台保持音频渲染
            player?.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible

            // 添加观察者
            addTimeObserver()
            addPlayerObservers(playerItem: playerItem)

            // 开始播放
            player?.play()
            isPlaying = true

            AudioSessionManager.shared.markActive(componentId: audioComponentId)

            print("▶️ 从缓存开始播放: \(whiteNoise.title)")
            logAudioSessionState(context: "after play() from cache")

            // 更新 Now Playing
            updateNowPlayingInfo()

            // 启动播放监控
            startPlaybackMonitor()

        } catch {
            print("❌ 从缓存播放失败: \(error)")
            // 降级到网络流播放
            if let url = URL(string: whiteNoise.audioUrl) {
                playFromNetworkURL(url)
            }
        }
    }

    // 从网络 URL 播放（原有逻辑）
    private func playFromNetworkURL(_ url: URL) {
        // 由 Orchestrator 统一保证会话类别
        AudioOrchestrator.shared.ensurePlaybackForWhiteNoise()
        activateAudioSession()

        // 🔥 关键：使用 AVURLAsset 配置后台网络流媒体支持
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: false
        ])

        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 30
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        player = AVPlayer(playerItem: playerItem)

        // 配置播放器
        player?.automaticallyWaitsToMinimizeStalling = false
        player?.actionAtItemEnd = .none
        player?.preventsDisplaySleepDuringVideoPlayback = false
        player?.allowsExternalPlayback = true
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true
        player?.volume = 1.0
        player?.isMuted = false

        // 🔥🔥🔥 关键：强制播放器在后台保持音频渲染
        player?.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible

        // 添加观察者
        addTimeObserver()
        addPlayerObservers(playerItem: playerItem)

        // 开始播放
        player?.play()
        isPlaying = true

        AudioSessionManager.shared.markActive(componentId: audioComponentId)

        print("▶️ 从网络开始播放: \(currentWhiteNoise?.title ?? "未知")")
        logAudioSessionState(context: "after play() from network")

        updateNowPlayingInfo()
        startPlaybackMonitor()
    }

    func resume() {
        guard let player = player else {
            print("❌ Resume 失败: player 为 nil")
            return
        }

        print("▶️ 尝试继续播放...")

        // 由 Orchestrator 统一保证会话类别
        AudioOrchestrator.shared.ensurePlaybackForWhiteNoise()
        // 关键修复：先确保音频会话类别正确并激活（先 setCategory 再 setActive）
        activateAudioSession()

        // 确保播放器不静音
        player.isMuted = false
        player.volume = 1.0

        // 开始播放（多次调用确保生效）
        player.play()
        player.rate = 1.0
        isPlaying = true

        // 延迟再次确保播放（保险措施）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, let player = self.player else { return }
            player.play()
            player.rate = 1.0
            print("✅ Resume: 延迟确认播放 - rate: \(player.rate), status: \(player.timeControlStatus.rawValue)")
        }

        print("🔍 Player rate after resume: \(player.rate)")
        print("🔍 Player timeControlStatus: \(player.timeControlStatus.rawValue)")

        // 更新 Now Playing 信息
        updateNowPlayingInfo()

        // 重新启动播放监控
        startPlaybackMonitor()

        // 标记白噪音为活跃，避免其他模块释放会话
        AudioSessionManager.shared.markActive(componentId: audioComponentId)
    }

    func stop() {
        player?.pause()
        removeTimeObserver()
        cancelSleepTimer()
        stopPlaybackMonitor()
        player = nil
        isPlaying = false
        progress = 0.0
        currentTime = 0
        duration = 0
        hasRecordedPlay = false
        loadedArtworkUrl = nil

        // 清除 Now Playing 信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

        // 释放音频会话（若无其他组件使用）
        AudioSessionManager.shared.unmarkActive(componentId: audioComponentId)
        AudioSessionManager.shared.releaseAudioSession(componentId: audioComponentId)
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        updateNowPlayingInfo()
    }

    private func updateNowPlayingInfo() {
        guard let whiteNoise = currentWhiteNoise else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        // 读取已有信息，尽量复用封面等字段，避免重复网络请求
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]

        // 标题
        nowPlayingInfo[MPMediaItemPropertyTitle] = whiteNoise.title

        // 艺术家
        nowPlayingInfo[MPMediaItemPropertyArtist] = "白噪音"

        // 专辑
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "青禾计划"

        // 时长
        if duration > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }

        // 当前播放时间
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime

        // 播放速率（1.0 表示正常播放，0.0 表示暂停）
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        // 仅在封面URL变更且处于前台时加载封面，避免后台频繁发起网络请求
        if loadedArtworkUrl != whiteNoise.coverUrl,
           UIApplication.shared.applicationState != .background,
           let coverURL = URL(string: whiteNoise.coverUrl) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: coverURL)
                    if let image = UIImage(data: data) {
                        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                        var updatedInfo = nowPlayingInfo
                        updatedInfo[MPMediaItemPropertyArtwork] = artwork
                        await MainActor.run {
                            MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
                            self.loadedArtworkUrl = whiteNoise.coverUrl
                        }
                    }
                } catch {
                    print("⚠️ 无法加载封面图片: \(error)")
                }
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        print("📱 Now Playing Info 已更新: \(whiteNoise.title)")
    }

    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }

            let oldTime = self.currentTime
            self.currentTime = time.seconds

            if let duration = self.player?.currentItem?.duration.seconds, duration.isFinite {
                self.duration = duration
                self.progress = time.seconds / duration

                // 每 5 秒更新一次 Now Playing Info（避免频繁更新）
                if abs(time.seconds - oldTime) >= 5.0 || oldTime == 0 {
                    self.updateNowPlayingInfo()
                }

                // 播放超过 5 秒后记录播放
                if !self.hasRecordedPlay && time.seconds > 5.0 {
                    self.recordPlay()
                }
            }
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func addPlayerObservers(playerItem: AVPlayerItem) {
        // 播放结束通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }

    @objc private func playerDidFinishPlaying() {
        // 循环播放
        player?.seek(to: .zero)
        player?.play()
    }

    private func recordPlay() {
        guard let whiteNoise = currentWhiteNoise else { return }
        hasRecordedPlay = true

        WhiteNoiseAPIService.shared.recordPlay(id: whiteNoise.id) { result in
            switch result {
            case .success:
                print("Play recorded successfully for: \(whiteNoise.title)")
            case .failure(let error):
                print("Failed to record play: \(error)")
            }
        }
    }

    // MARK: - Sleep Timer
    func setSleepTimer(minutes: Int) {
        cancelSleepTimer()

        sleepTimer = minutes
        remainingTime = TimeInterval(minutes * 60)

        let workItem = DispatchWorkItem { [weak self] in
            DispatchQueue.main.async {
                self?.stop()
                self?.sleepTimer = nil
                self?.remainingTime = 0
            }
        }

        sleepTimerWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(minutes * 60), execute: workItem)

        // 更新剩余时间
        updateRemainingTime()
    }

    func cancelSleepTimer() {
        sleepTimerWorkItem?.cancel()
        sleepTimerWorkItem = nil
        sleepTimer = nil
        remainingTime = 0
    }

    private func updateRemainingTime() {
        guard sleepTimer != nil else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self, self.sleepTimer != nil else { return }

            if self.remainingTime > 0 {
                self.remainingTime -= 1
                self.updateRemainingTime()
            }
        }
    }

    // MARK: - Playback Monitor

    private func startPlaybackMonitor() {
        stopPlaybackMonitor()

        // 🔥 关键修复：后台不启动播放监控，避免干扰播放器
        guard UIApplication.shared.applicationState != .background else {
            print("🔍 后台环境，跳过播放监控启动")
            return
        }

        // 重置失败计数
        consecutiveFailures = 0

        lastMonitorObservedTime = currentTime
        playbackMonitorTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }

            if self.isPlaying {
                let currentRate = player.rate
                let timeControlStatus = player.timeControlStatus
                let didAdvance = (self.currentTime - self.lastMonitorObservedTime) > 1.0
                let item = player.currentItem
                let bufferEmpty = item?.isPlaybackBufferEmpty ?? false
                let likelyToKeepUp = item?.isPlaybackLikelyToKeepUp ?? false

                // 🔥 关键修复：在后台时的判断标准
                let isInBackground = UIApplication.shared.applicationState == .background

                // 判断播放器是否真的停止了
                // 关键点：rate=0 表示播放器已停止，无论时间是否推进
                let isStalled: Bool
                if isInBackground {
                    // 🔥 后台关键修复：只要 rate 为 0，就认为是中断
                    // 原因：在后台，即使缓冲充足，rate=0 也意味着播放器被系统暂停了
                    isStalled = (currentRate == 0)
                } else {
                    // 前台：使用更严格的判断
                    isStalled = (timeControlStatus == .paused && !didAdvance && (bufferEmpty || !likelyToKeepUp))
                }

                if isStalled {
                    self.stallConsecutiveCount += 1
                    print("🧪 StallCheck \(isInBackground ? "[后台]" : "[前台]") paused, rate=\(currentRate), advanced=\(!didAdvance), bufferEmpty=\(bufferEmpty), likelyToKeepUp=\(likelyToKeepUp), count=\(self.stallConsecutiveCount)")

                    // 仅在连续检测到停滞达到2次（约10秒）后再进行恢复，避免误判
                    guard self.stallConsecutiveCount >= 2 else { return }
                    // 检查是否超过最大失败次数
                    if self.consecutiveFailures >= self.maxConsecutiveFailures {
                        print("⚠️ 播放恢复已失败 \(self.consecutiveFailures) 次，停止自动恢复")
                        print("💡 建议：检查是否有其他应用占用音频，或尝试手动重新播放")
                        self.stopPlaybackMonitor()
                        return
                    }

                    // 播放器已停止 - 尝试恢复
                    print("⚠️ 检测到播放中断！正在尝试恢复... (第 \(self.consecutiveFailures + 1) 次)")
                    print("🔍 Current rate: \(currentRate)")
                    print("🔍 TimeControlStatus: \(timeControlStatus.rawValue)")
                    print("🔍 Time advanced: \(didAdvance)")

                    // 尝试恢复播放
                    let _ = self.attemptPlaybackRecovery(player: player)

                    // 增加失败计数
                    self.consecutiveFailures += 1

                    // 连续失败达到阈值，重建播放管线
                    if self.consecutiveFailures >= 2 {
                        print("🧯 连续失败 \(self.consecutiveFailures) 次，尝试重建播放管线")
                        let _ = self.rebuildPlayerPipeline(seekBackTo: self.currentTime)
                    }
                } else {
                    // 播放正常，重置失败计数
                    if self.consecutiveFailures > 0 {
                        print("✅ 播放已恢复正常")
                        self.consecutiveFailures = 0
                    }
                    self.stallConsecutiveCount = 0

                    // 🔥 新增：在后台时，每30秒输出一次播放状态日志，方便调试
                    if isInBackground && Int(self.currentTime) % 30 == 0 {
                        print("📊 [后台播放监控] rate=\(currentRate), status=\(timeControlStatus.rawValue), time=\(String(format: "%.1f", self.currentTime))s, volume=\(player.volume), muted=\(player.isMuted)")
                    }
                }
                self.lastMonitorObservedTime = self.currentTime
            }
        }

        // 确保定时器在所有 RunLoop 模式下运行
        if let timer = playbackMonitorTimer {
            RunLoop.main.add(timer, forMode: .common)
        }

        print("🔍 播放监控已启动（间隔：5秒）")
    }

    private var recoveryAttemptCounter = 0

    private func attemptPlaybackRecovery(player: AVPlayer) -> Bool {
        print("🔧 尝试恢复播放...")
        recoveryAttemptCounter &+= 1
        let attemptId = recoveryAttemptCounter

        // 后台不调用 setActive，避免被系统判定为"抢占"而暂停播放
        // 只需确保播放器状态正确即可

        // 确保播放器不静音，音量正常
        player.isMuted = false
        player.volume = 1.0

        // 1. 直接恢复播放
        player.play()

        // 2. 强制设置播放速率（多次设置确保生效）
        player.rate = 1.0

        // 3. 延迟再次设置，确保播放器响应
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            player.play()
            player.rate = 1.0
        }

        // 4. 使用异步方式检查播放状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            // 如果这不是最新的恢复尝试（例如其间已重建播放管线），忽略过期检查
            guard attemptId == self.recoveryAttemptCounter else { return }

            let isRecovered = player.rate > 0 || player.timeControlStatus == .playing

            if isRecovered {
                print("✅ 播放恢复成功 - rate: \(player.rate), status: \(player.timeControlStatus.rawValue)")
                self.consecutiveFailures = 0
                // 更新 Now Playing Info
                self.updateNowPlayingInfo()
            } else {
                print("❌ 播放恢复失败 - rate: \(player.rate), status: \(player.timeControlStatus.rawValue)")
                // 再次尝试强制播放
                player.isMuted = false
                player.volume = 1.0
                player.play()
                player.rate = 1.0

                // 最后一次尝试
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    player.play()
                    player.rate = 1.0
                }
            }
        }

        // 立即返回 true，避免阻塞
        return true
    }

    // 连续失败后重建播放管线：重新创建 AVPlayerItem 并跳转回原时间
    private func rebuildPlayerPipeline(seekBackTo seconds: TimeInterval? = nil) -> Bool {
        guard let whiteNoise = currentWhiteNoise, let url = URL(string: whiteNoise.audioUrl) else { return false }
        let resumeTime = seconds ?? currentTime

        print("🛠️ 重建播放管线，目标时间: \(String(format: "%.2f", resumeTime))s")

        // 后台不调用 setActive，避免被系统暂停播放
        // 音频会话应该在前台启动时已经激活，后台只需管理播放器

        // 1. 清理观察者
        removeTimeObserver()

        // 2. 创建新的 item 并替换（使用与初始化相同的配置）
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: false
        ])
        let newItem = AVPlayerItem(asset: asset)
        newItem.preferredForwardBufferDuration = 30  // 增加缓冲时间
        newItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true

        if player == nil {
            player = AVPlayer(playerItem: newItem)
        } else {
            player?.replaceCurrentItem(with: newItem)
        }

        // 3. 配置播放器（使用优化后的配置）
        player?.automaticallyWaitsToMinimizeStalling = false
        player?.actionAtItemEnd = .none
        player?.preventsDisplaySleepDuringVideoPlayback = false  // 🔥 关键：纯音频播放
        player?.allowsExternalPlayback = true
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true
        player?.volume = 1.0
        player?.isMuted = false

        // 4. 重新添加观察者
        addTimeObserver()
        addPlayerObservers(playerItem: newItem)

        // 5. 跳转并播放
        let cm = CMTime(seconds: resumeTime, preferredTimescale: 600)
        player?.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self = self else { return }

            // 确保播放器配置正确
            self.player?.isMuted = false
            self.player?.volume = 1.0

            self.player?.play()
            self.player?.rate = 1.0
            self.isPlaying = true
            self.consecutiveFailures = 0
            self.updateNowPlayingInfo()
            print("✅ 播放管线重建完成，已恢复播放 - rate: \(self.player?.rate ?? 0)")

            // 延迟再次强制设置播放速率（多次确保）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.player?.play()
                self.player?.rate = 1.0
                print("🔄 [重建管线] 延迟确认播放 - rate: \(self.player?.rate ?? 0)")
            }
        }

        // 确认状态
        return true
    }

    private func stopPlaybackMonitor() {
        playbackMonitorTimer?.invalidate()
        playbackMonitorTimer = nil
        print("🔍 播放监控已停止")
    }

    // MARK: - App Lifecycle Hooks
    @objc private func appDidEnterBackground() {
        guard isPlaying else { return }

        print("📱 WhiteNoisePlayer: 应用进入后台，确保播放继续")

        // 申请额外的后台时间窗口，确保能完成播放恢复
        if bgTask == .invalid {
            bgTask = UIApplication.shared.beginBackgroundTask(withName: "WhiteNoiseKeepAlive") {
                UIApplication.shared.endBackgroundTask(self.bgTask)
                self.bgTask = .invalid
            }
        }

        // 后台不做会话激活或类别切换，避免被系统判定为"抢占"而暂停播放
        // iOS 后台音频的正确做法：前台激活会话，后台只管理播放器状态
        if AudioOrchestrator.shared.currentRole == .voiceMessage
           || AudioOrchestrator.shared.currentRole == .recording {
            print("ℹ️ [WhiteNoisePlayer] 后台处于语音/录音占用，跳过白噪音干预")
            return
        }

        // 🔥 关键：确保音频会话在后台保持激活
        let session = AVAudioSession.sharedInstance()
        do {
            // 确保类别正确
            if session.category != .playback {
                try session.setCategory(.playback, mode: .default, options: [])
            }
            // 确保会话激活
            if !session.isOtherAudioPlaying {
                try session.setActive(true, options: [])
                print("🔊 后台：音频会话已确认激活")
            }
        } catch let e as NSError {
            if e.domain == NSOSStatusErrorDomain && e.code == 561015905 {
                print("⚠️ 后台：音频会话已激活(561015905)")
            } else {
                print("❌ 后台：音频会话激活失败: \(e)")
            }
        }

        // 记录当前状态
        logAudioSessionState(context: "didEnterBackground")

        // 确保播放器继续播放
        if let player = player {
            let status = player.timeControlStatus
            print("🔍 后台播放器状态 - rate: \(player.rate), status: \(status.rawValue)")

            // 确保播放器不静音
            player.isMuted = false
            player.volume = 1.0

            // 强制开始播放
            player.play()
            player.rate = 1.0

            // 延迟再次确认播放（保险措施）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self, self.isPlaying else { return }
                self.player?.play()
                self.player?.rate = 1.0
                print("✅ 后台播放已确认启动")
            }

            // 更新 Now Playing Info（这对后台播放也很重要）
            updateNowPlayingInfo()
        }
    }

    // MARK: - Debug Logging
    private func logAudioSessionState(context: String) {
        let session = AVAudioSession.sharedInstance()
        let category = session.category.rawValue
        let mode = session.mode.rawValue
        let silenced = session.secondaryAudioShouldBeSilencedHint
        let outputVolume = session.outputVolume
        let otherPlaying = session.isOtherAudioPlaying
        let route = session.currentRoute
        let outputs = route.outputs.map { "\($0.portType.rawValue):\($0.portName)" }.joined(separator: ", ")
        let rate = player?.rate ?? 0
        let status = player?.timeControlStatus.rawValue ?? -1
        let item = player?.currentItem
        let bufferEmpty = item?.isPlaybackBufferEmpty ?? false
        let likelyToKeepUp = item?.isPlaybackLikelyToKeepUp ?? false

        print("🛰️ [AudioSession] \(context) | category=\(category), mode=\(mode), otherPlaying=\(otherPlaying), silencedHint=\(silenced), vol=\(String(format: "%.2f", outputVolume))")
        print("🔊 [Route] outputs=[\(outputs.isEmpty ? "<none>" : outputs)]")
        print("🎚️ [Player] rate=\(rate), status=\(status), bufferEmpty=\(bufferEmpty), likelyToKeepUp=\(likelyToKeepUp)")
    }

    @objc private func appWillEnterForeground() {
        print("📱 WhiteNoisePlayer: 应用返回前台")

        if bgTask != .invalid {
            UIApplication.shared.endBackgroundTask(bgTask)
            bgTask = .invalid
        }

        // 前台恢复：若应当播放且未被语音消息占用，轻量断言播放
        if isPlaying && AudioOrchestrator.shared.currentRole != .voiceMessage {
            print("🔊 前台：恢复播放状态")
            AudioOrchestrator.shared.ensurePlaybackForWhiteNoise()

            // 确保播放器不静音
            player?.isMuted = false
            player?.volume = 1.0

            player?.play()
            player?.rate = 1.0

            updateNowPlayingInfo()
            logAudioSessionState(context: "willEnterForeground")

            print("✅ 前台播放已恢复 - rate: \(player?.rate ?? 0)")

            // 🔥 关键：前台重新启动播放监控
            startPlaybackMonitor()
        } else {
            print("ℹ️ 前台：不需要恢复播放（isPlaying=\(isPlaying), role=\(AudioOrchestrator.shared.currentRole)）")
        }
    }

    // MARK: - Extra Handlers & Helpers
    @objc private func handleSilenceHint(_ n: Notification) {
        guard let v = n.userInfo?[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt else { return }
        if v == 1 {
            print("🔕 次要音频应被静音（hint=begin）")
        } else {
            print("🔔 次要音频静音提示结束（hint=end），尝试恢复播放")
            reassertPlaybackSessionAndResume()
            softRestartIfNoSound()
        }
    }

    @objc private func handleMediaServicesReset() {
        print("🧯 媒体服务已重置，重新配置会话并重建播放器")
        setupAudioSession()
        _ = rebuildPlayerPipeline(seekBackTo: currentTime)
    }

    // 🆕 处理音频会话类别变更
    @objc private func handleAudioSessionCategoryChange() {
        guard isPlaying else { return }

        // 后台不做会话断言，避免冲突；仅确保播放器继续
        if UIApplication.shared.applicationState == .background {
            print("ℹ️ [WhiteNoisePlayer] 后台检测到类别变更，跳过会话断言，仅保持播放器继续")
            self.player?.play()
            self.player?.rate = 1.0
            return
        }

        let session = AVAudioSession.sharedInstance()
        let currentCategory = session.category

        // 如果当前类别不是 playback，说明被其他组件切换了
        // 这时需要在合适的时机重新断言 playback 类别
        if currentCategory != .playback {
            print("⚠️ [WhiteNoisePlayer] 检测到音频会话类别变更: \(currentCategory.rawValue)")
            print("ℹ️ [WhiteNoisePlayer] 将在适当时机恢复 playback 类别")

            // 延迟一小段时间，等待其他组件使用完毕
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, self.isPlaying else { return }

                // 再次检查是否需要恢复
                let latestCategory = AVAudioSession.sharedInstance().category
                if latestCategory != .playback {
                    print("🔄 [WhiteNoisePlayer] 尝试恢复 playback 类别")
                    self.reassertPlaybackSessionAndResume()
                }
            }
        }
    }

    private func reassertPlaybackSessionAndResume() {
        // 统一走 resume() 内的激活流程，避免重复 setActive 导致 561015905
        resume()
    }

    private func softRestartIfNoSound() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self, let p = self.player else { return }
            let stillNotPlaying = (p.rate == 0 && p.timeControlStatus != .playing)
            if stillNotPlaying {
                print("🩹 兜底：检测到仍未进入播放状态，软重启播放器")
                _ = self.rebuildPlayerPipeline(seekBackTo: self.currentTime)
            }
        }
    }

    deinit {
        removeTimeObserver()
        cancelSleepTimer()
        stopPlaybackMonitor()
        NotificationCenter.default.removeObserver(self)
    }
}
