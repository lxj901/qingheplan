import SwiftUI
import Foundation

/// 带缓存的异步图片加载组件
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    private let showRetryButton: Bool

    @StateObject private var imageLoader = ImageLoader()

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        showRetryButton: Bool = true
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        self.showRetryButton = showRetryButton
    }
    
    var body: some View {
        Group {
            if let image = imageLoader.image {
                content(Image(uiImage: image))
            } else if imageLoader.hasError {
                // 根据 showRetryButton 参数决定是否显示重试按钮
                if showRetryButton {
                    // 显示错误状态和重试按钮
                    placeholder()
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title2)
                                    .foregroundColor(.orange)

                                Button("重试") {
                                    imageLoader.loadImage(from: url)
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                        )
                } else {
                    // 只显示占位符，不显示重试按钮（适用于头像等场景）
                    placeholder()
                }
            } else {
                placeholder()
            }
        }
        .onAppear {
            // 避免在视图更新周期内立即发布变化，延迟到下一次RunLoop
            DispatchQueue.main.async {
                imageLoader.loadImage(from: url)
            }
        }
        .onChange(of: url) {
            // 同样延迟触发，规避 "Publishing changes from within view updates" 崩溃
            DispatchQueue.main.async {
                imageLoader.loadImage(from: url)
            }
        }
    }
}

/// 图片加载器
@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var hasError = false

    private static let cache = NSCache<NSString, UIImage>()
    private var currentTask: Task<Void, Never>?
    private var retryCount = 0
    private let maxRetries = 3
    private let retryDelays: [TimeInterval] = [1.0, 2.0, 4.0] // 递增延迟

    // 自定义URLSession配置，支持移动网络
    private static let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true  // 允许使用移动网络
        config.allowsExpensiveNetworkAccess = true  // 允许使用昂贵网络（移动数据）
        config.allowsConstrainedNetworkAccess = true  // 允许受限网络
        config.waitsForConnectivity = false  // 不等待网络连接
        config.timeoutIntervalForRequest = 30  // 请求超时30秒
        config.timeoutIntervalForResource = 60  // 资源超时60秒
        config.requestCachePolicy = .returnCacheDataElseLoad  // 优先使用缓存
        return URLSession(configuration: config)
    }()

    init() {
        // 配置缓存
        Self.cache.countLimit = 100 // 最多缓存100张图片
        Self.cache.totalCostLimit = 50 * 1024 * 1024 // 最多50MB
    }
    
    func loadImage(from url: URL?) {
        // 取消之前的任务
        currentTask?.cancel()

        guard let url = url else {
            image = nil
            hasError = false
            return
        }

        let cacheKey = url.absoluteString as NSString
        let urlString = url.absoluteString

        // 检查缓存
        if let cachedImage = Self.cache.object(forKey: cacheKey) {
            image = cachedImage
            hasError = false
            return
        }

        // 检查是否是 base64 数据 URL
        if urlString.hasPrefix("data:image/") {
            loadBase64Image(from: urlString, cacheKey: cacheKey)
            return
        }

        // ✅ 验证 URL 是否有效（必须是 http:// 或 https:// 开头）
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            print("⚠️ 无效的图片URL（不是完整URL）: \(urlString)")
            image = nil
            hasError = true
            isLoading = false
            return
        }

        // 重置状态
        image = nil
        isLoading = true
        hasError = false
        retryCount = 0

        // 开始加载
        currentTask = Task {
            await loadImageWithRetry(url: url, cacheKey: cacheKey)
        }
    }
    
    private func loadBase64Image(from dataUrl: String, cacheKey: NSString) {
        // 解析 base64 数据
        // 格式: data:image/jpeg;base64,/9j/4AAQSkZJRgABA...
        guard let commaIndex = dataUrl.firstIndex(of: ",") else {
            hasError = true
            return
        }
        
        let base64String = String(dataUrl[dataUrl.index(after: commaIndex)...])
        
        // 解码 base64
        if let imageData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters),
           let uiImage = UIImage(data: imageData) {
            // 缓存图片
            Self.cache.setObject(uiImage, forKey: cacheKey)
            
            // 更新UI
            image = uiImage
            hasError = false
            isLoading = false
            print("✅ Base64图片加载成功")
        } else {
            hasError = true
            isLoading = false
            print("❌ Base64图片解码失败")
        }
    }

    private func loadImageWithRetry(url: URL, cacheKey: NSString) async {
        do {
            // 打印网络状态
            let networkMonitor = await NetworkMonitor.shared
            print("🌐 图片加载开始 - 网络状态: 连接=\(networkMonitor.isConnected), 类型=\(networkMonitor.connectionType?.description ?? "未知")")
            print("🖼️ 图片URL: \(url.absoluteString)")

            let (data, response) = try await Self.urlSession.data(from: url)

            guard !Task.isCancelled else { return }

            // 检查HTTP响应状态
            if let httpResponse = response as? HTTPURLResponse {
                print("🖼️ 图片加载状态码: \(httpResponse.statusCode) - \(url.absoluteString)")
                print("🖼️ 响应头: \(httpResponse.allHeaderFields)")

                // 如果是503或其他服务器错误，尝试重试
                if httpResponse.statusCode >= 500 && retryCount < maxRetries {
                    await retryLoad(url: url, cacheKey: cacheKey)
                    return
                }

                guard 200...299 ~= httpResponse.statusCode else {
                    throw URLError(.badServerResponse)
                }
            }

            if let uiImage = UIImage(data: data) {
                // 缓存图片
                Self.cache.setObject(uiImage, forKey: cacheKey)

                // 更新UI
                await MainActor.run {
                    image = uiImage
                    hasError = false
                    isLoading = false
                }
                print("✅ 图片加载成功: \(url.absoluteString)")
            } else {
                throw URLError(.cannotDecodeContentData)
            }

        } catch {
            print("❌ 图片加载失败 (尝试 \(retryCount + 1)/\(maxRetries + 1)): \(error.localizedDescription)")
            print("❌ 错误详情: \(error)")

            // 如果是URLError，打印更多信息
            if let urlError = error as? URLError {
                print("❌ URLError代码: \(urlError.code.rawValue)")
                print("❌ URLError描述: \(urlError.localizedDescription)")
                if let failingURL = urlError.failureURLString {
                    print("❌ 失败的URL: \(failingURL)")
                }
            }

            // 检查是否需要重试
            if retryCount < maxRetries && shouldRetry(error: error) {
                await retryLoad(url: url, cacheKey: cacheKey)
            } else {
                // 所有重试都失败了
                await MainActor.run {
                    hasError = true
                    isLoading = false
                }
                print("🚫 图片加载最终失败: \(url.absoluteString)")
            }
        }
    }

    private func retryLoad(url: URL, cacheKey: NSString) async {
        retryCount += 1
        let delay = retryDelays[min(retryCount - 1, retryDelays.count - 1)]

        print("🔄 图片加载重试 \(retryCount)/\(maxRetries)，延迟 \(delay)s: \(url.absoluteString)")

        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        guard !Task.isCancelled else { return }

        await loadImageWithRetry(url: url, cacheKey: cacheKey)
    }

    private func shouldRetry(error: Error) -> Bool {
        // 判断是否应该重试的错误类型
        if let urlError = error as? URLError {
            switch urlError.code {
            case .networkConnectionLost,
                 .notConnectedToInternet,
                 .timedOut,
                 .cannotConnectToHost,
                 .cannotFindHost,
                 .dnsLookupFailed,
                 .badServerResponse:
                return true
            default:
                return false
            }
        }
        return true // 其他错误也尝试重试
    }
    
    deinit {
        currentTask?.cancel()
    }

    // MARK: - 静态缓存管理方法
    static func getCacheSize() -> Int64 {
        // 估算图片缓存大小（NSCache不提供直接的大小计算方法）
        // 这里返回一个估算值，基于缓存的图片数量
        let estimatedSizePerImage: Int64 = 100 * 1024 // 假设每张图片平均100KB
        return Int64(cache.totalCostLimit) // 使用设置的总成本限制作为估算
    }

    static func clearCache() {
        cache.removeAllObjects()
        print("🧹 图片缓存已清理")
    }

    static func getCacheInfo() -> (count: Int, sizeLimit: Int) {
        return (cache.countLimit, cache.totalCostLimit)
    }
}

// MARK: - 便利初始化方法
extension CachedAsyncImage where Content == Image, Placeholder == Color {
    init(url: URL?) {
        self.init(
            url: url,
            content: { $0 },
            placeholder: { Color.gray.opacity(0.3) }
        )
    }
}

extension CachedAsyncImage where Placeholder == Color {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            content: content,
            placeholder: { Color.gray.opacity(0.3) }
        )
    }
}

// MARK: - 头像专用组件
struct CachedAvatarView: View {
    let url: URL?
    let fallbackText: String
    let size: CGFloat
    let showOnlineIndicator: Bool
    
    init(
        url: URL?,
        fallbackText: String,
        size: CGFloat = 44,
        showOnlineIndicator: Bool = false
    ) {
        self.url = url
        self.fallbackText = fallbackText
        self.size = size
        self.showOnlineIndicator = showOnlineIndicator
    }
    
    var body: some View {
        ZStack {
            NetworkAwareAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(ModernDesignSystem.Colors.backgroundSecondary)
                    .overlay(
                        Text(String(fallbackText.prefix(1)))
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    )
            }
            .frame(width: size, height: size)
            .clipShape(Circle())

            // 在线状态指示器
            if showOnlineIndicator {
                Circle()
                    .fill(ModernDesignSystem.Colors.successGreen)
                    .frame(width: size * 0.25, height: size * 0.25)
                    .overlay(
                        Circle()
                            .stroke(ModernDesignSystem.Colors.backgroundCard, lineWidth: 2)
                    )
                    .offset(x: size * 0.3, y: size * 0.3)
            }
        }
    }
}
