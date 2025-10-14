import Foundation

/// 会员订阅相关 API 服务
class MembershipAPIService {
    static let shared = MembershipAPIService()
    private init() {}

    // 获取会员状态
    func getStatus() async throws -> MembershipStatusResponse {
        let response: MembershipStatusResponse = try await NetworkManager.shared.get(
            endpoint: APIEndpoints.membershipStatus,
            parameters: nil,
            headers: nil,
            responseType: MembershipStatusResponse.self
        )
        guard response.isSuccess else {
            throw NetworkManager.NetworkError.serverMessage(response.message ?? "获取会员状态失败")
        }
        return response
    }

    // 获取套餐列表
    func getPlans() async throws -> MembershipPlansResponse {
        let response: MembershipPlansResponse = try await NetworkManager.shared.get(
            endpoint: APIEndpoints.membershipPlans,
            parameters: nil,
            headers: nil,
            responseType: MembershipPlansResponse.self
        )
        guard response.isSuccess else {
            throw NetworkManager.NetworkError.serverMessage(response.message ?? "获取套餐列表失败")
        }
        return response
    }

    // 获取订阅历史
    func getHistory(page: Int = 1, limit: Int = 10) async throws -> MembershipHistoryResponse {
        let response: MembershipHistoryResponse = try await NetworkManager.shared.get(
            endpoint: APIEndpoints.membershipHistory,
            parameters: ["page": page, "limit": limit],
            headers: nil,
            responseType: MembershipHistoryResponse.self
        )
        guard response.isSuccess else {
            throw NetworkManager.NetworkError.serverMessage(response.message ?? "获取订阅历史失败")
        }
        return response
    }

    // 取消自动续费
    func cancelAutoRenew() async throws -> MembershipCancelAutoRenewResponse {
        let response: MembershipCancelAutoRenewResponse = try await NetworkManager.shared.post(
            endpoint: APIEndpoints.membershipCancelAutoRenew,
            parameters: nil,
            headers: nil,
            responseType: MembershipCancelAutoRenewResponse.self
        )
        guard response.isSuccess else {
            throw NetworkManager.NetworkError.serverMessage(response.message ?? "取消自动续费失败")
        }
        return response
    }
}

