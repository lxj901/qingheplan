import SwiftUI
import AVFoundation

/// 短视频手势控制
/// 支持：双击暂停/播放、左右滑动调节进度、上下滑动调节音量/亮度
struct ShortVideoGestureControl: ViewModifier {
    @ObservedObject var playerManager: ShortVideoPlayerManager
    
    @State private var showPlayButton = false
    @State private var showVolumeIndicator = false
    @State private var showBrightnessIndicator = false
    @State private var showProgressIndicator = false
    
    @State private var volumeValue: Float = 0.5
    @State private var brightnessValue: CGFloat = 0.5
    @State private var progressValue: Double = 0.0
    
    @State private var dragStartLocation: CGPoint = .zero
    @State private var isDraggingLeft = false
    @State private var isDraggingRight = false
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .gesture(doubleTapGesture)
                .gesture(dragGesture)
            
            // 播放/暂停指示器
            if showPlayButton {
                playPauseIndicator
            }
            
            // 音量指示器
            if showVolumeIndicator {
                volumeIndicator
            }
            
            // 亮度指示器
            if showBrightnessIndicator {
                brightnessIndicator
            }
            
            // 进度指示器
            if showProgressIndicator {
                progressIndicator
            }
        }
    }
    
    // MARK: - Indicators
    
    /// 播放/暂停指示器
    private var playPauseIndicator: some View {
        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: 60))
            .foregroundColor(.white.opacity(0.8))
            .transition(.scale.combined(with: .opacity))
    }
    
    /// 音量指示器
    private var volumeIndicator: some View {
        VStack(spacing: 8) {
            Image(systemName: volumeValue > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            ProgressView(value: Double(volumeValue), total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .frame(width: 100)
            
            Text("\(Int(volumeValue * 100))%")
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
        .padding(20)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    
    /// 亮度指示器
    private var brightnessIndicator: some View {
        VStack(spacing: 8) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            ProgressView(value: brightnessValue, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .frame(width: 100)
            
            Text("\(Int(brightnessValue * 100))%")
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
        .padding(20)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    
    /// 进度指示器
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            Image(systemName: isDraggingRight ? "forward.fill" : "backward.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            Text(formatTime(progressValue))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text("/ \(formatTime(playerManager.duration))")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(20)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    
    // MARK: - Gestures
    
    /// 双击手势（播放/暂停）
    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                playerManager.togglePlayPause()
                showPlayButtonAnimation()
            }
    }
    
    /// 拖动手势
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let translation = value.translation
                let startLocation = value.startLocation
                
                // 判断拖动方向
                if abs(translation.width) > abs(translation.height) {
                    // 左右滑动 - 调节进度
                    handleProgressDrag(translation: translation, startLocation: startLocation)
                } else {
                    // 上下滑动 - 调节音量或亮度
                    handleVolumeOrBrightnessDrag(translation: translation, startLocation: startLocation)
                }
            }
            .onEnded { value in
                let translation = value.translation
                
                if abs(translation.width) > abs(translation.height) {
                    // 完成进度调节
                    finishProgressDrag()
                } else {
                    // 完成音量/亮度调节
                    finishVolumeOrBrightnessDrag()
                }
            }
    }
    
    // MARK: - Drag Handlers
    
    /// 处理进度拖动
    private func handleProgressDrag(translation: CGSize, startLocation: CGPoint) {
        if !showProgressIndicator {
            showProgressIndicator = true
            dragStartLocation = startLocation
            playerManager.pause()
        }
        
        // 计算进度变化（每100像素 = 10秒）
        let sensitivity: CGFloat = 10.0 / 100.0 // 10秒/100像素
        let timeChange = Double(translation.width) * Double(sensitivity)
        let newTime = max(0, min(playerManager.duration, playerManager.currentTime + timeChange))
        
        progressValue = newTime
        isDraggingRight = translation.width > 0
        isDraggingLeft = translation.width < 0
    }
    
    /// 完成进度拖动
    private func finishProgressDrag() {
        playerManager.seek(to: progressValue)
        playerManager.resume()
        
        withAnimation {
            showProgressIndicator = false
        }
        
        isDraggingLeft = false
        isDraggingRight = false
    }
    
    /// 处理音量/亮度拖动
    private func handleVolumeOrBrightnessDrag(translation: CGSize, startLocation: CGPoint) {
        let screenWidth = UIScreen.main.bounds.width
        
        if startLocation.x < screenWidth / 2 {
            // 左侧 - 调节亮度
            if !showBrightnessIndicator {
                showBrightnessIndicator = true
                brightnessValue = UIScreen.main.brightness
            }
            
            let sensitivity: CGFloat = 1.0 / 200.0 // 200像素 = 100%
            let brightnessChange = -translation.height * sensitivity
            let newBrightness = max(0, min(1, brightnessValue + brightnessChange))
            
            UIScreen.main.brightness = newBrightness
            brightnessValue = newBrightness
        } else {
            // 右侧 - 调节音量
            if !showVolumeIndicator {
                showVolumeIndicator = true
                volumeValue = AVAudioSession.sharedInstance().outputVolume
            }
            
            let sensitivity: Float = 1.0 / 200.0 // 200像素 = 100%
            let volumeChange = -Float(translation.height) * sensitivity
            let newVolume = max(0, min(1, volumeValue + volumeChange))
            
            // 注意：iOS 不允许直接设置系统音量，这里只是示意
            // 实际应用中需要使用 MPVolumeView 来调节音量
            volumeValue = newVolume
        }
    }
    
    /// 完成音量/亮度拖动
    private func finishVolumeOrBrightnessDrag() {
        withAnimation {
            showVolumeIndicator = false
            showBrightnessIndicator = false
        }
    }
    
    // MARK: - Helper Methods
    
    /// 显示播放按钮动画
    private func showPlayButtonAnimation() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showPlayButton = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showPlayButton = false
            }
        }
    }
    
    /// 格式化时间
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else {
            return "0:00"
        }
        
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - View Extension

extension View {
    /// 添加短视频手势控制
    func shortVideoGestureControl(playerManager: ShortVideoPlayerManager) -> some View {
        self.modifier(ShortVideoGestureControl(playerManager: playerManager))
    }
}

