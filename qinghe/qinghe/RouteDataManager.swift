//
//  RouteDataManager.swift
//  qinghe
//
//  Created by AI Assistant on 2025-09-08.
//  轨迹数据持久化管理器
//

import Foundation
import CoreLocation

// MARK: - 轨迹数据管理器
class RouteDataManager: ObservableObject {
    static let shared = RouteDataManager()
    
    // MARK: - 存储键
    private enum StorageKeys {
        static let workoutRoutes = "workout_routes"
        static let routePrefix = "route_"
    }
    
    // MARK: - 发布属性
    @Published var savedRoutes: [WorkoutRoute] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        loadAllRoutes()
    }
    
    // MARK: - 保存轨迹数据
    
    /// 保存运动轨迹
    /// - Parameters:
    ///   - routePoints: 轨迹点数组
    ///   - workoutType: 运动类型
    ///   - startTime: 开始时间
    ///   - endTime: 结束时间
    /// - Returns: 保存是否成功
    @discardableResult
    func saveWorkoutRoute(
        routePoints: [RoutePoint],
        workoutType: WorkoutType,
        startTime: Date,
        endTime: Date
    ) -> Bool {
        guard !routePoints.isEmpty else {
            errorMessage = "轨迹数据为空，无法保存"
            return false
        }
        
        let workoutRoute = WorkoutRoute(
            workoutType: workoutType,
            startTime: startTime,
            endTime: endTime,
            routePoints: routePoints
        )
        
        return saveWorkoutRoute(workoutRoute)
    }
    
    /// 保存WorkoutRoute对象
    /// - Parameter workoutRoute: 运动轨迹对象
    /// - Returns: 保存是否成功
    @discardableResult
    func saveWorkoutRoute(_ workoutRoute: WorkoutRoute) -> Bool {
        do {
            let encoded = try JSONEncoder().encode(workoutRoute)
            let key = StorageKeys.routePrefix + workoutRoute.id.uuidString
            UserDefaults.standard.set(encoded, forKey: key)
            
            // 更新路由列表
            savedRoutes.append(workoutRoute)
            savedRoutes.sort { $0.startTime > $1.startTime }
            
            // 保存路由ID列表
            saveRouteIdList()
            
            print("✅ 轨迹数据保存成功: \(workoutRoute.id)")
            return true
            
        } catch {
            errorMessage = "保存轨迹数据失败: \(error.localizedDescription)"
            print("❌ 保存轨迹数据失败: \(error)")
            return false
        }
    }
    
    // MARK: - 加载轨迹数据
    
    /// 加载所有保存的轨迹
    func loadAllRoutes() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .background).async {
            let routeIds = self.loadRouteIdList()
            var loadedRoutes: [WorkoutRoute] = []
            
            for routeId in routeIds {
                if let route = self.loadWorkoutRoute(id: routeId) {
                    loadedRoutes.append(route)
                }
            }
            
            // 按时间排序
            loadedRoutes.sort { $0.startTime > $1.startTime }
            
            DispatchQueue.main.async {
                self.savedRoutes = loadedRoutes
                self.isLoading = false
                print("📚 加载了 \(loadedRoutes.count) 条轨迹记录")
            }
        }
    }
    
    /// 根据ID加载特定轨迹
    /// - Parameter id: 轨迹ID
    /// - Returns: 轨迹对象，如果不存在则返回nil
    func loadWorkoutRoute(id: UUID) -> WorkoutRoute? {
        let key = StorageKeys.routePrefix + id.uuidString
        
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        
        do {
            let workoutRoute = try JSONDecoder().decode(WorkoutRoute.self, from: data)
            return workoutRoute
        } catch {
            print("❌ 加载轨迹数据失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 删除轨迹数据
    
    /// 删除指定轨迹
    /// - Parameter id: 轨迹ID
    /// - Returns: 删除是否成功
    @discardableResult
    func deleteWorkoutRoute(id: UUID) -> Bool {
        let key = StorageKeys.routePrefix + id.uuidString
        UserDefaults.standard.removeObject(forKey: key)
        
        // 从内存中移除
        savedRoutes.removeAll { $0.id == id }
        
        // 更新ID列表
        saveRouteIdList()
        
        print("🗑️ 删除轨迹数据: \(id)")
        return true
    }
    
    /// 清空所有轨迹数据
    func clearAllRoutes() {
        let routeIds = loadRouteIdList()
        
        for routeId in routeIds {
            let key = StorageKeys.routePrefix + routeId.uuidString
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        UserDefaults.standard.removeObject(forKey: StorageKeys.workoutRoutes)
        savedRoutes.removeAll()
        
        print("🧹 清空所有轨迹数据")
    }
    
    // MARK: - 轨迹统计
    
    /// 获取轨迹统计信息
    var routeStatistics: (count: Int, totalDistance: Double, totalDuration: TimeInterval) {
        let count = savedRoutes.count
        let totalDistance = savedRoutes.reduce(0) { $0 + $1.totalDistance }
        let totalDuration = savedRoutes.reduce(0) { $0 + $1.duration }
        
        return (count, totalDistance, totalDuration)
    }
    
    /// 按运动类型分组的统计
    func statisticsByWorkoutType() -> [WorkoutType: (count: Int, distance: Double, duration: TimeInterval)] {
        var stats: [WorkoutType: (count: Int, distance: Double, duration: TimeInterval)] = [:]
        
        for route in savedRoutes {
            let current = stats[route.workoutType] ?? (0, 0, 0)
            stats[route.workoutType] = (
                current.count + 1,
                current.distance + route.totalDistance,
                current.duration + route.duration
            )
        }
        
        return stats
    }
    
    // MARK: - 私有方法
    
    /// 保存轨迹ID列表
    private func saveRouteIdList() {
        let routeIds = savedRoutes.map { $0.id.uuidString }
        UserDefaults.standard.set(routeIds, forKey: StorageKeys.workoutRoutes)
    }
    
    /// 加载轨迹ID列表
    private func loadRouteIdList() -> [UUID] {
        guard let routeIdStrings = UserDefaults.standard.array(forKey: StorageKeys.workoutRoutes) as? [String] else {
            return []
        }
        
        return routeIdStrings.compactMap { UUID(uuidString: $0) }
    }
}

// MARK: - 轨迹导出功能
extension RouteDataManager {
    
    /// 导出轨迹为GPX格式
    /// - Parameter route: 要导出的轨迹
    /// - Returns: GPX格式的字符串
    func exportToGPX(_ route: WorkoutRoute) -> String {
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="青禾计划" xmlns="http://www.topografix.com/GPX/1/1">
        <metadata>
        <name>运动轨迹 - \(route.workoutType.rawValue)</name>
        <time>\(ISO8601DateFormatter().string(from: route.startTime))</time>
        </metadata>
        <trk>
        <name>\(route.workoutType.rawValue) - \(DateFormatter.shortDate.string(from: route.startTime))</name>
        <trkseg>
        """
        
        for point in route.routePoints {
            gpx += """
            <trkpt lat="\(point.latitude)" lon="\(point.longitude)">
            """
            
            if let altitude = point.altitude {
                gpx += "<ele>\(altitude)</ele>"
            }
            
            gpx += "<time>\(ISO8601DateFormatter().string(from: point.timestamp))</time>"
            
            if let speed = point.speed {
                gpx += "<extensions><speed>\(speed)</speed></extensions>"
            }
            
            gpx += "</trkpt>"
        }
        
        gpx += """
        </trkseg>
        </trk>
        </gpx>
        """
        
        return gpx
    }
}

// MARK: - DateFormatter 扩展
private extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
