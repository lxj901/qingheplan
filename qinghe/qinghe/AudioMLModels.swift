import Foundation
import CoreML
import AVFoundation

/// 音频机器学习模型管理器
/// 负责加载和管理 Silero VAD 和 Snore/Talking 分类模型
class AudioMLModels: ObservableObject {
    // MARK: - 模型实例
    private var sileroVAD: MLModel?
    private var classifierModel: MLModel?

    // MARK: - 模型状态
    @Published var isVADModelLoaded = false
    @Published var isClassificationModelLoaded = false

    init() {
        loadModels()
        // 添加模型加载状态的调试信息
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🔍 模型加载状态检查:")
            print("  - VAD模型已加载: \(self.isVADModelLoaded)")
            print("  - 分类模型已加载: \(self.isClassificationModelLoaded)")
            if let vadModel = self.sileroVAD {
                print("  - VAD模型描述: \(vadModel.modelDescription)")
            }
            if let classModel = self.classifierModel {
                print("  - 分类模型描述: \(classModel.modelDescription)")
            }
        }
    }

    // MARK: - 模型加载（存在即启用；不存在回退启发式）
    private func loadModels() {
        loadSileroVAD()
        loadSnoreTalking()
    }

    private func loadSileroVAD() {
        // 优先查找编译后的 .mlmodelc，其次 .mlmodel
        let candidates: [(name: String, ext: String)] = [
            ("SileroVAD", "mlmodelc"),
            ("SileroVAD", "mlmodel")
        ]
        for c in candidates {
            if let url = Bundle.main.url(forResource: c.name, withExtension: c.ext) {
                do {
                    sileroVAD = try MLModel(contentsOf: url)
                    isVADModelLoaded = true
                    print("✅ Silero VAD loaded (\(c.ext))")
                    return
                } catch {
                    print("⚠️ Failed loading SileroVAD (\(c.ext)): \(error)")
                }
            }
        }
        // 提示可用 ONNX（留作参考）
        if Bundle.main.url(forResource: "SileroVAD", withExtension: "onnx") != nil {
            print("ℹ️ Found SileroVAD.onnx but Core ML conversion needed; fallback VAD enabled")
        } else {
            print("ℹ️ No SileroVAD model found; fallback VAD enabled")
        }
    }

    private func loadSnoreTalking() {
        let candidates: [(name: String, ext: String)] = [
            ("SnoreTalking", "mlmodelc"),
            ("SnoreTalking", "mlmodel")
        ]
        for c in candidates {
            if let url = Bundle.main.url(forResource: c.name, withExtension: c.ext) {
                do {
                    classifierModel = try MLModel(contentsOf: url)
                    isClassificationModelLoaded = true
                    print("✅ SnoreTalking classifier loaded (\(c.ext))")
                    return
                } catch {
                    print("⚠️ Failed loading SnoreTalking (\(c.ext)): \(error)")
                }
            }
        }
        print("ℹ️ No SnoreTalking model found; using heuristic classifier")
    }

    // MARK: - VAD 推理
    /// 使用 Silero VAD 检测语音活动（16kHz，512样本=32ms）
    func detectVoiceActivity(audioBuffer: [Float]) -> Float {
        guard let model = sileroVAD, audioBuffer.count == 512 else {
            if sileroVAD == nil {
                print("⚠️ Silero VAD 模型未加载，使用基于能量的 VAD")
            } else if audioBuffer.count != 512 {
                print("⚠️ 音频缓冲区大小不匹配 (期望: 512, 实际: \(audioBuffer.count))，使用基于能量的 VAD")
            }
            return calculateEnergyBasedVAD(audioBuffer: audioBuffer)
        }
        do {
            // SileroVAD 模型期望 512 维 DOUBLE 输入，输出名为 "output"
            let inputArray = try MLMultiArray(shape: [512], dataType: .double)
            for (i, v) in audioBuffer.enumerated() {
                inputArray[i] = NSNumber(value: Double(v))
            }

            let provider = try MLDictionaryFeatureProvider(dictionary: ["input": inputArray])
            let out = try model.prediction(from: provider)

            // SileroVAD 输出名为 "output"
            if let v = out.featureValue(for: "output")?.multiArrayValue {
                let result = v[0].floatValue
                print("🎤 VAD 检测结果: \(result)")
                return result
            }

            print("⚠️ VAD 模型输出格式不匹配，可用特征: \(out.featureNames)")
        } catch {
            print("❌ VAD inference failed: \(error)")
        }
        return calculateEnergyBasedVAD(audioBuffer: audioBuffer)
    }

    /// 启发式 VAD（基于能量阈值）
    private func calculateEnergyBasedVAD(audioBuffer: [Float]) -> Float {
        guard !audioBuffer.isEmpty else { return 0 }
        let rms = sqrt(audioBuffer.map { $0 * $0 }.reduce(0, +) / Float(audioBuffer.count))
        let threshold: Float = 0.01
        return rms > threshold ? min(0.9, rms * 10) : 0.1
    }

    // MARK: - 音频分类
    /// 使用 SnoreTalking.mlmodel 进行分类；若不可用则回退启发式
    func classifyAudioEvent(audioBuffer: [Float]) -> (label: String, confidence: Float) {
        print("🔍 开始音频分类，缓冲区大小: \(audioBuffer.count)")

        guard let model = classifierModel, !audioBuffer.isEmpty else {
            print("⚠️ 分类模型不可用或音频缓冲区为空，使用启发式分类")
            print("  - 模型可用: \(classifierModel != nil)")
            print("  - 缓冲区非空: \(!audioBuffer.isEmpty)")
            return classifyWithHeuristics(audioBuffer: audioBuffer)
        }

        print("✅ 使用 Core ML 模型进行分类")
        // SnoreTalking 模型期望 130 维特征
        let features = computeBandLogEnergies(audioBuffer, bands: 130)
        do {
            // SnoreTalking 模型输入名为 "input"，期望 130 维 DOUBLE 数组
            let arr = try MLMultiArray(shape: [130], dataType: .double)
            for i in 0..<130 {
                arr[i] = NSNumber(value: Double(features[i]))
            }
            let provider = try MLDictionaryFeatureProvider(dictionary: ["input": arr])
            let out = try model.prediction(from: provider)

            // SnoreTalking 模型输出为字典类型和类别标签
            print("🔍 模型输出特征名: \(out.featureNames)")

            // 优先从概率字典中找最大类别（兼容不同导出键名）
            let dictKeys = ["classLabelProbs", "output"]
            var probs: [String: Double]? = nil
            for k in dictKeys {
                if let d = out.featureValue(for: k)?.dictionaryValue as? [String: NSNumber] {
                    probs = d.mapValues { $0.doubleValue }
                    print("📊 概率字典(\(k)): \(probs!)")
                    break
                }
            }

            // 如果存在概率字典，选最大概率类别
            if let p = probs, let (topLabel, topProb) = p.max(by: { $0.value < $1.value }) {
                let mapped = mapClassLabel(topLabel)
                print("✅ 分类结果(来自概率): \(topLabel) -> \(mapped) (置信度: \(Float(topProb)))")

                // 添加置信度阈值和启发式验证
                let finalResult = validateClassificationWithHeuristics(
                    mlLabel: mapped,
                    mlConfidence: Float(topProb),
                    audioBuffer: audioBuffer
                )
                print("🔍 最终分类结果: \(finalResult.label) (置信度: \(finalResult.confidence))")
                return finalResult
            }

            // 其次使用 classLabel
            if let classLabel = out.featureValue(for: "classLabel")?.stringValue {
                print("📊 分类标签: \(classLabel)")
                let mappedLabel = mapClassLabel(classLabel)
                print("✅ 分类结果(无概率): \(mappedLabel) (默认置信度: 0.8)")
                return (mappedLabel, 0.8)
            }

            print("⚠️ 未找到预期的输出格式，可用特征: \(out.featureNames)")
        } catch {
            print("⚠️ Classification inference failed: \(error)")
        }
        return classifyWithHeuristics(audioBuffer: audioBuffer)
    }

    /// 使用启发式方法验证和修正 ML 模型的分类结果
    private func validateClassificationWithHeuristics(mlLabel: String, mlConfidence: Float, audioBuffer: [Float]) -> (label: String, confidence: Float) {
        // 计算音频特征用于验证
        let rms = sqrt(audioBuffer.map { $0 * $0 }.reduce(0, +) / Float(audioBuffer.count))
        let zcr = calculateZeroCrossingRate(audioBuffer: audioBuffer)

        print("🔍 验证分类 - ML结果: \(mlLabel)(\(mlConfidence)), 音频特征: RMS=\(rms), ZCR=\(zcr)")

        // 置信度阈值：低于 0.75 的分类需要启发式验证
        let confidenceThreshold: Float = 0.75

        if mlConfidence >= confidenceThreshold {
            // 高置信度，但仍需要基本合理性检查
            if mlLabel == "talking" && rms > 0.003 && zcr < 0.15 {
                // 低音量/低过零率更偏向打鼾
                print("⚠️ ML分类为talking但音频特征像snoring（低音量场景阈值），修正为snoring")
                return ("snoring", max(0.75, mlConfidence))
            }
            if mlLabel == "snoring" && ((rms > 0.005 && zcr > 0.25) || (rms > 0.01 && zcr > 0.2)) {
                // 过零率较高更偏向说话
                print("⚠️ ML分类为snoring但音频特征像talking（动态阈值），修正为talking")
                return ("talking", max(0.75, mlConfidence))
            }
            // 特征与分类一致，保持原结果
            return (mlLabel, mlConfidence)
        } else {
            // 低置信度，使用启发式重新分类
            print("⚠️ ML置信度过低(\(mlConfidence) < \(confidenceThreshold))，使用启发式分类")
            return classifyWithHeuristics(audioBuffer: audioBuffer)
        }
    }

    /// 将模型输出的类别标签映射为我们期望的格式
    private func mapClassLabel(_ label: String) -> String {
        let l = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // 统一的关键词归类（中英混合）
        let snoreKeys = ["snore", "snoring", "呼噜", "打鼾", "鼾", "鼾声"]
        let talkKeys  = ["talk", "talking", "speech", "说话", "语音", "梦话"]
        let breathKeys = ["breath", "breathing", "呼吸", "呼吸声"]
        let silenceKeys = ["silence", "quiet", "静音", "安静", "静默", "无声", "背景噪声", "噪声", "环境"]

        func containsAny(_ keys: [String]) -> Bool { keys.contains { l.contains($0) } }
        if containsAny(snoreKeys) { return "snoring" }
        if containsAny(talkKeys)  { return "talking" }
        if containsAny(breathKeys){ return "breathing" }
        if containsAny(silenceKeys){ return "silence" }

        // 常见其他标签直接映射为静音，避免偏向“talking”
        if ["other", "others", "unknown", "noise", "background"].contains(l) { return "silence" }

        // 如果完全未知，使用启发式关键词再判；仍未知则保守为 "silence"
        print("⚠️ 未知的类别标签: \(label)，映射为 silence")
        return "silence"
    }

    /// 启发式音频分类（兜底）
    private func classifyWithHeuristics(audioBuffer: [Float]) -> (label: String, confidence: Float) {
        print("🔍 使用启发式分类")
        guard !audioBuffer.isEmpty else {
            print("📊 启发式分类结果: 静音 (缓冲区为空)")
            return ("silence", 0.8)
        }

        let rms = sqrt(audioBuffer.map { $0 * $0 }.reduce(0, +) / Float(audioBuffer.count))
        let zcr = calculateZeroCrossingRate(audioBuffer: audioBuffer)

        print("📊 音频特征 - RMS: \(rms), ZCR: \(zcr)")

        if rms > 0.0035 && zcr < 0.15 {
            print("✅ 启发式分类结果: 打鼾 (低音量阈值) (RMS: \(rms), ZCR: \(zcr))")
            return ("snoring", 0.7)
        }
        if (zcr > 0.25 && rms > 0.003) || (zcr > 0.20 && rms > 0.008) {
            print("✅ 启发式分类结果: 说话 (RMS: \(rms), ZCR: \(zcr))")
            return ("talking", 0.6)
        }
        if rms > 0.002 {
            print("✅ 启发式分类结果: 呼吸 (RMS: \(rms), ZCR: \(zcr))")
            return ("breathing", 0.5)
        }

        print("✅ 启发式分类结果: 静音 (RMS: \(rms), ZCR: \(zcr))")
        return ("silence", 0.8)
    }

    /// 计算过零率（Zero Crossing Rate）
    private func calculateZeroCrossingRate(audioBuffer: [Float]) -> Float {
        guard audioBuffer.count > 1 else { return 0 }
        var crossings = 0
        for i in 1..<audioBuffer.count {
            if (audioBuffer[i] >= 0) != (audioBuffer[i - 1] >= 0) { crossings += 1 }
        }
        return Float(crossings) / Float(audioBuffer.count - 1)
    }

    // 简单频带对数能量特征（无需外部依赖）
    private func computeBandLogEnergies(_ x: [Float], bands: Int) -> [Float] {
        let n = x.count
        guard n > 0, bands > 0 else { return Array(repeating: 0, count: max(bands, 1)) }
        // 粗略分帧求能量（无需FFT）：将时间序列分成 bands 份，取每份RMS作为特征
        let chunk = max(1, n / bands)
        var feats: [Float] = []
        feats.reserveCapacity(bands)
        var i = 0
        while feats.count < bands {
            let end = min(n, i + chunk)
            if i < end {
                let seg = x[i..<end]
                let rms = sqrt(seg.reduce(0) { $0 + $1 * $1 } / Float(end - i))
                feats.append(log(1e-6 + Double(rms)) .isFinite ? Float(log(1e-6 + Double(rms))) : 0)
            } else {
                feats.append(0)
            }
            i += chunk
        }
        return feats
    }

    // MARK: - 音频预处理
    /// 将 AVAudioPCMBuffer 转换为 Float 数组（单通道）
    func convertBufferToFloatArray(_ buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData?.pointee else { return [] }
        let frameCount = Int(buffer.frameLength)
        return Array(UnsafeBufferPointer(start: channelData, count: frameCount))
    }
}
