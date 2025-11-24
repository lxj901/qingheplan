import Foundation
import AVFoundation

/// 短视频预加载策略
/// 负责智能预加载视频，提升用户体验
class ShortVideoPreloadStrategy {
    static let shared = ShortVideoPreloadStrategy()
    
    // MARK: - Properties
    
    /// 预加载队列
    private var preloadQueue: [String] = []
    
    /// 已预加载的视频
    private var preloadedVideos: Set<String> = []
    
    /// 预加载任务
    private var preloadTasks: [String: URLSessionDataTask] = [:]
    
    /// 缓存大小限制（MB）
    private let maxCacheSize: Int = 200
    
    /// 单个视频预加载大小限制（MB）
    private let maxPreloadSize: Int = 10
    
    /// 预加载数量
    private let preloadCount: Int = 2
    
    /// URL Session
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,  // 50 MB
            diskCapacity: 200 * 1024 * 1024,   // 200 MB
            diskPath: "ShortVideoCache"
        )
        return URLSession(configuration: config)
    }()
    
    // MARK: - Initialization
    
    private init() {
        setupCache()
    }
    
    // MARK: - Public Methods
    
    /// 预加载视频列表
    /// - Parameters:
    ///   - urls: 视频 URL 列表
    ///   - currentIndex: 当前播放的索引
    func preloadVideos(urls: [String], currentIndex: Int) {
        print("📥 ShortVideoPreloadStrategy: 开始预加载，当前索引: \(currentIndex)")
        
        // 清空旧的预加载队列
        cancelAllPreloads()
        
        // 计算需要预加载的视频
        var urlsToPreload: [String] = []
        
        // 预加载下一个视频
        if currentIndex + 1 < urls.count {
            urlsToPreload.append(urls[currentIndex + 1])
        }
        
        // 预加载下下个视频
        if currentIndex + 2 < urls.count && preloadCount >= 2 {
            urlsToPreload.append(urls[currentIndex + 2])
        }
        
        // 执行预加载
        for url in urlsToPreload {
            preloadVideo(url: url)
        }
    }
    
    /// 预加载单个视频
    /// - Parameter url: 视频 URL
    func preloadVideo(url: String) {
        // 如果已经预加载过，跳过
        if preloadedVideos.contains(url) {
            print("⏭️ ShortVideoPreloadStrategy: 已预加载，跳过 - \(url)")
            return
        }
        
        // 如果正在预加载，跳过
        if preloadTasks[url] != nil {
            print("⏭️ ShortVideoPreloadStrategy: 正在预加载，跳过 - \(url)")
            return
        }
        
        guard let videoURL = URL(string: url) else {
            print("❌ ShortVideoPreloadStrategy: 无效的 URL - \(url)")
            return
        }
        
        print("📥 ShortVideoPreloadStrategy: 开始预加载 - \(url)")
        
        // 创建预加载任务
        var request = URLRequest(url: videoURL)
        request.cachePolicy = .returnCacheDataElseLoad
        
        // 只预加载前面的部分数据（Range 请求）
        let preloadBytes = maxPreloadSize * 1024 * 1024 // 转换为字节
        request.setValue("bytes=0-\(preloadBytes)", forHTTPHeaderField: "Range")
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ ShortVideoPreloadStrategy: 预加载失败 - \(url), 错误: \(error.localizedDescription)")
                self.preloadTasks.removeValue(forKey: url)
                return
            }
            
            if let data = data {
                print("✅ ShortVideoPreloadStrategy: 预加载完成 - \(url), 大小: \(data.count / 1024) KB")
                self.preloadedVideos.insert(url)
                self.preloadTasks.removeValue(forKey: url)
                
                // 缓存数据
                if let response = response {
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    self.urlSession.configuration.urlCache?.storeCachedResponse(cachedResponse, for: request)
                }
            }
        }
        
        preloadTasks[url] = task
        task.resume()
    }
    
    /// 取消所有预加载任务
    func cancelAllPreloads() {
        print("🛑 ShortVideoPreloadStrategy: 取消所有预加载任务")
        
        for (_, task) in preloadTasks {
            task.cancel()
        }
        
        preloadTasks.removeAll()
    }
    
    /// 取消指定视频的预加载
    /// - Parameter url: 视频 URL
    func cancelPreload(url: String) {
        if let task = preloadTasks[url] {
            print("🛑 ShortVideoPreloadStrategy: 取消预加载 - \(url)")
            task.cancel()
            preloadTasks.removeValue(forKey: url)
        }
    }
    
    /// 检查视频是否已预加载
    /// - Parameter url: 视频 URL
    /// - Returns: 是否已预加载
    func isPreloaded(url: String) -> Bool {
        return preloadedVideos.contains(url)
    }
    
    /// 清空缓存
    func clearCache() {
        print("🗑️ ShortVideoPreloadStrategy: 清空缓存")
        
        urlSession.configuration.urlCache?.removeAllCachedResponses()
        preloadedVideos.removeAll()
        cancelAllPreloads()
    }
    
    /// 获取缓存大小
    /// - Returns: 缓存大小（MB）
    func getCacheSize() -> Double {
        guard let cache = urlSession.configuration.urlCache else {
            return 0
        }
        
        let currentDiskUsage = cache.currentDiskUsage
        let sizeInMB = Double(currentDiskUsage) / (1024 * 1024)
        
        return sizeInMB
    }
    
    /// 清理过期缓存
    func cleanupExpiredCache() {
        print("🧹 ShortVideoPreloadStrategy: 清理过期缓存")
        
        guard let cache = urlSession.configuration.urlCache else {
            return
        }
        
        let currentSize = cache.currentDiskUsage
        let maxSize = maxCacheSize * 1024 * 1024
        
        if currentSize > maxSize {
            print("⚠️ ShortVideoPreloadStrategy: 缓存超出限制，当前: \(currentSize / 1024 / 1024) MB, 最大: \(maxCacheSize) MB")
            
            // 清理一半的缓存
            cache.removeAllCachedResponses()
            preloadedVideos.removeAll()
        }
    }
    
    // MARK: - Private Methods
    
    /// 设置缓存
    private func setupCache() {
        // 确保缓存目录存在
        let fileManager = FileManager.default
        let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("ShortVideoCache")

        if let cacheURL = cacheURL, !fileManager.fileExists(atPath: cacheURL.path) {
            try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
            print("📁 ShortVideoPreloadStrategy: 创建缓存目录 - \(cacheURL.path)")
        }
    }
}

// MARK: - Preload Priority

/// 预加载优先级
enum PreloadPriority {
    case high    // 下一个视频
    case medium  // 下下个视频
    case low     // 更远的视频
    
    var weight: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

// MARK: - Preload Status

/// 预加载状态
enum PreloadStatus {
    case notStarted
    case loading
    case completed
    case failed
    case cancelled
}

