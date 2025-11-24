import Foundation
import SwiftUI

/// 创建专栏/合集 ViewModel
class CreateCollectionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var type: CollectionType = .column
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var coverImage: String = ""
    @Published var visibility: CollectionVisibility = .public
    
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    
    @Published var isUploadingImage: Bool = false
    @Published var uploadProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let creatorAPIService = CreatorAPIService.shared
    
    // MARK: - Computed Properties
    
    /// 表单是否有效
    var isFormValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty && trimmedTitle.count <= 200
    }
    
    /// 标题字数统计
    var titleCharacterCount: Int {
        title.count
    }
    
    /// 标题是否超出限制
    var isTitleOverLimit: Bool {
        title.count > 200
    }
    
    // MARK: - Public Methods
    
    /// 创建专栏/合集
    func createCollection() async -> Bool {
        guard isFormValid else {
            await MainActor.run {
                showErrorMessage("请填写标题（最多200字）")
            }
            return false
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let request = CreateCollectionRequest(
                type: type.rawValue,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.isEmpty ? nil : description,
                coverImage: coverImage.isEmpty ? nil : coverImage,
                visibility: visibility.rawValue
            )
            
            let response = try await creatorAPIService.createCollection(request: request)
            
            await MainActor.run {
                isLoading = false
                UserFeedbackManager.shared.showSuccess("\(type.displayName)创建成功")
            }
            
            return true
            
        } catch {
            await MainActor.run {
                isLoading = false
                NetworkErrorHandler.shared.handleError(error)
            }
            return false
        }
    }
    
    /// 上传封面图
    func uploadCoverImage(_ image: UIImage) async {
        await MainActor.run {
            isUploadingImage = true
            uploadProgress = 0.0
        }
        
        do {
            let uploadResponse = try await AvatarUploadService.shared.uploadAvatar(image)
            
            await MainActor.run {
                coverImage = uploadResponse.data.url
                isUploadingImage = false
                print("✅ 封面图上传成功: \(uploadResponse.data.url)")
            }
            
        } catch {
            await MainActor.run {
                isUploadingImage = false
                let errorMessage = AvatarUploadService.getUserFriendlyError(error)
                showErrorMessage(errorMessage)
                print("❌ 封面图上传失败: \(error)")
            }
        }
    }
    
    /// 验证表单
    func validateForm() -> Bool {
        // 检查标题
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            showErrorMessage("请输入\(type.displayName)标题")
            return false
        }
        
        if trimmedTitle.count > 200 {
            showErrorMessage("标题不能超过200字")
            return false
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - 数据模型

/// 专栏/合集类型
enum CollectionType: String, CaseIterable {
    case column = "column"
    case collection = "collection"
    
    var displayName: String {
        switch self {
        case .column: return "专栏"
        case .collection: return "合集"
        }
    }
    
    var icon: String {
        switch self {
        case .column: return "folder.fill"
        case .collection: return "square.stack.3d.up.fill"
        }
    }
}

/// 可见性
enum CollectionVisibility: String, CaseIterable {
    case `public` = "public"
    case `private` = "private"
    
    var displayName: String {
        switch self {
        case .public: return "公开"
        case .private: return "私密"
        }
    }
}

