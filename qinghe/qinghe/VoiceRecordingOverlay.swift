import SwiftUI

/// 语音录制弹窗组件
struct VoiceRecordingOverlay: View {
    @Binding var isRecording: Bool
    @Binding var recordingDuration: TimeInterval
    @State private var animationPhase: Double = 0

    let onCancel: () -> Void
    let onSend: () -> Void

    // 从外部传入拖拽状态
    var isDraggedUp: Bool = false
    
    var body: some View {
        if isRecording {
            ZStack {
                // 半透明背景
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                // 录制弹窗
                recordingModal
                    .transition(.scale.combined(with: .opacity))
            }
            .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
    }
    
    private var recordingModal: some View {
        VStack(spacing: 20) {
            // 录制状态指示器
            recordingIndicator
            
            // 操作提示文本
            instructionText
            
            // 录制时长
            durationText
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
        )
        .foregroundColor(.white)
        .scaleEffect(isDraggedUp ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isDraggedUp)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private var recordingIndicator: some View {
        ZStack {
            // 外圈动画
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 80, height: 80)
                .scaleEffect(1 + animationPhase * 0.3)
                .opacity(1 - animationPhase * 0.5)
            
            // 内圈
            Circle()
                .fill(Color.red)
                .frame(width: 60, height: 60)
            
            // 图标
            if isDraggedUp {
                // 取消图标
                Image(systemName: "arrow.down")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            } else {
                // 音频波形图标
                audioWaveform
            }
        }
    }
    
    private var audioWaveform: some View {
        HStack(spacing: 2) {
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white)
                    .frame(width: 2, height: CGFloat.random(in: 8...20))
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: animationPhase
                    )
            }
        }
    }
    
    private var instructionText: some View {
        Text(isDraggedUp ? "松开手指，取消发送" : "手指上划，取消发送")
            .font(.system(size: 16, weight: .medium))
            .multilineTextAlignment(.center)
            .animation(.easeInOut(duration: 0.2), value: isDraggedUp)
    }
    
    private var durationText: some View {
        Text(formatDuration(recordingDuration))
            .font(.system(size: 14, weight: .regular))
            .opacity(0.8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
    }
    
    private func stopAnimation() {
        animationPhase = 0
    }
    

}

/// 语音录制按钮组件
struct VoiceRecordingButton: View {
    @Binding var isRecording: Bool
    @Binding var isDraggedUp: Bool
    @State private var dragOffset: CGFloat = 0

    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onCancelRecording: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .fill(isRecording ? Color.red : ModernDesignSystem.Colors.backgroundSecondary)
                .frame(width: 40, height: 40)

            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle")
                .font(.system(size: isRecording ? 24 : 32))
                .foregroundColor(isRecording ? .white : ModernDesignSystem.Colors.textSecondary)
        }
        .scaleEffect(isRecording ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isRecording)
        .offset(y: dragOffset)
        .onTapGesture {
            if !isRecording {
                // 点击开始录制
                onStartRecording()
            } else {
                // 点击停止录制并发送
                onStopRecording()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    if isRecording {
                        let dragDistance = -value.translation.height // 向上为正
                        dragOffset = value.translation.height

                        // 当向上拖拽超过50点时，进入取消状态
                        if dragDistance > 50 {
                            if !isDraggedUp {
                                isDraggedUp = true
                                // 触觉反馈
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                        } else {
                            if isDraggedUp {
                                isDraggedUp = false
                                // 触觉反馈
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        }
                    }
                }
                .onEnded { _ in
                    if isRecording {
                        dragOffset = 0

                        if isDraggedUp {
                            // 取消录制
                            onCancelRecording()
                        } else {
                            // 发送录制
                            onStopRecording()
                        }

                        isDraggedUp = false
                    }
                }
        )
    }
}

// MARK: - 预览
struct VoiceRecordingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()

            VoiceRecordingOverlay(
                isRecording: .constant(true),
                recordingDuration: .constant(5.5),
                onCancel: {},
                onSend: {}
            )

            Spacer()
        }
        .background(Color.gray.opacity(0.1))
    }
}
