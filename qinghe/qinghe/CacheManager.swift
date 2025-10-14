import Foundation
import SwiftUI
import CoreData

// MARK: - 缓存管理器
class CacheManager: ObservableObject {
    static let shared = CacheManager()
    
    private var memoryCache: [String: Any] = [:]
    private var diskCacheURL: URL
    private let fileManager = FileManager.default
    
    private init() {
        // 设置磁盘缓存路径
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        diskCacheURL = documentsPath.appendingPathComponent("QingheCache")
        
        // 创建缓存目录
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    // MARK: - 内存缓存操作
    func setMemoryCache<T>(_ value: T, forKey key: String) {
        memoryCache[key] = value
    }
    
    func getMemoryCache<T>(forKey key: String, as type: T.Type) -> T? {
        return memoryCache[key] as? T
    }
    
    func removeMemoryCache(forKey key: String) {
        memoryCache.removeValue(forKey: key)
    }
    
    func clearMemoryCaches() {
        memoryCache.removeAll()
    }
    
    // MARK: - 磁盘缓存操作
    func setDiskCache<T: Codable>(_ value: T, forKey key: String) {
        let fileURL = diskCacheURL.appendingPathComponent("\(key).cache")
        
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: fileURL)
        } catch {
            print("❌ 磁盘缓存写入失败: \(error)")
        }
    }
    
    func getDiskCache<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        let fileURL = diskCacheURL.appendingPathComponent("\(key).cache")
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("❌ 磁盘缓存读取失败: \(error)")
            return nil
        }
    }
    
    func removeDiskCache(forKey key: String) {
        let fileURL = diskCacheURL.appendingPathComponent("\(key).cache")
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func clearDiskCaches() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print("❌ 清理磁盘缓存失败: \(error)")
        }
    }
    
    // MARK: - 特定功能缓存管理
    func disableCommunityCaches() {
        // 禁用社区相关缓存以减少内存占用
        removeMemoryCache(forKey: "community_posts")
        removeMemoryCache(forKey: "community_users")
    }
    
    func getCacheSize() -> String {
        var totalSize: Int64 = 0

        // 计算磁盘缓存大小
        do {
            let files = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey])
            for file in files {
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(attributes.fileSize ?? 0)
            }
        } catch {
            print("❌ 计算缓存大小失败: \(error)")
        }

        // 格式化大小显示
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }

    // MARK: - 获取详细缓存信息
    @MainActor
    func getDetailedCacheInfo() -> CacheInfo {
        var diskCacheSize: Int64 = 0
        var diskCacheFileCount = 0

        // 计算磁盘缓存
        do {
            let files = try fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey])
            diskCacheFileCount = files.count
            for file in files {
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                diskCacheSize += Int64(attributes.fileSize ?? 0)
            }
        } catch {
            print("❌ 计算磁盘缓存大小失败: \(error)")
        }

        // 计算音频缓存大小
        let audioCacheSize = AudioCacheManager.shared.getCacheSize()
        let audioCacheFileCount = AudioCacheManager.shared.getCacheFileCount()

        // 计算图片缓存大小（估算）
        let imageCacheSize = ImageLoader.getCacheSize()

        // 计算视频缓存大小
        let videoCacheSize = VideoCacheManager.shared.getCacheSize()
        let videoCacheFileCount = VideoCacheManager.shared.getCacheFileCount()

        // 计算 URLCache 大小
        let urlCacheSize = Int64(URLCache.shared.currentDiskUsage)

        // 计算临时文件大小
        let tempFilesSize = getTempFilesSize()

        // 内存缓存项目数量
        let memoryCacheCount = memoryCache.count

        return CacheInfo(
            totalSize: diskCacheSize + audioCacheSize + imageCacheSize + videoCacheSize + urlCacheSize + tempFilesSize,
            diskCacheSize: diskCacheSize,
            diskCacheFileCount: diskCacheFileCount,
            audioCacheSize: audioCacheSize,
            audioCacheFileCount: audioCacheFileCount,
            imageCacheSize: imageCacheSize,
            videoCacheSize: videoCacheSize,
            videoCacheFileCount: videoCacheFileCount,
            urlCacheSize: urlCacheSize,
            tempFilesSize: tempFilesSize,
            memoryCacheCount: memoryCacheCount
        )
    }
    
    // MARK: - 获取临时文件大小
    private func getTempFilesSize() -> Int64 {
        var totalSize: Int64 = 0
        
        do {
            let tmpDirectory = fileManager.temporaryDirectory
            let files = try fileManager.contentsOfDirectory(at: tmpDirectory, includingPropertiesForKeys: [.fileSizeKey])
            for file in files {
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(attributes.fileSize ?? 0)
            }
        } catch {
            print("❌ 计算临时文件大小失败: \(error)")
        }
        
        return totalSize
    }
    
    // MARK: - 清理临时文件
    func clearTempFiles() {
        do {
            let tmpDirectory = fileManager.temporaryDirectory
            let files = try fileManager.contentsOfDirectory(at: tmpDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try? fileManager.removeItem(at: file)
            }
            print("🧹 临时文件已清理")
        } catch {
            print("❌ 清理临时文件失败: \(error)")
        }
    }
    
    // MARK: - 清理 URL 缓存
    func clearURLCache() {
        URLCache.shared.removeAllCachedResponses()
        print("🧹 URL缓存已清理")
    }

    // MARK: - 清理所有缓存
    @MainActor
    func clearAllCaches() {
        clearMemoryCaches()
        clearDiskCaches()

        // 清理音频缓存
        AudioCacheManager.shared.clearCache()

        // 清理图片缓存
        ImageLoader.clearCache()
        
        // 清理视频缓存
        VideoCacheManager.shared.clearCache()
        
        // 清理 URL 缓存
        clearURLCache()
        
        // 清理临时文件
        clearTempFiles()

        // 清理其他服务的缓存
        TemptationService.shared.clearCache()

        print("🧹 所有缓存已清理完成")
    }
    
    // MARK: - 选择性清理缓存
    @MainActor
    func clearSpecificCaches(types: Set<CacheType>) {
        for type in types {
            switch type {
            case .memory:
                clearMemoryCaches()
            case .disk:
                clearDiskCaches()
            case .image:
                ImageLoader.clearCache()
            case .audio:
                AudioCacheManager.shared.clearCache()
            case .video:
                VideoCacheManager.shared.clearCache()
            case .urlCache:
                clearURLCache()
            case .tempFiles:
                clearTempFiles()
            }
        }
        print("🧹 已清理选中的缓存类型")
    }
}

// MARK: - 缓存类型枚举
enum CacheType: String, CaseIterable, Identifiable {
    case memory = "内存缓存"
    case disk = "磁盘缓存"
    case image = "图片缓存"
    case audio = "音频缓存"
    case video = "视频缓存"
    case urlCache = "网络缓存"
    case tempFiles = "临时文件"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .memory: return "memorychip"
        case .disk: return "internaldrive"
        case .image: return "photo"
        case .audio: return "waveform"
        case .video: return "video"
        case .urlCache: return "network"
        case .tempFiles: return "doc.text"
        }
    }
}

// MARK: - 缓存信息模型
struct CacheInfo {
    let totalSize: Int64
    let diskCacheSize: Int64
    let diskCacheFileCount: Int
    let audioCacheSize: Int64
    let audioCacheFileCount: Int
    let imageCacheSize: Int64
    let videoCacheSize: Int64
    let videoCacheFileCount: Int
    let urlCacheSize: Int64
    let tempFilesSize: Int64
    let memoryCacheCount: Int

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var formattedDiskCacheSize: String {
        ByteCountFormatter.string(fromByteCount: diskCacheSize, countStyle: .file)
    }

    var formattedAudioCacheSize: String {
        ByteCountFormatter.string(fromByteCount: audioCacheSize, countStyle: .file)
    }

    var formattedImageCacheSize: String {
        ByteCountFormatter.string(fromByteCount: imageCacheSize, countStyle: .file)
    }
    
    var formattedVideoCacheSize: String {
        ByteCountFormatter.string(fromByteCount: videoCacheSize, countStyle: .file)
    }
    
    var formattedURLCacheSize: String {
        ByteCountFormatter.string(fromByteCount: urlCacheSize, countStyle: .file)
    }
    
    var formattedTempFilesSize: String {
        ByteCountFormatter.string(fromByteCount: tempFilesSize, countStyle: .file)
    }
    
    // 获取特定类型的缓存大小
    func size(for type: CacheType) -> Int64 {
        switch type {
        case .memory: return 0 // 内存缓存大小难以准确计算
        case .disk: return diskCacheSize
        case .image: return imageCacheSize
        case .audio: return audioCacheSize
        case .video: return videoCacheSize
        case .urlCache: return urlCacheSize
        case .tempFiles: return tempFilesSize
        }
    }
    
    func formattedSize(for type: CacheType) -> String {
        ByteCountFormatter.string(fromByteCount: size(for: type), countStyle: .file)
    }
    
    func fileCount(for type: CacheType) -> Int? {
        switch type {
        case .disk: return diskCacheFileCount
        case .audio: return audioCacheFileCount
        case .video: return videoCacheFileCount
        case .memory: return memoryCacheCount
        default: return nil
        }
    }
}
