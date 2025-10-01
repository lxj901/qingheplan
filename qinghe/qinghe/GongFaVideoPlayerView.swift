import SwiftUI
import AVKit
import WebKit

struct GongFaVideoPlayerView: View {
    let course: GongFaCourse
    let videoURL: URL?

    @State private var player: AVPlayer = AVPlayer()
    @State private var isPlaying: Bool = true

    // 横屏偏好
    @State private var didForceLandscape = false

    init(course: GongFaCourse, videoURL: URL? = nil) {
        self.course = course
        if let videoURL = videoURL {
            self.videoURL = videoURL
        } else {
            // 默认：使用提供的央视国家体育总局八段锦 B站链接
            self.videoURL = URL(string: "https://www.bilibili.com/video/BV1kWaGzTEcx")
        }
    }

    var body: some View {
        ZStack(alignment: .center) {
            // 全屏视频
            videoContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)

            // 顶部右侧标签（课程名 + 功效标签示例）
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        pill(text: course.title)
                        if let tag = course.tags.first { pill(text: tag) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                Spacer()
            }

            // 右侧中部：能量消耗浮层
            VStack { Spacer() }
                .overlay(
                    CalorieFloatingView(tint: course.tint)
                        .padding(.trailing, 24)
                        .padding(.top, 0)
                    , alignment: .trailing
                )
        }
        .ignoresSafeArea()
        .onAppear { forceLandscape(); preparePlayerIfNeeded() }
        .onDisappear { restorePortrait(); player.pause() }
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
        .asSubView()
    }

    private var isWebURL: Bool {
        guard let url = videoURL else { return false }
        return url.host?.contains("bilibili.com") == true || url.pathExtension.isEmpty
    }

    @ViewBuilder private var videoContent: some View {
        if let url = videoURL {
            if isWebURL {
                WebPlayerView(url: embedURL(for: url))
            } else {
                VideoPlayer(player: player)
                    .onAppear { player.play(); isPlaying = true }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { togglePlay() }
            }
        } else {
            LinearGradient(colors: [course.tint.opacity(0.6), course.tint], startPoint: .top, endPoint: .bottom)
            Text("暂无视频资源").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
        }
    }

    private func preparePlayerIfNeeded() {
        guard let url = videoURL, !isWebURL else { return }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
    }

    private func embedURL(for url: URL) -> URL {
        // 将 bilibili 标准视频页转换为播放器 iframe URL
        guard url.host?.contains("bilibili.com") == true else { return url }
        let absolute = url.absoluteString
        if let range = absolute.range(of: "/video/"), let bvRange = absolute[range.upperBound...].firstIndex(where: { $0 == "/" || $0 == "?" }) {
            let bvid = String(absolute[range.upperBound..<bvRange])
            let embed = "https://player.bilibili.com/player.html?bvid=\(bvid)&high_quality=1&danmaku=0&autoplay=1"
            return URL(string: embed) ?? url
        }
        if absolute.contains("BV") {
            // 粗略提取 BV 号
            if let bvStart = absolute.range(of: "BV") {
                let bv = String(absolute[bvStart.lowerBound...].prefix(12))
                let embed = "https://player.bilibili.com/player.html?bvid=\(bv)&high_quality=1&danmaku=0&autoplay=1"
                return URL(string: embed) ?? url
            }
        }
        return url
    }

    private func togglePlay() {
        if isPlaying { player.pause() } else { player.play() }
        isPlaying.toggle()
    }

    private func forceLandscape() {
        guard !didForceLandscape else { return }
        didForceLandscape = true
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientationMask = [.landscapeLeft, .landscapeRight]
        }
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }

    private func restorePortrait() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientationMask = [.portrait]
        }
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }
}

// 右侧悬浮卡路里组件（叠加在播放器之上）
private struct CalorieFloatingView: View {
    let tint: Color
    @State private var calories: Int = 9
    @State private var target: Int = 160
    var progress: Double { min(1.0, Double(calories)/Double(target)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "flame.fill").foregroundColor(.red.opacity(0.9))
                Text("\(calories)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("千卡")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.35)).frame(height: 6)
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [Color.red, Color.orange], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 120 * progress, height: 6)
            }
            .frame(width: 120)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.15), lineWidth: 0.6)
        )
        .padding(.trailing, 16)
        .padding(.top, 0)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("WorkoutCaloriesUpdated"))) { note in
            if let userInfo = note.userInfo {
                if let c = userInfo["calories"] as? Int { calories = c }
                if let t = userInfo["target"] as? Int { target = t }
            }
        }
    }
}

// 顶部标签胶囊
private func pill(text: String) -> some View {
    Text(text)
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.35)))
}

// Web 播放（用于 bilibili 页面）
private struct WebPlayerView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView()
        web.scrollView.isScrollEnabled = false
        web.allowsBackForwardNavigationGestures = true
        web.configuration.allowsInlineMediaPlayback = true
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: url))
    }
}

#Preview {
    GongFaVideoPlayerView(course: .init(title: "八段锦", tags: ["科学健体"], level: "入门", duration: "15分钟", cover: nil, tint: ModernDesignSystem.Colors.primaryGreen), videoURL: URL(string: "https://www.bilibili.com/video/BV1kWaGzTEcx"))
}
