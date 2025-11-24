//
//  FloatingAudioControl.swift
//  qinghe
//
//  悬浮球音频控制组件
//

import SwiftUI

struct FloatingAudioControl: View {
    @ObservedObject var audioPlayer = GlobalAudioPlayer.shared
    @State private var position: CGPoint
    @State private var isExpanded = false
    @State private var isDragging = false
    @GestureState private var dragOffset = CGSize.zero

    init() {
        // 从 UserDefaults 加载位置，默认在右上角
        let savedX = UserDefaults.standard.double(forKey: "floatingControlX")
        let savedY = UserDefaults.standard.double(forKey: "floatingControlY")

        if savedX > 0 && savedY > 0 {
            _position = State(initialValue: CGPoint(x: savedX, y: savedY))
        } else {
            _position = State(initialValue: CGPoint(
                x: UIScreen.main.bounds.width - 80,
                y: 100
            ))
        }
    }

    var body: some View {
        // 只在有播放内容时显示
        if !audioPlayer.playlist.isEmpty {
            ZStack {
                if isExpanded {
                    expandedControl
                } else {
                    compactControl
                }
            }
            .position(position)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                        isDragging = true
                    }
                    .onEnded { value in
                        // 更新位置
                        position.x += value.translation.width
                        position.y += value.translation.height

                        // 边界限制
                        let bounds = UIScreen.main.bounds
                        position.x = max(40, min(position.x, bounds.width - 40))
                        position.y = max(60, min(position.y, bounds.height - 60))

                        // 保存位置
                        savePosition()

                        isDragging = false
                    }
            )
            .offset(dragOffset)
            .animation(.spring(), value: isExpanded)
            .animation(.spring(), value: dragOffset)
        }
    }

    // MARK: - 收起的悬浮球
    private var compactControl: some View {
        Button(action: {
            if !isDragging {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded = true
                }
            }
        }) {
            ZStack {
                // 背景
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.15, blue: 0.1),
                                Color(red: 0.3, green: 0.2, blue: 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

                // 播放图标
                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.8))
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - 展开的控制面板
    private var expandedControl: some View {
        VStack(spacing: 16) {
            // 标题和收起按钮
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(audioPlayer.playlist[safe: audioPlayer.currentIndex]?.original ?? "")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(audioPlayer.chapterTitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            // 播放控制按钮
            HStack(spacing: 24) {
                // 上一曲
                Button(action: {
                    audioPlayer.playPrevious()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                // 播放/暂停
                Button(action: {
                    audioPlayer.togglePlayPause()
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                }

                // 下一曲
                Button(action: {
                    audioPlayer.playNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            // 进度条
            VStack(spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 4)

                        // 进度
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(
                                width: geometry.size.width * CGFloat(audioPlayer.currentTime / max(audioPlayer.duration, 1)),
                                height: 4
                            )
                    }
                }
                .frame(height: 4)

                // 时间显示
                HStack {
                    Text(formatTime(audioPlayer.currentTime))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text(formatTime(audioPlayer.duration))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // 倍速和定时
            HStack(spacing: 16) {
                // 倍速选择
                Menu {
                    ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
                        Button("\(String(format: "%.2f", rate))x") {
                            audioPlayer.setPlaybackRate(Float(rate))
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 12))
                        Text("\(String(format: "%.2f", audioPlayer.playbackRate))x")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                }

                // 定时关闭
                Menu {
                    Button("15分钟") { audioPlayer.setSleepTimer(minutes: 15) }
                    Button("30分钟") { audioPlayer.setSleepTimer(minutes: 30) }
                    Button("45分钟") { audioPlayer.setSleepTimer(minutes: 45) }
                    Button("60分钟") { audioPlayer.setSleepTimer(minutes: 60) }

                    if audioPlayer.sleepTimer != nil {
                        Divider()
                        Button("取消定时", role: .destructive) {
                            audioPlayer.cancelSleepTimer()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: audioPlayer.sleepTimer != nil ? "moon.fill" : "moon")
                            .font(.system(size: 12))
                        if let timer = audioPlayer.sleepTimer {
                            let remaining = Int(timer.timeIntervalSinceNow / 60)
                            Text("\(remaining)分")
                                .font(.system(size: 12, weight: .medium))
                        } else {
                            Text("定时")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.15, blue: 0.1),
                            Color(red: 0.3, green: 0.2, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
        )
        .frame(width: 260)
    }

    // MARK: - 辅助方法
    private func savePosition() {
        UserDefaults.standard.set(position.x, forKey: "floatingControlX")
        UserDefaults.standard.set(position.y, forKey: "floatingControlY")
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - 预览
struct FloatingAudioControl_Previews: PreviewProvider {
    static var previews: some View {
        FloatingAudioControl()
    }
}
