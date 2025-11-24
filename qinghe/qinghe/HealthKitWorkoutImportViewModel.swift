import Foundation
import HealthKit
import SwiftUI

/// HealthKit运动记录导入ViewModel
@MainActor
class HealthKitWorkoutImportViewModel: ObservableObject {
    @Published var workouts: [HKWorkout] = []
    @Published var selectedWorkouts: Set<UUID> = []
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var errorMessage: String?
    @Published var uploadProgress: Double = 0.0
    @Published var uploadedCount: Int = 0
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var uploadErrorMessage: String?
    @Published var showOnlyNotUploaded = false // 是否只显示未上传的记录

    private let healthKitManager = HealthKitManager.shared
    private let apiService = NewWorkoutAPIService.shared

    // 用于存储已上传的HealthKit运动记录UUID
    private let uploadedWorkoutsKey = "uploadedHealthKitWorkouts"
    @Published var uploadedWorkoutUUIDs: Set<String> = []

    init() {
        loadUploadedWorkouts()
    }

    // 从UserDefaults加载已上传的记录
    private func loadUploadedWorkouts() {
        if let data = UserDefaults.standard.data(forKey: uploadedWorkoutsKey),
           let uuids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            uploadedWorkoutUUIDs = uuids
            print("📦 加载已上传记录: \(uuids.count) 条")
        }
    }

    // 保存已上传的记录到UserDefaults
    private func saveUploadedWorkouts() {
        if let data = try? JSONEncoder().encode(uploadedWorkoutUUIDs) {
            UserDefaults.standard.set(data, forKey: uploadedWorkoutsKey)
            print("💾 保存已上传记录: \(uploadedWorkoutUUIDs.count) 条")
        }
    }

    // 检查运动记录是否已上传
    func isWorkoutUploaded(_ workout: HKWorkout) -> Bool {
        return uploadedWorkoutUUIDs.contains(workout.uuid.uuidString)
    }

    // 标记运动记录为已上传
    private func markWorkoutAsUploaded(_ workout: HKWorkout) {
        uploadedWorkoutUUIDs.insert(workout.uuid.uuidString)
        saveUploadedWorkouts()
    }

    // 获取过滤后的运动记录列表
    var filteredWorkouts: [HKWorkout] {
        if showOnlyNotUploaded {
            return workouts.filter { !isWorkoutUploaded($0) }
        }
        return workouts
    }

    // 待上传数量
    var notUploadedCount: Int {
        workouts.filter { !isWorkoutUploaded($0) }.count
    }

    // 已上传总数量（历史记录）
    var totalUploadedCount: Int {
        workouts.filter { isWorkoutUploaded($0) }.count
    }

    // 按日期分组的待上传运动记录
    var groupedNotUploadedWorkouts: [String: [HKWorkout]] {
        let notUploaded = workouts.filter { !isWorkoutUploaded($0) }
        return Dictionary(grouping: notUploaded) { workout in
            formatDateForGrouping(workout.startDate)
        }
    }

    // 按日期分组的已上传运动记录
    var groupedUploadedWorkouts: [String: [HKWorkout]] {
        let uploaded = workouts.filter { isWorkoutUploaded($0) }
        return Dictionary(grouping: uploaded) { workout in
            formatDateForGrouping(workout.startDate)
        }
    }

    // 格式化日期用于分组
    private func formatDateForGrouping(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: date)
        }
    }

    // 上传所有未上传的记录
    func uploadAllNotUploaded() async {
        let notUploaded = workouts.filter { !isWorkoutUploaded($0) }
        selectedWorkouts = Set(notUploaded.map { $0.uuid })
        await uploadSelectedWorkouts()
    }
    
    var isAllSelected: Bool {
        !workouts.isEmpty && selectedWorkouts.count == workouts.count
    }
    
    /// 加载运动记录
    func loadWorkouts() async {
        isLoading = true
        errorMessage = nil

        print("🔄 开始加载运动记录...")

        do {
            // 请求HealthKit授权
            print("🔐 请求HealthKit授权...")
            let authorized = await healthKitManager.requestAuthorization()

            if !authorized {
                let message = "需要授权访问健康数据才能导入运动记录。\n\n请在「设置」->「隐私与安全性」->「健康」中允许青禾计划访问运动数据。"
                errorMessage = message
                print("❌ 授权失败")
                isLoading = false
                return
            }

            print("✅ 授权成功，开始查询运动记录...")

            // 查询所有运动记录
            let fetchedWorkouts = try await healthKitManager.queryWorkoutHistory(limit: 100)

            print("📊 查询结果: \(fetchedWorkouts.count) 条记录")

            // 统计最近7天的数据
            let calendar = Calendar.current
            let now = Date()
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            let recentWorkouts = fetchedWorkouts.filter { $0.startDate >= sevenDaysAgo }

            if recentWorkouts.isEmpty {
                print("⚠️ 最近7天没有运动记录")
            } else {
                print("📅 最近7天的运动记录: \(recentWorkouts.count) 条")
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd HH:mm"
                for workout in recentWorkouts.prefix(5) {
                    print("   - \(dateFormatter.string(from: workout.startDate)): \(healthKitManager.getWorkoutTypeName(workout.workoutActivityType))")
                }
            }

            // 过滤掉已经上传过的记录（可选：通过本地缓存或API检查）
            workouts = fetchedWorkouts

            if workouts.isEmpty {
                print("⚠️ 没有找到运动记录")
                // 不设置errorMessage，让界面显示空状态
            } else {
                print("✅ 成功加载 \(workouts.count) 条运动记录")
                // 打印运动类型统计
                let typeCount = Dictionary(grouping: workouts, by: { $0.workoutActivityType })
                print("📈 运动类型统计:")
                for (type, items) in typeCount {
                    print("   - \(healthKitManager.getWorkoutTypeName(type)): \(items.count)条")
                }
            }

        } catch {
            let message = "加载运动记录失败: \(error.localizedDescription)\n\n请确保：\n1. 已授权访问健康数据\n2. Apple健康中有运动记录\n3. 设备支持HealthKit"
            errorMessage = message
            print("❌ 加载运动记录失败: \(error)")
        }

        isLoading = false
    }
    
    /// 切换选择状态
    func toggleSelection(_ workout: HKWorkout) {
        if selectedWorkouts.contains(workout.uuid) {
            selectedWorkouts.remove(workout.uuid)
        } else {
            selectedWorkouts.insert(workout.uuid)
        }
    }
    
    /// 全选/取消全选
    func toggleSelectAll() {
        if isAllSelected {
            selectedWorkouts.removeAll()
        } else {
            selectedWorkouts = Set(workouts.map { $0.uuid })
        }
    }
    
    /// 上传选中的运动记录
    func uploadSelectedWorkouts() async {
        guard !selectedWorkouts.isEmpty else { return }
        
        isUploading = true
        uploadProgress = 0.0
        uploadedCount = 0
        uploadErrorMessage = nil
        
        let selectedWorkoutsList = workouts.filter { selectedWorkouts.contains($0.uuid) }
        let totalCount = selectedWorkoutsList.count
        
        var successCount = 0
        var failedCount = 0
        
        for (index, workout) in selectedWorkoutsList.enumerated() {
            do {
                // 转换为NewWorkout格式
                let newWorkout = try await convertToNewWorkout(workout)

                // 上传到服务器
                let success = try await apiService.createWorkout(newWorkout)

                if success {
                    successCount += 1
                    // 标记为已上传
                    markWorkoutAsUploaded(workout)
                    print("✅ 上传成功: \(healthKitManager.getWorkoutTypeName(workout.workoutActivityType))")
                } else {
                    failedCount += 1
                    print("❌ 上传失败: \(healthKitManager.getWorkoutTypeName(workout.workoutActivityType))")
                }

            } catch {
                failedCount += 1
                print("❌ 上传出错: \(error.localizedDescription)")
            }

            // 更新进度
            uploadedCount = index + 1
            uploadProgress = Double(uploadedCount) / Double(totalCount)

            // 添加延迟，避免请求过于频繁（每次上传后等待1秒）
            // 最后一条记录不需要延迟
            if index < selectedWorkoutsList.count - 1 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒 = 1,000,000,000纳秒
                print("⏱️ 等待1秒后继续上传...")
            }
        }
        
        isUploading = false

        // 显示结果
        print("📊 上传完成 - 成功: \(successCount) 条, 失败: \(failedCount) 条")

        if failedCount == 0 {
            // 全部成功
            showSuccessAlert = true

            // 发送刷新通知
            WorkoutNotificationManager.shared.postWorkoutDataUpdatedNotification()
            WorkoutNotificationManager.shared.postWorkoutRecordsRefreshNotification()
        } else if successCount > 0 {
            // 部分成功
            uploadErrorMessage = "成功导入 \(successCount) 条，失败 \(failedCount) 条"
            showErrorAlert = true

            // 即使有失败，也发送刷新通知（因为有部分成功）
            WorkoutNotificationManager.shared.postWorkoutDataUpdatedNotification()
            WorkoutNotificationManager.shared.postWorkoutRecordsRefreshNotification()
        } else {
            // 全部失败
            uploadErrorMessage = "导入失败，请检查网络连接或稍后重试"
            showErrorAlert = true
        }
    }
    
    /// 将HKWorkout转换为NewWorkout
    private func convertToNewWorkout(_ workout: HKWorkout) async throws -> NewWorkout {
        let workoutType = healthKitManager.convertWorkoutType(workout.workoutActivityType)

        // 基础指标
        let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        let calories = Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)

        // 计算配速（分钟/公里）
        let averagePace = distance > 0 ? (workout.duration / 60) / (distance / 1000) : 0

        let basicMetrics = WorkoutBasicMetrics(
            totalDistance: distance / 1000, // 转换为公里
            totalSteps: 0, // HealthKit的workout不直接提供步数
            calories: calories,
            averagePace: averagePace,
            maxSpeed: 0 // HealthKit不提供最大速度
        )

        // 高级指标（心率数据）
        let heartRateData = try? await queryHeartRateForWorkout(workout)
        let advancedMetrics = WorkoutAdvancedMetrics(
            averageHeartRate: heartRateData?.average,
            maxHeartRate: heartRateData?.max,
            averageCadence: nil,
            elevationGain: nil,
            elevationLoss: nil
        )

        // 设备信息
        let deviceInfo = WorkoutDeviceInfo(
            deviceType: workout.device?.name ?? "iPhone",
            deviceModel: workout.device?.model ?? UIDevice.current.model,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            dataSource: "HealthKit"
        )

        // 格式化时间
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return NewWorkout(
            workoutId: nil,
            workoutType: workoutType,
            startTime: formatter.string(from: workout.startDate),
            endTime: formatter.string(from: workout.endDate),
            duration: Int(workout.duration),
            basicMetrics: basicMetrics,
            advancedMetrics: advancedMetrics,
            routeData: nil, // HealthKit路径数据需要单独查询，暂不支持
            deviceInfo: deviceInfo,
            notes: "从HealthKit导入 - \(workout.sourceRevision.source.name)"
        )
    }
    
    /// 查询运动期间的心率数据
    private func queryHeartRateForWorkout(_ workout: HKWorkout) async throws -> (average: Int, max: Int, min: Int)? {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let heartRateSamples = samples as? [HKQuantitySample], !heartRateSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let unit = HKUnit.count().unitDivided(by: .minute())
                let heartRates = heartRateSamples.map { Int($0.quantity.doubleValue(for: unit)) }
                
                let average = heartRates.reduce(0, +) / heartRates.count
                let max = heartRates.max() ?? 0
                let min = heartRates.min() ?? 0
                
                continuation.resume(returning: (average: average, max: max, min: min))
            }
            
            let healthStore = HKHealthStore()
            healthStore.execute(query)
        }
    }
}

