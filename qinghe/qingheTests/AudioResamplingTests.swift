import XCTest
import AVFoundation
@testable import qinghe

final class AudioResamplingTests: XCTestCase {
    // 生成 440Hz 正弦波，采样率 44100，时长 0.1s
    private func makeSineBuffer(sampleRate: Double, duration: Double, freq: Double = 440.0, channels: AVAudioChannelCount = 1) -> AVAudioPCMBuffer {
        let frames = Int(sampleRate * duration)
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: channels, interleaved: false)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))!
        buffer.frameLength = AVAudioFrameCount(frames)
        let ptr = buffer.floatChannelData!.pointee
        for i in 0..<frames {
            let t = Double(i) / sampleRate
            ptr[i] = Float(sin(2.0 * .pi * freq * t))
        }
        return buffer
    }

    func testAVAudioConverterResampleTo16k() throws {
        let recorder = SleepAudioRecorder()
        let src = makeSineBuffer(sampleRate: 44100, duration: 0.1)
        let resampled = recorder.bufferTo16kFloats(src)
        // 期望长度接近 0.1s * 16000 = 1600 帧（容差 10%）
        XCTAssertGreaterThan(resampled.count, 1400)
        XCTAssertLessThan(resampled.count, 1800)
        // 能量不为零
        let energy = resampled.reduce(0.0) { $0 + Double($1 * $1) }
        XCTAssertGreaterThan(energy, 1e-3)
    }
}

