import Foundation
import HealthKit

final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    // Anchors and queries
    private var heartRateAnchor: HKQueryAnchor?
    private var heartRateQuery: HKAnchoredObjectQuery?

    private init() {}

    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ 此设备不支持 HealthKit")
            return false
        }

        // Read types
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return false
        }

        // 添加运动类型
        let workoutType = HKObjectType.workoutType()

        // Write types (可选，先仅申请写入Workout)
        let typesToRead: Set<HKObjectType> = [heartRateType, activeEnergyType, distanceType, stepCountType, workoutType]
        let typesToWrite: Set<HKSampleType> = []

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            let statusHR = healthStore.authorizationStatus(for: heartRateType)
            print("✅ HealthKit 授权完成 - 心率授权状态: \(statusHR.rawValue)")
            return true
        } catch {
            print("❌ HealthKit 授权失败: \(error)")
            return false
        }
    }

    // MARK: - Heart Rate Streaming
    func startHeartRateStreaming(onUpdate: @escaping (Double) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        // 从现在开始监听
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        let query = HKAnchoredObjectQuery(type: heartRateType,
                                          predicate: predicate,
                                          anchor: heartRateAnchor,
                                          limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, _ in
            self?.heartRateAnchor = newAnchor
            if let bpm = Self.extractLatestBPM(from: samples) {
                Task { @MainActor in onUpdate(bpm) }
            }
        }

        query.updateHandler = { [weak self] _, samples, _, newAnchor, _ in
            self?.heartRateAnchor = newAnchor
            if let bpm = Self.extractLatestBPM(from: samples) {
                Task { @MainActor in onUpdate(bpm) }
            }
        }

        healthStore.execute(query)
        heartRateQuery = query
        print("📡 已开始订阅心率更新")
    }

    func stopHeartRateStreaming() {
        if let q = heartRateQuery {
            healthStore.stop(q)
            heartRateQuery = nil
            print("🛑 已停止心率订阅")
        }
    }

    private static func extractLatestBPM(from samples: [HKSample]?) -> Double? {
        guard let quantitySamples = samples as? [HKQuantitySample],
              let last = quantitySamples.last else { return nil }
        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        return last.quantity.doubleValue(for: unit)
    }

    // MARK: - Today Totals
    func queryTodayTotals(completion: @escaping (_ energyKcal: Double, _ distanceKm: Double) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let group = DispatchGroup()
        var energyKcal: Double = 0
        var distanceKm: Double = 0

        if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            group.enter()
            let q = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                if let sum = stats?.sumQuantity() {
                    energyKcal = sum.doubleValue(for: .kilocalorie())
                }
                group.leave()
            }
            healthStore.execute(q)
        }

        if let distType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            group.enter()
            let q = HKStatisticsQuery(quantityType: distType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                if let sum = stats?.sumQuantity() {
                    distanceKm = sum.doubleValue(for: HKUnit.meter()) / 1000.0
                }
                group.leave()
            }
            healthStore.execute(q)
        }

        group.notify(queue: .main) {
            completion(energyKcal, distanceKm)
        }
    }

    // MARK: - Today Steps and Calories
    func queryTodayStepsAndCalories(completion: @escaping (_ steps: Int, _ energyKcal: Double) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let group = DispatchGroup()
        var steps: Int = 0
        var energyKcal: Double = 0

        // 查询步数
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            group.enter()
            let q = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                if let sum = stats?.sumQuantity() {
                    steps = Int(sum.doubleValue(for: .count()))
                }
                group.leave()
            }
            healthStore.execute(q)
        }

        // 查询热量
        if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            group.enter()
            let q = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                if let sum = stats?.sumQuantity() {
                    energyKcal = sum.doubleValue(for: .kilocalorie())
                }
                group.leave()
            }
            healthStore.execute(q)
        }

        group.notify(queue: .main) {
            completion(steps, energyKcal)
        }
    }

    // MARK: - Workout History
    /// 查询历史运动记录
    /// - Parameters:
    ///   - startDate: 开始日期（默认为nil，查询所有数据）
    ///   - endDate: 结束日期（默认为现在）
    ///   - limit: 限制返回数量（默认100条）
    /// - Returns: HealthKit运动记录数组
    func queryWorkoutHistory(
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int = 100
    ) async throws -> [HKWorkout] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "此设备不支持 HealthKit"])
        }

        let workoutType = HKObjectType.workoutType()

        // 检查授权状态
        let authStatus = healthStore.authorizationStatus(for: workoutType)
        print("🔐 Workout授权状态: \(authStatus.rawValue)")

        if authStatus == .notDetermined {
            print("⚠️ 需要先请求授权")
            throw NSError(domain: "HealthKit", code: -2, userInfo: [NSLocalizedDescriptionKey: "需要授权访问运动数据"])
        }

        // 如果没有指定开始日期，查询所有数据（不设置开始日期限制）
        // 如果指定了开始日期，则使用指定的日期
        let end = endDate ?? Date()

        let predicate: NSPredicate?
        if let start = startDate {
            print("📅 查询时间范围: \(start) 到 \(end)")
            predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        } else {
            print("📅 查询所有运动记录（截止到 \(end)）")
            // 不设置开始日期，查询所有历史数据
            predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: end, options: [])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("❌ 查询运动记录失败: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = samples as? [HKWorkout] ?? []
                print("✅ 查询到 \(workouts.count) 条运动记录")

                // 打印前几条记录的详细信息
                if workouts.isEmpty {
                    print("⚠️ 没有找到运动记录，请检查：")
                    print("   1. 是否已授权访问健康数据")
                    print("   2. Apple健康中是否有运动记录")
                    print("   3. 运动记录是否在查询的时间范围内")
                } else {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    dateFormatter.locale = Locale(identifier: "zh_CN")
                    dateFormatter.timeZone = TimeZone.current

                    print("📊 查询到的运动记录详情（前5条）：")
                    for (index, workout) in workouts.prefix(5).enumerated() {
                        let typeName = self.getWorkoutTypeName(workout.workoutActivityType)
                        let dateStr = dateFormatter.string(from: workout.startDate)
                        let duration = Int(workout.duration / 60)
                        let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
                        let calories = Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)

                        print("   \(index + 1). [\(typeName)] \(dateStr)")
                        print("      时长: \(duration)分钟, 距离: \(String(format: "%.2f", distance/1000))km, 卡路里: \(calories)")
                    }

                    // 检查是否有今天的数据
                    let calendar = Calendar.current
                    let todayWorkouts = workouts.filter { calendar.isDateInToday($0.startDate) }
                    print("📅 今天的运动记录: \(todayWorkouts.count) 条")

                    if todayWorkouts.isEmpty && !workouts.isEmpty {
                        print("⚠️ 注意：查询到了运动记录，但没有今天的数据")
                        if let latestWorkout = workouts.first {
                            print("   最新的运动记录日期: \(dateFormatter.string(from: latestWorkout.startDate))")
                        }
                    }
                }

                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }

    /// 将HKWorkout转换为应用的运动类型字符串
    func convertWorkoutType(_ activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .running:
            return "running"
        case .cycling:
            return "cycling"
        case .walking:
            return "walking"
        case .swimming:
            return "swimming"
        case .yoga:
            return "yoga"
        case .hiking:
            return "walking"
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            return "strength"
        default:
            return "other"
        }
    }

    /// 获取运动类型的显示名称
    func getWorkoutTypeName(_ activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .running:
            return "跑步"
        case .cycling:
            return "骑行"
        case .walking:
            return "步行"
        case .swimming:
            return "游泳"
        case .yoga:
            return "瑜伽"
        case .hiking:
            return "徒步"
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            return "力量训练"
        default:
            return "其他运动"
        }
    }
}

