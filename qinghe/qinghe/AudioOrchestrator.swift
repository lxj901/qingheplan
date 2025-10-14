import Foundation
import AVFoundation

/// 统一协调 App 内部的音频会话占用，避免白噪音与语音消息等互相抢占，
/// 并确保后台行为简单稳定（后台尽量不切换类别、不频繁 setActive）。
final class AudioOrchestrator {
    static let shared = AudioOrchestrator()

    enum Role {
        case none
        case whiteNoise
        case voiceMessage
        case recording
    }

    private(set) var currentRole: Role = .none
    private var whiteNoiseWasPlayingBeforeVoiceMsg = false
    private var whiteNoiseWasPlayingBeforeRecording = false

    private let session = AVAudioSession.sharedInstance()
    private let queue = DispatchQueue(label: "audio.orchestrator.serial")

    private init() {}

    // MARK: - Public APIs

    /// 在播放白噪音前调用，确保会话设置为 .playback（独占），避免被混音误判为“次要音频”。
    func ensurePlaybackForWhiteNoise() {
        queue.sync {
            // 如果当前是语音消息占用，则不要硬切回，等待语音消息结束后自动恢复
            if currentRole == .voiceMessage { return }
            do {
                if session.category != .playback || session.mode != .default {
                    try session.setCategory(.playback, mode: .default, options: [])
                }
                do {
                    try session.setActive(true, options: [])
                } catch let e as NSError {
                    // 忙（561015905）时忽略
                    if !(e.domain == NSOSStatusErrorDomain && e.code == 561015905) {
                        throw e
                    }
                }
                currentRole = .whiteNoise
            } catch {
                print("❌ [AudioOrchestrator] ensurePlaybackForWhiteNoise 失败: \(error)")
            }
        }
    }

    /// 语音消息开始播放前调用：
    /// 1) 若白噪音在播则先暂停并记录状态；
    /// 2) 切到 .playAndRecord + .defaultToSpeaker；
    /// 3) 激活会话。
    func beginVoiceMessage() {
        queue.sync {
            whiteNoiseWasPlayingBeforeVoiceMsg = WhiteNoisePlayer.shared.isPlaying
            if whiteNoiseWasPlayingBeforeVoiceMsg {
                WhiteNoisePlayer.shared.pause()
            }
            do {
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
                do {
                    try session.setActive(true, options: [])
                } catch let e as NSError {
                    if !(e.domain == NSOSStatusErrorDomain && e.code == 561015905) {
                        throw e
                    }
                }
                currentRole = .voiceMessage
            } catch {
                print("❌ [AudioOrchestrator] beginVoiceMessage 失败: \(error)")
            }
        }
    }

    /// 语音消息结束后调用：
    /// 回到 .playback 并按需恢复白噪音。
    func endVoiceMessage() {
        queue.sync {
            do {
                if session.category != .playback || session.mode != .default {
                    try session.setCategory(.playback, mode: .default, options: [])
                }
                do { try session.setActive(true, options: []) } catch let e as NSError {
                    if !(e.domain == NSOSStatusErrorDomain && e.code == 561015905) { throw e }
                }
                currentRole = .whiteNoise
            } catch {
                print("❌ [AudioOrchestrator] endVoiceMessage 切回 playback 失败: \(error)")
            }

            if whiteNoiseWasPlayingBeforeVoiceMsg { WhiteNoisePlayer.shared.resume() }
            whiteNoiseWasPlayingBeforeVoiceMsg = false
        }
    }

    // MARK: - Background Recording (Sleep tracking etc.)
    func beginBackgroundRecording() {
        queue.sync {
            whiteNoiseWasPlayingBeforeRecording = WhiteNoisePlayer.shared.isPlaying
            do {
                try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
                do { try session.setActive(true, options: []) } catch let e as NSError {
                    if !(e.domain == NSOSStatusErrorDomain && e.code == 561015905) { throw e }
                }
                currentRole = .recording
            } catch {
                print("❌ [AudioOrchestrator] beginBackgroundRecording 失败: \(error)")
            }
        }
    }

    func endBackgroundRecording() {
        queue.sync {
            do {
                // 录音结束后，若之前存在白噪音播放需求，回到 playback
                if session.category != .playback || session.mode != .default {
                    try session.setCategory(.playback, mode: .default, options: [])
                }
                do { try session.setActive(true, options: []) } catch let e as NSError {
                    if !(e.domain == NSOSStatusErrorDomain && e.code == 561015905) { throw e }
                }
                currentRole = .whiteNoise
            } catch {
                print("❌ [AudioOrchestrator] endBackgroundRecording 切回 playback 失败: \(error)")
            }

            if whiteNoiseWasPlayingBeforeRecording {
                WhiteNoisePlayer.shared.resume()
            }
            whiteNoiseWasPlayingBeforeRecording = false
        }
    }
}

