import SwiftUI
import Combine

/// 创建圈子视图模型
class CreateCircleViewModel: ObservableObject {
    // MARK: - 基本信息
    @Published var circleName = ""
    @Published var description = ""
    @Published var category = "运动健身"
    @Published var city = ""
    @Published var district = ""
    @Published var address = ""
    @Published var contactPhone = ""
    @Published var contactEmail = ""
    @Published var tags: [String] = []
    @Published var rules = ""
    @Published var avatarImage: UIImage?
    @Published var coverImage: UIImage?
    @Published var organizationType = "personal" // personal/enterprise

    // MARK: - 实名认证信息
    @Published var realName = ""
    @Published var idCardNumber = ""
    @Published var idCardFrontImage: UIImage?
    @Published var idCardBackImage: UIImage?
    @Published var faceImage: UIImage?
    @Published var faceVerifyPassed = false
    @Published var faceVerifySimilarity: Double = 0

    // MARK: - 营业执照信息(企业组织)
    @Published var businessLicenseImage: UIImage?
    @Published var businessLicenseNumber = ""
    @Published var companyName = ""

    // MARK: - 支付宝信息
    @Published var alipayAccount = ""
    @Published var alipayRealName = ""

    // MARK: - UI状态
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""

    // MARK: - 图片URL缓存
    private var idCardFrontUrl: String?
    private var idCardBackUrl: String?
    private var faceImageUrl: String?
    private var avatarUrl: String?
    private var coverImageUrl: String?
    private var businessLicenseUrl: String?

    // 分类选项
    let categoryOptions = ["运动健身", "读书学习", "艺术文化", "科技创新", "公益慈善", "兴趣爱好", "其他"]

    // API服务
    private let apiService = OrganizationAPIService.shared
    private let networkManager = NetworkManager.shared
    
    // MARK: - 验证方法
    func canProceedFromStep(_ step: Int) -> Bool {
        switch step {
        case 0: // 基本信息
            return !circleName.isEmpty &&
                   !description.isEmpty &&
                   !city.isEmpty &&
                   !contactPhone.isEmpty &&
                   isValidPhone(contactPhone)
            
        case 1: // 实名认证
            if organizationType == "enterprise" {
                return !realName.isEmpty &&
                       !idCardNumber.isEmpty &&
                       idCardFrontImage != nil &&
                       idCardBackImage != nil &&
                       faceImage != nil &&
                       faceVerifyPassed &&
                       businessLicenseImage != nil &&
                       !businessLicenseNumber.isEmpty &&
                       !companyName.isEmpty
            } else {
                return !realName.isEmpty &&
                       !idCardNumber.isEmpty &&
                       idCardFrontImage != nil &&
                       idCardBackImage != nil &&
                       faceImage != nil &&
                       faceVerifyPassed
            }
            
        case 2: // 支付宝绑定
            return !alipayAccount.isEmpty &&
                   !alipayRealName.isEmpty &&
                   alipayRealName == realName
            
        case 3: // 确认提交
            return true
            
        default:
            return false
        }
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^1[3-9]\\d{9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
    
    // MARK: - OCR识别身份证
    func recognizeIDCard(image: UIImage, side: String, completion: @escaping (Bool) -> Void) {
        isLoading = true

        Task {
            do {
                // 1. 上传图片到OSS获取URL
                let uploadResponse = try await networkManager.uploadHealthImage(image, compressionQuality: 0.8)
                let imageUrl = uploadResponse.data.url

                // 缓存图片URL
                if side == "front" {
                    self.idCardFrontUrl = imageUrl
                } else {
                    self.idCardBackUrl = imageUrl
                }

                // 2. 调用OCR识别API
                let ocrResponse = try await apiService.ocrIdCard(imageUrl: imageUrl, side: side)

                await MainActor.run {
                    self.isLoading = false

                    // 填充识别结果
                    if side == "front", let data = ocrResponse.data.name {
                        self.realName = data
                        self.idCardNumber = ocrResponse.data.idNumber ?? ""
                    }

                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.alertMessage = "OCR识别失败: \(error.localizedDescription)"
                    self.showAlert = true
                    completion(false)
                    print("❌ OCR识别失败: \(error)")
                }
            }
        }
    }
    
    // MARK: - 人脸核身验证（金融级）
    func startFaceVerification(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        // 检查是否已完成身份证识别
        guard !realName.isEmpty && !idCardNumber.isEmpty else {
            alertMessage = "请先完成身份证识别"
            showAlert = true
            completion(false)
            return
        }

        isLoading = true

        Task {
            do {
                // 1. 获取设备元信息
                let metaInfo = FaceVerificationManager.shared.getMetaInfo()

                // 2. 调用后端 API 获取 VerificationToken
                let tokenResponse = try await apiService.getVerificationToken(
                    realName: realName,
                    idCardNumber: idCardNumber,
                    metaInfo: metaInfo
                )

                await MainActor.run {
                    self.isLoading = false
                }

                // 3. 使用 VerificationToken 启动人脸核身 SDK
                await MainActor.run {
                    FaceVerificationManager.shared.startVerification(
                        verificationToken: tokenResponse.data.verificationToken,
                        from: viewController
                    ) { [weak self] result in
                        guard let self = self else { return }

                        switch result {
                        case .success(let imageData):
                            // 保存人脸照片
                            if let imageData = imageData, let faceImage = UIImage(data: imageData) {
                                self.faceImage = faceImage
                            }

                            // 人脸核身成功，调用后端验证接口确认结果
                            self.confirmFaceVerification(imageData: imageData, completion: completion)

                        case .failure(let code, let message):
                            self.alertMessage = "人脸核身失败: \(message) (错误码: \(code))"
                            self.showAlert = true
                            completion(false)

                        case .userCancelled:
                            self.alertMessage = "您已取消人脸核身"
                            self.showAlert = true
                            completion(false)
                        }
                    }
                }

            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.alertMessage = "获取验证令牌失败: \(error.localizedDescription)"
                    self.showAlert = true
                    completion(false)
                    print("❌ 获取验证令牌失败: \(error)")
                }
            }
        }
    }

    // MARK: - 确认人脸核身结果
    private func confirmFaceVerification(imageData: Data?, completion: @escaping (Bool) -> Void) {
        isLoading = true

        Task {
            do {
                // 调用后端 API 确认人脸核身结果
                let verifyResponse = try await apiService.verifyFace(
                    realName: realName,
                    idCardNumber: idCardNumber,
                    faceImageUrl: nil // SDK 已完成验证，不需要传图片
                )

                await MainActor.run {
                    self.isLoading = false

                    if verifyResponse.data.passed {
                        self.faceVerifyPassed = true
                        self.faceVerifySimilarity = 99.0 // 金融级验证，默认高匹配度
                        self.alertMessage = "人脸核身验证通过！\(verifyResponse.data.reason ?? "")"
                        self.showAlert = true
                        completion(true)
                    } else {
                        self.faceVerifyPassed = false
                        self.alertMessage = verifyResponse.data.reason ?? "人脸核身验证失败"
                        self.showAlert = true
                        completion(false)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.alertMessage = "验证结果确认失败: \(error.localizedDescription)"
                    self.showAlert = true
                    completion(false)
                    print("❌ 验证结果确认失败: \(error)")
                }
            }
        }
    }
    
    // MARK: - 提交申请
    func submitApplication(completion: @escaping () -> Void) {
        isLoading = true

        Task {
            do {
                // 1. 上传所有图片到OSS
                try await uploadAllImages()

                // 2. 构建申请请求
                guard let idCardFrontUrl = self.idCardFrontUrl,
                      let idCardBackUrl = self.idCardBackUrl,
                      let faceImageUrl = self.faceImageUrl else {
                    await MainActor.run {
                        self.isLoading = false
                        self.alertMessage = "请先完成实名认证和人脸验证"
                        self.showAlert = true
                        completion()
                    }
                    return
                }

                let request = CreateOrganizationRequest(
                    name: circleName,
                    description: description,
                    category: category,
                    avatar: avatarUrl,
                    coverImage: coverImageUrl,
                    city: city,
                    district: district.isEmpty ? nil : district,
                    address: address.isEmpty ? nil : address,
                    contactPhone: contactPhone,
                    contactEmail: contactEmail.isEmpty ? nil : contactEmail,
                    tags: tags.isEmpty ? nil : tags,
                    rules: rules.isEmpty ? nil : rules,
                    realName: realName,
                    idCardNumber: idCardNumber,
                    idCardFront: idCardFrontUrl,
                    idCardBack: idCardBackUrl,
                    faceImage: faceImageUrl,
                    alipayAccount: alipayAccount,
                    alipayRealName: alipayRealName,
                    organizationType: organizationType,
                    businessLicense: businessLicenseUrl,
                    businessLicenseNumber: businessLicenseNumber.isEmpty ? nil : businessLicenseNumber,
                    companyName: companyName.isEmpty ? nil : companyName
                )

                // 3. 调用创建组织申请API
                let response = try await apiService.createOrganizationApplication(request: request)

                await MainActor.run {
                    self.isLoading = false
                    self.alertMessage = "申请提交成功！请支付\(response.data.serviceFee)元服务费后等待审核。"
                    self.showAlert = true

                    // TODO: 这里可以调用支付宝支付
                    // 暂时先完成申请流程
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        completion()
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.alertMessage = "申请提交失败: \(error.localizedDescription)"
                    self.showAlert = true
                    print("❌ 申请提交失败: \(error)")
                }
            }
        }
    }

    // MARK: - 上传所有图片
    private func uploadAllImages() async throws {
        // 上传头像（如果有）
        if let avatarImage = avatarImage, avatarUrl == nil {
            let uploadResponse = try await networkManager.uploadHealthImage(avatarImage, compressionQuality: 0.8)
            self.avatarUrl = uploadResponse.data.url
        }

        // 上传封面图（如果有）
        if let coverImage = coverImage, coverImageUrl == nil {
            let uploadResponse = try await networkManager.uploadHealthImage(coverImage, compressionQuality: 0.8)
            self.coverImageUrl = uploadResponse.data.url
        }

        // 上传人脸照片（如果有且未上传）
        if let faceImage = faceImage, faceImageUrl == nil {
            let uploadResponse = try await networkManager.uploadHealthImage(faceImage, compressionQuality: 0.8)
            self.faceImageUrl = uploadResponse.data.url
        }

        // 上传营业执照（企业组织）
        if organizationType == "enterprise", let businessLicenseImage = businessLicenseImage, businessLicenseUrl == nil {
            let uploadResponse = try await networkManager.uploadHealthImage(businessLicenseImage, compressionQuality: 0.8)
            self.businessLicenseUrl = uploadResponse.data.url
        }
    }
}

