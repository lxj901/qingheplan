import Foundation
import AVFoundation

// MARK: - 视频服务类
class VideoService {
    static let shared = VideoService()
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1"

    private var authToken: String? {
        return AuthManager.shared.getToken()
    }

    // MARK: - 上传视频

    /// 上传视频到服务器
    /// - Parameters:
    ///   - videoURL: 本地视频文件URL
    ///   - title: 视频标题
    ///   - description: 视频描述（可选）
    ///   - category: 分类（可选）
    ///   - tags: 标签数组（可选）
    ///   - progressHandler: 上传进度回调 (0.0-1.0)
    ///   - completion: 完成回调
    func uploadVideo(
        videoURL: URL,
        title: String,
        description: String? = nil,
        category: String? = nil,
        tags: [String]? = nil,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (Result<VideoUploadResponse, Error>) -> Void
    ) {
        guard let uploadURL = URL(string: "\(baseURL)/videos/upload") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // 添加视频文件
        do {
            let videoData = try Data(contentsOf: videoURL)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"video\"; filename=\"video.mp4\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
            body.append(videoData)
            body.append("\r\n".data(using: .utf8)!)
        } catch {
            completion(.failure(error))
            return
        }

        // 添加其他字段
        let fields: [String: String?] = [
            "title": title,
            "description": description,
            "category": category,
            "tags": tags?.joined(separator: ",")
        ]

        for (key, value) in fields {
            guard let value = value else { continue }
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        // 配置长超时时间（1GB文件需要）
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 600 // 10分钟
        config.timeoutIntervalForResource = 1200 // 20分钟

        let session = URLSession(configuration: config)
        let task = session.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }

            // 打印响应数据用于调试
            if let responseString = String(data: data, encoding: .utf8) {
                print("📹 视频上传响应: \(responseString)")
            }

            // 检查HTTP状态码
            if let httpResponse = response as? HTTPURLResponse {
                print("📹 HTTP状态码: \(httpResponse.statusCode)")

                // 如果状态码不是2xx，尝试解析错误信息
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = errorJson["message"] as? String {
                        completion(.failure(NSError(domain: "VideoUploadError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                    } else {
                        completion(.failure(NSError(domain: "VideoUploadError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "上传失败，HTTP状态码: \(httpResponse.statusCode)"])))
                    }
                    return
                }
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(VideoUploadResponse.self, from: data)
                completion(.success(result))
            } catch {
                print("❌ 解析错误: \(error)")
                // 提供更详细的错误信息
                completion(.failure(NSError(domain: "VideoUploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "服务器响应格式错误: \(error.localizedDescription)"])))
            }
        }

        // 监听上传进度
        let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                progressHandler?(progress.fractionCompleted)
            }
        }

        task.resume()
    }

    // MARK: - 获取视频处理状态

    /// 查询视频的审核和转码状态
    func getVideoStatus(videoId: String, completion: @escaping (Result<VideoStatusResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/videos/\(videoId)/status") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📹 状态查询HTTP: \(httpResponse.statusCode)")
            }
            if let str = String(data: data, encoding: .utf8) {
                print("📹 状态查询响应: \(str)")
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(VideoStatusResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - 发布视频

    /// 手动发布视频（审核通过后调用）
    func publishVideo(videoId: String, completion: @escaping (Result<UpdateVideoResponse, Error>) -> Void) {
        updateVideo(videoId: videoId, updates: ["publishStatus": "published"], completion: completion)
    }

    // MARK: - 获取视频详情

    /// 获取视频详情，包括播放URL和多清晰度版本
    func getVideoDetail(videoId: String, completion: @escaping (Result<VideoDetailResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/videos/\(videoId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(VideoDetailResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - 删除视频

    /// 删除视频（仅作者可删除）
    func deleteVideo(videoId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/videos/\(videoId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "DeleteFailed", code: -1)))
            }
        }.resume()
    }

    // MARK: - 点赞相关

    /// 点赞视频
    func likeVideo(videoId: String, completion: @escaping (Result<VideoLikeResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/videos/\(videoId)/like") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(VideoLikeResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    /// 取消点赞视频
    func unlikeVideo(videoId: String, completion: @escaping (Result<VideoLikeResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/videos/\(videoId)/like") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(VideoLikeResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - 收藏相关

    /// 收藏视频
    func favoriteVideo(videoId: String, completion: @escaping (Result<VideoFavoriteResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/videos/\(videoId)/favorite") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(VideoFavoriteResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    /// 取消收藏视频
    func unfavoriteVideo(videoId: String, completion: @escaping (Result<VideoFavoriteResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/videos/\(videoId)/favorite") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(VideoFavoriteResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - 更新视频信息

    private func updateVideo(
        videoId: String,
        updates: [String: Any],
        completion: @escaping (Result<UpdateVideoResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/videos/\(videoId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: updates)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(UpdateVideoResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - 数据模型

/// 视频上传响应
struct VideoUploadResponse: Codable {
    let status: String
    let message: String?
    let data: VideoUploadData

    struct VideoUploadData: Codable {
        let videoId: String
        let title: String
        let originalUrl: String
        let duration: Double
        let size: Int64
        let resolution: String?
        let status: String?              // 后端data中可能不返回该字段
        let transcodeStatus: String
        let moderationStatus: String
        let uploadedAt: String?          // 后端data中可能不返回该字段
        let message: String?
        let canTranscode: Bool?

        private enum CodingKeys: String, CodingKey {
            case videoId, title, originalUrl, duration, size, resolution, status, transcodeStatus, moderationStatus, uploadedAt, message, canTranscode
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            videoId = try container.decode(String.self, forKey: .videoId)
            title = try container.decode(String.self, forKey: .title)
            originalUrl = try container.decode(String.self, forKey: .originalUrl)

            // duration: Double or String
            if let d = try? container.decode(Double.self, forKey: .duration) {
                duration = d
            } else if let s = try? container.decode(String.self, forKey: .duration), let d = Double(s) {
                duration = d
            } else {
                throw DecodingError.typeMismatch(Double.self, DecodingError.Context(codingPath: [CodingKeys.duration], debugDescription: "Expected Double or String for duration"))
            }

            // size: Int64 or Int or String
            if let i64 = try? container.decode(Int64.self, forKey: .size) {
                size = i64
            } else if let i = try? container.decode(Int.self, forKey: .size) {
                size = Int64(i)
            } else if let s = try? container.decode(String.self, forKey: .size), let i64 = Int64(s) {
                size = i64
            } else {
                throw DecodingError.typeMismatch(Int64.self, DecodingError.Context(codingPath: [CodingKeys.size], debugDescription: "Expected Int/Int64 or String for size"))
            }

            resolution = try? container.decode(String.self, forKey: .resolution)
            status = try? container.decode(String.self, forKey: .status)
            transcodeStatus = (try? container.decode(String.self, forKey: .transcodeStatus)) ?? "pending"
            moderationStatus = (try? container.decode(String.self, forKey: .moderationStatus)) ?? "pending"
            uploadedAt = try? container.decode(String.self, forKey: .uploadedAt)
            message = try? container.decode(String.self, forKey: .message)
            canTranscode = try? container.decode(Bool.self, forKey: .canTranscode)
        }
    }
}

/// 视频状态响应
struct VideoStatusResponse: Codable {
    let status: String
    let message: String?
    let data: VideoStatusData

    struct VideoStatusData: Codable {
        let videoId: String
        let publishStatus: String           // draft/published/private
        let moderationStatus: String        // pending/reviewing/approved/rejected
        let moderationResult: ModerationResult?
        let transcodeStatus: String         // pending/processing/completed/failed
        let transcodeProgress: Int
        let transcodeCompletedAt: String?
        let error: String?
        let canPlay: Bool

        // 计算属性：是否可以发布
        var canPublish: Bool {
            return moderationStatus == "approved" && publishStatus == "draft"
        }

        // 兼容旧的message字段
        var message: String? {
            return error
        }
    }
}

/// 审核结果
struct ModerationResult: Codable {
    let action: String
    let message: String
    let queriedAt: String
}

/// 更新视频响应
struct UpdateVideoResponse: Codable {
    let status: String
    let data: UpdatedVideoData

    struct UpdatedVideoData: Codable {
        let id: String
        let title: String
        let status: String?
        let publishStatus: String?
        let transcodeStatus: String
        let message: String?
    }
}

/// 视频详情响应
struct VideoDetailResponse: Codable {
    let status: String
    let data: VideoDetail
}

/// 视频详情
struct VideoDetail: Codable {
    let id: String
    let title: String
    let description: String?
    let thumbnailUrl: String
    let playUrl: String  // HLS播放URL (.m3u8)
    let versions: VideoVersions
    let duration: Double
    let resolution: String
    let viewsCount: Int
    let likesCount: Int
    let commentsCount: Int
    let favoritesCount: Int
    let category: String?
    let tags: [String]?
    let status: String
    let transcodeStatus: String
    let moderationStatus: String
    let uploader: VideoUploader
    let isLiked: Bool
    let isFavorited: Bool
    let canPlay: Bool
    let canDownload: Bool
    let createdAt: String
    let publishedAt: String?
}

/// 视频清晰度版本
struct VideoVersions: Codable {
    let hd: VideoVersion?  // 1080p
    let sd: VideoVersion?  // 720p
    let ld: VideoVersion?  // 480p
}

/// 视频版本信息
struct VideoVersion: Codable {
    let quality: String  // "1080p", "720p", "480p"
    let url: String      // HLS URL
    let size: Int64      // 文件大小（字节）
    let bitrate: Int     // 码率（kbps）
}

/// 视频上传者信息
struct VideoUploader: Codable {
    let id: String
    let phone: String?
    let qingheId: String?
    let avatarUrl: String?
    let nickname: String?
}

/// 视频点赞响应
struct VideoLikeResponse: Codable {
    let status: String
    let data: VideoLikeData

    struct VideoLikeData: Codable {
        let videoId: String
        let isLiked: Bool
        let likesCount: Int
    }
}

/// 视频收藏响应
struct VideoFavoriteResponse: Codable {
    let status: String
    let data: VideoFavoriteData

    struct VideoFavoriteData: Codable {
        let videoId: String
        let isFavorited: Bool
        let favoritesCount: Int
    }
}
