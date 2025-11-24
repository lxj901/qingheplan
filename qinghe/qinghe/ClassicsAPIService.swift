import Foundation

// MARK: - 国学经典 API 数据模型

/// 书籍信息
struct ClassicsBookAPI: Codable, Identifiable {
    let id: String
    let bookId: String
    let title: String
    let category: String
    let author: String?
    let description: String?
    let coverUrl: String?
    let userId: Int?        // 导入者用户ID（新增）
    let isPublic: Bool?     // 是否公开（新增，默认为 true）
    let createdAt: String?
    let updatedAt: String?
}

/// 书籍详情（包含章节列表）
struct ClassicsBookDetail: Codable {
    let book: ClassicsBookAPI
    let chapters: [ClassicsChapterAPI]
}

/// 章节信息
struct ClassicsChapterAPI: Codable, Identifiable {
    let id: String
    let bookId: String
    let chapterId: String
    let chapterTitle: String
    let order: Int
    let createdAt: String?
}

/// 章节详情（包含句段列表）
struct ClassicsChapterDetail: Codable {
    let chapter: ClassicsChapterAPI
    let sections: [ClassicsSectionAPI]
}

/// 句段信息
struct ClassicsSectionAPI: Codable, Identifiable {
    let id: String
    let sectionId: Int
    let original: String
    let pinyin: String?
    let translation: String?
    let annotation: String?
    let audioUrl: String?
    let order: Int
}

/// 学习进度
struct ClassicsProgress: Codable {
    let id: String?
    let userId: Int
    let bookId: String
    let chapterId: String
    let sectionId: String
    let mode: String  // read=阅读, recite=背诵
    let readCount: Int?
    let reciteCount: Int?
    let lastReadAt: String?
    let difficulty: String?  // easy/normal/hard
    let hideMode: String?    // none/half/full/byChar
}

/// 学习进度记录请求
struct ClassicsProgressRequest: Codable {
    let userId: Int
    let bookId: String
    let chapterId: String
    let sectionId: String
    let mode: String
    let difficulty: String?
    let hideMode: String?
}

// MARK: - 文字范围
struct TextRange: Codable {
    let startOffset: Int
    let endOffset: Int
    let text: String
}

// MARK: - 段落信息（用于标记中的段落数据）
struct MarkSection: Codable {
    let id: String
    let original: String
    let translation: String?

    enum CodingKeys: String, CodingKey {
        case id
        case original
        case translation
    }
}

/// 标记信息（收藏、高亮、笔记）- 符合新 API 文档
struct ClassicsMark: Codable, Identifiable {
    let id: String
    let sectionId: String
    let types: [String]?             // 标记类型数组: ["highlight", "favorite", "note"] (可选)
    let isFavorite: Bool
    let highlightColor: String?      // 高亮颜色: yellow, green, blue, pink, purple
    let note: String?                // 笔记内容（可选）
    let textRange: TextRange?
    let createdAt: String
    let updatedAt: String

    // 段落信息（可选，用于兼容旧接口）
    let section: MarkSection?

    // 书籍和章节信息（笔记中心接口返回）
    let bookId: String?
    let bookTitle: String?
    let bookCoverUrl: String?
    let chapterId: String?
    let chapterTitle: String?
    let chapterOrder: Int?

    // 原文和译文（笔记中心接口直接返回在根级别）
    let original: String?
    let translation: String?

    enum CodingKeys: String, CodingKey {
        case id, sectionId, types, isFavorite, highlightColor, note, textRange
        case createdAt  // 后端返回的是驼峰命名 createdAt
        case updatedAt  // 后端返回的是驼峰命名 updatedAt
        case section
        case bookId, bookTitle, bookCoverUrl, chapterId, chapterTitle, chapterOrder
        case original, translation
    }
}

/// 带句段信息的标记（用于获取标记列表）- 保留兼容性
struct ClassicsMarkWithSection: Codable, Identifiable {
    let id: String
    let sectionId: String
    let isFavorite: Bool?
    let highlight: String?
    let note: String?
    let section: ClassicsMarkSection?
    let createdAt: String?
}

/// 标记关联的句段信息
struct ClassicsMarkSection: Codable {
    let original: String
    let bookId: String
    let chapterId: String
    let bookTitle: String?      // 书籍标题
    let chapterTitle: String?   // 章节标题
}

// MARK: - 笔记中心响应（最新优先）
struct NotesCenterLatestResponse: Codable {
    let groupBy: String              // "none"
    let total: Int
    let limit: Int
    let offset: Int
    let data: [ClassicsMark]
}

// MARK: - 笔记中心响应（按书籍分组）
struct NotesCenterBookResponse: Codable {
    let groupBy: String              // "book"
    let total: Int
    let data: [BookGroup]
}

struct BookGroup: Codable {
    let bookId: String
    let bookTitle: String
    let bookCoverUrl: String?
    let chapters: [ChapterGroup]
}

struct ChapterGroup: Codable {
    let chapterId: String
    let chapterTitle: String
    let chapterOrder: Int
    let marks: [ClassicsMark]
}

/// 复习计划
struct ClassicsReviewPlan: Codable, Identifiable {
    let id: String
    let sectionId: String
    let bookId: String
    let chapterId: String
    let original: String?
    let nextReviewAt: String
    let reviewCount: Int
    let interval: Int?
}

// MARK: - 国学经典 API 服务

class ClassicsAPIService {
    static let shared = ClassicsAPIService()
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1/classics"
    
    private init() {}
    
    // MARK: - 书籍管理
    
    /// 获取书籍列表
    /// - Parameters:
    ///   - category: 分类筛选（可选）
    ///   - q: 关键词搜索（可选）
    ///   - limit: 每页数量
    ///   - offset: 偏移量
    func getBooks(
        category: String? = nil,
        q: String? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [ClassicsBookAPI] {
        var urlString = "\(baseURL)/books?limit=\(limit)&offset=\(offset)"

        if let category = category {
            urlString += "&category=\(category)"
        }

        if let q = q {
            urlString += "&q=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }

        // ⭐ 添加用户ID参数，用于权限过滤
        if let userId = AuthManager.shared.getCurrentUserId() {
            urlString += "&userId=\(userId)"
            print("📚 获取书籍列表 - 用户ID: \(userId)")
        } else {
            print("📚 获取书籍列表 - 未登录，只显示公开书籍")
        }

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ClassicsAPIResponse<[ClassicsBookAPI]>.self, from: data)

        guard response.code == 0, let books = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }

        return books
    }
    
    /// 获取书籍详情（包含章节列表）
    /// - Parameter bookId: 书籍ID
    func getBookDetail(bookId: String) async throws -> ClassicsBookDetail {
        guard let url = URL(string: "\(baseURL)/books/\(bookId)") else {
            throw NSError(domain: "Invalid URL", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ClassicsAPIResponse<ClassicsBookDetail>.self, from: data)
        
        guard response.code == 0, let detail = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }
        
        return detail
    }
    
    // MARK: - 章节内容
    
    /// 获取章节详情（包含句段列表）
    /// - Parameters:
    ///   - bookId: 书籍ID
    ///   - chapterId: 章节ID
    func getChapterDetail(bookId: String, chapterId: String) async throws -> ClassicsChapterDetail {
        guard let url = URL(string: "\(baseURL)/books/\(bookId)/chapters/\(chapterId)") else {
            throw NSError(domain: "Invalid URL", code: -1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ClassicsAPIResponse<ClassicsChapterDetail>.self, from: data)

        guard response.code == 0, let detail = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }

        return detail
    }

    /// 确保句段音频生成（用于刷新过期的音频URL）
    /// - Parameters:
    ///   - bookId: 书籍ID
    ///   - chapterId: 章节ID
    ///   - sectionId: 句段ID
    ///   - voice: 音色（可选）
    /// - Returns: 音频URL
    func ensureAudio(bookId: String, chapterId: String, sectionId: String, voice: String? = nil) async throws -> String? {
        guard let url = URL(string: "\(baseURL)/books/\(bookId)/chapters/\(chapterId)/sections/\(sectionId)/ensure-audio") else {
            throw NSError(domain: "Invalid URL", code: -1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 如果指定了音色，添加到请求体
        if let voice = voice {
            let body = ["voice": voice]
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, _) = try await URLSession.shared.data(for: request)

        // 定义响应数据结构
        struct EnsureAudioResponse: Codable {
            let audioUrl: String?
            let duration: Double?
            let voice: String?
            let existed: Bool?
        }

        let response = try JSONDecoder().decode(ClassicsAPIResponse<EnsureAudioResponse>.self, from: data)

        guard response.code == 0, let audioData = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }

        print("✅ ensureAudio 成功 - audioUrl: \(audioData.audioUrl ?? "nil"), existed: \(audioData.existed ?? false)")

        return audioData.audioUrl
    }
    
    // MARK: - 学习进度
    
    /// 记录学习进度
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - bookId: 书籍ID
    ///   - chapterId: 章节ID
    ///   - sectionId: 句段ID
    ///   - mode: 模式（read/recite）
    ///   - difficulty: 难度（可选）
    ///   - hideMode: 隐藏模式（可选）
    func recordProgress(
        userId: Int,
        bookId: String,
        chapterId: String,
        sectionId: String,
        mode: String = "read",
        difficulty: String? = nil,
        hideMode: String? = nil
    ) async throws -> ClassicsProgress {
        guard let url = URL(string: "\(baseURL)/progress") else {
            throw NSError(domain: "Invalid URL", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证头
        if let authHeaders = AuthManager.shared.getAuthHeader() {
            for (key, value) in authHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let progressRequest = ClassicsProgressRequest(
            userId: userId,
            bookId: bookId,
            chapterId: chapterId,
            sectionId: sectionId,
            mode: mode,
            difficulty: difficulty,
            hideMode: hideMode
        )
        
        request.httpBody = try JSONEncoder().encode(progressRequest)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ClassicsAPIResponse<ClassicsProgress>.self, from: data)
        
        guard response.code == 0, let progress = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }
        
        return progress
    }
    
    /// 获取用户学习进度
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - bookId: 书籍ID（可选）
    func getProgress(userId: Int, bookId: String? = nil) async throws -> [ClassicsProgress] {
        var urlString = "\(baseURL)/progress?userId=\(userId)"

        if let bookId = bookId {
            urlString += "&bookId=\(bookId)"
        }

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 添加认证头
        if let authHeaders = AuthManager.shared.getAuthHeader() {
            for (key, value) in authHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ClassicsAPIResponse<[ClassicsProgress]>.self, from: data)

        guard response.code == 0, let progressList = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }

        return progressList
    }

    // MARK: - 标记功能

    // MARK: - 标记功能（新 API）

    /// 创建标记
    /// - Parameters:
    ///   - sectionId: 段落ID
    ///   - textRange: 选中的文字范围（可选）
    ///   - highlightColor: 高亮颜色（可选）yellow/green/blue/pink/purple
    ///   - note: 笔记内容（可选）
    ///   - isFavorite: 是否收藏
    /// - Returns: 创建的标记
    func createMark(
        sectionId: String,
        textRange: TextRange? = nil,
        highlightColor: String? = nil,
        note: String? = nil,
        isFavorite: Bool = false
    ) async throws -> ClassicsMark {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            throw NSError(domain: "Auth Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }

        print("📝 创建标记: sectionId=\(sectionId), color=\(highlightColor ?? "nil"), favorite=\(isFavorite)")

        var parameters: [String: Any] = [
            "userId": userId,
            "sectionId": sectionId,
            "isFavorite": isFavorite
        ]

        if let textRange = textRange {
            parameters["textRange"] = [
                "startOffset": textRange.startOffset,
                "endOffset": textRange.endOffset,
                "text": textRange.text
            ]
        }

        if let highlightColor = highlightColor {
            parameters["highlightColor"] = highlightColor
        }

        if let note = note, !note.isEmpty {
            parameters["note"] = note
        }

        let response: ClassicsAPIResponse<ClassicsMark> = try await NetworkManager.shared.post(
            endpoint: "/classics/text-marks",
            parameters: parameters,
            headers: nil,
            responseType: ClassicsAPIResponse<ClassicsMark>.self
        )

        guard response.code == 0, let mark = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }

        print("✅ 标记创建成功: \(mark.id)")
        return mark
    }

    /// 更新标记
    /// - Parameters:
    ///   - markId: 标记ID
    ///   - highlightColor: 高亮颜色（可选）
    ///   - note: 笔记内容（可选）
    ///   - isFavorite: 是否收藏（可选）
    /// - Returns: 更新后的标记
    func updateMark(
        markId: String,
        highlightColor: String? = nil,
        note: String? = nil,
        isFavorite: Bool? = nil
    ) async throws -> ClassicsMark {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            throw NSError(domain: "Auth Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }

        print("📝 更新标记: markId=\(markId)")

        var parameters: [String: Any] = [
            "userId": userId
        ]

        if let highlightColor = highlightColor {
            parameters["highlightColor"] = highlightColor
        }

        if let note = note {
            parameters["note"] = note
        }

        if let isFavorite = isFavorite {
            parameters["isFavorite"] = isFavorite
        }

        let response: ClassicsAPIResponse<ClassicsMark> = try await NetworkManager.shared.put(
            endpoint: "/classics/text-marks/\(markId)",
            parameters: parameters,
            headers: nil,
            responseType: ClassicsAPIResponse<ClassicsMark>.self
        )

        guard response.code == 0, let mark = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }

        print("✅ 标记更新成功")
        return mark
    }

    /// 删除标记
    /// - Parameter markId: 标记ID
    func deleteMark(markId: String) async throws {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            throw NSError(domain: "Auth Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }

        print("🗑️ 删除标记: markId=\(markId)")

        let parameters: [String: Any] = [
            "userId": userId
        ]

        struct DeleteResponse: Codable {
            let success: Bool
        }

        let response: ClassicsAPIResponse<DeleteResponse> = try await NetworkManager.shared.delete(
            endpoint: "/classics/text-marks/\(markId)",
            parameters: parameters,
            headers: nil,
            responseType: ClassicsAPIResponse<DeleteResponse>.self
        )

        guard response.code == 0 else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }

        print("✅ 标记删除成功")
    }

    /// 获取某个段落的所有标记
    /// - Parameter sectionId: 段落ID
    /// - Returns: 标记数组
    func getSectionMarks(sectionId: String) async throws -> [ClassicsMark] {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            throw NSError(domain: "Auth Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }

        print("📖 获取段落标记: sectionId=\(sectionId)")

        let parameters: [String: Any] = [
            "userId": userId
        ]

        let response: ClassicsAPIResponse<[ClassicsMark]> = try await NetworkManager.shared.get(
            endpoint: "/classics/sections/\(sectionId)/marks",
            parameters: parameters,
            headers: nil,
            responseType: ClassicsAPIResponse<[ClassicsMark]>.self
        )

        guard response.code == 0, let marks = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }

        print("✅ 获取到 \(marks.count) 个标记")
        return marks
    }

    /// 添加/更新标记（收藏、高亮、笔记）- 兼容旧代码
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - sectionId: 句段ID
    ///   - isFavorite: 是否收藏（可选）
    ///   - highlight: 高亮颜色 (yellow/green/blue/pink/purple)（可选）
    ///   - note: 笔记内容（可选）
    /// - Returns: 标记信息
    func addOrUpdateMark(
        userId: Int,
        sectionId: String,
        isFavorite: Bool? = nil,
        highlight: String? = nil,
        note: String? = nil
    ) async throws -> ClassicsMark {
        // 使用新的 createMark 方法
        return try await createMark(
            sectionId: sectionId,
            textRange: nil,
            highlightColor: highlight,
            note: note,
            isFavorite: isFavorite ?? false
        )
    }

    /// 获取笔记中心数据（最新优先）
    /// - Parameters:
    ///   - type: 筛选类型 (all/favorite/highlight/note)
    ///   - bookId: 书籍ID（可选）
    ///   - limit: 限制数量
    ///   - offset: 偏移量
    /// - Returns: 笔记中心响应
    func getNotesCenterLatest(
        type: String = "all",
        bookId: String? = nil,
        limit: Int = 100,
        offset: Int = 0
    ) async throws -> NotesCenterLatestResponse {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            throw NSError(domain: "Auth Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }

        print("📚 获取笔记中心数据: type=\(type), limit=\(limit), offset=\(offset)")

        var parameters: [String: Any] = [
            "userId": userId,
            "type": type,
            "sortBy": "latest",
            "limit": limit,
            "offset": offset
        ]

        if let bookId = bookId {
            parameters["bookId"] = bookId
        }

        let response: ClassicsAPIResponse<NotesCenterLatestResponse> = try await NetworkManager.shared.get(
            endpoint: "/classics/notes-center",
            parameters: parameters,
            headers: nil,
            responseType: ClassicsAPIResponse<NotesCenterLatestResponse>.self
        )

        guard response.code == 0, let data = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }

        print("✅ 获取到 \(data.total) 个标记")
        return data
    }

    /// 获取笔记中心数据（按书籍分组）
    /// - Parameters:
    ///   - type: 筛选类型 (all/favorite/highlight/note)
    ///   - bookId: 书籍ID（可选）
    /// - Returns: 笔记中心响应
    func getNotesCenterByBook(
        type: String = "all",
        bookId: String? = nil
    ) async throws -> NotesCenterBookResponse {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            throw NSError(domain: "Auth Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }

        print("📚 获取笔记中心数据（按书籍分组）: type=\(type)")

        var parameters: [String: Any] = [
            "userId": userId,
            "type": type,
            "sortBy": "book"
        ]

        if let bookId = bookId {
            parameters["bookId"] = bookId
        }

        let response: ClassicsAPIResponse<NotesCenterBookResponse> = try await NetworkManager.shared.get(
            endpoint: "/classics/notes-center",
            parameters: parameters,
            headers: nil,
            responseType: ClassicsAPIResponse<NotesCenterBookResponse>.self
        )

        guard response.code == 0, let data = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }

        print("✅ 获取到 \(data.total) 个标记，涉及 \(data.data.count) 本书")
        return data
    }

    /// 获取用户的标记列表
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - bookId: 书籍ID（可选）
    ///   - isFavorite: 只获取收藏（可选）
    /// - Returns: 标记列表
    func getMarks(
        userId: Int,
        bookId: String? = nil,
        isFavorite: Bool? = nil
    ) async throws -> [ClassicsMarkWithSection] {
        var urlString = "\(baseURL)/marks?userId=\(userId)"

        if let bookId = bookId {
            urlString += "&bookId=\(bookId)"
        }

        if let isFavorite = isFavorite {
            urlString += "&isFavorite=\(isFavorite)"
        }

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 添加认证头
        if let authHeaders = AuthManager.shared.getAuthHeader() {
            for (key, value) in authHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ClassicsAPIResponse<[ClassicsMarkWithSection]>.self, from: data)

        guard response.code == 0, let marks = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }

        print("✅ 成功获取标记列表: \(marks.count) 条")
        return marks
    }

    // MARK: - 复习计划

    /// 获取复习列表
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - dueOnly: 只获取到期的复习项（可选，默认 true）
    /// - Returns: 复习计划列表
    func getReviewList(userId: Int, dueOnly: Bool = true) async throws -> [ClassicsReviewPlan] {
        var urlString = "\(baseURL)/review/list?userId=\(userId)&dueOnly=\(dueOnly)"

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 添加认证头
        if let authHeaders = AuthManager.shared.getAuthHeader() {
            for (key, value) in authHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ClassicsAPIResponse<[ClassicsReviewPlan]>.self, from: data)

        guard response.code == 0, let reviewList = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }

        print("✅ 成功获取复习列表: \(reviewList.count) 条")
        return reviewList
    }

    // MARK: - TTS 音频

    /// 获取章节播放列表
    /// - Parameters:
    ///   - bookId: 书籍ID
    ///   - chapterId: 章节ID
    /// - Returns: 播放列表
    func getChapterPlaylist(bookId: String, chapterId: String) async throws -> ChapterPlaylist {
        let urlString = "\(baseURL)/books/\(bookId)/chapters/\(chapterId)/playlist"
        print("📻 请求播放列表 URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60  // 增加超时时间到 60 秒

        // 重试逻辑：最多重试 2 次
        var lastError: Error?
        for attempt in 1...3 {
            do {
                print("📻 尝试获取播放列表 (第 \(attempt) 次)...")

                let (data, response) = try await URLSession.shared.data(for: request)

                // 打印响应状态码
                if let httpResponse = response as? HTTPURLResponse {
                    print("📻 响应状态码: \(httpResponse.statusCode)")

                    // 如果是 504 超时，等待后重试
                    if httpResponse.statusCode == 504 {
                        print("⚠️ 服务器超时，等待 3 秒后重试...")
                        try await Task.sleep(nanoseconds: 3_000_000_000)  // 等待 3 秒
                        continue
                    }
                }

                // 打印原始响应用于调试
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📻 播放列表 API 响应: \(jsonString.prefix(500))...")
                }

                let decodedResponse = try JSONDecoder().decode(ClassicsAPIResponse<ChapterPlaylist>.self, from: data)

                guard decodedResponse.code == 0, let playlist = decodedResponse.data else {
                    throw NSError(domain: "API Error", code: decodedResponse.code, userInfo: [NSLocalizedDescriptionKey: decodedResponse.message])
                }

                print("✅ 成功获取播放列表，共 \(playlist.items.count) 个音频")
                return playlist

            } catch {
                lastError = error
                print("❌ 第 \(attempt) 次尝试失败: \(error.localizedDescription)")

                // 如果不是最后一次尝试，等待后重试
                if attempt < 3 {
                    try await Task.sleep(nanoseconds: 2_000_000_000)  // 等待 2 秒
                }
            }
        }

        // 所有重试都失败，抛出最后一个错误
        throw lastError ?? NSError(domain: "Unknown Error", code: -1)
    }

    /// 获取TTS音色列表
    /// - Returns: 音色列表
    func getTTSVoices() async throws -> [TTSVoice] {
        guard let url = URL(string: "\(baseURL)/tts/voices") else {
            throw NSError(domain: "Invalid URL", code: -1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request)

        // 打印原始响应用于调试
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🎤 TTS Voices API 响应: \(jsonString)")
        }

        // 定义响应数据结构
        struct TTSVoicesResponse: Codable {
            let voices: [TTSVoice]
        }

        let response = try JSONDecoder().decode(ClassicsAPIResponse<TTSVoicesResponse>.self, from: data)

        guard response.code == 0, let voicesData = response.data else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.message])
        }

        return voicesData.voices
    }
}

// MARK: - 播放列表数据模型

/// 章节播放列表
struct ChapterPlaylist: Codable {
    let bookId: String
    let chapterId: String
    let items: [PlaylistItem]
    let totalDuration: Double?  // 总时长（秒），由后端计算
}

/// 播放列表项
struct PlaylistItem: Codable, Identifiable {
    let id: String
    let sectionId: Int
    let original: String
    let audioUrl: String?
    let duration: Double?
}

/// TTS音色
struct TTSVoice: Codable, Identifiable {
    let voiceId: String
    let description: String

    // 兼容两种API格式
    let recommended: Bool?      // 旧格式：使用 recommended 字段
    let category: String?       // 新格式：使用 category 字段
    let gender: String?         // 性别（可选）
    let dialect: String?        // 方言类型（可选）

    var id: String { voiceId }

    // 计算属性：获取音色名称（从 description 中提取）
    var name: String {
        // description 格式: "芊悦 - 阳光积极、亲切自然小姐姐"
        // 提取 "-" 前面的部分作为名称
        if let dashIndex = description.firstIndex(of: "-") {
            return String(description[..<dashIndex]).trimmingCharacters(in: .whitespaces)
        }
        return description
    }

    // 计算属性：获取分类（兼容两种格式）
    var voiceCategory: String {
        // 优先使用 category 字段
        if let category = category {
            return category
        }
        // 否则根据 recommended 字段判断
        if let recommended = recommended {
            return recommended ? "recommended" : "dialect"
        }
        // 默认为推荐
        return "recommended"
    }

    // 是否为推荐音色
    var isRecommended: Bool {
        return voiceCategory == "recommended"
    }
}

// MARK: - 排行榜和推荐书籍数据模型

/// 书籍排行榜数据模型
struct BookRanking: Codable, Identifiable {
    let id: String
    let bookId: String
    let title: String
    let category: String
    let author: String
    let coverUrl: String?
    let readCount: Int
    let rank: Int
    let rankChange: Int
    let lastRank: Int?
    let updatedDate: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, bookId, title, category, author, coverUrl
        case readCount, rank, rankChange, lastRank, updatedDate
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // 排名变化状态
    var rankTrend: RankTrend {
        if lastRank == nil {
            return .new
        } else if rankChange > 0 {
            return .up
        } else if rankChange < 0 {
            return .down
        } else {
            return .stable
        }
    }
}

/// 排名变化趋势
enum RankTrend {
    case up      // 上升
    case down    // 下降
    case stable  // 不变
    case new     // 新上榜
}

/// 推荐书籍数据模型
struct RecommendedBook: Codable, Identifiable {
    let id: String
    let bookId: String
    let title: String
    let category: String
    let author: String
    let description: String
    let coverUrl: String?
    let readCount: Int
    let isRecommended: Bool
    let recommendedAt: String?
    let recommendOrder: Int
    let createdAt: String?  // 改为可选，后端可能不返回
    let updatedAt: String?  // 改为可选，后端可能不返回
}

/// 排行榜 API 响应
struct BookRankingResponse: Codable {
    let code: Int
    let message: String
    let data: [BookRanking]
}

/// 推荐书籍 API 响应
struct RecommendedBooksResponse: Codable {
    let code: Int
    let message: String
    let data: [RecommendedBook]
}

// MARK: - ClassicsAPIService 扩展：排行榜和推荐功能

extension ClassicsAPIService {

    /// 获取书籍排行榜
    /// - Parameters:
    ///   - category: 分类筛选（可选）
    ///   - limit: 返回数量，最大100
    ///   - offset: 偏移量，用于分页
    /// - Returns: 排行榜数据数组
    func fetchBookRankings(
        category: String? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [BookRanking] {
        var components = URLComponents(string: "\(baseURL)/rankings/books")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]

        // 分类参数需要URL编码
        if let category = category, category != "全部" {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
        }

        print("📊 获取排行榜: category=\(category ?? "全部"), limit=\(limit), offset=\(offset)")
        print("📊 请求URL: \(url.absoluteString)")

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(BookRankingResponse.self, from: data)

        guard response.code == 0 else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [
                NSLocalizedDescriptionKey: response.message
            ])
        }

        print("✅ 成功获取 \(response.data.count) 条排行榜数据")
        return response.data
    }

    /// 获取推荐书籍
    /// - Parameter limit: 返回数量，最大50
    /// - Returns: 推荐书籍数组
    func fetchRecommendedBooks(limit: Int = 10) async throws -> [RecommendedBook] {
        var components = URLComponents(string: "\(baseURL)/recommended")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        guard let url = components.url else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
        }

        print("⭐ 获取推荐书籍: limit=\(limit)")
        print("⭐ 请求URL: \(url.absoluteString)")

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(RecommendedBooksResponse.self, from: data)

        guard response.code == 0 else {
            throw NSError(domain: "API Error", code: response.code, userInfo: [
                NSLocalizedDescriptionKey: response.message
            ])
        }

        print("✅ 成功获取 \(response.data.count) 条推荐书籍")
        return response.data
    }
}

