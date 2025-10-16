import Foundation
import AVFoundation

// MARK: - 运动音频播放器
@MainActor
class WorkoutAudioPlayer: NSObject, ObservableObject {
    static let shared = WorkoutAudioPlayer()
    
    // 发布的属性
    @Published var isPlaying = false
    @Published var currentAudioUrl: String?
    @Published var playbackProgress: Double = 0.0
    @Published var volume: Float = 1.0
    
    // 私有属性
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var completionHandler: ((Bool) -> Void)?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - 音频会话设置
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // 设置音频会话类别 - 支持运动时播放
            // .allowBluetooth(HFP) 与 .playback 不兼容，避免触发 -50 错误
            try audioSession.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )
            
            try audioSession.setActive(true)
            
            print("🔊 音频会话已配置 - 类别: 播放, 模式: 语音")
        } catch {
            print("❌ 音频会话配置失败: \(error)")
        }
    }
    
    // MARK: - 播放音频
    func playAudio(from url: URL, completion: @escaping (Bool) -> Void) async {
        // 停止当前播放
        stopCurrentAudio()
        
        completionHandler = completion
        currentAudioUrl = url.absoluteString
        
        do {
            // 下载音频数据
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ 音频下载失败 - 状态码: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                await handlePlaybackCompletion(success: false)
                return
            }
            
            // 创建音频播放器
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            
            // 开始播放
            if audioPlayer?.play() == true {
                isPlaying = true
                startPlaybackTimer()
                print("🎵 开始播放音频 - URL: \(url.absoluteString)")
            } else {
                print("❌ 音频播放启动失败")
                await handlePlaybackCompletion(success: false)
            }
            
        } catch {
            print("❌ 音频播放错误: \(error)")
            await handlePlaybackCompletion(success: false)
        }
    }
    
    // MARK: - 播放控制
    func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        stopPlaybackTimer()
        print("⏸️ 音频播放已暂停")
    }
    
    func resumeAudio() {
        if audioPlayer?.play() == true {
            isPlaying = true
            startPlaybackTimer()
            print("▶️ 音频播放已恢复")
        }
    }
    
    func stopAudio() {
        stopCurrentAudio()
        print("⏹️ 音频播放已停止")
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume))
        audioPlayer?.volume = volume
        print("🔊 音量已设置为: \(Int(volume * 100))%")
    }
    
    // MARK: - 私有方法
    
    private func stopCurrentAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playbackProgress = 0.0
        stopPlaybackTimer()
        currentAudioUrl = nil
        
        // 释放音频会话，若白噪音正在播放则保留会话，避免后台播放被意外中断
        if WhiteNoisePlayer.shared.isPlaying {
            print("ℹ️ WorkoutAudioPlayer: 保留音频会话（白噪音正在播放）")
        } else {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                print("✅ WorkoutAudioPlayer: 音频会话已释放")
            } catch {
                print("⚠️ WorkoutAudioPlayer: 音频会话释放失败: \(error)")
            }
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
        
        if player.duration > 0 {
            playbackProgress = player.currentTime / player.duration
        }
    }
    
    private func handlePlaybackCompletion(success: Bool) async {
        isPlaying = false
        playbackProgress = success ? 1.0 : 0.0
        stopPlaybackTimer()
        
        if let completion = completionHandler {
            completion(success)
            completionHandler = nil
        }
        
        currentAudioUrl = nil
    }
}

// MARK: - AVAudioPlayerDelegate
extension WorkoutAudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            print("🎵 音频播放完成 - 成功: \(flag)")
            await handlePlaybackCompletion(success: flag)
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            print("❌ 音频解码错误: \(error?.localizedDescription ?? "未知错误")")
            await handlePlaybackCompletion(success: false)
        }
    }
}

// MARK: - 音频播放状态
enum AudioPlaybackState {
    case idle
    case loading
    case playing
    case paused
    case completed
    case error(String)
    
    var description: String {
        switch self {
        case .idle: return "空闲"
        case .loading: return "加载中"
        case .playing: return "播放中"
        case .paused: return "已暂停"
        case .completed: return "播放完成"
        case .error(let message): return "错误: \(message)"
        }
    }
}

// MARK: - 音频播放配置
struct AudioPlaybackConfig {
    let volume: Float
    let allowBackground: Bool
    let duckOthers: Bool
    let allowBluetooth: Bool
    
    static let `default` = AudioPlaybackConfig(
        volume: 1.0,
        allowBackground: true,
        duckOthers: true,
        allowBluetooth: true
    )
    
    static let workout = AudioPlaybackConfig(
        volume: 0.8,
        allowBackground: true,
        duckOthers: true,
        allowBluetooth: true
    )
}
