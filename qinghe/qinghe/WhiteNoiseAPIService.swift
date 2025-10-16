import Foundation

// MARK: - 白噪音数据模型
struct WhiteNoise: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let category: String
    let duration: Int
    let audioUrl: String
    let coverUrl: String
    let playCount: Int
    let likeCount: Int
    let tags: [String]?
    let description: String
    let format: String
    let fileSize: Int?
    let createdAt: String
    let updatedAt: String?
}

// MARK: - 分类数据模型
struct WhiteNoiseCategory: Codable, Identifiable, Hashable {
    let category: String
    let name: String
    let count: Int
    let totalPlays: Int
    
    var id: String { category }
}

// MARK: - 分页数据模型
struct PaginatedResponse<T: Codable>: Codable {
    let list: [T]
    let pagination: Pagination
}

struct Pagination: Codable {
    let total: Int
    let page: Int
    let limit: Int
    let pages: Int
}

// MARK: - 白噪音 API 服务
class WhiteNoiseAPIService {
    static let shared = WhiteNoiseAPIService()
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1"
    
    private init() {}
    
    // 获取分类列表
    func getCategories(completion: @escaping (Result<[WhiteNoiseCategory], Error>) -> Void) {
        let url = URL(string: "\(baseURL)/white-noise/categories")!
        performRequest(url: url, completion: completion)
    }
    
    // 获取白噪音列表
    func getWhiteNoiseList(
        category: String? = nil,
        page: Int = 1,
        limit: Int = 20,
        completion: @escaping (Result<PaginatedResponse<WhiteNoise>, Error>) -> Void
    ) {
        var components = URLComponents(string: "\(baseURL)/white-noise")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        performRequest(url: url, completion: completion)
    }
    
    // 获取白噪音详情
    func getWhiteNoiseDetail(
        id: Int,
        completion: @escaping (Result<WhiteNoise, Error>) -> Void
    ) {
        let url = URL(string: "\(baseURL)/white-noise/\(id)")!
        performRequest(url: url, completion: completion)
    }
    
    // 记录播放
    func recordPlay(
        id: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let url = URL(string: "\(baseURL)/white-noise/\(id)/play")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }.resume()
    }
    
    // 获取推荐白噪音
    func getRecommendations(
        limit: Int = 6,
        completion: @escaping (Result<[WhiteNoise], Error>) -> Void
    ) {
        var components = URLComponents(string: "\(baseURL)/white-noise/recommendations")!
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        
        guard let url = components.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        performRequest(url: url, completion: completion)
    }
    
    // 通用请求方法
    private func performRequest<T: Codable>(
        url: URL,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                }
                return
            }
            
            do {
                let apiResponse = try JSONDecoder().decode(APIResponse<T>.self, from: data)
                DispatchQueue.main.async {
                    if let responseData = apiResponse.data {
                        completion(.success(responseData))
                    } else {
                        completion(.failure(NSError(domain: "WhiteNoiseAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: apiResponse.message ?? "数据为空"])))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

