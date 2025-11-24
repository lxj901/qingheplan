import Foundation
import AVFoundation
import Combine
import UIKit

/// 短视频播放器管理器（单例）
/// 负责管理播放器池、预加载、缓存等核心功能
@MainActor
class ShortVideoPlayerManager: ObservableObject {
    static let shared = ShortVideoPlayerManager()
    
    // MARK: - Published Properties
    
    /// 当前播放的视频 URL
    @Published var currentVideoURL: String?
    
    /// 播放状态
    @Published var isPlaying: Bool = false
    
    /// 缓冲状态
    @Published var isBuffering: Bool = false
    
    /// 播放进度 (0.0 - 1.0)
    @Published var progress: Double = 0.0
    
    /// 当前播放时间（秒）
    @Published var currentTime: Double = 0.0
    
    /// 总时长（秒）
    @Published var duration: Double = 0.0
    
    /// 是否静音
    @Published var isMuted: Bool = false

    /// 视频尺寸
    @Published var videoSize: CGSize = .zero

    /// 视频宽高比
    @Published var videoAspectRatio: CGFloat = 16.0 / 9.0

    // MARK: - Private Properties
    
    /// 播放器池（最多保持3个播放器实例）
    private var playerPool: [String: AVPlayer] = [:]
    
    /// 播放器项池
    private var playerItemPool: [String: AVPlayerItem] = [:]
    
    /// 当前活跃的播放器
    private var currentPlayer: AVPlayer?
    
    /// 预加载的视频 URL 列表
    private var preloadQueue: [String] = []
    
    /// 时间观察者
    private var timeObserver: Any?
    
    /// 播放结束观察者
    private var playbackEndObservers: [NSObjectProtocol] = []
    
    /// 播放器状态观察者
    private var statusObservers: [NSKeyValueObservation] = []
    
    /// 缓冲状态观察者
    private var bufferObservers: [NSKeyValueObservation] = []
    
    /// 最大播放器池大小
    private let maxPoolSize = 3
    
    /// 最大预加载数量
    private let maxPreloadCount = 2
    
    // MARK: - Initialization
    
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Public Methods
    
    /// 播放视频
    /// - Parameters:
    ///   - url: 视频 URL
    ///   - autoPlay: 是否自动播放
    ///   - loop: 是否循环播放
    ///   - muted: 是否静音
    func play(url: String, autoPlay: Bool = true, loop: Bool = true, muted: Bool = false) {
        print("🎬 ShortVideoPlayerManager: 播放视频 - \(url)")

        // 如果是同一个视频，直接播放
        if currentVideoURL == url, let player = currentPlayer {
            print("▶️ ShortVideoPlayerManager: 继续播放当前视频")
            player.play()
            isPlaying = true
            return
        }

        // 暂停之前的播放器
        if let previousPlayer = currentPlayer {
            print("⏸️ ShortVideoPlayerManager: 暂停之前的播放器")
            previousPlayer.pause()
        }

        // 清理观察者
        removeObservers()

        currentVideoURL = url
        isMuted = muted

        // 获取或创建播放器
        let player = getOrCreatePlayer(for: url)
        currentPlayer = player

        // 如果是复用的播放器，重置播放位置
        if let playerItem = player.currentItem {
            if playerItem.currentTime() != .zero {
                print("🔄 ShortVideoPlayerManager: 重置播放位置")
                playerItem.seek(to: .zero, completionHandler: nil)
            }
        }

        // 设置静音
        player.isMuted = muted

        // 设置循环播放
        if loop {
            setupLooping(for: player, url: url)
        }

        // 添加时间观察者
        addTimeObserver(to: player)

        // 添加状态观察者
        addStatusObserver(to: player, url: url)

        // 自动播放
        if autoPlay {
            player.play()
            isPlaying = true
        }
    }
    
    /// 暂停播放
    func pause() {
        currentPlayer?.pause()
        isPlaying = false
        print("⏸️ ShortVideoPlayerManager: 暂停播放")
    }
    
    /// 恢复播放
    func resume() {
        currentPlayer?.play()
        isPlaying = true
        print("▶️ ShortVideoPlayerManager: 恢复播放")
    }
    
    /// 切换播放/暂停
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }
    
    /// 跳转到指定时间
    /// - Parameter time: 目标时间（秒）
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        currentPlayer?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        print("⏩ ShortVideoPlayerManager: 跳转到 \(time) 秒")
    }
    
    /// 设置静音
    /// - Parameter muted: 是否静音
    func setMuted(_ muted: Bool) {
        isMuted = muted
        currentPlayer?.isMuted = muted
        print("🔇 ShortVideoPlayerManager: 静音状态 - \(muted)")
    }
    
    /// 预加载视频
    /// - Parameter urls: 要预加载的视频 URL 列表
    func preload(urls: [String]) {
        print("📥 ShortVideoPlayerManager: 预加载 \(urls.count) 个视频")
        
        // 限制预加载数量
        let urlsToPreload = Array(urls.prefix(maxPreloadCount))
        
        for url in urlsToPreload {
            // 如果已经在池中，跳过
            if playerItemPool[url] != nil {
                continue
            }
            
            // 创建 PlayerItem 并预加载
            if let videoURL = URL(string: url) {
                let playerItem = AVPlayerItem(url: videoURL)
                playerItemPool[url] = playerItem
                
                // 观察缓冲状态
                let observer = playerItem.observe(\.status) { [weak self] item, _ in
                    if item.status == .readyToPlay {
                        print("✅ ShortVideoPlayerManager: 预加载完成 - \(url)")
                    } else if item.status == .failed {
                        print("❌ ShortVideoPlayerManager: 预加载失败 - \(url)")
                    }
                }
                statusObservers.append(observer)
            }
        }
        
        preloadQueue = urlsToPreload
    }
    
    /// 获取当前播放器
    func getCurrentPlayer() -> AVPlayer? {
        return currentPlayer
    }

    /// 移除观察者（切换视频时调用）
    private func removeObservers() {
        // 移除时间观察者
        if let observer = timeObserver {
            currentPlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }

        // 移除播放结束观察者
        for observer in playbackEndObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        playbackEndObservers.removeAll()

        // 注意：不清理 statusObservers 和 bufferObservers
        // 因为它们可能被其他播放器使用
    }

    /// 清理资源
    func cleanup() {
        print("🧹 ShortVideoPlayerManager: 清理资源")
        
        // 移除时间观察者
        if let observer = timeObserver {
            currentPlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // 移除播放结束观察者
        for observer in playbackEndObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        playbackEndObservers.removeAll()
        
        // 移除状态观察者
        statusObservers.removeAll()
        bufferObservers.removeAll()
        
        // 暂停所有播放器
        for (_, player) in playerPool {
            player.pause()
        }
        
        // 清空当前播放器
        currentPlayer = nil
        currentVideoURL = nil
        isPlaying = false
    }
    
    /// 清空播放器池
    func clearPool() {
        print("🗑️ ShortVideoPlayerManager: 清空播放器池")
        cleanup()
        playerPool.removeAll()
        playerItemPool.removeAll()
        preloadQueue.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// 获取或创建播放器
    private func getOrCreatePlayer(for url: String) -> AVPlayer {
        // 如果池中已有，直接返回
        if let existingPlayer = playerPool[url] {
            print("♻️ ShortVideoPlayerManager: 复用播放器 - \(url)")

            // 检查 PlayerItem 状态
            if let playerItem = existingPlayer.currentItem {
                // 如果 PlayerItem 已经播放完毕或出错，重新创建
                if playerItem.status == .failed {
                    print("⚠️ ShortVideoPlayerManager: PlayerItem 失败，重新创建")
                    playerPool.removeValue(forKey: url)
                    playerItemPool.removeValue(forKey: url)
                    return getOrCreatePlayer(for: url)
                }
            }

            return existingPlayer
        }

        // 如果池已满，移除最旧的播放器
        if playerPool.count >= maxPoolSize {
            if let oldestKey = playerPool.keys.first {
                print("🗑️ ShortVideoPlayerManager: 移除旧播放器 - \(oldestKey)")
                playerPool[oldestKey]?.pause()
                playerPool.removeValue(forKey: oldestKey)
                playerItemPool.removeValue(forKey: oldestKey)
            }
        }

        // 创建新播放器
        let player: AVPlayer
        if let playerItem = playerItemPool[url] {
            // 使用预加载的 PlayerItem
            print("📦 ShortVideoPlayerManager: 使用预加载的 PlayerItem - \(url)")

            // 检查 PlayerItem 状态
            if playerItem.status == .failed {
                print("⚠️ ShortVideoPlayerManager: 预加载的 PlayerItem 失败，重新创建")
                playerItemPool.removeValue(forKey: url)
                return getOrCreatePlayer(for: url)
            }

            player = AVPlayer(playerItem: playerItem)
        } else if let videoURL = URL(string: url) {
            // 创建新的 PlayerItem
            print("🆕 ShortVideoPlayerManager: 创建新播放器 - \(url)")
            let playerItem = AVPlayerItem(url: videoURL)
            playerItemPool[url] = playerItem
            player = AVPlayer(playerItem: playerItem)
        } else {
            print("❌ ShortVideoPlayerManager: 无效的 URL - \(url)")
            return AVPlayer()
        }

        // 添加到池中
        playerPool[url] = player

        // 解析视频尺寸
        parseVideoSize(from: player)

        return player
    }
    
    /// 设置循环播放
    private func setupLooping(for player: AVPlayer, url: String) {
        let observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self, weak player] _ in
            player?.seek(to: .zero)
            player?.play()
            self?.isPlaying = true
            print("🔄 ShortVideoPlayerManager: 循环播放 - \(url)")
        }
        playbackEndObservers.append(observer)
    }
    
    /// 添加时间观察者
    private func addTimeObserver(to player: AVPlayer) {
        // 移除旧的观察者
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        
        // 每0.1秒更新一次进度
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            let currentTime = time.seconds
            let duration = player.currentItem?.duration.seconds ?? 0
            
            self.currentTime = currentTime
            self.duration = duration
            
            if duration > 0 {
                self.progress = currentTime / duration
            }
        }
    }
    
    /// 添加状态观察者
    private func addStatusObserver(to player: AVPlayer, url: String) {
        guard let playerItem = player.currentItem else { return }
        
        // 观察播放状态
        let statusObserver = playerItem.observe(\.status) { [weak self] item, _ in
            Task { @MainActor in
                switch item.status {
                case .readyToPlay:
                    print("✅ ShortVideoPlayerManager: 准备就绪 - \(url)")
                    self?.isBuffering = false
                case .failed:
                    print("❌ ShortVideoPlayerManager: 播放失败 - \(url)")
                    self?.isBuffering = false
                case .unknown:
                    print("⚠️ ShortVideoPlayerManager: 状态未知 - \(url)")
                    self?.isBuffering = true
                @unknown default:
                    break
                }
            }
        }
        statusObservers.append(statusObserver)
        
        // 观察缓冲状态
        let bufferObserver = playerItem.observe(\.isPlaybackLikelyToKeepUp) { [weak self] item, _ in
            Task { @MainActor in
                self?.isBuffering = !item.isPlaybackLikelyToKeepUp
            }
        }
        bufferObservers.append(bufferObserver)
    }
    
    /// 解析视频尺寸
    private func parseVideoSize(from player: AVPlayer) {
        guard let playerItem = player.currentItem else {
            print("⚠️ ShortVideoPlayerManager: 无法获取 PlayerItem")
            return
        }

        // 方法1: 从 PlayerItem 的 presentationSize 获取（需要等待加载）
        // 添加观察者监听 presentationSize 变化
        let sizeObserver = playerItem.observe(\.presentationSize, options: [.new]) { [weak self] item, change in
            Task { @MainActor in
                guard let self = self else { return }
                let size = item.presentationSize

                if size.width > 0 && size.height > 0 {
                    self.videoSize = size
                    self.videoAspectRatio = size.width / size.height
                    print("📐 ShortVideoPlayerManager: 视频尺寸 - \(size.width) x \(size.height), 宽高比: \(self.videoAspectRatio)")
                }
            }
        }
        statusObservers.append(sizeObserver)

        // 方法2: 从 AVAsset 的 tracks 获取（更准确）
        Task {
            guard let asset = playerItem.asset as? AVURLAsset else { return }

            do {
                // 异步加载视频轨道
                let tracks = try await asset.loadTracks(withMediaType: .video)

                if let videoTrack = tracks.first {
                    // 获取自然尺寸
                    let naturalSize = try await videoTrack.load(.naturalSize)

                    // 获取变换矩阵（处理旋转）
                    let preferredTransform = try await videoTrack.load(.preferredTransform)

                    // 计算实际显示尺寸（考虑旋转）
                    let size = naturalSize.applying(preferredTransform)
                    let actualSize = CGSize(width: abs(size.width), height: abs(size.height))

                    await MainActor.run {
                        self.videoSize = actualSize
                        self.videoAspectRatio = actualSize.width / actualSize.height
                        print("📐 ShortVideoPlayerManager: 视频实际尺寸 - \(actualSize.width) x \(actualSize.height), 宽高比: \(self.videoAspectRatio)")
                    }
                }
            } catch {
                print("❌ ShortVideoPlayerManager: 解析视频尺寸失败 - \(error)")
            }
        }
    }

    /// 设置音频会话
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("🔊 ShortVideoPlayerManager: 音频会话设置成功")
        } catch {
            print("❌ ShortVideoPlayerManager: 音频会话设置失败 - \(error)")
        }
    }
}

