import SwiftUI
import Photos
import AVKit

/// 媒体预览视图
struct MediaPreviewView: View {
    let asset: PHAsset
    let initialThumbnail: UIImage?
    let isSelected: Bool
    let onDismiss: () -> Void
    let onToggleSelection: () -> Void

    @State private var thumbnailImage: UIImage?
    @State private var fullImage: UIImage?
    @State private var videoPlayer: AVPlayer?
    @State private var isLoadingFull = true

    init(asset: PHAsset,
         initialThumbnail: UIImage?,
         isSelected: Bool,
         onDismiss: @escaping () -> Void,
         onToggleSelection: @escaping () -> Void) {
        self.asset = asset
        self.initialThumbnail = initialThumbnail
        self.isSelected = isSelected
        self.onDismiss = onDismiss
        self.onToggleSelection = onToggleSelection
        _thumbnailImage = State(initialValue: initialThumbnail)
    }

    var body: some View {
        ZStack {
            // 确保背景始终是黑色，完全覆盖整个屏幕
            Color.black
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if asset.mediaType == .image {
                imagePreview
            } else if asset.mediaType == .video {
                videoPreview
            }

            // 加载指示器（仅在加载高清内容时显示）
            if isLoadingFull && fullImage == nil && videoPlayer == nil {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }

            // 顶部工具栏
            VStack {
                topToolbar
                Spacer()
            }

            // 底部工具栏
            VStack {
                Spacer()
                bottomToolbar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
        .preferredColorScheme(.dark)
        .onAppear {
            // 如果没有传入缩略图，快速请求一张（包括视频海报帧）
            if thumbnailImage == nil {
                loadThumbnailFirst()
            }
            loadMedia()
        }
        .onDisappear {
            videoPlayer?.pause()
            videoPlayer = nil
        }
    }
    
    // MARK: - 图片预览
    private var imagePreview: some View {
        Group {
            if let image = fullImage ?? thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - 视频预览
    private var videoPreview: some View {
        Group {
            if let player = videoPlayer {
                VideoPlayer(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        player.play()
                    }
            } else if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color.clear
            }
        }
    }
    
    // MARK: - 顶部工具栏
    private var topToolbar: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Button(action: onToggleSelection) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.3))
                        .frame(width: 28, height: 28)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .ignoresSafeArea(edges: .top)
        )
    }
    
    // MARK: - 底部工具栏
    private var bottomToolbar: some View {
        HStack {
            if asset.mediaType == .video {
                HStack(spacing: 8) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    Text(formatDuration(asset.duration))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(16)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.5)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - 快速加载缩略图（图片/视频海报帧）
    private func loadThumbnailFirst() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        let thumbnailSize = CGSize(width: 500, height: 500)

        manager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFit, options: options) { image, _ in
            DispatchQueue.main.async {
                if self.thumbnailImage == nil { // 避免覆盖传入的缩略图
                    self.thumbnailImage = image
                }
            }
        }
    }

    // MARK: - 加载媒体
    private func loadMedia() {
        if asset.mediaType == .image {
            loadFullImage()
        } else if asset.mediaType == .video {
            loadVideo()
        }
    }

    private func loadFullImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        let targetSize = CGSize(width: 2048, height: 2048)

        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
            DispatchQueue.main.async {
                self.fullImage = image
                self.isLoadingFull = false
            }
        }
    }
    
    private func loadVideo() {
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        manager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            DispatchQueue.main.async {
                if let urlAsset = avAsset as? AVURLAsset {
                    self.videoPlayer = AVPlayer(url: urlAsset.url)
                }
                self.isLoadingFull = false
            }
        }
    }
}

// MARK: - 格式化时长
private func formatDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%d:%02d", minutes, seconds)
}

