import Foundation
import UIKit

/// 头像上传服务
class AvatarUploadService {
    static let shared = AvatarUploadService()
    
    private let networkManager = NetworkManager.shared
    private let authManager = AuthManager.shared
    
    private init() {}
    
    /// 上传头像
    /// - Parameter image: 要上传的头像图片
    /// - Returns: 上传成功后的头像URL
    func uploadAvatar(_ image: UIImage) async throws -> AvatarUploadResponse {
        // 1. 验证授权
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权，请重新登录")
        }
        
        // 2. 图片处理和压缩
        let processedImage = processAvatarImage(image)
        guard let imageData = processedImage.jpegData(compressionQuality: 0.8) else {
            throw NetworkManager.NetworkError.networkError("图片处理失败")
        }
        
        // 3. 文件大小检查
        let maxFileSize = 5 * 1024 * 1024 // 5MB，头像文件相对较小
        if imageData.count > maxFileSize {
            throw NetworkManager.NetworkError.networkError("头像文件过大，请选择小于5MB的图片")
        }
        
        print("📸 开始上传头像，文件大小: \(imageData.count) bytes")
        
        // 4. 构建上传请求
        let fullURL = "\(networkManager.baseURL)/upload/avatar"
        print("🔍 头像上传URL: \(fullURL)")
        
        let url = URL(string: fullURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60.0
        
        // 5. 设置认证头
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 6. 构建multipart请求体
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加头像文件
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // 结束边界
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // 7. 发送请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 检查HTTP响应状态
            if let httpResponse = response as? HTTPURLResponse {
                print("🖼️ 头像上传状态码: \(httpResponse.statusCode)")
                
                guard 200...299 ~= httpResponse.statusCode else {
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = errorData["message"] as? String {
                        throw NetworkManager.NetworkError.networkError("上传失败: \(message)")
                    } else {
                        throw NetworkManager.NetworkError.networkError("上传失败，状态码: \(httpResponse.statusCode)")
                    }
                }
            }
            
            // 解析响应
            let uploadResponse = try JSONDecoder().decode(AvatarUploadResponse.self, from: data)
            
            if uploadResponse.success {
                print("✅ 头像上传成功: \(uploadResponse.data.url)")
                return uploadResponse
            } else {
                throw NetworkManager.NetworkError.networkError(uploadResponse.message ?? "上传失败")
            }
            
        } catch let error as DecodingError {
            print("❌ 头像上传响应解析失败: \(error)")
            throw NetworkManager.NetworkError.networkError("服务器响应格式错误")
        } catch let error as NetworkManager.NetworkError {
            print("❌ 头像上传网络错误: \(error)")
            throw error
        } catch {
            print("❌ 头像上传未知错误: \(error)")
            throw NetworkManager.NetworkError.networkError("上传失败: \(error.localizedDescription)")
        }
    }
    
    /// 处理头像图片（压缩和调整尺寸）
    private func processAvatarImage(_ image: UIImage) -> UIImage {
        let targetSize = CGSize(width: 512, height: 512) // 头像目标尺寸
        
        // 计算缩放比例，保持宽高比
        let widthRatio = targetSize.width / image.size.width
        let heightRatio = targetSize.height / image.size.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledSize = CGSize(
            width: image.size.width * scaleFactor,
            height: image.size.height * scaleFactor
        )
        
        // 创建正方形画布
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let processedImage = renderer.image { context in
            // 填充背景色（白色）
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            
            // 计算居中位置
            let x = (targetSize.width - scaledSize.width) / 2
            let y = (targetSize.height - scaledSize.height) / 2
            let drawRect = CGRect(x: x, y: y, width: scaledSize.width, height: scaledSize.height)
            
            // 绘制图片
            image.draw(in: drawRect)
        }
        
        return processedImage
    }
}

// MARK: - 响应数据模型

/// 头像上传响应
struct AvatarUploadResponse: Codable {
    let success: Bool
    let data: AvatarData
    let message: String?
}

/// 头像数据
struct AvatarData: Codable {
    let url: String
    let thumbnails: AvatarThumbnails
    let filename: String
    let originalName: String
    let size: Int
    let mimetype: String
    let provider: String
    let metadata: AvatarMetadata?
}

/// 头像缩略图
struct AvatarThumbnails: Codable {
    let small: String   // 64x64
    let medium: String  // 128x128
    let large: String   // 256x256
}

/// 头像元数据
struct AvatarMetadata: Codable {
    let width: Int
    let height: Int
    let format: String
}

// MARK: - 错误处理扩展

extension AvatarUploadService {
    /// 获取用户友好的错误信息
    static func getUserFriendlyError(_ error: Error) -> String {
        if let networkError = error as? NetworkManager.NetworkError {
            switch networkError {
            case .networkError(let message):
                if message.contains("未授权") {
                    return "登录已过期，请重新登录"
                } else if message.contains("文件过大") {
                    return "图片文件过大，请选择小于5MB的图片"
                } else if message.contains("处理失败") {
                    return "图片格式不支持，请选择JPG或PNG格式"
                } else {
                    return message
                }
            case .noData:
                return "服务器无响应，请检查网络连接"
            case .decodingError:
                return "数据解析失败，请稍后重试"
            case .invalidURL:
                return "网络地址错误，请稍后重试"
            case .serverError(let message):
                return "服务器错误: \(message)"
            case .rateLimitExceeded:
                return "请求过于频繁，请稍后重试"
            case .serverMessage(let message):
                return message
            }
        }

        return "头像上传失败，请稍后重试"
    }
}
