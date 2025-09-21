import Foundation
import SwiftUI

// MARK: - 缓存管理器
class CacheManager: ObservableObject {
    static let shared = CacheManager()
    
    private var memoryCache: [String: Any] = [:]
    private var diskCacheURL: URL
    
    private init() {
        // 设置磁盘缓存路径
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        diskCacheURL = documentsPath.appendingPathComponent("QingheCache")
        
        // 创建缓存目录
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
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
            let files = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey])
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

        // 计算图片缓存大小（估算）
        let imageCacheSize = ImageLoader.getCacheSize()

        // 内存缓存项目数量
        let memoryCacheCount = memoryCache.count

        return CacheInfo(
            totalSize: diskCacheSize + audioCacheSize + imageCacheSize,
            diskCacheSize: diskCacheSize,
            diskCacheFileCount: diskCacheFileCount,
            audioCacheSize: audioCacheSize,
            imageCacheSize: imageCacheSize,
            memoryCacheCount: memoryCacheCount
        )
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

        // 清理其他服务的缓存
        TemptationService.shared.clearCache()

        print("🧹 所有缓存已清理完成")
    }
}

// MARK: - 缓存信息模型
struct CacheInfo {
    let totalSize: Int64
    let diskCacheSize: Int64
    let diskCacheFileCount: Int
    let audioCacheSize: Int64
    let imageCacheSize: Int64
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
}
