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
              let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return false
        }

        // Write types (可选，先仅申请写入Workout)
        let typesToRead: Set<HKObjectType> = [heartRateType, activeEnergyType, distanceType]
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
}

