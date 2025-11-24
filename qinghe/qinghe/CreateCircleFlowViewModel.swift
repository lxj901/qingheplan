import SwiftUI
import PhotosUI

/// 创建圈子流程 ViewModel
class CreateCircleFlowViewModel: ObservableObject {
    // MARK: - Step 1: 基本信息
    @Published var circleName = ""
    @Published var circleBio = ""
    
    // MARK: - Step 2: 图片
    @Published var avatarImage: UIImage?
    @Published var bgImage: UIImage?
    @Published var selectedAvatarItem: PhotosPickerItem?
    @Published var selectedBgItem: PhotosPickerItem?
    
    // MARK: - Step 3: 分类
    @Published var selectedCategory: CircleCategory?
    
    // MARK: - Step 4: 地址
    @Published var address = ""
    
    // MARK: - Step 5: 电话
    @Published var phone = ""
    
    // MARK: - Step 6: 身份证
    @Published var idCardFrontImage: UIImage?
    @Published var idCardBackImage: UIImage?
    @Published var isRealNameVerified = false
    @Published var realName = ""
    @Published var idCardNumber = ""
    
    // MARK: - Step 7: 活体检测
    @Published var faceImage: UIImage?
    @Published var isLivenessPassed = false
    
    // MARK: - Step 8: 营业执照
    @Published var businessLicenseImage: UIImage?
    @Published var selectedLicenseItem: PhotosPickerItem?
    
    // MARK: - Step 9: 支付方式
    @Published var paymentMethod: PaymentMethod = .alipay
    
    // MARK: - 状态
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - 验证方法
    func canProceedFromStep(_ step: Int) -> Bool {
        switch step {
        case 1:
            return !circleName.isEmpty && !circleBio.isEmpty
        case 2:
            return avatarImage != nil && bgImage != nil
        case 3:
            return selectedCategory != nil
        case 4:
            return !address.isEmpty
        case 5:
            return phone.count == 11
        case 6:
            return isRealNameVerified
        case 7:
            return isLivenessPassed
        case 8:
            return businessLicenseImage != nil
        case 9:
            return true
        default:
            return false
        }
    }
    
    // MARK: - 模拟 OCR 识别
    func simulateOCR() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isRealNameVerified = true
            self.realName = "张*三"
            self.idCardNumber = "310***********0000"
            self.isLoading = false
        }
    }
    
    // MARK: - 模拟活体检测
    func simulateLiveness() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isLivenessPassed = true
            self.isLoading = false
        }
    }
    
    // MARK: - 提交支付
    func submitPayment(completion: @escaping () -> Void) {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            completion()
        }
    }
    
    // MARK: - 处理图片选择
    func loadAvatarImage() {
        guard let item = selectedAvatarItem else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.avatarImage = image
                }
            }
        }
    }
    
    func loadBgImage() {
        guard let item = selectedBgItem else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.bgImage = image
                }
            }
        }
    }
    
    func loadLicenseImage() {
        guard let item = selectedLicenseItem else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.businessLicenseImage = image
                }
            }
        }
    }
}

// MARK: - 数据模型
struct CircleCategory: Identifiable, Hashable {
    let id: Int
    let name: String
    let icon: String
}

enum PaymentMethod {
    case alipay
    case wechat
}

