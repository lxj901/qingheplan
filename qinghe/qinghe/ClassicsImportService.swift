import Foundation

// MARK: - 数据模型

/// 上传信息
struct UploadInfo: Codable {
    let uploadUrl: String
    let fileKey: String
    let expires: Int
}

/// 任务信息
struct JobInfo: Codable {
    let jobId: String
    let status: String
    let message: String
}

/// 导入状态
struct ImportStatus: Codable {
    let jobId: String
    let status: String
    let progress: Int
    let message: String
    let result: ImportResult?
    let failedReason: String?
    let logs: [String]?
}

/// 导入结果
struct ImportResult: Codable {
    let success: Bool
    let bookId: String
    let title: String
    let chaptersCount: Int
    let sectionsCount: Int
}

/// 国学经典 API 响应
struct ClassicsAPIResponse<T: Codable>: Codable {
    let code: Int
    let message: String
    let data: T?
}

// MARK: - 书籍导入服务

class ClassicsImportService {
    static let shared = ClassicsImportService()
    
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1/classics"
    private let authManager = AuthManager.shared
    
    private init() {}
    
    // MARK: - 完整导入流程
    
    /// 导入书籍
    /// - Parameters:
    ///   - fileURL: 本地文件URL
    ///   - userId: 用户ID
    ///   - bookId: 书籍ID（可选）
    ///   - category: 分类（可选）
    ///   - author: 作者（可选）
    /// - Returns: 任务ID
    func importBook(
        fileURL: URL,
        userId: Int,
        bookId: String? = nil,
        category: String? = nil,
        author: String? = nil
    ) async throws -> String {
        let originalFilename = fileURL.lastPathComponent
        print("📚 开始导入书籍: \(originalFilename)")

        // 清理文件名（移除空格和特殊字符）
        let cleanedFilename = cleanFilename(originalFilename)
        print("🧹 清理后的文件名: \(cleanedFilename)")

        // 1. 获取上传URL
        print("1️⃣ 获取上传URL...")
        let uploadInfo = try await getUploadURL(filename: cleanedFilename)
        print("✅ 获取上传URL成功: \(uploadInfo.uploadUrl)")

        // 2. 上传文件到OSS
        print("2️⃣ 读取文件数据...")
        let fileData = try Data(contentsOf: fileURL)
        print("✅ 文件大小: \(fileData.count) 字节")

        guard let uploadURL = URL(string: uploadInfo.uploadUrl) else {
            print("❌ 无效的上传URL: \(uploadInfo.uploadUrl)")
            throw NSError(domain: "URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的上传URL"])
        }

        print("3️⃣ 上传文件到OSS...")
        try await uploadToOSS(url: uploadURL, data: fileData, fileURL: fileURL)

        // 3. 完成上传
        print("4️⃣ 通知服务器完成上传...")
        let jobId = try await completeUpload(
            fileKey: uploadInfo.fileKey,
            originalName: originalFilename,  // 使用原始文件名
            userId: userId,
            bookId: bookId,
            category: category,
            author: author
        )

        print("✅ 导入任务创建成功，任务ID: \(jobId)")
        return jobId
    }

    // MARK: - 文件名清理

    /// 清理文件名，移除空格和特殊字符
    /// - Parameter filename: 原始文件名
    /// - Returns: 清理后的文件名
    private func cleanFilename(_ filename: String) -> String {
        // 分离文件名和扩展名
        let nsFilename = filename as NSString
        let nameWithoutExt = nsFilename.deletingPathExtension
        let ext = nsFilename.pathExtension

        // 清理文件名：
        // 1. 去除首尾空格
        // 2. 将中间的连续空格替换为单个下划线
        // 3. 移除其他特殊字符（保留中文、字母、数字、下划线、连字符）
        var cleaned = nameWithoutExt.trimmingCharacters(in: .whitespacesAndNewlines)

        // 将连续空格替换为单个下划线
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)

        // 移除不安全的字符（保留中文、字母、数字、下划线、连字符）
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
            .union(CharacterSet(charactersIn: "\u{4E00}"..."\u{9FFF}"))  // 中文字符范围

        cleaned = cleaned.unicodeScalars
            .filter { allowedCharacters.contains($0) }
            .map { String($0) }
            .joined()

        // 如果清理后为空，使用时间戳
        if cleaned.isEmpty {
            cleaned = "file_\(Int(Date().timeIntervalSince1970))"
        }

        // 重新组合文件名和扩展名
        return ext.isEmpty ? cleaned : "\(cleaned).\(ext)"
    }
    
    // MARK: - 获取上传URL
    
    /// 获取上传URL
    /// - Parameter filename: 文件名
    /// - Returns: 上传信息
    func getUploadURL(filename: String) async throws -> UploadInfo {
        guard let authHeaders = authManager.getAuthHeader() else {
            print("❌ 未授权，无法获取认证头")
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "未授权，请重新登录"])
        }

        guard let url = URL(string: "\(baseURL)/import/upload-url") else {
            print("❌ 无效的URL: \(baseURL)/import/upload-url")
            throw NSError(domain: "URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 添加认证头
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let fileExtension = (filename as NSString).pathExtension
        let body: [String: Any] = [
            "filename": filename,
            "filetype": ".\(fileExtension)"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("📡 请求上传URL - 文件名: \(filename), 类型: .\(fileExtension)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 无效的响应")
            throw NSError(domain: "Network", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的响应"])
        }

        print("📥 响应状态码: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            print("❌ 服务器错误: \(httpResponse.statusCode), 响应: \(errorMessage)")
            throw NSError(domain: "Network", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "服务器错误: \(httpResponse.statusCode)"])
        }

        let apiResponse = try JSONDecoder().decode(ClassicsAPIResponse<UploadInfo>.self, from: data)
        print("📦 API 响应 - code: \(apiResponse.code), message: \(apiResponse.message)")

        guard apiResponse.code == 0, let uploadInfo = apiResponse.data else {
            print("❌ API 错误 - code: \(apiResponse.code), message: \(apiResponse.message)")
            throw NSError(domain: "API", code: apiResponse.code, userInfo: [NSLocalizedDescriptionKey: apiResponse.message])
        }

        return uploadInfo
    }
    
    // MARK: - 上传到OSS
    
    /// 上传文件到OSS
    /// - Parameters:
    ///   - url: 上传URL
    ///   - data: 文件数据
    ///   - fileURL: 文件URL（用于获取MIME类型）
    func uploadToOSS(url: URL, data: Data, fileURL: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        // 根据文件扩展名设置Content-Type
        let fileExtension = fileURL.pathExtension.lowercased()
        let contentType: String
        switch fileExtension {
        case "pdf":
            contentType = "application/pdf"
        case "docx":
            contentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "doc":
            contentType = "application/msword"
        default:
            contentType = "application/octet-stream"
        }

        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的响应"])
        }

        // OSS 上传成功可能返回 200 或 204
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: responseData, encoding: .utf8) ?? "未知错误"
            print("❌ OSS 上传失败 - 状态码: \(httpResponse.statusCode), 错误: \(errorMessage)")
            throw NSError(domain: "Upload", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "文件上传失败 (状态码: \(httpResponse.statusCode))"])
        }

        print("✅ OSS 上传成功 - 状态码: \(httpResponse.statusCode)")
    }
    
    // MARK: - 完成上传
    
    /// 完成上传并开始导入
    /// - Parameters:
    ///   - fileKey: 文件键值
    ///   - originalName: 原始文件名
    ///   - userId: 用户ID
    ///   - bookId: 书籍ID（可选）
    ///   - category: 分类（可选）
    ///   - author: 作者（可选）
    /// - Returns: 任务ID
    func completeUpload(
        fileKey: String,
        originalName: String,
        userId: Int,
        bookId: String? = nil,
        category: String? = nil,
        author: String? = nil
    ) async throws -> String {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "未授权，请重新登录"])
        }

        guard let url = URL(string: "\(baseURL)/import/complete") else {
            throw NSError(domain: "URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 添加认证头
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        var body: [String: Any] = [
            "fileKey": fileKey,
            "originalName": originalName,
            "userId": userId
        ]

        if let bookId = bookId {
            body["bookId"] = bookId
        }
        if let category = category {
            body["category"] = category
        }
        if let author = author {
            body["author"] = author
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Network", code: -1, userInfo: [NSLocalizedDescriptionKey: "请求失败"])
        }

        let apiResponse = try JSONDecoder().decode(ClassicsAPIResponse<JobInfo>.self, from: data)

        guard apiResponse.code == 0, let jobInfo = apiResponse.data else {
            throw NSError(domain: "API", code: apiResponse.code, userInfo: [NSLocalizedDescriptionKey: apiResponse.message])
        }

        return jobInfo.jobId
    }
    
    // MARK: - 查询进度
    
    /// 查询导入进度
    /// - Parameter jobId: 任务ID
    /// - Returns: 导入状态
    func getImportStatus(jobId: String) async throws -> ImportStatus {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "未授权，请重新登录"])
        }

        guard let url = URL(string: "\(baseURL)/import/status/\(jobId)") else {
            throw NSError(domain: "URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
        }

        var request = URLRequest(url: url)

        // 添加认证头
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        let apiResponse = try JSONDecoder().decode(ClassicsAPIResponse<ImportStatus>.self, from: data)

        guard apiResponse.code == 0, let status = apiResponse.data else {
            throw NSError(domain: "API", code: apiResponse.code, userInfo: [NSLocalizedDescriptionKey: apiResponse.message])
        }

        return status
    }
    
    // MARK: - 轮询进度
    
    /// 轮询导入进度直到完成
    /// - Parameters:
    ///   - jobId: 任务ID
    ///   - onProgress: 进度回调
    /// - Returns: 导入结果
    func pollImportStatus(
        jobId: String,
        onProgress: @escaping (Int, String) -> Void
    ) async throws -> ImportResult {
        while true {
            let status = try await getImportStatus(jobId: jobId)
            
            // 更新进度
            onProgress(status.progress, status.message)
            
            // 检查是否完成
            if status.status == "completed" {
                guard let result = status.result else {
                    throw NSError(domain: "Import", code: -1, userInfo: [NSLocalizedDescriptionKey: "导入结果为空"])
                }
                return result
            } else if status.status == "failed" {
                throw NSError(domain: "Import", code: -1, userInfo: [NSLocalizedDescriptionKey: status.failedReason ?? "导入失败"])
            }
            
            // 等待2秒后再次查询
            try await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }
}

