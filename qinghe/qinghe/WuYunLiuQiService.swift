import Foundation

// 轻量占位服务：对接后端五运六气 API（先留出接口，不强制调用）
struct WuYunLiuQiAnalysis: Codable {
    // 与后端实际返回保持一致的轻量模型（字段均为可选，避免类型不匹配）
    let analysisId: Int?
    let analysisDate: String?
    let currentSolarTerm: String?

    struct FiveMovements: Codable { let element: String?; let nature: String?; let influence: String? }
    let fiveMovements: FiveMovements?

    struct SixQi: Codable { let qi: String?; let season: String?; let influence: String? }
    let sixQi: SixQi?

    struct PersonalizedAdvice: Codable { /* 简化为透传声明，若后续需要可复制 HealthProfileAPIService 的详细结构 */ }
    let personalizedAdvice: PersonalizedAdvice?

    struct ConstitutionMatch: Codable {
        let constitution: String?
        let constitutionElement: String?
        let overallLevel: String?
        let overallScore: Int?
    }
    let constitutionMatch: ConstitutionMatch?
}

enum WuYunRangeScope: String { case day = "day", week = "week", year = "year" }

class WuYunLiuQiService {
    static let shared = WuYunLiuQiService()
    private init() {}

    func fetchCurrent(scope: WuYunRangeScope = .day) async throws -> WuYunLiuQiAnalysis {
        // 先用 NetworkManager 统一基址
        let endpoint = "/health/five-elements/current?scope=\(scope.rawValue)"
        struct Resp<T: Codable>: Codable { let success: Bool; let data: T }
        let resp: Resp<WuYunLiuQiAnalysis> = try await NetworkManager.shared.get(
            endpoint: endpoint,
            parameters: nil,
            headers: nil,
            responseType: Resp<WuYunLiuQiAnalysis>.self
        )
        return resp.data
    }
}
