import Foundation

/// 国学经典音频URL管理器
/// 负责检查音频URL是否过期，并在需要时刷新URL
class ClassicsAudioURLManager {
    static let shared = ClassicsAudioURLManager()
    
    private init() {}
    
    // MARK: - URL过期检查
    
    /// 检查音频URL是否过期
    /// - Parameter urlString: 音频URL字符串
    /// - Returns: 是否过期（true=过期，false=未过期）
    func isAudioUrlExpired(_ urlString: String?) -> Bool {
        guard let urlString = urlString,
              let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("⚠️ 音频URL无效或为空")
            return true
        }
        
        // 查找 Expires 参数
        guard let expiresString = components.queryItems?.first(where: { $0.name == "Expires" })?.value,
              let expiresTimestamp = Int(expiresString) else {
            print("⚠️ 音频URL中没有找到 Expires 参数")
            return true
        }
        
        let currentTimestamp = Int(Date().timeIntervalSince1970)
        // 提前1小时判断为过期（3600秒）
        let isExpired = currentTimestamp >= (expiresTimestamp - 3600)
        
        if isExpired {
            print("⚠️ 音频URL已过期 - 当前时间: \(currentTimestamp), 过期时间: \(expiresTimestamp)")
        } else {
            let remainingSeconds = expiresTimestamp - currentTimestamp
            print("✅ 音频URL有效 - 剩余时间: \(remainingSeconds)秒 (\(remainingSeconds / 3600)小时)")
        }
        
        return isExpired
    }
    
    // MARK: - URL刷新
    
    /// 确保音频URL有效（如果过期则刷新）
    /// - Parameters:
    ///   - currentUrl: 当前的音频URL
    ///   - bookId: 书籍ID
    ///   - chapterId: 章节ID
    ///   - sectionId: 句段ID
    ///   - voice: 音色（可选）
    /// - Returns: 有效的音频URL
    func ensureValidAudioUrl(
        currentUrl: String?,
        bookId: String,
        chapterId: String,
        sectionId: String,
        voice: String? = nil
    ) async -> String? {
        // 检查当前URL是否过期
        if !isAudioUrlExpired(currentUrl) {
            print("✅ 音频URL有效，直接使用")
            return currentUrl
        }
        
        // URL过期或无效，调用 ensure-audio API 刷新
        print("🔄 音频URL过期，正在刷新...")
        
        do {
            let newUrl = try await ClassicsAPIService.shared.ensureAudio(
                bookId: bookId,
                chapterId: chapterId,
                sectionId: sectionId,
                voice: voice
            )
            
            if let newUrl = newUrl {
                print("✅ 音频URL刷新成功: \(newUrl.prefix(100))...")
                return newUrl
            } else {
                print("⚠️ 音频URL刷新失败，返回nil")
                return nil
            }
        } catch {
            print("❌ 音频URL刷新失败: \(error.localizedDescription)")
            return currentUrl // 失败时返回原URL，让播放器尝试
        }
    }
    
    // MARK: - 批量刷新
    
    /// 批量确保章节中所有句段的音频URL有效
    /// - Parameters:
    ///   - sections: 句段列表
    ///   - bookId: 书籍ID
    ///   - chapterId: 章节ID
    /// - Returns: 更新后的句段列表
    func ensureChapterAudioUrls(
        sections: [ClassicsSectionAPI],
        bookId: String,
        chapterId: String
    ) async -> [ClassicsSectionAPI] {
        var updatedSections: [ClassicsSectionAPI] = []
        
        for section in sections {
            // 检查音频URL是否过期
            if isAudioUrlExpired(section.audioUrl) {
                print("🔄 刷新句段 \(section.sectionId) 的音频URL...")
                
                // 刷新音频URL
                if let newUrl = await ensureValidAudioUrl(
                    currentUrl: section.audioUrl,
                    bookId: bookId,
                    chapterId: chapterId,
                    sectionId: section.id,
                    voice: nil
                ) {
                    // 创建新的section对象，更新audioUrl
                    let updatedSection = ClassicsSectionAPI(
                        id: section.id,
                        sectionId: section.sectionId,
                        original: section.original,
                        pinyin: section.pinyin,
                        translation: section.translation,
                        annotation: section.annotation,
                        audioUrl: newUrl,
                        order: section.order
                    )
                    updatedSections.append(updatedSection)
                } else {
                    // 刷新失败，保留原section
                    updatedSections.append(section)
                }
            } else {
                // URL有效，保留原section
                updatedSections.append(section)
            }
        }
        
        return updatedSections
    }
    
    // MARK: - 辅助方法
    
    /// 从URL中提取过期时间戳
    /// - Parameter urlString: 音频URL字符串
    /// - Returns: 过期时间戳（秒）
    func extractExpiresTimestamp(_ urlString: String?) -> Int? {
        guard let urlString = urlString,
              let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let expiresString = components.queryItems?.first(where: { $0.name == "Expires" })?.value,
              let expiresTimestamp = Int(expiresString) else {
            return nil
        }
        
        return expiresTimestamp
    }
    
    /// 计算URL剩余有效时间（秒）
    /// - Parameter urlString: 音频URL字符串
    /// - Returns: 剩余有效时间（秒），如果已过期或无效则返回0
    func remainingValidTime(_ urlString: String?) -> Int {
        guard let expiresTimestamp = extractExpiresTimestamp(urlString) else {
            return 0
        }
        
        let currentTimestamp = Int(Date().timeIntervalSince1970)
        let remaining = expiresTimestamp - currentTimestamp
        
        return max(0, remaining)
    }
    
    /// 格式化剩余时间为可读字符串
    /// - Parameter urlString: 音频URL字符串
    /// - Returns: 格式化的时间字符串（如 "2小时30分钟"）
    func formatRemainingTime(_ urlString: String?) -> String {
        let seconds = remainingValidTime(urlString)
        
        if seconds == 0 {
            return "已过期"
        }
        
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

