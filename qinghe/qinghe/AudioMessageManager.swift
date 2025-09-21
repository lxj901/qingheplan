import Foundation
import AVFoundation
import Combine
import CryptoKit

/// 音频消息播放管理器
@MainActor
class AudioMessageManager: NSObject, ObservableObject {
    static let shared = AudioMessageManager()
    
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var currentPlayingMessageId: String?
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var playbackProgress: Double = 0
    
    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var audioSession = AVAudioSession.sharedInstance()
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Public Methods
    
    /// 播放音频消息
    func playAudio(from message: ChatMessage) {
        guard let audioUrl = message.mediaUrl else {
            print("❌ 音频URL为空")
            return
        }

        print("🎵 准备播放音频: \(audioUrl)")

        // 如果正在播放同一条消息，则暂停
        if currentPlayingMessageId == message.id && isPlaying {
            pauseAudio()
            return
        }

        // 如果正在播放其他消息，先停止
        if isPlaying {
            stopAudio()
        }

        currentPlayingMessageId = message.id

        // 检查是否是本地文件
        if audioUrl.hasPrefix("file://") {
            playLocalAudio(url: audioUrl)
        } else if audioUrl.hasPrefix("http://") || audioUrl.hasPrefix("https://") {
            // 远程URL，下载并播放
            downloadAndPlayAudio(url: audioUrl)
        } else {
            // 可能是相对路径或其他格式，尝试作为远程URL处理
            print("⚠️ 未知的音频URL格式，尝试作为远程URL处理: \(audioUrl)")
            downloadAndPlayAudio(url: audioUrl)
        }
    }
    
    /// 暂停播放
    func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        stopPlaybackTimer()
    }
    
    /// 停止播放
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentPlayingMessageId = nil
        currentTime = 0
        duration = 0
        playbackProgress = 0
        stopPlaybackTimer()
    }
    
    /// 跳转到指定时间
    func seekTo(time: Double) {
        guard let player = audioPlayer else { return }
        player.currentTime = time
        currentTime = time
        updateProgress()
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            // 设置音频会话类别为播放和录制，支持蓝牙和扬声器
            // 注意：.allowBluetoothA2DP 不能与 .playAndRecord 同时使用，否则会导致 -50 (paramErr)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            print("✅ 音频会话设置成功")
        } catch {
            print("❌ 音频会话设置失败: \(error)")
            // 尝试备用配置
            do {
                try audioSession.setCategory(.playback, mode: .default)
                try audioSession.setActive(true)
                print("✅ 音频会话备用配置成功")
            } catch {
                print("❌ 音频会话备用配置也失败: \(error)")
            }
        }
    }
    
    private func playLocalAudio(url: String) {
        guard let fileURL = URL(string: url) else {
            print("❌ 无效的本地音频URL: \(url)")
            return
        }

        // 检查文件是否存在
        let filePath = fileURL.path
        if !FileManager.default.fileExists(atPath: filePath) {
            print("❌ 音频文件不存在: \(filePath)")

            // 尝试从原始URL中提取文件名，看是否可以从服务器下载
            let fileName = fileURL.lastPathComponent
            if !fileName.isEmpty {
                print("🔄 尝试从服务器下载音频文件: \(fileName)")
                // 构造可能的服务器URL
                let serverUrl = "https://api.qinghe.com/uploads/audio/\(fileName)"
                downloadAndPlayAudio(url: serverUrl)
            }
            return
        }

        // 获取文件信息
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            print("📁 音频文件信息: 路径=\(filePath), 大小=\(fileSize)字节")

            if fileSize == 0 {
                print("❌ 音频文件为空")
                return
            }
        } catch {
            print("❌ 无法获取文件信息: \(error)")
        }

        // 重新设置音频会话
        setupAudioSession()

        do {
            // 尝试创建音频播放器
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            print("✅ 成功创建音频播放器")
            configureAndPlayAudio()
        } catch let error as NSError {
            print("❌ 本地音频播放失败: \(error)")
            print("❌ 错误代码: \(error.code)")
            print("❌ 错误域: \(error.domain)")

            // 尝试使用Data方式加载
            do {
                let audioData = try Data(contentsOf: fileURL)
                print("📁 音频数据大小: \(audioData.count)字节")
                playAudioData(audioData)
            } catch {
                print("❌ 使用Data方式也失败: \(error)")
            }
        }
    }
    
    private func downloadAndPlayAudio(url: String) {
        guard let audioURL = URL(string: url) else {
            print("❌ 无效的音频URL: \(url)")
            return
        }
        
        // 检查缓存
        if let cachedData = AudioCacheManager.shared.getCachedAudio(for: url) {
            playAudioData(cachedData)
            return
        }
        
        // 下载音频
        URLSession.shared.dataTask(with: audioURL) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("❌ 音频下载失败: \(error?.localizedDescription ?? "未知错误")")
                return
            }
            
            // 缓存音频数据
            AudioCacheManager.shared.cacheAudio(data, for: url)
            
            DispatchQueue.main.async {
                self?.playAudioData(data)
            }
        }.resume()
    }
    
    private func playAudioData(_ data: Data) {
        print("🎵 尝试播放音频数据，大小: \(data.count)字节")

        // 检查数据是否为空
        if data.isEmpty {
            print("❌ 音频数据为空")
            return
        }

        // 检测音频格式
        let format = detectAudioFormat(from: data)
        print("🎵 检测到音频格式: \(format)")

        // 重新设置音频会话
        setupAudioSession()

        do {
            audioPlayer = try AVAudioPlayer(data: data)
            print("✅ 成功从数据创建音频播放器")
            configureAndPlayAudio()
        } catch let error as NSError {
            print("❌ 音频播放失败: \(error)")
            print("❌ 错误代码: \(error.code)")
            print("❌ 错误域: \(error.domain)")

            // 检查是否是文件格式问题
            if error.code == Int(kAudioFileUnsupportedFileTypeError) {
                print("❌ 不支持的音频文件格式: \(format)")

                // 如果是不支持的格式，尝试使用系统音频服务
                tryPlayWithSystemAudioServices(data: data)
            }
        }
    }

    /// 尝试使用系统音频服务播放（作为备用方案）
    private func tryPlayWithSystemAudioServices(data: Data) {
        print("🎵 尝试使用系统音频服务播放")

        // 创建临时文件
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_audio.m4a")

        do {
            try data.write(to: tempURL)

            // 尝试重新加载
            audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
            print("✅ 使用临时文件成功创建音频播放器")
            configureAndPlayAudio()

            // 播放完成后删除临时文件
            DispatchQueue.main.asyncAfter(deadline: .now() + (duration + 1)) {
                try? FileManager.default.removeItem(at: tempURL)
            }
        } catch {
            print("❌ 系统音频服务也失败: \(error)")
        }
    }
    
    private func configureAndPlayAudio() {
        guard let player = audioPlayer else {
            print("❌ 音频播放器为空")
            return
        }

        player.delegate = self

        // 设置音频播放器属性
        player.volume = 1.0
        player.enableRate = true

        // 准备播放
        let prepareResult = player.prepareToPlay()
        print("🎵 音频播放器准备结果: \(prepareResult)")

        duration = player.duration
        currentTime = 0
        playbackProgress = 0

        print("🎵 音频信息: 时长=\(duration)秒, 格式=\(player.format.description)")
        print("🎵 音频播放器状态: isPlaying=\(player.isPlaying), url=\(player.url?.absoluteString ?? "无URL")")

        // 尝试播放
        if player.play() {
            isPlaying = true
            startPlaybackTimer()
            print("🎵 开始播放音频，时长: \(duration)秒")
        } else {
            print("❌ 音频播放启动失败")
            print("❌ 播放器错误: \(player.isPlaying)")
        }
    }
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePlaybackProgress()
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updatePlaybackProgress() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
        updateProgress()
    }
    
    private func updateProgress() {
        if duration > 0 {
            playbackProgress = currentTime / duration
        }
    }

    /// 检测音频文件格式
    private func detectAudioFormat(from data: Data) -> String {
        let header = data.prefix(16)

        if header.starts(with: [0x66, 0x74, 0x79, 0x70]) { // ftyp
            return "M4A/MP4"
        } else if header.starts(with: [0x49, 0x44, 0x33]) { // ID3
            return "MP3"
        } else if header.starts(with: [0xFF, 0xFB]) || header.starts(with: [0xFF, 0xFA]) {
            return "MP3"
        } else if header.starts(with: [0x52, 0x49, 0x46, 0x46]) { // RIFF
            return "WAV"
        } else if header.starts(with: [0x4F, 0x67, 0x67, 0x53]) { // OggS
            return "OGG"
        } else if header.starts(with: [0x66, 0x4C, 0x61, 0x43]) { // fLaC
            return "FLAC"
        } else {
            let headerHex = header.map { String(format: "%02x", $0) }.joined(separator: " ")
            return "未知格式 (头部: \(headerHex))"
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioMessageManager: @preconcurrency AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🎵 音频播放完成，成功: \(flag)")
        Task { @MainActor in
            stopAudio()

            // 发送播放完成通知
            NotificationCenter.default.post(
                name: .audioPlaybackFinished,
                object: currentPlayingMessageId
            )
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ 音频解码错误: \(error?.localizedDescription ?? "未知错误")")
        Task { @MainActor in
            stopAudio()
        }
    }
}

// MARK: - Audio Cache Manager
class AudioCacheManager {
    static let shared = AudioCacheManager()
    private let cache = NSCache<NSString, NSData>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // 创建音频缓存目录
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("AudioCache")
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        // 设置缓存限制
        cache.countLimit = 100 // 最多缓存100个音频文件
        cache.totalCostLimit = 50 * 1024 * 1024 // 最大50MB
    }
    
    func cacheAudio(_ data: Data, for url: String) {
        let key = NSString(string: url.md5)
        cache.setObject(NSData(data: data), forKey: key, cost: data.count)
        
        // 同时保存到磁盘
        let fileURL = cacheDirectory.appendingPathComponent("\(url.md5).m4a")
        try? data.write(to: fileURL)
    }
    
    func getCachedAudio(for url: String) -> Data? {
        let key = NSString(string: url.md5)
        
        // 先从内存缓存获取
        if let cachedData = cache.object(forKey: key) {
            return Data(referencing: cachedData)
        }
        
        // 从磁盘缓存获取
        let fileURL = cacheDirectory.appendingPathComponent("\(url.md5).m4a")
        if let data = try? Data(contentsOf: fileURL) {
            // 重新加入内存缓存
            cache.setObject(NSData(data: data), forKey: key, cost: data.count)
            return data
        }
        
        return nil
    }
    
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        print("🧹 音频缓存已清理")
    }

    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0

        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            for file in files {
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(attributes.fileSize ?? 0)
            }
        } catch {
            print("❌ 计算音频缓存大小失败: \(error)")
        }

        return totalSize
    }

    func getCacheFileCount() -> Int {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            return files.count
        } catch {
            print("❌ 获取音频缓存文件数量失败: \(error)")
            return 0
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let audioPlaybackFinished = Notification.Name("AudioPlaybackFinished")
}

// MARK: - String Extension for MD5
extension String {
    var md5: String {
        let data = Data(self.utf8)
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}


