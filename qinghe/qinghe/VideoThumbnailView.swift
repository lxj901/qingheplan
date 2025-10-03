import SwiftUI
import AVFoundation
import AVKit
import UIKit

// MARK: - 视频自动播放视图（列表中使用）
/// 在帖子列表中自动播放的视频组件，点击后进入横屏全屏播放
struct VideoThumbnailView: View {
    let videoURL: String
    let duration: Double?
    var isFullWidth: Bool = false // 是否全宽显示（无圆角无边距）
    var showControls: Bool = false // 是否显示播放控制（用于详情页）
    var loop: Bool = false         // 是否循环播放（详情页可开启）
    let onTap: () -> Void

    @StateObject private var playerManager = VideoPlayerManager()
    @State private var isLoading = true
    @State private var showingFullScreen = false
    @State private var fullscreenReturnTime: CMTime? = nil

    var body: some View {
        ZStack {
            // 背景色
            Color.black

            // 自动播放的视频
            if let player = playerManager.player {
                if showControls {
                    // 详情页：显示完整控制的播放器
                    VideoPlayer(player: player)
                        // 双击切换播放/暂停，保留系统单击显示控制条
                        .simultaneousGesture(
                            TapGesture(count: 2).onEnded {
                                playerManager.togglePlayPause()
                            }
                        )
                        .onAppear {
                            isLoading = false
                        }
                        .overlay(alignment: .topTrailing) {
                            // 全屏按钮（仅详情页显示）
                            Button(action: {
                                // 打开全屏前暂停内嵌播放器，避免双声道
                                playerManager.pause()
                                showingFullScreen = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("全屏")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Capsule())
                                .padding(8)
                            }
                            .buttonStyle(.plain)
                        }
                } else {
                    // 列表：无控制的自动播放
                    VideoPlayer(player: player) {
                        // 移除默认的播放控件
                    }
                    .disabled(true) // 禁用默认交互
                    .onAppear {
                        isLoading = false
                    }
                }
            } else if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                // 加载失败显示占位图
                Image(systemName: "video.slash")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.5))
            }

            // 列表模式：可点击区域（跳转到详情页）
            if !showControls {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTap()
                    }

                // 静音指示器
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "speaker.slash.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                            .padding(8)
                    }
                    Spacer()
                }

                // 时长标签
                if let duration = duration {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(formatDuration(duration))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(4)
                                .padding(8)
                        }
                    }
                }
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .cornerRadius(isFullWidth ? 0 : 12) // 全宽时无圆角
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                        if !showControls { // 只在列表模式检测可见性
                            checkVisibility(frame: newFrame)
                        }
                    }
                    .onAppear {
                        if !showControls {
                            checkVisibility(frame: geometry.frame(in: .global))
                        }
                    }
            }
        )
        .onAppear {
            // 列表模式默认静音且循环；详情页依据 loop 参数决定是否循环
            // 详情页模式自动播放
            playerManager.setupPlayer(urlString: videoURL, isMuted: !showControls, loop: loop || !showControls, autoPlay: showControls)
            print("🎬 视频组件出现: \(videoURL), showControls: \(showControls)")
        }
        .onDisappear {
            playerManager.cleanup()
            print("🎬 视频组件消失: \(videoURL)")
        }
        // 系统原生全屏播放器
        .fullScreenCover(isPresented: $showingFullScreen) {
            NativeFullScreenVideoPlayer(videoURL: videoURL, startTime: playerManager.getCurrentTime(), onDismiss: { returnTime in
                fullscreenReturnTime = returnTime
            })
            .onDisappear {
                // 关闭全屏后恢复内嵌播放器并定位到返回的播放位置
                if showControls {
                    if let returnTime = fullscreenReturnTime {
                        playerManager.seek(to: returnTime)
                    }
                    playerManager.play()
                }
            }
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func checkVisibility(frame: CGRect) {
        let screenHeight = UIScreen.main.bounds.height

        // 计算可见高度
        let visibleTop = max(frame.minY, 0)
        let visibleBottom = min(frame.maxY, screenHeight)
        let visibleHeight = max(0, visibleBottom - visibleTop)
        let totalHeight = frame.height

        guard totalHeight > 0 else { return }

        let visibilityRatio = visibleHeight / totalHeight

        print("🎬 视频可见性: \(String(format: "%.1f%%", visibilityRatio * 100)) - Frame: \(frame)")

        // 视频至少有50%在屏幕内才播放
        if visibilityRatio >= 0.5 {
            print("✅ 开始播放")
            playerManager.play()
        } else {
            print("⏸️ 暂停播放")
            playerManager.pause()
        }
    }
}

// MARK: - 可见性 Preference Key
struct VisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

// MARK: - Window 工具
@inline(__always)
private func getKeyWindow() -> UIWindow? {
    for scene in UIApplication.shared.connectedScenes {
        if let windowScene = scene as? UIWindowScene {
            if let key = windowScene.windows.first(where: { $0.isKeyWindow }) {
                return key
            }
        }
    }
    return UIApplication.shared.windows.first { $0.isKeyWindow }
}

// MARK: - 视频播放管理器
class VideoPlayerManager: ObservableObject {
    @Published var player: AVPlayer?
    private var looper: AVPlayerLooper?

    func setupPlayer(urlString: String, isMuted: Bool = true, loop: Bool = true, autoPlay: Bool = false) {
        guard let url = URL(string: urlString) else { return }

        // 在后台预加载关键属性，避免主线程同步查询阻塞 PreferredTransform 等
        Task.detached(priority: .userInitiated) { [weak self] in
            let asset = AVURLAsset(url: url)
            do {
                if #available(iOS 15.0, *) {
                    _ = try await asset.load(.isPlayable)
                    let tracks = try await asset.load(.tracks)
                    if let videoTrack = tracks.first(where: { $0.mediaType == .video }) {
                        _ = try? await videoTrack.load(.preferredTransform)
                        _ = try? await videoTrack.load(.naturalSize)
                    }
                } else {
                    let keys = ["playable", "tracks", "duration"]
                    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                        asset.loadValuesAsynchronously(forKeys: keys) {
                            cont.resume()
                        }
                    }
                }

                await MainActor.run { [weak self] in
                    let item = AVPlayerItem(asset: asset)
                    let queuePlayer = AVQueuePlayer(playerItem: item)
                    queuePlayer.isMuted = isMuted
                    if loop {
                        self?.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
                    }
                    self?.player = queuePlayer
                    
                    // 如果需要自动播放，在播放器创建后立即播放
                    if autoPlay {
                        queuePlayer.play()
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    let item = AVPlayerItem(asset: asset)
                    let queuePlayer = AVQueuePlayer(playerItem: item)
                    queuePlayer.isMuted = isMuted
                    if loop {
                        self?.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
                    }
                    self?.player = queuePlayer
                    
                    // 如果需要自动播放，在播放器创建后立即播放
                    if autoPlay {
                        queuePlayer.play()
                    }
                }
            }
        }
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func cleanup() {
        player?.pause()
        player = nil
        looper = nil
    }

    func togglePlayPause() {
        guard let player = player else { return }
        if player.timeControlStatus == .playing || player.rate > 0 {
            player.pause()
        } else {
            player.play()
        }
    }
    
    // 获取当前播放时间
    func getCurrentTime() -> CMTime? {
        return player?.currentTime()
    }
    
    // 定位到指定时间
    func seek(to time: CMTime) {
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
}

// MARK: - 系统原生全屏视频播放器
/// 使用系统 AVPlayerViewController 的原生全屏功能，自动横屏
struct NativeFullScreenVideoPlayer: View {
    let videoURL: String
    let startTime: CMTime?
    let onDismiss: ((CMTime?) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    
    init(videoURL: String, startTime: CMTime? = nil, onDismiss: ((CMTime?) -> Void)? = nil) {
        self.videoURL = videoURL
        self.startTime = startTime
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            // 使用 AVPlayerViewController 包装器
            AVPlayerViewControllerWrapper(videoURL: videoURL, startTime: startTime, onPlayerCreated: { createdPlayer in
                self.player = createdPlayer
            })
            .ignoresSafeArea()
            .onAppear {
                // 设置支持横屏
                if let appDelegate = AppDelegate.shared {
                    appDelegate.orientationMask = [.landscapeLeft, .landscapeRight]
                }
                // 立即请求横屏
                forceLandscape()
            }
            .onDisappear {
                // 恢复竖屏
                if let appDelegate = AppDelegate.shared {
                    appDelegate.orientationMask = [.portrait]
                }
                restorePortrait()
                
                // 返回播放时间
                if let currentTime = player?.currentTime() {
                    onDismiss?(currentTime)
                }
            }
        }
        .statusBar(hidden: true)
    }

    private func forceLandscape() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if #available(iOS 16.0, *) {
                let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
                scene.requestGeometryUpdate(prefs) { error in
                    print("🔄 强制横屏: \(String(describing: error))")
                }
                if let rootVC = scene.windows.first?.rootViewController {
                    rootVC.setNeedsUpdateOfSupportedInterfaceOrientations()
                }
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }

    private func restorePortrait() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if #available(iOS 16.0, *) {
                let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                try? scene.requestGeometryUpdate(prefs)
                if let rootVC = scene.windows.first?.rootViewController {
                    rootVC.setNeedsUpdateOfSupportedInterfaceOrientations()
                }
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }

    // AVPlayerViewController 包装器
    private struct AVPlayerViewControllerWrapper: UIViewControllerRepresentable {
        let videoURL: String
        let startTime: CMTime?
        let onPlayerCreated: ((AVPlayer) -> Void)?

        func makeUIViewController(context: Context) -> LandscapePlayerViewController {
            let controller = LandscapePlayerViewController()

            // 基本配置
            controller.showsPlaybackControls = true
            controller.allowsPictureInPicturePlayback = false
            controller.videoGravity = .resizeAspectFill
            controller.view.backgroundColor = .black

            // 禁用系统的额外全屏按钮（我们已经是全屏了）
            controller.entersFullScreenWhenPlaybackBegins = false
            controller.exitsFullScreenWhenPlaybackEnds = false

            // 加载并播放视频
            if let url = URL(string: videoURL) {
                let player = AVPlayer(url: url)
                controller.player = player
                
                // 回调通知播放器已创建
                onPlayerCreated?(player)

                // 如果有起始时间，先定位到该时间点
                if let startTime = startTime, startTime.seconds > 0 {
                    player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
                }

                // 延迟播放，确保视图已经加载
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    player.play()
                }
            }

            return controller
        }

        func updateUIViewController(_ uiViewController: LandscapePlayerViewController, context: Context) {
            // 不需要更新
        }

        // 自定义 AVPlayerViewController，强制横屏
        class LandscapePlayerViewController: AVPlayerViewController {
            override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
                return [.landscapeLeft, .landscapeRight]
            }

            override var shouldAutorotate: Bool {
                return true
            }

            override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
                return .landscapeRight
            }
        }
    }
}

// MARK: - 视频播放器横屏全屏视图（旧版，保留备用）
/// 横屏全屏视频播放器
struct VideoPlayerFullScreenView: View {
    let videoURL: String
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let url = URL(string: videoURL), let player = player {
                // 使用 AVPlayerViewController 确保完全填充
                AVPlayerViewControllerWrapper(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        forceLandscape()
                    }
                    .onDisappear {
                        restorePortrait()
                        player.pause()
                    }
            } else if URL(string: videoURL) != nil {
                // 加载中
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                    .onAppear {
                        if let url = URL(string: videoURL) {
                            prepareAndPlay(url: url)
                            forceLandscape()
                        }
                    }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    Text("无法加载视频")
                        .foregroundColor(.white)
                }
            }

            // 关闭按钮（横屏时在右上角）
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 44, height: 44)
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(16)
                    }
                }
                Spacer()
            }
        }
        .statusBar(hidden: true) // 隐藏状态栏
    }

    // AVPlayerViewController 包装器 - 确保填充整个屏幕
    private struct AVPlayerViewControllerWrapper: UIViewControllerRepresentable {
        let player: AVPlayer

        func makeUIViewController(context: Context) -> AVPlayerViewController {
            let controller = AVPlayerViewController()
            controller.player = player
            controller.showsPlaybackControls = true
            controller.videoGravity = .resizeAspectFill  // 填充整个屏幕，裁切超出部分
            controller.view.backgroundColor = .black

            // 禁用系统全屏按钮（因为我们已经在全屏模式了）
            controller.entersFullScreenWhenPlaybackBegins = false
            controller.exitsFullScreenWhenPlaybackEnds = false

            // 禁用画中画
            controller.allowsPictureInPicturePlayback = false

            return controller
        }

        func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
            uiViewController.player = player
            uiViewController.videoGravity = .resizeAspectFill
        }
    }

    // 使用 AVPlayerViewController 自定义全屏播放器（保留，默认不使用）
    private struct FullScreenPlayerView: UIViewControllerRepresentable {
        let player: AVPlayer
        var fill: Bool = true
        private let debugEnable: Bool = false // 诊断开关（默认关闭）

        func makeUIViewController(context: Context) -> AVPlayerViewController {
            let vc = LandscapePlayerViewController()
            vc.player = player
            vc.showsPlaybackControls = true
            vc.view.backgroundColor = .black
            vc.videoGravity = fill ? .resizeAspectFill : .resizeAspect
            vc.exitsFullScreenWhenPlaybackEnds = false
            if debugEnable { addDebugOverlay(to: vc) }
            logContext(prefix: "makeUIViewController", vc: vc)
            return vc
        }

        func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
            uiViewController.player = player
            uiViewController.videoGravity = fill ? .resizeAspectFill : .resizeAspect
            if debugEnable { logContext(prefix: "updateUIViewController", vc: uiViewController) }
        }

        private class LandscapePlayerViewController: AVPlayerViewController {
            override var supportedInterfaceOrientations: UIInterfaceOrientationMask { [.portrait, .landscapeLeft, .landscapeRight] }
            override var shouldAutorotate: Bool { false }
            override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeRight }
            override func viewDidLoad() {
                super.viewDidLoad()
                view.backgroundColor = .black
                view.isOpaque = true
            }
        }

        // MARK: - Debug helpers (visual border + logs)
        private func addDebugOverlay(to vc: AVPlayerViewController) {
            // 红色 1px 边框覆盖整个视图，用于判断是否存在 UI 留白
            let border = UIView()
            border.isUserInteractionEnabled = false
            border.layer.borderColor = UIColor.red.cgColor
            border.layer.borderWidth = 1 / UIScreen.main.scale
            border.backgroundColor = .clear
            border.translatesAutoresizingMaskIntoConstraints = false
            vc.view.addSubview(border)
            NSLayoutConstraint.activate([
                border.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
                border.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
                border.topAnchor.constraint(equalTo: vc.view.topAnchor),
                border.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor)
            ])

            // 在四角放置小圆点，便于截图确认是否贴边
            func cornerDot() -> UIView {
                let v = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 6))
                v.layer.cornerRadius = 3
                v.backgroundColor = .red
                v.translatesAutoresizingMaskIntoConstraints = false
                return v
            }
            let tl = cornerDot(), tr = cornerDot(), bl = cornerDot(), br = cornerDot()
            [tl, tr, bl, br].forEach { vc.view.addSubview($0) }
            NSLayoutConstraint.activate([
                tl.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 2),
                tl.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 2),
                tr.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -2),
                tr.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 2),
                bl.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 2),
                bl.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: -2),
                br.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -2),
                br.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: -2)
            ])
        }

        private func logContext(prefix: String, vc: AVPlayerViewController) {
            let bounds = vc.view.bounds
            let insets = vc.view.safeAreaInsets
            let gravity = vc.videoGravity.rawValue
            print("🧪 Debug[\(prefix)]: view.bounds = \(bounds), safeAreaInsets = \(insets), videoGravity = \(gravity)")
            if let item = player.currentItem, let track = item.asset.tracks(withMediaType: .video).first {
                let ns = track.naturalSize
                let tx = track.preferredTransform
                let w = abs(ns.applying(tx).width)
                let h = abs(ns.applying(tx).height)
                let aspect = h > 0 ? w / h : 0
                print("🧪 Debug[\(prefix)]: asset naturalSize = \(ns), orientedSize = \(CGSize(width: w, height: h)), aspect = \(String(format: "%.3f", aspect))")
            }
        }
    }

    // MARK: - 方案A：自定义 PlayerLayer（完全填充，无白边）
    private struct FullScreenPlayerLayerView: UIViewRepresentable {
        let player: AVPlayer
        var zoom: CGFloat = 1.0   // 保持为 1.0，通过 resizeAspectFill 自动填充
        var offset: CGPoint = .zero // 可做细微偏移，默认不偏移

        func makeUIView(context: Context) -> PlayerLayerView {
            let v = PlayerLayerView()
            v.backgroundColor = .black
            v.playerLayer.player = player
            v.playerLayer.videoGravity = .resizeAspectFill  // 自动填充，裁切多余部分
            return v
        }

        func updateUIView(_ uiView: PlayerLayerView, context: Context) {
            if uiView.playerLayer.player !== player {
                uiView.playerLayer.player = player
            }
            uiView.playerLayer.videoGravity = .resizeAspectFill
        }

        final class PlayerLayerView: UIView {
            override static var layerClass: AnyClass { AVPlayerLayer.self }
            var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

            override func layoutSubviews() {
                super.layoutSubviews()
                // 确保 playerLayer 填充整个 view，不应用任何 transform
                playerLayer.frame = bounds
            }
        }
    }

    private func prepareAndPlay(url: URL) {
        // 异步预加载，避免主线程同步属性查询阻塞
        Task.detached(priority: .userInitiated) {
            let asset = AVURLAsset(url: url)
            do {
                if #available(iOS 15.0, *) {
                    _ = try await asset.load(.isPlayable)
                    let tracks = try await asset.load(.tracks)
                    if let videoTrack = tracks.first(where: { $0.mediaType == .video }) {
                        _ = try? await videoTrack.load(.preferredTransform)
                        _ = try? await videoTrack.load(.naturalSize)
                    }
                } else {
                    let keys = ["playable", "tracks", "duration"]
                    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                        asset.loadValuesAsynchronously(forKeys: keys) {
                            cont.resume()
                        }
                    }
                }

                await MainActor.run {
                    let item = AVPlayerItem(asset: asset)
                    let p = AVPlayer(playerItem: item)
                    p.automaticallyWaitsToMinimizeStalling = true
                    self.player = p
                    p.play()
                    // 额外打印一次素材信息，帮助判断“白边”是否来自内容本身
                    if let track = asset.tracks(withMediaType: .video).first {
                        let ns = track.naturalSize
                        let tx = track.preferredTransform
                        let w = abs(ns.applying(tx).width)
                        let h = abs(ns.applying(tx).height)
                        let aspect = h > 0 ? w / h : 0
                        print("🧪 Debug[prepare]: asset naturalSize = \(ns), orientedSize = \(CGSize(width: w, height: h)), aspect = \(String(format: "%.3f", aspect))")
                    }
                }
            } catch {
                await MainActor.run {
                    let p = AVPlayer(url: url)
                    p.automaticallyWaitsToMinimizeStalling = true
                    self.player = p
                    p.play()
                }
            }
        }
    }

    private func forceLandscape() {
        print("🔄 VideoPlayerFullScreenView: 尝试强制横屏")

        // 设置全局方向锁为横屏
        AppDelegate.shared?.orientationMask = [.portrait, .landscapeLeft, .landscapeRight]

        // 遍历所有 scenes，发起几何更新到横屏
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                print("🔄 VideoPlayerFullScreenView: 找到 WindowScene")

                // 直接请求几何更新
                if #available(iOS 16.0, *) {
                    print("✅ VideoPlayerFullScreenView: 使用 iOS 16+ API 请求横屏")
                    let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
                    windowScene.requestGeometryUpdate(prefs) { error in
                        print("🔄 VideoPlayerFullScreenView: requestGeometryUpdate 完成，error: \(error)")
                    }
                    if let rootVC = windowScene.windows.first?.rootViewController {
                        rootVC.setNeedsUpdateOfSupportedInterfaceOrientations()
                    }
                } else {
                    print("✅ VideoPlayerFullScreenView: 使用旧版 API 请求横屏")
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                    UIViewController.attemptRotationToDeviceOrientation()
                }
                break
            }
        }
    }

    private func restorePortrait() {
        if let appDelegate = AppDelegate.shared {
            appDelegate.orientationMask = [.portrait]
        }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if #available(iOS 16.0, *) {
                let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                try? scene.requestGeometryUpdate(prefs)
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }
}

// MARK: - 仅横屏的 Hosting 包装（用于全屏播放器）
private struct LandscapeHostingVideo<Content: View>: UIViewControllerRepresentable {
    let content: Content

    func makeUIViewController(context: Context) -> UIViewController {
        Controller(rootView: content)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    private class Controller: UIHostingController<Content> {
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            view.isOpaque = true
        }
        override var prefersHomeIndicatorAutoHidden: Bool { true }
        override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }
        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            print("🔄 LandscapeHosting: supportedInterfaceOrientations = .portrait + .landscape")
            return [.portrait, .landscapeLeft, .landscapeRight]
        }
        override var shouldAutorotate: Bool {
            print("🔄 LandscapeHosting: shouldAutorotate = false")
            return false
        }
        override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
            print("🔄 LandscapeHosting: preferredInterfaceOrientationForPresentation = .landscapeRight")
            return .landscapeRight
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            print("🔄 LandscapeHosting: viewWillAppear - 设置横屏支持")

            // 先放宽为同时支持竖屏+横屏，确保呈现链有公共方向
            AppDelegate.shared?.orientationMask = [.portrait, .landscapeLeft, .landscapeRight]

            // 通知系统重新查询支持方向，并尝试旋转到横屏
            DispatchQueue.main.async {
                if let keyWindow = getKeyWindow(), let scene = keyWindow.windowScene, let rootVC = keyWindow.rootViewController {
                    if #available(iOS 16.0, *) {
                        rootVC.setNeedsUpdateOfSupportedInterfaceOrientations()
                        let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
                        scene.requestGeometryUpdate(prefs) { error in
                            print("🔄 LandscapeHosting: requestGeometryUpdate 完成，error: \(String(describing: error))")
                            if error != nil {
                                // 回退方案
                                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                                UIViewController.attemptRotationToDeviceOrientation()
                            }
                        }
                    } else {
                        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                        UIViewController.attemptRotationToDeviceOrientation()
                    }
                }
            }
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            // 视图已出现，使用当前窗口的 scene 再次请求旋转，随后收紧为纯横屏，避免系统回切竖屏
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                if let keyWindow = getKeyWindow(), let scene = keyWindow.windowScene {
                    if #available(iOS 16.0, *) {
                        let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
                        scene.requestGeometryUpdate(prefs) { error in
                            print("🔄 LandscapeHosting(viewDidAppear): requestGeometryUpdate 完成，error: \(String(describing: error))")
                            // 收紧全局方向锁为纯横屏（仅在成功或即便失败也收紧，防止回切）
                            AppDelegate.shared?.orientationMask = [.landscapeLeft, .landscapeRight]
                            if error != nil {
                                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                                UIViewController.attemptRotationToDeviceOrientation()
                            }
                        }
                    } else {
                        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                        UIViewController.attemptRotationToDeviceOrientation()
                        AppDelegate.shared?.orientationMask = [.landscapeLeft, .landscapeRight]
                    }
                }
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            print("🔄 LandscapeHosting: viewWillDisappear - 恢复竖屏支持")

            // 恢复竖屏支持
            AppDelegate.shared?.orientationMask = [.portrait]

            // 强制刷新方向
            DispatchQueue.main.async {
                if #available(iOS 16.0, *) {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = scene.windows.first?.rootViewController {
                        rootVC.setNeedsUpdateOfSupportedInterfaceOrientations()
                        let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                        try? scene.requestGeometryUpdate(prefs)
                    }
                } else {
                    UIViewController.attemptRotationToDeviceOrientation()
                }
            }
        }
    }
}
