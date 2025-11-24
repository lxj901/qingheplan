//
//  FaceVerificationManager.swift
//  qinghe
//
//  人脸核身管理器 - 封装阿里云人脸核身 SDK
//

import Foundation
import UIKit

/// 人脸核身结果
enum FaceVerificationResult {
    case success(imageData: Data?)
    case failure(code: Int, message: String)
    case userCancelled
}

/// 人脸核身管理器（占位实现：暂时不调用阿里云 SDK）
class FaceVerificationManager: NSObject {
    static let shared = FaceVerificationManager()
    
    private override init() {
        super.init()
    }
    
    /// 初始化 SDK（在 AppDelegate 中调用）
    static func initializeSDK() {
        #if DEBUG
        print("🔐 人脸核身 SDK 已暂时禁用（未集成阿里云 SDK）")
        #endif
    }
    
    /// 获取设备元信息（用于后端 API 调用）
    func getMetaInfo() -> String {
        // 占位实现：返回空 JSON
        return "{}"
    }
    
    /// 开始人脸核身验证
    /// - Parameters:
    ///   - verificationToken: 从后端获取的验证令牌
    ///   - viewController: 当前视图控制器
    ///   - completion: 完成回调
    func startVerification(
        verificationToken: String,
        from viewController: UIViewController,
        completion: @escaping (FaceVerificationResult) -> Void
    ) {
        #if DEBUG
        print("🔍 人脸核身功能已暂时禁用，这里直接返回 success（仅供开发调试使用）")
        #endif
        
        // 你可以根据需要改成 .failure 或 .userCancelled
        completion(.success(imageData: nil))
    }
}
