import Foundation
import AVFoundation

// MARK: - 视频缓存管理器
class VideoCacheManager {
    static let shared = VideoCacheManager()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let memoryCache = NSCache<NSString, NSData>()
    
    private init() {
        // 创建视频缓存目录
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("VideoCache")
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        // 设置内存缓存限制
        memoryCache.countLimit = 10 // 最多缓存10个视频
        memoryCache.totalCostLimit = 100 * 1024 * 1024 // 最大100MB
    }
    
    // MARK: - 缓存视频数据
    func cacheVideo(_ data: Data, for url: String) {
        let key = NSString(string: url.md5Hash())
        
        // 保存到内存缓存
        memoryCache.setObject(NSData(data: data), forKey: key, cost: data.count)
        
        // 保存到磁盘缓存
        let fileURL = cacheDirectory.appendingPathComponent("\(url.md5Hash()).mp4")
        try? data.write(to: fileURL)
        
        print("📹 视频已缓存: \(url.md5Hash()).mp4, 大小: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
    }
    
    // MARK: - 获取缓存的视频
    func getCachedVideo(for url: String) -> Data? {
        let key = NSString(string: url.md5Hash())
        
        // 先从内存缓存获取
        if let cachedData = memoryCache.object(forKey: key) {
            return Data(referencing: cachedData)
        }
        
        // 从磁盘缓存获取
        let fileURL = cacheDirectory.appendingPathComponent("\(url.md5Hash()).mp4")
        if let data = try? Data(contentsOf: fileURL) {
            // 重新加入内存缓存
            memoryCache.setObject(NSData(data: data), forKey: key, cost: data.count)
            return data
        }
        
        return nil
    }
    
    // MARK: - 检查是否已缓存
    func isCached(url: String) -> Bool {
        let key = NSString(string: url.md5Hash())
        
        // 检查内存缓存
        if memoryCache.object(forKey: key) != nil {
            return true
        }
        
        // 检查磁盘缓存
        let fileURL = cacheDirectory.appendingPathComponent("\(url.md5Hash()).mp4")
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - 获取缓存文件URL
    func getCachedFileURL(for url: String) -> URL? {
        let fileURL = cacheDirectory.appendingPathComponent("\(url.md5Hash()).mp4")
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        return nil
    }
    
    // MARK: - 删除特定视频缓存
    func removeCache(for url: String) {
        let key = NSString(string: url.md5Hash())
        memoryCache.removeObject(forKey: key)
        
        let fileURL = cacheDirectory.appendingPathComponent("\(url.md5Hash()).mp4")
        try? fileManager.removeItem(at: fileURL)
    }
    
    // MARK: - 清理所有缓存
    func clearCache() {
        memoryCache.removeAllObjects()
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
            print("🧹 视频缓存已清理")
        } catch {
            print("❌ 清理视频缓存失败: \(error)")
        }
    }
    
    // MARK: - 获取缓存大小
    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            for file in files {
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(attributes.fileSize ?? 0)
            }
        } catch {
            print("❌ 计算视频缓存大小失败: \(error)")
        }
        
        return totalSize
    }
    
    // MARK: - 获取缓存文件数量
    func getCacheFileCount() -> Int {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            return files.count
        } catch {
            print("❌ 获取视频缓存文件数量失败: \(error)")
            return 0
        }
    }
    
    // MARK: - 获取缓存文件列表
    func getCachedFiles() -> [(url: URL, size: Int64, date: Date)] {
        var files: [(url: URL, size: Int64, date: Date)] = []
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]
            )
            
            for fileURL in fileURLs {
                let attributes = try fileURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
                let size = Int64(attributes.fileSize ?? 0)
                let date = attributes.creationDate ?? Date()
                files.append((url: fileURL, size: size, date: date))
            }
        } catch {
            print("❌ 获取缓存文件列表失败: \(error)")
        }
        
        return files.sorted { $0.date > $1.date } // 按日期降序排列
    }
    
    // MARK: - 清理过期缓存（超过指定天数）
    func clearExpiredCache(olderThanDays days: Int) {
        let expirationDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        do {
            let files = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.creationDateKey]
            )
            
            var removedCount = 0
            var freedSize: Int64 = 0
            
            for file in files {
                let attributes = try file.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                if let creationDate = attributes.creationDate, creationDate < expirationDate {
                    let size = Int64(attributes.fileSize ?? 0)
                    try fileManager.removeItem(at: file)
                    removedCount += 1
                    freedSize += size
                }
            }
            
            if removedCount > 0 {
                print("🧹 已清理 \(removedCount) 个过期视频缓存，释放空间: \(ByteCountFormatter.string(fromByteCount: freedSize, countStyle: .file))")
            }
        } catch {
            print("❌ 清理过期缓存失败: \(error)")
        }
    }
    
    // MARK: - 限制缓存大小（删除最旧的文件直到大小符合限制）
    func limitCacheSize(to maxBytes: Int64) {
        let currentSize = getCacheSize()
        
        if currentSize <= maxBytes {
            return
        }
        
        var files = getCachedFiles()
        var totalSize = currentSize
        var removedCount = 0
        
        // 从最旧的文件开始删除
        while totalSize > maxBytes && !files.isEmpty {
            let oldestFile = files.removeLast()
            do {
                try fileManager.removeItem(at: oldestFile.url)
                totalSize -= oldestFile.size
                removedCount += 1
            } catch {
                print("❌ 删除缓存文件失败: \(error)")
            }
        }
        
        if removedCount > 0 {
            print("🧹 已删除 \(removedCount) 个旧视频缓存以符合大小限制")
        }
    }
}

// MARK: - String Extension for MD5 Hash
extension String {
    func md5Hash() -> String {
        // 如果已经有 md5 扩展，使用它；否则使用简单的哈希
        if let md5Method = self.responds(to: Selector(("md5"))) ? self.perform(Selector(("md5")))?.takeUnretainedValue() as? String : nil {
            return md5Method
        }
        
        // 简单的哈希实现（作为备选）
        return String(self.hashValue)
    }
}

