import Foundation

// MARK: - API 错误类型
enum NewWorkoutAPIError: Error, LocalizedError {
    case noToken
    case invalidResponse
    case rateLimited
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "未找到认证令牌"
        case .invalidResponse:
            return "无效的响应"
        case .rateLimited:
            return "请求频率过高"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .cancelled:
            return "请求已取消"
        }
    }
}

// MARK: - API 响应类型
struct NewAPIResponse<T: Codable>: Codable {
    let status: String
    let message: String
    let data: T?

    // 计算属性，用于判断是否成功
    var isSuccess: Bool {
        return status == "success"
    }

    enum CodingKeys: String, CodingKey {
        case status
        case message
        case data
    }
}

struct NewWorkoutListData: Codable {
    let workouts: [ServerWorkout]
    let totalCount: Int?
    let hasMore: Bool?

    func toStandardWorkoutList() -> [QingheWorkout] {
        return workouts.map { $0.toQingheWorkout() }
    }
}

// 服务器实际返回的运动记录格式
struct ServerWorkout: Codable {
    let workoutId: String  // 服务器返回字符串类型
    let workoutType: String
    let startTime: String
    let duration: Int
    let basicMetrics: ServerBasicMetrics
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case workoutId, workoutType, startTime, duration, basicMetrics, createdAt
    }

    func toQingheWorkout() -> QingheWorkout {
        return QingheWorkout(
            workoutId: Int(workoutId) ?? 0,  // 转换字符串为整数
            workoutType: workoutType,
            startTime: startTime,
            endTime: startTime,  // 如果没有endTime，使用startTime
            duration: duration,
            basicMetrics: WorkoutBasicMetrics(
                totalDistance: Double(basicMetrics.totalDistance) ?? 0.0,
                totalSteps: 0,  // 服务器没有返回，使用默认值
                calories: basicMetrics.calories,
                averagePace: 0.0,  // 服务器没有返回，使用默认值
                maxSpeed: 0.0   // 服务器没有返回，使用默认值
            ),
            advancedMetrics: nil,
            notes: nil
        )
    }
}

// 服务器返回的基础指标格式
struct ServerBasicMetrics: Codable {
    let totalDistance: String  // 服务器返回字符串类型
    let calories: Int

    enum CodingKeys: String, CodingKey {
        case totalDistance, calories
    }
}

struct SimpleOperationResult: Codable {
    let success: Bool
    let message: String?
}

// 创建运动记录的响应数据模型
struct CreateWorkoutResponseData: Codable {
    let workoutId: String
    let userId: Int
    let workoutType: String
    let startTime: String
    let endTime: String
    let duration: Int
    let basicMetrics: BasicMetricsResponse
    let createdAt: String
    let updatedAt: String
}

// 服务器返回的基础指标格式
struct BasicMetricsResponse: Codable {
    let totalDistance: String
    let totalSteps: Int
    let calories: Int
    let averagePace: String
    let maxSpeed: String
}

// MARK: - 运动数据管理API数据模型

// 创建运动记录请求模型
struct CreateWorkoutRequest: Codable {
    let workoutType: String
    let startTime: String
    let endTime: String
    let duration: Int
    let basicMetrics: BasicMetricsForAPI
    let advancedMetrics: AdvancedMetricsForAPI?
    let routeData: RouteDataForAPI?
    let deviceInfo: DeviceInfoForAPI
    let weatherInfo: WeatherInfoForAPI?
    let notes: String?
}

struct BasicMetricsForAPI: Codable {
    let totalDistance: Double
    let totalSteps: Int
    let calories: Int
    let averagePace: Double
    let maxSpeed: Double
}

struct AdvancedMetricsForAPI: Codable {
    let averageHeartRate: Int?
    let maxHeartRate: Int?
    let averageCadence: Int?
    let elevationGain: Double?
    let elevationLoss: Double?
}

struct RouteDataForAPI: Codable {
    let coordinates: [GPSCoordinateForAPI]
}

struct GPSCoordinateForAPI: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: String
    let altitude: Double?
}

struct DeviceInfoForAPI: Codable {
    let deviceType: String
    let appVersion: String
    let osVersion: String?
}

struct WeatherInfoForAPI: Codable {
    let temperature: Int?
    let humidity: Int?
    let weather: String?
}

// 今日运动数据响应模型
struct TodayWorkoutsResponse: Codable {
    let status: String
    let message: String
    let data: TodayWorkoutsData
}

struct TodayWorkoutsData: Codable {
    let date: String
    let workouts: [WorkoutDetailForAPI]
    let statistics: WorkoutStatisticsForAPI
    let typeDistribution: [TypeDistributionForAPI]
    let hourlyDistribution: [String: Int]
    let qualityAnalysis: QualityAnalysisForAPI
}

// 服务器返回的运动详情格式
struct ServerWorkoutDetail: Codable {
    let workoutId: String
    let workoutType: String
    let startTime: String
    let endTime: String
    let duration: Int
    let basicMetrics: ServerBasicMetricsDetail
    let advancedMetrics: ServerAdvancedMetricsDetail?
    let routeData: RouteDataForAPI?

    func toWorkoutDetailForAPI() -> WorkoutDetailForAPI {
        return WorkoutDetailForAPI(
            workoutId: workoutId,
            workoutType: workoutType,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            basicMetrics: BasicMetricsForAPI(
                totalDistance: Double(basicMetrics.totalDistance) ?? 0.0,
                totalSteps: basicMetrics.totalSteps ?? 0,
                calories: basicMetrics.calories,
                averagePace: Double(basicMetrics.averagePace ?? "0.0") ?? 0.0,
                maxSpeed: Double(basicMetrics.maxSpeed ?? "0.0") ?? 0.0
            ),
            advancedMetrics: advancedMetrics?.toAdvancedMetricsForAPI(),
            routeData: routeData
        )
    }
}

// 服务器返回的基础指标详情格式
struct ServerBasicMetricsDetail: Codable {
    let totalDistance: String  // 服务器返回字符串
    let totalSteps: Int?
    let calories: Int
    let averagePace: String?   // 服务器返回字符串
    let maxSpeed: String?      // 服务器返回字符串
}

// 服务器返回的高级指标详情格式
struct ServerAdvancedMetricsDetail: Codable {
    let averageHeartRate: Int?
    let maxHeartRate: Int?
    let averageCadence: Int?
    let elevationGain: String?  // 服务器返回字符串类型
    let elevationLoss: String?  // 服务器返回字符串类型

    func toAdvancedMetricsForAPI() -> AdvancedMetricsForAPI {
        return AdvancedMetricsForAPI(
            averageHeartRate: averageHeartRate,
            maxHeartRate: maxHeartRate,
            averageCadence: averageCadence,
            elevationGain: elevationGain != nil ? Double(elevationGain!) : nil,  // 转换字符串为Double
            elevationLoss: elevationLoss != nil ? Double(elevationLoss!) : nil   // 转换字符串为Double
        )
    }
}

struct WorkoutDetailForAPI: Codable {
    let workoutId: String
    let workoutType: String
    let startTime: String
    let endTime: String
    let duration: Int
    let basicMetrics: BasicMetricsForAPI
    let advancedMetrics: AdvancedMetricsForAPI?
    let routeData: RouteDataForAPI?
}

struct WorkoutStatisticsForAPI: Codable {
    let totalWorkouts: Int
    let totalDistance: Double
    let totalDuration: Int
    let totalCalories: Int
    let totalSteps: Int
}

struct TypeDistributionForAPI: Codable {
    let workoutType: String
    let count: Int
    let totalDuration: Int
    let totalCalories: Int
}

struct QualityAnalysisForAPI: Codable {
    let validWorkouts: Int
    let shortWorkouts: Int
    let averageDuration: Int
    let averageDistance: Double
    let averageCalories: Int
}

// 运动统计数据响应模型
struct WorkoutStatisticsResponse: Codable {
    let status: String
    let message: String
    let data: WorkoutStatisticsData
}

struct WorkoutStatisticsData: Codable {
    let period: String
    let workoutType: String?
    let statistics: WorkoutStatisticsForAPI?
    let trends: [WorkoutTrendData]?
    let achievements: [WorkoutAchievement]?

    // 实际API响应的直接统计字段
    let totalWorkouts: Int?
    let totalDistance: Double?
    let totalDuration: Int?
    let totalCalories: Int?
    let totalSteps: Int?
    let averageDistance: Double?
    let averageDuration: Int?

    // 实际API响应的新字段
    let weeklyTrend: [WorkoutWeeklyTrendData]?
    let workoutTypeBreakdown: [String: Int]?

    // 提供一个计算属性来获取统计数据
    var effectiveStatistics: WorkoutStatisticsForAPI {
        if let statistics = statistics {
            return statistics
        } else {
            // 如果没有嵌套的statistics对象，尝试从直接字段构建
            return WorkoutStatisticsForAPI(
                totalWorkouts: totalWorkouts ?? 0,
                totalDistance: totalDistance ?? 0.0,
                totalDuration: totalDuration ?? 0,
                totalCalories: totalCalories ?? 0,
                totalSteps: totalSteps ?? 0
            )
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        period = try container.decode(String.self, forKey: .period)
        workoutType = try container.decodeIfPresent(String.self, forKey: .workoutType)

        // 尝试解码嵌套的statistics对象
        statistics = try container.decodeIfPresent(WorkoutStatisticsForAPI.self, forKey: .statistics)

        // 尝试解码可选的数组
        trends = try container.decodeIfPresent([WorkoutTrendData].self, forKey: .trends) ?? []
        achievements = try container.decodeIfPresent([WorkoutAchievement].self, forKey: .achievements) ?? []

        // 解码直接的统计字段
        totalWorkouts = try container.decodeIfPresent(Int.self, forKey: .totalWorkouts)
        totalDistance = try container.decodeIfPresent(Double.self, forKey: .totalDistance)
        totalDuration = try container.decodeIfPresent(Int.self, forKey: .totalDuration)
        totalCalories = try container.decodeIfPresent(Int.self, forKey: .totalCalories)
        totalSteps = try container.decodeIfPresent(Int.self, forKey: .totalSteps)
        averageDistance = try container.decodeIfPresent(Double.self, forKey: .averageDistance)
        averageDuration = try container.decodeIfPresent(Int.self, forKey: .averageDuration)

        // 解码新的字段
        weeklyTrend = try container.decodeIfPresent([WorkoutWeeklyTrendData].self, forKey: .weeklyTrend) ?? []
        workoutTypeBreakdown = try container.decodeIfPresent([String: Int].self, forKey: .workoutTypeBreakdown) ?? [:]
    }

    private enum CodingKeys: String, CodingKey {
        case period, workoutType, statistics, trends, achievements
        case totalWorkouts, totalDistance, totalDuration, totalCalories, totalSteps
        case averageDistance, averageDuration, weeklyTrend, workoutTypeBreakdown
    }
}

struct WorkoutTrendData: Codable {
    let date: String
    let value: Double
    let type: String // duration, distance, calories, count
}

struct WorkoutWeeklyTrendData: Codable {
    let week: String
    let startDate: String
    let endDate: String
    let workouts: Int
    let distance: Double
    let calories: Int
}

struct WorkoutAchievement: Codable {
    let type: String
    let title: String
    let description: String
    let achievedAt: String
}

/// 新的运动数据API服务类
class NewWorkoutAPIService {

    static let shared = NewWorkoutAPIService()
    private init() {}

    // MARK: - 常量配置
    private let baseURL = "https://api.qinghejihua.com.cn"
    private let apiVersion = "v1"

    // MARK: - 运动数据管理API方法
    
    // MARK: - 获取运动记录列表
    func getWorkouts(
        page: Int = 1,
        limit: Int = 10,
        workoutType: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        sortBy: String? = nil,
        sortOrder: String? = nil
    ) async throws -> [QingheWorkout] {
        
        guard let token = AuthManager.shared.getToken() else {
            throw NewWorkoutAPIError.noToken
        }
        
        // 构建URL
        var components = URLComponents(string: "\(baseURL)/api/\(apiVersion)/workouts")!
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        // 添加可选参数
        if let workoutType = workoutType {
            queryItems.append(URLQueryItem(name: "workoutType", value: workoutType))
        }
        if let startDate = startDate {
            queryItems.append(URLQueryItem(name: "startDate", value: startDate))
        }
        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "endDate", value: endDate))
        }
        if let sortBy = sortBy {
            queryItems.append(URLQueryItem(name: "sortBy", value: sortBy))
        }
        if let sortOrder = sortOrder {
            queryItems.append(URLQueryItem(name: "sortOrder", value: sortOrder))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw NewWorkoutAPIError.invalidResponse
        }
        
        // 构建请求
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // 增加超时时间到30秒
        
        print("🌐 发起API请求: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 检查HTTP状态码
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 API响应状态码: \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 200:
                    break // 成功
                case 401:
                    throw NewWorkoutAPIError.noToken
                case 429:
                    throw NewWorkoutAPIError.rateLimited
                case 400...499:
                    throw NewWorkoutAPIError.serverError("客户端错误: \(httpResponse.statusCode)")
                case 500...599:
                    throw NewWorkoutAPIError.serverError("服务器错误: \(httpResponse.statusCode)")
                default:
                    throw NewWorkoutAPIError.serverError("未知错误: \(httpResponse.statusCode)")
                }
            }
            
            // 打印原始响应数据用于调试
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📝 API原始响应: \(jsonString.prefix(500))...")
            }
            
            // 解析响应
            let apiResponse = try JSONDecoder().decode(NewAPIResponse<NewWorkoutListData>.self, from: data)

            if apiResponse.isSuccess {
                let workouts = apiResponse.data?.workouts ?? []
                print("✅ 成功获取 \(workouts.count) 条运动记录")

                // 转换为兼容的格式
                return workouts.map { $0.toQingheWorkout() }
            } else {
                throw NewWorkoutAPIError.serverError(apiResponse.message)
            }
            
        } catch let error as DecodingError {
            print("❌ JSON解析错误: \(error)")
            throw NewWorkoutAPIError.decodingError(error)
        } catch let error as NewWorkoutAPIError {
            print("❌ API错误: \(error.localizedDescription)")
            throw error
        } catch {
            // 检查是否是任务取消错误
            if (error as NSError).code == NSURLErrorCancelled {
                print("ℹ️ 请求被取消 (这通常是正常的，当用户快速切换筛选条件时)")
                throw NewWorkoutAPIError.cancelled
            }
            print("❌ 网络错误: \(error.localizedDescription)")
            throw NewWorkoutAPIError.networkError(error)
        }
    }
    
    // MARK: - 获取单个运动记录详情
    func getWorkout(workoutId: Int) async throws -> QingheWorkout {
        guard let token = AuthManager.shared.getToken() else {
            throw NewWorkoutAPIError.noToken
        }
        
        let url = URL(string: "\(baseURL)/api/\(apiVersion)/workouts/\(workoutId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                throw NewWorkoutAPIError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            let apiResponse = try JSONDecoder().decode(NewAPIResponse<NewWorkout>.self, from: data)
            
            if apiResponse.isSuccess, let workout = apiResponse.data {
                return workout.toQingheWorkout()
            } else {
                throw NewWorkoutAPIError.serverError(apiResponse.message)
            }
            
        } catch let error as DecodingError {
            throw NewWorkoutAPIError.decodingError(error)
        } catch let error as NewWorkoutAPIError {
            throw error
        } catch {
            throw NewWorkoutAPIError.networkError(error)
        }
    }
    
    // MARK: - 创建运动记录
    func createWorkout(_ workout: NewWorkout) async throws -> Bool {
        guard let token = AuthManager.shared.getToken() else {
            throw NewWorkoutAPIError.noToken
        }

        let url = URL(string: "\(baseURL)/api/\(apiVersion)/workouts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            // 编码请求数据 - 使用不包含workoutId的版本
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let uploadData = workout.forAPIUpload()
            request.httpBody = try encoder.encode(uploadData)

            // 打印请求信息用于调试
            print("🏃‍♂️ 创建运动记录请求:")
            print("URL: \(url)")
            print("Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let bodyData = request.httpBody,
               let bodyString = String(data: bodyData, encoding: .utf8) {
                print("Body: \(bodyString)")
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            // 详细的HTTP响应处理
            if let httpResponse = response as? HTTPURLResponse {
                print("🏃‍♂️ 运动数据上传响应状态码: \(httpResponse.statusCode)")

                // 打印响应数据用于调试
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🏃‍♂️ 服务器响应: \(responseString)")
                }

                // 处理不同的HTTP状态码
                switch httpResponse.statusCode {
                case 200:
                    // 成功，继续处理
                    break
                case 400:
                    // 解析400错误的详细信息
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let errorMessage = errorResponse["message"] as? String ?? "请求参数错误"
                        let errorCode = errorResponse["code"] as? Int
                        print("❌ HTTP 400 错误详情: \(errorMessage)")
                        if let code = errorCode {
                            print("❌ 错误代码: \(code)")
                        }
                        throw NewWorkoutAPIError.serverError("HTTP 400: \(errorMessage)")
                    } else {
                        throw NewWorkoutAPIError.serverError("HTTP 400: 请求参数错误")
                    }
                case 401:
                    throw NewWorkoutAPIError.serverError("HTTP 401: 认证失败，请重新登录")
                case 403:
                    throw NewWorkoutAPIError.serverError("HTTP 403: 权限不足")
                case 404:
                    throw NewWorkoutAPIError.serverError("HTTP 404: 接口不存在")
                case 429:
                    throw NewWorkoutAPIError.rateLimited
                case 500...599:
                    throw NewWorkoutAPIError.serverError("HTTP \(httpResponse.statusCode): 服务器内部错误")
                default:
                    throw NewWorkoutAPIError.serverError("HTTP \(httpResponse.statusCode): 未知错误")
                }
            }

            let apiResponse = try JSONDecoder().decode(NewAPIResponse<CreateWorkoutResponseData>.self, from: data)

            if apiResponse.isSuccess {
                print("✅ 运动数据创建成功，workoutId: \(apiResponse.data?.workoutId ?? "未知")")
                return true
            } else {
                print("❌ 运动数据创建失败: \(apiResponse.message)")
                throw NewWorkoutAPIError.serverError("创建失败: \(apiResponse.message)")
            }

        } catch let error as DecodingError {
            print("❌ 运动数据编码/解码错误: \(error)")
            print("❌ DecodingError 详情: \(error.localizedDescription)")
            throw NewWorkoutAPIError.decodingError(error)
        } catch let error as NewWorkoutAPIError {
            print("❌ 重新抛出 NewWorkoutAPIError: \(error)")
            throw error
        } catch {
            print("❌ 运动数据上传网络错误: \(error)")
            print("❌ 错误类型: \(type(of: error))")
            print("❌ 错误描述: \(error.localizedDescription)")
            throw NewWorkoutAPIError.networkError(error)
        }
    }
    
    // MARK: - 删除运动记录
    func deleteWorkout(workoutId: Int) async throws -> Bool {
        guard let token = AuthManager.shared.getToken() else {
            throw NewWorkoutAPIError.noToken
        }
        
        let url = URL(string: "\(baseURL)/api/\(apiVersion)/workouts/\(workoutId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                throw NewWorkoutAPIError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            let apiResponse = try JSONDecoder().decode(NewAPIResponse<SimpleOperationResult>.self, from: data)
            return apiResponse.isSuccess
            
        } catch let error as DecodingError {
            throw NewWorkoutAPIError.decodingError(error)
        } catch let error as NewWorkoutAPIError {
            throw error
        } catch {
            throw NewWorkoutAPIError.networkError(error)
        }
    }
    

    
    // MARK: - 更新运动记录
    func updateWorkout(workoutId: Int, workout: NewWorkout) async throws -> Bool {
        guard let token = AuthManager.shared.getToken() else {
            throw NewWorkoutAPIError.noToken
        }
        
        let url = URL(string: "\(baseURL)/api/\(apiVersion)/workouts/\(workoutId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(workout)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                throw NewWorkoutAPIError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            let apiResponse = try JSONDecoder().decode(NewAPIResponse<SimpleOperationResult>.self, from: data)
            return apiResponse.isSuccess
            
        } catch let error as DecodingError {
            throw NewWorkoutAPIError.decodingError(error)
        } catch let error as NewWorkoutAPIError {
            throw error
        } catch {
            throw NewWorkoutAPIError.networkError(error)
        }
    }

    // MARK: - 新的运动数据管理API方法

    /// 创建运动记录（基于API文档）
    func createWorkoutRecord(_ request: CreateWorkoutRequest) async throws -> CreateWorkoutResponseData {
        guard let token = AuthManager.shared.getToken() else {
            throw NewWorkoutAPIError.noToken
        }

        let url = URL(string: "\(baseURL)/api/\(apiVersion)/workouts")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            urlRequest.httpBody = try encoder.encode(request)

            print("🌐 创建运动记录请求: \(url.absoluteString)")

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 创建运动记录响应状态码: \(httpResponse.statusCode)")

                guard httpResponse.statusCode == 200 else {
                    throw NewWorkoutAPIError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }

            let apiResponse = try JSONDecoder().decode(NewAPIResponse<CreateWorkoutResponseData>.self, from: data)

            if apiResponse.isSuccess, let workoutData = apiResponse.data {
                print("✅ 运动记录创建成功: \(workoutData.workoutId)")
                return workoutData
            } else {
                throw NewWorkoutAPIError.serverError(apiResponse.message)
            }

        } catch let error as DecodingError {
            print("❌ 创建运动记录解码错误: \(error)")
            throw NewWorkoutAPIError.decodingError(error)
        } catch let error as NewWorkoutAPIError {
            throw error
        } catch {
            print("❌ 创建运动记录网络错误: \(error)")
            throw NewWorkoutAPIError.networkError(error)
        }
    }

    /// 获取今日运动数据
    func getTodayWorkouts() async throws -> TodayWorkoutsData {
        guard let token = AuthManager.shared.getToken() else {
            throw NewWorkoutAPIError.noToken
        }

        let url = URL(string: "\(baseURL)/api/\(apiVersion)/workouts/today")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        print("🌐 获取今日运动数据请求: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 今日运动数据响应状态码: \(httpResponse.statusCode)")

                guard httpResponse.statusCode == 200 else {
                    throw NewWorkoutAPIError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }

            let apiResponse = try JSONDecoder().decode(TodayWorkoutsResponse.self, from: data)

            if apiResponse.status == "success" {
                print("✅ 成功获取今日运动数据")
                return apiResponse.data
            } else {
                throw NewWorkoutAPIError.serverError(apiResponse.message)
            }

        } catch let error as DecodingError {
            print("❌ 今日运动数据解码错误: \(error)")
            throw NewWorkoutAPIError.decodingError(error)
        } catch let error as NewWorkoutAPIError {
            throw error
        } catch {
            print("❌ 今日运动数据网络错误: \(error)")
            throw NewWorkoutAPIError.networkError(error)
        }
    }

    /// 获取运动统计数据
    func getWorkoutStatistics(
        period: String = "week",
        workoutType: String? = nil
    ) async throws -> WorkoutStatisticsData {
        guard let token = AuthManager.shared.getToken() else {
            throw NewWorkoutAPIError.noToken
        }

        var components = URLComponents(string: "\(baseURL)/api/\(apiVersion)/workouts/statistics")!
        var queryItems = [URLQueryItem(name: "period", value: period)]

        if let workoutType = workoutType {
            queryItems.append(URLQueryItem(name: "workoutType", value: workoutType))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw NewWorkoutAPIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        print("🌐 获取运动统计数据请求: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 运动统计数据响应状态码: \(httpResponse.statusCode)")

                guard httpResponse.statusCode == 200 else {
                    throw NewWorkoutAPIError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }

            // 打印原始响应数据用于调试
            if let responseString = String(data: data, encoding: .utf8) {
                print("📡 运动统计数据原始响应: \(responseString)")
            }

            let apiResponse = try JSONDecoder().decode(WorkoutStatisticsResponse.self, from: data)

            if apiResponse.status == "success" {
                print("✅ 成功获取运动统计数据")
                return apiResponse.data
            } else {
                throw NewWorkoutAPIError.serverError(apiResponse.message)
            }

        } catch let error as DecodingError {
            print("❌ 运动统计数据解码错误: \(error)")
            throw NewWorkoutAPIError.decodingError(error)
        } catch let error as NewWorkoutAPIError {
            throw error
        } catch {
            print("❌ 运动统计数据网络错误: \(error)")
            throw NewWorkoutAPIError.networkError(error)
        }
    }

    /// 获取单个运动记录详情
    func getWorkoutDetail(workoutId: String) async throws -> WorkoutDetailForAPI {
        guard let token = AuthManager.shared.getToken() else {
            throw NewWorkoutAPIError.noToken
        }

        let url = URL(string: "\(baseURL)/api/\(apiVersion)/workouts/\(workoutId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        print("🌐 获取运动详情请求: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 运动详情响应状态码: \(httpResponse.statusCode)")

                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 404 {
                        throw NewWorkoutAPIError.serverError("运动记录不存在")
                    }
                    throw NewWorkoutAPIError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }

            // 先尝试解码为服务器格式
            let apiResponse = try JSONDecoder().decode(NewAPIResponse<ServerWorkoutDetail>.self, from: data)

            if apiResponse.isSuccess, let serverWorkoutDetail = apiResponse.data {
                print("✅ 成功获取运动详情")
                // 转换为标准格式
                return serverWorkoutDetail.toWorkoutDetailForAPI()
            } else {
                throw NewWorkoutAPIError.serverError(apiResponse.message)
            }

        } catch let error as DecodingError {
            print("❌ 运动详情解码错误: \(error)")
            throw NewWorkoutAPIError.decodingError(error)
        } catch let error as NewWorkoutAPIError {
            throw error
        } catch {
            print("❌ 运动详情网络错误: \(error)")
            throw NewWorkoutAPIError.networkError(error)
        }
    }
}

