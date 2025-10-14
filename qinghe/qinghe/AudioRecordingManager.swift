import Foundation
import AVFoundation
import UIKit

/// 语音录制管理器
@MainActor
class AudioRecordingManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = AudioRecordingManager()
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var hasPermission = false
    @Published var showPermissionAlert = false
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var audioSession = AVAudioSession.sharedInstance()
    
    // MARK: - Constants
    private let maxRecordingDuration: TimeInterval = 60 // 最大录制时长60秒
    private let minRecordingDuration: TimeInterval = 1  // 最小录制时长1秒
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupAudioSession()
        checkMicrophonePermission()
    }
    
    // MARK: - Public Methods
    
    /// 请求麦克风权限
    func requestMicrophonePermission() async -> Bool {
        // 使用新的API检查权限
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                hasPermission = true
                return true
            case .denied:
                hasPermission = false
                showPermissionAlert = true
                return false
            case .undetermined:
                return await withCheckedContinuation { continuation in
                    audioSession.requestRecordPermission { granted in
                        Task { @MainActor in
                            self.hasPermission = granted
                            if !granted {
                                self.showPermissionAlert = true
                            }
                            continuation.resume(returning: granted)
                        }
                    }
                }
            @unknown default:
                hasPermission = false
                return false
            }
        } else {
            // iOS 17.0以下使用旧API
            switch audioSession.recordPermission {
            case .granted:
                hasPermission = true
                return true
            case .denied:
                hasPermission = false
                showPermissionAlert = true
                return false
            case .undetermined:
                return await withCheckedContinuation { continuation in
                    audioSession.requestRecordPermission { granted in
                        Task { @MainActor in
                            self.hasPermission = granted
                            if !granted {
                                self.showPermissionAlert = true
                            }
                            continuation.resume(returning: granted)
                        }
                    }
                }
            @unknown default:
                hasPermission = false
                return false
            }
        }
    }
    
    /// 开始录制
    func startRecording() async -> Bool {
        // 检查权限
        guard await requestMicrophonePermission() else {
            print("🎤 录音权限被拒绝")
            return false
        }
        
        // 如果正在录制，先停止
        if isRecording {
            let _ = stopRecording()
        }
        
        do {
            // 统一交由 AudioOrchestrator 管理录音场景
            AudioOrchestrator.shared.beginBackgroundRecording()

            // 创建录音文件URL
            let recordingURL = getRecordingURL()
            
            // 配置录音设置
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // 创建录音器
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            // 开始录制
            if audioRecorder?.record() == true {
                isRecording = true
                recordingStartTime = Date()
                recordingDuration = 0
                startRecordingTimer()
                print("🎤 开始录音")
                return true
            } else {
                print("🎤 录音启动失败")
                return false
            }
            
        } catch {
            print("🎤 录音设置失败: \(error)")
            return false
        }
    }
    
    /// 停止录制
    func stopRecording() -> URL? {
        guard isRecording, let recorder = audioRecorder else {
            return nil
        }
        
        isRecording = false
        stopRecordingTimer()
        
        recorder.stop()
        
        // 释放音频会话；若白噪音正在播放则保留会话，避免后台播放被中断
        if WhiteNoisePlayer.shared.isPlaying {
            print("ℹ️ AudioRecordingManager: 保留音频会话（白噪音正在播放）")
        } else {
            AudioOrchestrator.shared.endBackgroundRecording()
            print("✅ AudioRecordingManager: 音频会话交由 Orchestrator 释放")
        }
        
        // 检查录制时长
        if recordingDuration < minRecordingDuration {
            print("🎤 录音时长太短，已删除")
            deleteRecordingFile(recorder.url)
            return nil
        }
        
        print("🎤 录音完成，时长: \(recordingDuration)秒")
        return recorder.url
    }
    
    /// 取消录制
    func cancelRecording() {
        guard isRecording, let recorder = audioRecorder else {
            return
        }
        
        isRecording = false
        stopRecordingTimer()
        
        recorder.stop()
        
        // 释放音频会话；若白噪音正在播放则保留会话，避免后台播放被中断
        if WhiteNoisePlayer.shared.isPlaying {
            print("ℹ️ AudioRecordingManager: 保留音频会话（白噪音正在播放）")
        } else {
            do {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                print("✅ AudioRecordingManager: 音频会话已释放")
            } catch {
                print("⚠️ AudioRecordingManager: 音频会话释放失败: \(error)")
            }
        }
        
        // 删除录音文件
        deleteRecordingFile(recorder.url)
        print("🎤 录音已取消")
    }
    
    // MARK: - Private Methods
    
    /// 设置音频会话
    private func setupAudioSession() {
        print("ℹ️ AudioRecordingManager: 音频会话由 AudioOrchestrator 统一管理")
    }

    /// 检查麦克风权限
    private func checkMicrophonePermission() {
        if #available(iOS 17.0, *) {
            hasPermission = AVAudioApplication.shared.recordPermission == .granted
        } else {
            hasPermission = audioSession.recordPermission == .granted
        }
    }
    
    /// 获取录音文件URL
    private func getRecordingURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "voice_\(Int(Date().timeIntervalSince1970)).m4a"
        return documentsPath.appendingPathComponent(fileName)
    }
    
    /// 开始录制计时器
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRecordingDuration()
            }
        }
    }
    
    /// 停止录制计时器
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    /// 更新录制时长
    private func updateRecordingDuration() {
        guard let startTime = recordingStartTime else { return }
        
        recordingDuration = Date().timeIntervalSince(startTime)
        
        // 检查是否超过最大录制时长
        if recordingDuration >= maxRecordingDuration {
            let _ = stopRecording()
        }
    }
    
    /// 删除录音文件
    private func deleteRecordingFile(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("🎤 删除录音文件失败: \(error)")
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecordingManager: @preconcurrency AVAudioRecorderDelegate {

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("🎤 录音完成但有错误")
            Task { @MainActor in
                isRecording = false
                stopRecordingTimer()
            }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("🎤 录音编码错误: \(error?.localizedDescription ?? "未知错误")")
        Task { @MainActor in
            isRecording = false
            stopRecordingTimer()
        }
    }
}
