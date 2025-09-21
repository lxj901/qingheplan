import SwiftUI
import AVFoundation


struct EventSegmentsView: View {
    let sessionId: String
    @State var segments: [SleepLocalAudioSegment]
    @State private var player: AVAudioPlayer?
    @State private var nowPlayingId: UUID?
    @State private var isPlaying: Bool = false
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable, Identifiable {
        case all = "全部"
        case snoring = "snoring"
        case talking = "talking"
        var id: String { rawValue }
    }

    var filteredSegments: [SleepLocalAudioSegment] {
        switch filter {
        case .all: return segments
        case .snoring: return segments.filter { $0.type.lowercased() == "snoring" }
        case .talking: return segments.filter { $0.type.lowercased() == "talking" }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // 筛选器
            Picker("筛选", selection: $filter) {
                ForEach(Filter.allCases) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(filteredSegments, id: \.id) { seg in
                        EventSegmentRow(seg: seg, isPlaying: nowPlayingId == seg.id && isPlaying) {
                            togglePlay(seg)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("事件列表")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(red: 0.08, green: 0.12, blue: 0.25).ignoresSafeArea())
    }

    private func togglePlay(_ seg: SleepLocalAudioSegment) {
        // 如果点击的是当前正在播放的片段，则暂停/恢复
        if nowPlayingId == seg.id {
            if isPlaying {
                player?.pause()
                isPlaying = false
            } else {
                player?.play()
                isPlaying = true
            }
            return
        }
        
        // 如果点击的是不同的片段，则停止当前播放并播放新片段
        player?.stop()
        isPlaying = false
        
        guard let path = seg.actualFilePath, FileManager.default.fileExists(atPath: path) else {
            print("⚠️ 找不到事件音频文件: \(seg.fileName ?? "-")")
            return
        }
        
        do {
            nowPlayingId = seg.id
            player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            player?.delegate = AudioPlayerDelegate { [self] in
                // 播放结束时重置状态
                DispatchQueue.main.async {
                    self.isPlaying = false
                    self.nowPlayingId = nil
                }
            }
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
        } catch {
            print("❌ 播放失败: \(error)")
        }
    }
}

private struct EventSegmentRow: View {
    let seg: SleepLocalAudioSegment
    let isPlaying: Bool
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(typeColor(for: seg.type).opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: typeIcon(for: seg.type))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(typeColor(for: seg.type))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(displayName(seg.type))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                // 进度条（基础版本）：用置信度可视化
                ProgressView(value: min(max(seg.confidence, 0), 1))
                    .progressViewStyle(LinearProgressViewStyle(tint: typeColor(for: seg.type)))
                    .frame(height: 4)
                HStack(spacing: 12) {
                    Text(String(format: "%.1fs", seg.duration))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                    if let date = seg.eventDate {
                        Text(dateFormatter.string(from: date))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            Spacer()
            Button(action: onPlay) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.cyan)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(typeColor(for: seg.type).opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MM-dd HH:mm"
        return df
    }

    private func displayName(_ type: String) -> String {
        // 将英文事件类型转换为中文显示
        switch type.lowercased() {
        case "talking": return "说话"
        case "snoring": return "打鼾"
        default: return type
        }
    }

    private func typeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "snoring": return .orange
        case "talking": return .purple
        default: return .gray
        }
    }

    private func typeIcon(for type: String) -> String {
        switch type.lowercased() {
        case "snoring": return "zzz"
        case "talking": return "zzz"
        default: return "zzz"
        }
    }
}

// MARK: - Audio Player Delegate
private class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinished: () -> Void
    
    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinished()
    }
}

