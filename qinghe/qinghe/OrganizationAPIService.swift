import Foundation

/// 组织/圈子 API 服务
class OrganizationAPIService: ObservableObject {
    static let shared = OrganizationAPIService()
    
    private let networkManager = NetworkManager.shared
    private let authManager = AuthManager.shared
    
    private init() {}
    
    // MARK: - API端点
    private enum Endpoint {
        static let organizations = "/organizations"
        static let apply = "/organizations/apply"
        static let myOrganizations = "/organizations/my"
        static let ocrIdCard = "/face-verify/ocr-idcard"
        static let faceVerify = "/face-verify/verify"
        static func organizationDetail(id: String) -> String { "/organizations/\(id)" }
        static func serviceFeeOrder(applicationId: String) -> String { "/organizations/applications/\(applicationId)/service-fee-order" }
    }
    
    // MARK: - 获取我的组织列表
    /// 获取用户的组织列表
    /// - Parameters:
    ///   - status: 筛选状态 (all/owned/joined/pending)
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 组织列表响应
    func getMyOrganizations(
        status: String = "all",
        page: Int = 1,
        limit: Int = 20
    ) async throws -> OrganizationListResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        var parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        
        if status != "all" {
            parameters["status"] = status
        }
        
        let response: OrganizationListResponse = try await networkManager.get(
            endpoint: Endpoint.myOrganizations,
            parameters: parameters,
            headers: authHeaders,
            responseType: OrganizationListResponse.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取组织列表失败")
        }
        
        return response
    }
    
    // MARK: - OCR识别身份证
    /// OCR识别身份证信息
    /// - Parameters:
    ///   - imageUrl: 身份证图片URL
    ///   - side: 正反面 (front/back)
    /// - Returns: OCR识别结果
    func ocrIdCard(imageUrl: String, side: String) async throws -> OCRIdCardResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        let parameters: [String: Any] = [
            "imageUrl": imageUrl,
            "side": side
        ]
        
        let response: OCRIdCardResponse = try await networkManager.post(
            endpoint: Endpoint.ocrIdCard,
            parameters: parameters,
            headers: authHeaders,
            responseType: OCRIdCardResponse.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "OCR识别失败")
        }
        
        return response
    }
    
    // MARK: - 获取人脸核身 VerificationToken
    /// 获取人脸核身验证令牌
    /// - Parameters:
    ///   - realName: 真实姓名
    ///   - idCardNumber: 身份证号码
    ///   - metaInfo: 设备元信息（从 SDK 获取）
    /// - Returns: VerificationToken
    func getVerificationToken(realName: String, idCardNumber: String, metaInfo: String) async throws -> VerificationTokenResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let parameters: [String: Any] = [
            "realName": realName,
            "idCardNumber": idCardNumber,
            "metaInfo": metaInfo
        ]

        let response: VerificationTokenResponse = try await networkManager.post(
            endpoint: "/face-verify/get-token",
            parameters: parameters,
            headers: authHeaders,
            responseType: VerificationTokenResponse.self
        )

        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取验证令牌失败")
        }

        return response
    }

    // MARK: - 人脸核身验证（金融级）
    /// 人脸核身验证 - 基于阿里云金融级人脸识别服务
    /// - Parameters:
    ///   - realName: 真实姓名
    ///   - idCardNumber: 身份证号码
    ///   - faceImageUrl: 人脸照片URL（可选，SDK 会自动采集）
    /// - Returns: 人脸核身验证结果
    func verifyFace(realName: String, idCardNumber: String, faceImageUrl: String? = nil) async throws -> FaceVerifyResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        var parameters: [String: Any] = [
            "realName": realName,
            "idCardNumber": idCardNumber
        ]

        if let faceImageUrl = faceImageUrl {
            parameters["faceImage"] = faceImageUrl
        }

        let response: FaceVerifyResponse = try await networkManager.post(
            endpoint: Endpoint.faceVerify,
            parameters: parameters,
            headers: authHeaders,
            responseType: FaceVerifyResponse.self
        )

        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "人脸核身验证失败")
        }

        return response
    }
    
    // MARK: - 创建组织申请
    /// 创建组织申请
    /// - Parameter request: 申请请求参数
    /// - Returns: 申请结果
    func createOrganizationApplication(request: CreateOrganizationRequest) async throws -> CreateOrganizationResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        let parameters = try request.toDictionary()
        
        let response: CreateOrganizationResponse = try await networkManager.post(
            endpoint: Endpoint.apply,
            parameters: parameters,
            headers: authHeaders,
            responseType: CreateOrganizationResponse.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "创建申请失败")
        }
        
        return response
    }
    
    // MARK: - 创建服务费订单
    /// 创建服务费订单
    /// - Parameter applicationId: 申请ID
    /// - Returns: 订单信息（包含支付宝支付URL）
    func createServiceFeeOrder(applicationId: String) async throws -> ServiceFeeOrderResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: ServiceFeeOrderResponse = try await networkManager.post(
            endpoint: Endpoint.serviceFeeOrder(applicationId: applicationId),
            parameters: nil,
            headers: authHeaders,
            responseType: ServiceFeeOrderResponse.self
        )

        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "创建订单失败")
        }

        return response
    }
}

// MARK: - 数据模型

/// 组织列表响应
struct OrganizationListResponse: Codable {
    let success: Bool
    let message: String?
    let data: OrganizationListData
}

struct OrganizationListData: Codable {
    let organizations: [OrganizationCircle]
    let pagination: OrganizationPagination
}

/// 组织圈子数据模型
struct OrganizationCircle: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let category: String?
    let avatar: String?
    let coverImage: String?
    let city: String?
    let district: String?
    let address: String?
    let memberCount: Int
    let status: String?
    let role: String?
    let createdAt: String?
    let updatedAt: String?
}

/// 组织分页信息
struct OrganizationPagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}

/// OCR识别响应
struct OCRIdCardResponse: Codable {
    let status: String
    let message: String?
    let data: OCRIdCardData

    // 兼容属性
    var success: Bool {
        return status == "success"
    }
}

struct OCRIdCardData: Codable {
    let name: String?
    let idNumber: String?
    let address: String?
    let nationality: String?
    let birthDate: String?
    let gender: String?
    let issuingAuthority: String?
    let validPeriod: String?
}

/// 获取 VerificationToken 响应
struct VerificationTokenResponse: Codable {
    let status: String
    let message: String?
    let data: VerificationTokenData

    // 兼容属性
    var success: Bool {
        return status == "success"
    }
}

struct VerificationTokenData: Codable {
    let verificationToken: String
    let expiresIn: Int? // 有效期（秒）
}

/// 人脸验证响应
struct FaceVerifyResponse: Codable {
    let status: String
    let message: String?
    let data: FaceVerifyData

    // 兼容属性
    var success: Bool {
        return status == "success"
    }
}

struct FaceVerifyData: Codable {
    let verified: Bool
    let passed: Bool
    let reason: String?
    let verificationToken: String?
}

/// 创建组织请求
struct CreateOrganizationRequest: Codable {
    let name: String
    let description: String
    let category: String
    let avatar: String?
    let coverImage: String?
    let city: String
    let district: String?
    let address: String?
    let contactPhone: String
    let contactEmail: String?
    let tags: [String]?
    let rules: String?

    let realName: String
    let idCardNumber: String
    let idCardFront: String
    let idCardBack: String
    let faceImage: String

    let alipayAccount: String
    let alipayRealName: String

    let organizationType: String
    let businessLicense: String?
    let businessLicenseNumber: String?
    let companyName: String?

    func toDictionary() throws -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "description": description,
            "category": category,
            "city": city,
            "contactPhone": contactPhone,
            "realName": realName,
            "idCardNumber": idCardNumber,
            "idCardFront": idCardFront,
            "idCardBack": idCardBack,
            "faceImage": faceImage,
            "alipayAccount": alipayAccount,
            "alipayRealName": alipayRealName,
            "organizationType": organizationType
        ]

        if let avatar = avatar { dict["avatar"] = avatar }
        if let coverImage = coverImage { dict["coverImage"] = coverImage }
        if let district = district { dict["district"] = district }
        if let address = address { dict["address"] = address }
        if let contactEmail = contactEmail { dict["contactEmail"] = contactEmail }
        if let tags = tags { dict["tags"] = tags }
        if let rules = rules { dict["rules"] = rules }
        if let businessLicense = businessLicense { dict["businessLicense"] = businessLicense }
        if let businessLicenseNumber = businessLicenseNumber { dict["businessLicenseNumber"] = businessLicenseNumber }
        if let companyName = companyName { dict["companyName"] = companyName }

        return dict
    }
}

/// 创建组织响应
struct CreateOrganizationResponse: Codable {
    let status: String
    let message: String?
    let data: CreateOrganizationData

    // 兼容属性
    var success: Bool {
        return status == "success"
    }
}

struct CreateOrganizationData: Codable {
    let applicationId: String
    let organizationId: String
    let status: String
    let serviceFee: Double
    let createdAt: String
}

/// 服务费订单响应
struct ServiceFeeOrderResponse: Codable {
    let status: String
    let message: String?
    let data: ServiceFeeOrderData

    // 兼容属性
    var success: Bool {
        return status == "success"
    }
}

struct ServiceFeeOrderData: Codable {
    let orderNo: String
    let amount: Double
    let alipayUrl: String
    let createdAt: String
}

