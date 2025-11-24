import SwiftUI
import AVFoundation
import AVKit

/// 短视频播放器视图
/// 支持手势控制、自动播放、循环播放等功能
struct ShortVideoPlayerView: View {
    // MARK: - Properties
    
    let videoURL: String
    var autoPlay: Bool = true
    var loop: Bool = true
    var muted: Bool = false
    var showControls: Bool = false
    var onTap: (() -> Void)?
    
    @StateObject private var playerManager = ShortVideoPlayerManager.shared
    @State private var showPlayButton = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 视频播放器
            if let player = playerManager.getCurrentPlayer() {
                GeometryReader { geometry in
                    VideoPlayerLayer(
                        player: player,
                        videoSize: playerManager.videoSize,
                        containerSize: geometry.size
                    )
                    .ignoresSafeArea()
                }
            } else {
                // 加载中
                Color.black
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
            }
            
            // 缓冲指示器
            if playerManager.isBuffering {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
            
            // 播放/暂停按钮（点击后短暂显示）
            if showPlayButton {
                Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.8))
                    .transition(.scale.combined(with: .opacity))
            }
            
            // 控制层（如果需要）
            if showControls {
                controlsOverlay
            }
        }
        .contentShape(Rectangle())
        .gesture(doubleTapGesture)
        .gesture(dragGesture)
        .onAppear {
            setupPlayer()
        }
    }
    
    // MARK: - Subviews
    
    /// 控制层
    private var controlsOverlay: some View {
        VStack {
            Spacer()
            
            // 进度条
            VStack(spacing: 8) {
                // 时间显示
                HStack {
                    Text(formatTime(playerManager.currentTime))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formatTime(playerManager.duration))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 3)
                        
                        // 进度
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: geometry.size.width * playerManager.progress, height: 3)
                    }
                    .cornerRadius(1.5)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let progress = value.location.x / geometry.size.width
                                let clampedProgress = max(0, min(1, progress))
                                let targetTime = clampedProgress * playerManager.duration
                                playerManager.seek(to: targetTime)
                            }
                    )
                }
                .frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
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
    
    /// 拖动手势（调节进度）
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    playerManager.pause()
                }
                dragOffset = value.translation.width
            }
            .onEnded { value in
                isDragging = false
                
                // 根据拖动距离调整进度
                let sensitivity: CGFloat = 0.1 // 灵敏度
                let progressChange = Double(value.translation.width) * sensitivity / 100.0
                let newProgress = max(0, min(1, playerManager.progress + progressChange))
                let targetTime = newProgress * playerManager.duration
                
                playerManager.seek(to: targetTime)
                playerManager.resume()
                
                dragOffset = 0
            }
    }
    
    // MARK: - Private Methods
    
    /// 设置播放器
    private func setupPlayer() {
        playerManager.play(
            url: videoURL,
            autoPlay: autoPlay,
            loop: loop,
            muted: muted
        )
    }
    
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

// MARK: - Video Player Layer

/// 视频播放器图层（UIKit 包装）
struct VideoPlayerLayer: UIViewRepresentable {
    let player: AVPlayer
    let videoSize: CGSize
    let containerSize: CGSize

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.player = player
        view.updateVideoGravity(videoSize: videoSize, containerSize: containerSize)
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.player = player
        uiView.updateVideoGravity(videoSize: videoSize, containerSize: containerSize)
    }

    /// 自定义播放器视图
    class PlayerView: UIView {
        var player: AVPlayer? {
            didSet {
                playerLayer.player = player
            }
        }

        override class var layerClass: AnyClass {
            return AVPlayerLayer.self
        }

        private var playerLayer: AVPlayerLayer {
            return layer as! AVPlayerLayer
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupLayer()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupLayer()
        }

        private func setupLayer() {
            // 默认使用 resizeAspect 保持原始比例，不放大视频
            playerLayer.videoGravity = .resizeAspect
            backgroundColor = .black
        }

        /// 根据视频尺寸和容器尺寸更新显示模式
        func updateVideoGravity(videoSize: CGSize, containerSize: CGSize) {
            guard videoSize.width > 0 && videoSize.height > 0,
                  containerSize.width > 0 && containerSize.height > 0 else {
                // 默认使用 resizeAspect 保持原始比例
                playerLayer.videoGravity = .resizeAspect
                return
            }

            let videoAspectRatio = videoSize.width / videoSize.height
            let containerAspectRatio = containerSize.width / containerSize.height

            // 所有视频都使用 resizeAspect 保持原始比例，不放大不裁剪
            playerLayer.videoGravity = .resizeAspect

            // 判断视频方向（仅用于日志）
            if videoAspectRatio < 1.0 {
                print("📱 VideoPlayerLayer: 竖屏视频 (\(videoSize.width)x\(videoSize.height)) - 使用 resizeAspect 保持原始比例")
            } else if videoAspectRatio > 1.5 {
                print("🖥️ VideoPlayerLayer: 横屏视频 (\(videoSize.width)x\(videoSize.height)) - 使用 resizeAspect 保持原始比例")
            } else {
                print("⬜ VideoPlayerLayer: 方形视频 (\(videoSize.width)x\(videoSize.height)) - 使用 resizeAspect 保持原始比例")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ShortVideoPlayerView(
        videoURL: "https://example.com/video.mp4",
        autoPlay: true,
        loop: true,
        muted: false,
        showControls: true
    )
}

