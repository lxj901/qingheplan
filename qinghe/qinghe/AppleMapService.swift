import Foundation
import CoreLocation
import MapKit
import SwiftUI

// MARK: - 位置相关模型
struct NearbyLocation: Identifiable, Codable {
    let id = UUID()
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: String
    let distance: Double // 距离（米）
    
    enum CodingKeys: String, CodingKey {
        case name, address, latitude, longitude, category, distance
    }
}

struct EnhancedNearbyLocation: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: LocationCategory
    let distance: Double
    let rating: Double?
    let isOpen: Bool?
    
    var formattedDistance: String {
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

enum LocationCategory: String, CaseIterable {
    case all = "all"
    case restaurant = "restaurant"
    case cafe = "cafe"
    case shopping = "shopping"
    case entertainment = "entertainment"
    case transport = "transport"
    case health = "health"
    case education = "education"
    case business = "business"
    case residential = "residential"
    case road = "road"
    case landmark = "landmark"
    case park = "park"
    case hospital = "hospital"
    case government = "government"
    case office = "office"
    case hotel = "hotel"
    case bank = "bank"
    case gas = "gas"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .restaurant: return "餐厅"
        case .cafe: return "咖啡厅"
        case .shopping: return "购物"
        case .entertainment: return "娱乐"
        case .transport: return "交通"
        case .health: return "医疗"
        case .education: return "教育"
        case .business: return "商务"
        case .residential: return "住宅"
        case .road: return "道路"
        case .landmark: return "地标"
        case .park: return "公园"
        case .hospital: return "医院"
        case .government: return "政府"
        case .office: return "办公"
        case .hotel: return "酒店"
        case .bank: return "银行"
        case .gas: return "加油站"
        case .other: return "其他"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer"
        case .shopping: return "bag"
        case .entertainment: return "gamecontroller"
        case .transport: return "car"
        case .health: return "cross"
        case .education: return "book"
        case .business: return "building"
        case .residential: return "house"
        case .road: return "road.lanes"
        case .landmark: return "mappin.and.ellipse"
        case .park: return "tree"
        case .hospital: return "cross.case"
        case .government: return "building.columns"
        case .office: return "building.2"
        case .hotel: return "bed.double"
        case .bank: return "banknote"
        case .gas: return "fuelpump"
        case .other: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .all: return .gray
        case .restaurant: return .orange
        case .cafe: return .brown
        case .shopping: return .purple
        case .entertainment: return .pink
        case .transport: return .blue
        case .health: return .red
        case .education: return .green
        case .business: return .indigo
        case .residential: return .yellow
        case .road: return .gray
        case .landmark: return .red
        case .park: return .green
        case .hospital: return .red
        case .government: return .blue
        case .office: return .indigo
        case .hotel: return .purple
        case .bank: return .green
        case .gas: return .orange
        case .other: return .gray
        }
    }
}

// MARK: - Apple 地图服务
class AppleMapService: NSObject, ObservableObject {
    static let shared = AppleMapService()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking = false
    @Published var errorMessage: String?
    @Published var locationError: Error?

    // 运动追踪相关属性
    @Published var routePoints: [CLLocationCoordinate2D] = []
    @Published var mapBasedDistance: Double = 0.0
    @Published var duration: TimeInterval = 0.0

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var trackingStartTime: Date?
    private var lastLocation: CLLocation?
    private var currentPace: Double = 0.0
    private var bestPace: Double = 0.0
    @Published var averageSpeed: Double = 0.0
    @Published var currentSpeed: Double = 0.0
    @Published var maxSpeed: Double = 0.0

    // 轨迹优化相关属性
    private var speedReadings: [Double] = []
    private var lastValidLocation: CLLocation?
    private var locationBuffer: [CLLocation] = []

    override init() {
        super.init()
        setupLocationManager()
        // 初始化权限状态（仅读取，不在此处启动定位，等待授权回调里处理）
        authorizationStatus = locationManager.authorizationStatus

        if authorizationStatus == .notDetermined {
            requestLocationPermission()
        }
        // 其余状态在授权回调中统一处理，避免主线程卡顿
    }
    
    // MARK: - 设置位置管理器
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation  // 导航级精度
        locationManager.distanceFilter = 1.0  // 1米更新一次，提高轨迹精度
        locationManager.activityType = .fitness  // 运动模式，优化GPS性能
        locationManager.pausesLocationUpdatesAutomatically = false

        print("🛰️ GPS配置完成：导航级精度，1米过滤，运动模式")
    }

    // MARK: - 配置后台定位
    private func configureBackgroundLocationIfNeeded() {
        // 只有在有Always权限时才启用后台定位
        guard authorizationStatus == .authorizedAlways else {
            print("⚠️ 没有Always权限，跳过后台定位配置")
            return
        }

        // 检查是否配置了后台模式
        guard let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String],
              backgroundModes.contains("location") else {
            print("⚠️ 未配置location后台模式，跳过后台定位")
            return
        }

        // 安全地启用后台定位
        locationManager.allowsBackgroundLocationUpdates = true
        print("✅ 后台定位已启用")
    }
    
    // MARK: - 请求位置权限
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // 引导用户到设置页面
            errorMessage = "请在设置中允许访问位置信息"
            showLocationPermissionAlert()
        case .authorizedWhenInUse:
            // 如果支持后台定位，请求Always权限
            if Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription") != nil {
                locationManager.requestAlwaysAuthorization()
            } else {
                startLocationUpdates()
            }
        case .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }

    // MARK: - 显示位置权限提示
    private func showLocationPermissionAlert() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let alert = UIAlertController(
                    title: "需要位置权限",
                    message: "为了记录运动轨迹，请在设置中允许访问位置信息",
                    preferredStyle: .alert
                )

                alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                })

                alert.addAction(UIAlertAction(title: "取消", style: .cancel))

                window.rootViewController?.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - 开始位置更新
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("❌ 无法启动位置更新：权限不足 (\(authorizationStatus))")
            requestLocationPermission()
            return
        }

        // 检查位置服务是否可用
        if !CLLocationManager.locationServicesEnabled() {
            print("❌ 设备位置服务未开启")
            errorMessage = "请在设备设置中开启位置服务"
            return
        }

        print("🛰️ 开始位置更新")
        isTracking = true
        locationManager.startUpdatingLocation()
    }

    // MARK: - 停止位置更新
    func stopLocationUpdates() {
        print("⏹️ 停止位置更新")
        isTracking = false
        locationManager.stopUpdatingLocation()
    }

    // MARK: - 运动追踪方法
    func startTracking() {
        trackingStartTime = Date()
        routePoints.removeAll()
        mapBasedDistance = 0.0
        duration = 0.0
        currentPace = 0.0
        bestPace = 0.0
        currentSpeed = 0.0
        maxSpeed = 0.0
        averageSpeed = 0.0
        lastLocation = nil
        lastValidLocation = nil
        speedReadings.removeAll()
        locationBuffer.removeAll()
        startLocationUpdates()

        print("🏃‍♂️ 开始运动追踪，GPS优化已启用")
    }

    func stopTracking() {
        // 保存轨迹数据
        if let startTime = trackingStartTime, !routePoints.isEmpty {
            saveCurrentRoute(startTime: startTime, endTime: Date())
        }

        trackingStartTime = nil
        stopLocationUpdates()

        print("⏹️ 停止运动追踪")
    }

    /// 保存当前轨迹数据
    /// - Parameters:
    ///   - startTime: 开始时间
    ///   - endTime: 结束时间
    private func saveCurrentRoute(startTime: Date, endTime: Date) {
        // 转换坐标点为RoutePoint
        let routePointsData = routePoints.enumerated().map { index, coordinate in
            // 使用时间戳估算每个点的时间
            let timeOffset = Double(index) * (endTime.timeIntervalSince(startTime) / Double(routePoints.count))
            let pointTime = startTime.addingTimeInterval(timeOffset)

            return RoutePoint(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                altitude: nil,  // 这里可以从实际数据中获取
                timestamp: pointTime,
                speed: index < speedReadings.count ? speedReadings[index] : nil,
                course: 0,
                horizontalAccuracy: 5.0  // 默认精度
            )
        }

        // 保存到RouteDataManager
        RouteDataManager.shared.saveWorkoutRoute(
            routePoints: routePointsData,
            workoutType: .running,  // 这里应该从实际运动类型获取
            startTime: startTime,
            endTime: endTime
        )

        print("💾 轨迹数据已保存，包含 \(routePointsData.count) 个轨迹点")
    }

    func getMapBasedDistanceInKm() -> Double {
        return mapBasedDistance
    }

    func getCurrentPace() -> Double {
        guard currentSpeed > 0 && currentSpeed.isFinite else { return 0 }
        let pace = 1000 / (currentSpeed * 60)  // 转换为分钟/公里
        return pace.isFinite ? pace : 0
    }

    func getBestPace() -> Double {
        return bestPace
    }

    func getAveragePace() -> Double {
        guard averageSpeed > 0 && averageSpeed.isFinite else { return 0 }
        let pace = 1000 / (averageSpeed * 60)  // 转换为分钟/公里
        return pace.isFinite ? pace : 0
    }

    /// 获取格式化的配速字符串
    func getFormattedPace() -> String {
        let pace = getCurrentPace()
        guard pace > 0 && pace.isFinite else { return "--'--\"" }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    /// 获取格式化的速度字符串
    func getFormattedSpeed() -> String {
        return String(format: "%.1f km/h", currentSpeed * 3.6)
    }

    /// 获取格式化的距离字符串
    func getFormattedDistance() -> String {
        return String(format: "%.2f km", mapBasedDistance)
    }

    /// 获取格式化的持续时间字符串
    func getFormattedDuration() -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// 获取卡路里消耗（估算）
    func getCaloriesBurned() -> Double {
        // 简单的卡路里估算公式
        // 这里可以根据用户体重、运动类型等进行更精确的计算
        let durationInHours = duration / 3600.0
        let averageSpeedKmh = averageSpeed * 3.6

        // 基础代谢率估算（假设70kg体重）
        let baseCaloriesPerHour = 70.0

        // 运动强度系数（基于速度）
        let intensityFactor: Double
        if averageSpeedKmh < 5 {
            intensityFactor = 3.0  // 慢走
        } else if averageSpeedKmh < 8 {
            intensityFactor = 5.0  // 快走
        } else if averageSpeedKmh < 12 {
            intensityFactor = 8.0  // 慢跑
        } else {
            intensityFactor = 12.0  // 跑步
        }

        return baseCaloriesPerHour * intensityFactor * durationInHours
    }

    // MARK: - 调试和诊断方法

    /// 获取定位服务状态信息
    func getLocationServiceStatus() -> String {
        var status = "📍 定位服务状态:\n"

        // 设备位置服务状态
        status += "• 设备位置服务: \(CLLocationManager.locationServicesEnabled() ? "✅ 已开启" : "❌ 未开启")\n"

        // 应用权限状态
        let authStatus: String
        switch authorizationStatus {
        case .notDetermined:
            authStatus = "⏳ 未确定"
        case .denied:
            authStatus = "❌ 已拒绝"
        case .restricted:
            authStatus = "⚠️ 受限制"
        case .authorizedWhenInUse:
            authStatus = "✅ 使用期间"
        case .authorizedAlways:
            authStatus = "✅ 始终允许"
        @unknown default:
            authStatus = "❓ 未知"
        }
        status += "• 应用权限: \(authStatus)\n"

        // 当前位置状态
        if let location = currentLocation {
            status += "• 当前位置: \(String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude))\n"
            status += "• 位置精度: ±\(String(format: "%.0f", location.horizontalAccuracy))m\n"
            status += "• 更新时间: \(DateFormatter.localizedString(from: location.timestamp, dateStyle: .none, timeStyle: .medium))\n"
        } else {
            status += "• 当前位置: ❌ 无位置数据\n"
        }

        // 追踪状态
        status += "• 追踪状态: \(isTracking ? "🏃‍♂️ 追踪中" : "⏹️ 已停止")\n"

        // 轨迹点数量
        status += "• 轨迹点数: \(routePoints.count)\n"

        // 错误信息
        if let error = errorMessage {
            status += "• 错误信息: ⚠️ \(error)\n"
        }

        return status
    }

    /// 强制请求位置更新（用于调试）
    func forceLocationUpdate() {
        print("🔄 强制请求位置更新")
        locationManager.requestLocation()
    }

    func handleMemoryWarning() {
        print("⚠️ 收到内存警告，开始清理轨迹缓存")

        // 更激进的清理策略
        let currentCount = routePoints.count
        if currentCount > 1000 {
            let pointsToKeep = 1000
            let pointsToRemove = currentCount - pointsToKeep
            routePoints.removeFirst(pointsToRemove)
            print("🧹 内存清理：保留最近 \(pointsToKeep) 个位置点")
        }

        // 清理速度记录
        if speedReadings.count > 100 {
            speedReadings.removeFirst(speedReadings.count - 100)
            print("🧹 内存清理：保留最近 100 个速度记录")
        }

        // 清理位置缓冲区
        locationBuffer.removeAll()

        // 强制垃圾回收
        DispatchQueue.global(qos: .utility).async {
            autoreleasepool {
                // 触发自动释放池清理
                print("🗑️ 触发垃圾回收")
            }
        }
    }

    func pauseTracking() {
        // 暂停追踪但不停止位置更新
        print("⏸️ 暂停运动追踪")
    }

    func resumeTracking() {
        // 恢复追踪
        print("▶️ 恢复运动追踪")
    }

    func trimLocationHistory() {
        // 清理位置历史记录以节省内存
        let maxPoints = 5000  // 最大保留5000个点
        let maxSpeedReadings = 500  // 最大保留500个速度记录

        if routePoints.count > maxPoints {
            let pointsToRemove = routePoints.count - maxPoints
            routePoints.removeFirst(pointsToRemove)  // 保留最新轨迹
            print("🧹 清理了 \(pointsToRemove) 个历史位置点")
        }

        if speedReadings.count > maxSpeedReadings {
            let speedPointsToRemove = speedReadings.count - maxSpeedReadings
            speedReadings.removeFirst(speedPointsToRemove)
            print("🧹 清理了 \(speedPointsToRemove) 个历史速度记录")
        }
    }

    // MARK: - 轨迹数据验证和过滤

    /// 验证位置更新的有效性
    /// - Parameter location: 新的位置数据
    /// - Returns: 是否为有效的位置更新
    private func isValidLocationUpdate(_ location: CLLocation) -> Bool {
        // 坐标有效性检查
        guard location.coordinate.isValid else {
            print("⚠️ 无效坐标被过滤: \(location.coordinate)")
            return false
        }

        // 精度检查 - 过滤精度过低的点
        guard location.horizontalAccuracy <= 50.0 && location.horizontalAccuracy > 0 else {
            print("⚠️ 精度过低被过滤: \(location.horizontalAccuracy)m")
            return false
        }

        // 时间检查 - 过滤过旧的数据
        let timeInterval = abs(location.timestamp.timeIntervalSinceNow)
        guard timeInterval <= 10.0 else {
            print("⚠️ 数据过旧被过滤: \(timeInterval)s")
            return false
        }

        // GPS跳跃检查
        if let lastLoc = lastValidLocation {
            let distance = location.distance(from: lastLoc)
            let timeDiff = location.timestamp.timeIntervalSince(lastLoc.timestamp)

            // 防止除零错误
            guard timeDiff > 0.1 else {
                print("⚠️ 时间间隔过短被过滤: \(timeDiff)s")
                return false
            }

            let speed = distance / timeDiff

            // 过滤超过合理速度的点（防止GPS跳跃）
            let maxReasonableSpeed = 50.0  // 180km/h上限
            guard speed <= maxReasonableSpeed else {
                print("⚠️ 速度异常被过滤: \(String(format: "%.1f", speed * 3.6))km/h")
                return false
            }

            // 最小移动距离检查（去抖动）
            let minDistance = 3.0  // 最小3米移动距离，过滤微小抖动
            guard distance >= minDistance else {
                print("⚠️ 移动距离过小被过滤: \(String(format: "%.1f", distance))m (<3m)")
                return false
            }
        }

        return true
    }

    /// 处理位置更新（带坐标转换和过滤）
    /// - Parameter location: 原始GPS位置
    private func processLocationUpdate(_ location: CLLocation) {
        // 验证位置有效性
        guard isValidLocationUpdate(location) else {
            return
        }

        // WGS84 → GCJ02 坐标转换（解决中国地区偏移问题）
        let convertedLocation = location.convertedForChineseMap()

        // 更新当前位置
        DispatchQueue.main.async {
            self.currentLocation = convertedLocation

            // 如果正在追踪运动，更新轨迹数据
            if self.isTracking {
                self.updateTrackingData(with: convertedLocation, originalLocation: location)
            }
        }

        // 更新最后有效位置
        lastValidLocation = location

        print("🛤️ 轨迹点坐标转换:")
        print("   原始坐标: \(String(format: "%.8f, %.8f", location.coordinate.latitude, location.coordinate.longitude))")
        print("   转换坐标: \(String(format: "%.8f, %.8f", convertedLocation.coordinate.latitude, convertedLocation.coordinate.longitude))")
    }

    /// 更新运动追踪数据
    /// - Parameters:
    ///   - convertedLocation: 转换后的位置
    ///   - originalLocation: 原始GPS位置
    private func updateTrackingData(with convertedLocation: CLLocation, originalLocation: CLLocation) {
        guard let startTime = trackingStartTime else { return }

        // 添加轨迹点
        routePoints.append(convertedLocation.coordinate)

        // 更新距离
        updateMapBasedDistance(for: convertedLocation)

        // 计算持续时间
        duration = Date().timeIntervalSince(startTime)

        // 计算速度和配速
        calculateSpeed(from: originalLocation)

        // 定期清理内存
        if routePoints.count % 100 == 0 {
            trimLocationHistory()
        }

        print("📊 运动数据更新:")
        print("   距离: \(String(format: "%.2f", mapBasedDistance))km")
        print("   时长: \(String(format: "%.0f", duration))s")
        print("   当前速度: \(String(format: "%.1f", currentSpeed * 3.6))km/h")
    }

    /// 更新基于地图的距离计算
    /// - Parameter location: 当前位置
    private func updateMapBasedDistance(for location: CLLocation) {
        if let lastLoc = lastLocation {
            let distance = location.distance(from: lastLoc)

            // 异常值过滤 - 防止GPS跳跃
            let maxReasonableDistance = 100.0  // 100米/秒最大合理距离
            let timeDiff = location.timestamp.timeIntervalSince(lastLoc.timestamp)

            if distance <= maxReasonableDistance && timeDiff > 0.5 {
                mapBasedDistance += distance / 1000.0  // 转换为公里
                print("✅ 距离更新: +\(String(format: "%.1f", distance))m, 总计: \(String(format: "%.2f", mapBasedDistance))km")
            } else {
                print("⚠️ 过滤异常距离: \(String(format: "%.1f", distance))m")
            }
        }

        lastLocation = location
    }

    /// 计算速度和配速
    /// - Parameter location: 当前位置
    private func calculateSpeed(from location: CLLocation) {
        if let lastLoc = lastValidLocation {
            let distance = location.distance(from: lastLoc)
            let timeDiff = location.timestamp.timeIntervalSince(lastLoc.timestamp)

            // 最小时间和距离阈值
            let minTimeDiff = 0.5  // 最小0.5秒
            let minDistance = 1.0  // 最小1米

            if timeDiff >= minTimeDiff && distance >= minDistance {
                let calculatedSpeed = distance / timeDiff
                let maxReasonableSpeed = 13.9  // 50km/h上限 (13.9 m/s)

                if calculatedSpeed <= maxReasonableSpeed && calculatedSpeed.isFinite {
                    currentSpeed = calculatedSpeed
                    speedReadings.append(calculatedSpeed)
                    maxSpeed = max(maxSpeed, calculatedSpeed)

                    // 计算平均速度
                    averageSpeed = speedReadings.reduce(0, +) / Double(speedReadings.count)

                    // 更新配速
                    updatePace()

                    print("✅ 速度更新: \(String(format: "%.2f", calculatedSpeed)) m/s (\(String(format: "%.1f", calculatedSpeed * 3.6)) km/h)")
                } else {
                    print("⚠️ 过滤异常速度: \(String(format: "%.2f", calculatedSpeed)) m/s")
                }
            }
        }
    }

    /// 更新配速计算
    private func updatePace() {
        // 计算当前配速（分钟/公里）
        if currentSpeed > 0 && currentSpeed.isFinite {
            currentPace = 1000 / (currentSpeed * 60)  // 转换为分钟/公里

            // 更新最佳配速
            if bestPace == 0 || (currentPace > 0 && currentPace < bestPace) {
                bestPace = currentPace
            }
        }
    }
    
    // MARK: - 获取当前位置地址
    func getCurrentLocationAddress() async -> String? {
        guard let location = currentLocation else { return nil }
        
        return await withCheckedContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    print("反向地理编码失败: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let address = self.formatAddress(from: placemark)
                continuation.resume(returning: address)
            }
        }
    }
    
    // MARK: - 搜索地点
    func searchLocations(query: String) async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        if let currentLocation = currentLocation {
            request.region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                latitudinalMeters: 10000,
                longitudinalMeters: 10000
            )
        }
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            return response.mapItems
        } catch {
            print("搜索失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - 获取附近地点
    func getNearbyLocations(category: LocationCategory = .all, radius: Double = 1000) async -> [EnhancedNearbyLocation] {
        guard let currentLocation = currentLocation else { return [] }
        
        // 模拟获取附近地点
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        return generateMockNearbyLocations(around: currentLocation, category: category, radius: radius)
    }
    
    // MARK: - 私有辅助方法
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let name = placemark.name {
            components.append(name)
        }
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        if let subLocality = placemark.subLocality {
            components.append(subLocality)
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        return components.joined(separator: ", ")
    }
    
    private func generateMockNearbyLocations(around location: CLLocation, category: LocationCategory, radius: Double) -> [EnhancedNearbyLocation] {
        let mockLocations = [
            ("星巴克咖啡", "购物中心1楼", LocationCategory.cafe, 150.0, 4.5, true),
            ("麦当劳", "商业街", LocationCategory.restaurant, 280.0, 4.2, true),
            ("华润万家", "购物中心B1", LocationCategory.shopping, 320.0, 4.3, true),
            ("中国银行", "金融街", LocationCategory.business, 450.0, 4.0, true),
            ("地铁站", "地铁1号线", LocationCategory.transport, 500.0, nil, nil),
            ("人民医院", "医疗区", LocationCategory.health, 680.0, 4.1, true),
            ("电影院", "购物中心3楼", LocationCategory.entertainment, 720.0, 4.4, true),
            ("图书馆", "文化区", LocationCategory.education, 850.0, 4.6, true)
        ]
        
        return mockLocations.compactMap { (name, address, cat, distance, rating, isOpen) in
            if category != .all && cat != category {
                return nil
            }
            
            if distance > radius {
                return nil
            }
            
            // 生成随机坐标（在指定半径内）
            let randomAngle = Double.random(in: 0...(2 * Double.pi))
            let randomDistance = Double.random(in: 0...distance)
            let deltaLat = randomDistance * cos(randomAngle) / 111000 // 大约111km每度
            let deltaLon = randomDistance * sin(randomAngle) / (111000 * cos(location.coordinate.latitude * Double.pi / 180))
            
            return EnhancedNearbyLocation(
                name: name,
                address: address,
                latitude: location.coordinate.latitude + deltaLat,
                longitude: location.coordinate.longitude + deltaLon,
                category: cat,
                distance: distance,
                rating: rating,
                isOpen: isOpen
            )
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension AppleMapService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("⚠️ 没有收到位置数据")
            return
        }

        print("📍 收到位置更新: \(String(format: "%.8f, %.8f", location.coordinate.latitude, location.coordinate.longitude))")
        print("   精度: \(location.horizontalAccuracy)m, 时间: \(location.timestamp)")

        // 使用新的位置处理逻辑（包含坐标转换和数据过滤）
        processLocationUpdate(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status

            print("🔐 定位权限状态变更: \(status)")

            switch status {
            case .authorizedWhenInUse:
                print("✅ 获得使用期间定位权限")
                self.errorMessage = nil
                self.startLocationUpdates()
            case .authorizedAlways:
                print("✅ 获得始终定位权限")
                self.errorMessage = nil
                self.configureBackgroundLocationIfNeeded()
                self.startLocationUpdates()
            case .denied:
                print("❌ 定位权限被拒绝")
                self.errorMessage = "位置权限被拒绝，请在设置中开启"
                self.stopLocationUpdates()
            case .restricted:
                print("❌ 定位权限受限")
                self.errorMessage = "位置权限受限"
                self.stopLocationUpdates()
            case .notDetermined:
                print("⏳ 定位权限未确定")
                break
            @unknown default:
                print("❓ 未知定位权限状态")
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ 定位失败: \(error.localizedDescription)")

        DispatchQueue.main.async {
            if let clError = error as? CLError {
                switch clError.code {
                case .locationUnknown:
                    self.errorMessage = "无法确定位置，请稍后重试"
                case .denied:
                    self.errorMessage = "位置权限被拒绝，请在设置中开启"
                case .network:
                    self.errorMessage = "网络错误，请检查网络连接"
                case .headingFailure:
                    self.errorMessage = "方向传感器错误"
                case .rangingUnavailable:
                    self.errorMessage = "测距功能不可用"
                case .rangingFailure:
                    self.errorMessage = "测距失败"
                default:
                    self.errorMessage = "定位服务错误: \(error.localizedDescription)"
                }
            } else {
                self.errorMessage = "定位服务错误: \(error.localizedDescription)"
            }
        }
    }
}
