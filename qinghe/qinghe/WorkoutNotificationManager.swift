import Foundation
import SwiftUI

// MARK: - 通知名称扩展
extension NSNotification.Name {
    static let workoutDidComplete = NSNotification.Name("workoutDidComplete")
    static let workoutDataDidUpload = NSNotification.Name("workoutDataDidUpload")
    static let workoutDataDidUpdate = NSNotification.Name("workoutDataDidUpdate")
    static let workoutRecordsDidRefresh = NSNotification.Name("workoutRecordsDidRefresh")
    static let workoutSyncDidComplete = NSNotification.Name("workoutSyncDidComplete")
}

// MARK: - 运动数据通知管理器
/// 负责管理运动相关的通知发送和接收
class WorkoutNotificationManager {
    static let shared = WorkoutNotificationManager()
    
    private init() {}
    
    // MARK: - 通知发送方法
    
    /// 发送运动完成通知
    /// - Parameter workoutData: 完成的运动数据
    func postWorkoutCompletedNotification(workoutData: QingheWorkout) {
        let userInfo: [String: Any] = [
            "workoutData": workoutData,
            "timestamp": Date()
        ]
        
        NotificationCenter.default.post(
            name: .workoutDidComplete,
            object: nil,
            userInfo: userInfo
        )
        
        print("📢 发送运动完成通知: \(workoutData.workoutType)")
    }
    
    /// 发送运动数据上传成功通知
    /// - Parameter workoutData: 上传成功的运动数据
    func postWorkoutDataUploadedNotification(workoutData: QingheWorkout) {
        let userInfo: [String: Any] = [
            "workoutData": workoutData,
            "timestamp": Date()
        ]
        
        NotificationCenter.default.post(
            name: .workoutDataDidUpload,
            object: nil,
            userInfo: userInfo
        )
        
        print("📢 发送运动数据上传成功通知: \(workoutData.workoutId)")
    }
    
    /// 发送运动数据更新通知
    func postWorkoutDataUpdatedNotification() {
        NotificationCenter.default.post(
            name: .workoutDataDidUpdate,
            object: nil,
            userInfo: ["timestamp": Date()]
        )
        
        print("📢 发送运动数据更新通知")
    }
    
    /// 发送运动记录刷新通知
    func postWorkoutRecordsRefreshNotification() {
        NotificationCenter.default.post(
            name: .workoutRecordsDidRefresh,
            object: nil,
            userInfo: ["timestamp": Date()]
        )
        
        print("📢 发送运动记录刷新通知")
    }
    
    /// 发送运动同步完成通知
    func postWorkoutSyncCompletedNotification() {
        NotificationCenter.default.post(
            name: .workoutSyncDidComplete,
            object: nil,
            userInfo: ["timestamp": Date()]
        )
        
        print("📢 发送运动同步完成通知")
    }
}

// MARK: - 通知名称已在AuthManager.swift中定义，这里不重复定义

// MARK: - 通知监听辅助类
/// 提供便捷的通知监听方法
class WorkoutNotificationObserver: ObservableObject {
    private var observers: [NSObjectProtocol] = []
    
    deinit {
        removeAllObservers()
    }
    
    /// 监听运动完成通知
    /// - Parameter handler: 处理回调
    func observeWorkoutCompleted(handler: @escaping (QingheWorkout) -> Void) {
        let observer = NotificationCenter.default.addObserver(
            forName: .workoutDidComplete,
            object: nil,
            queue: .main
        ) { notification in
            if let workoutData = notification.userInfo?["workoutData"] as? QingheWorkout {
                handler(workoutData)
            }
        }
        observers.append(observer)
    }
    
    /// 监听运动数据上传通知
    /// - Parameter handler: 处理回调
    func observeWorkoutDataUploaded(handler: @escaping (QingheWorkout) -> Void) {
        let observer = NotificationCenter.default.addObserver(
            forName: .workoutDataDidUpload,
            object: nil,
            queue: .main
        ) { notification in
            if let workoutData = notification.userInfo?["workoutData"] as? QingheWorkout {
                handler(workoutData)
            }
        }
        observers.append(observer)
    }
    
    /// 监听运动数据更新通知
    /// - Parameter handler: 处理回调
    func observeWorkoutDataUpdated(handler: @escaping () -> Void) {
        let observer = NotificationCenter.default.addObserver(
            forName: .workoutDataDidUpdate,
            object: nil,
            queue: .main
        ) { _ in
            handler()
        }
        observers.append(observer)
    }
    
    /// 监听运动记录刷新通知
    /// - Parameter handler: 处理回调
    func observeWorkoutRecordsRefresh(handler: @escaping () -> Void) {
        let observer = NotificationCenter.default.addObserver(
            forName: .workoutRecordsDidRefresh,
            object: nil,
            queue: .main
        ) { _ in
            handler()
        }
        observers.append(observer)
    }
    
    /// 监听运动同步完成通知
    /// - Parameter handler: 处理回调
    func observeWorkoutSyncCompleted(handler: @escaping () -> Void) {
        let observer = NotificationCenter.default.addObserver(
            forName: .workoutSyncDidComplete,
            object: nil,
            queue: .main
        ) { _ in
            handler()
        }
        observers.append(observer)
    }
    
    /// 移除所有观察者
    func removeAllObservers() {
        observers.forEach { observer in
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }
}

// MARK: - 统计数据模型
struct WorkoutDayStats {
    let totalDistance: Double
    let totalDuration: Int // 秒
    let totalCalories: Int
    let totalSteps: Int
    let workoutCount: Int
    
    init(totalDistance: Double = 0.0, totalDuration: Int = 0, totalCalories: Int = 0, totalSteps: Int = 0, workoutCount: Int = 0) {
        self.totalDistance = totalDistance
        self.totalDuration = totalDuration
        self.totalCalories = totalCalories
        self.totalSteps = totalSteps
        self.workoutCount = workoutCount
    }
}

struct WorkoutWeekStats {
    let totalDistance: Double
    let totalDuration: Int
    let totalCalories: Int
    let workoutCount: Int
    let averageDistance: Double
    let averageDuration: Int
    let averageCalories: Int
    
    init(totalDistance: Double = 0.0, totalDuration: Int = 0, totalCalories: Int = 0, workoutCount: Int = 0, averageDistance: Double = 0.0, averageDuration: Int = 0, averageCalories: Int = 0) {
        self.totalDistance = totalDistance
        self.totalDuration = totalDuration
        self.totalCalories = totalCalories
        self.workoutCount = workoutCount
        self.averageDistance = averageDistance
        self.averageDuration = averageDuration
        self.averageCalories = averageCalories
    }
}
