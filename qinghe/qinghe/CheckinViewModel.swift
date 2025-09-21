import Foundation
import SwiftUI
import CoreLocation

// MARK: - 打卡ViewModel
@MainActor
class CheckinViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var isCheckingIn = false
    @Published var hasCheckedInToday = false
    @Published var todayCheckinRecord: CheckinAPIRecord?
    @Published var statistics: CheckinStatistics?
    @Published var recentCheckins: [CheckinAPIRecord] = []
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showCheckinToast = false
    @Published var checkinToastMessage = ""
    
    // 打卡表单数据
    @Published var checkinNote = ""
    @Published var checkinMood = ""
    @Published var checkinChallenges = ""
    @Published var useLocation = false
    @Published var currentLocation: CLLocation?
    @Published var locationAddress: String?
    
    // MARK: - Private Properties
    private let apiService = CheckinAPIService.shared
    private let locationManager = CLLocationManager()
    private var locationDelegate: LocationDelegate?
    
    // MARK: - Initialization
    init() {
        setupLocationManager()
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Public Methods
    
    /// 加载初始数据
    func loadInitialData() async {
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.checkTodayStatus() }
            group.addTask { await self.loadStatistics() }
            group.addTask { await self.loadRecentCheckins() }
        }
        
        isLoading = false
    }
    
    /// 刷新数据
    func refreshData() async {
        await loadInitialData()
    }
    
    /// 执行打卡
    func performCheckin() async {
        guard !isCheckingIn else { return }

        isCheckingIn = true
        errorMessage = nil

        do {
            // 准备位置信息
            var location: CheckinLocation?
            if useLocation, let currentLocation = currentLocation {
                location = CheckinLocation(
                    latitude: currentLocation.coordinate.latitude,
                    longitude: currentLocation.coordinate.longitude,
                    address: locationAddress ?? ""
                )
            }

            // 执行打卡
            let checkinRecord = try await apiService.checkin(
                note: checkinNote.isEmpty ? nil : checkinNote,
                mood: checkinMood.isEmpty ? nil : checkinMood,
                challenges: checkinChallenges.isEmpty ? nil : checkinChallenges,
                location: location
            )

            // 更新状态
            hasCheckedInToday = true
            todayCheckinRecord = checkinRecord

            // 清空表单
            clearCheckinForm()

            // 显示成功提示
            checkinToastMessage = "打卡成功！"
            showCheckinToast = true

            // 刷新数据
            await loadStatistics()
            await loadRecentCheckins()

        } catch {
            handleError(error)
        }

        isCheckingIn = false
    }
    
    /// 检查今日打卡状态
    func checkTodayStatus() async {
        do {
            let status = try await apiService.getTodayCheckinStatus()
            hasCheckedInToday = status.hasCheckedIn
            todayCheckinRecord = status.checkin
        } catch {
            print("检查今日状态失败: \(error)")
        }
    }

    /// 加载统计数据
    func loadStatistics() async {
        do {
            statistics = try await apiService.getCheckinStatistics()
        } catch {
            print("加载统计数据失败: \(error)")
        }
    }

    /// 加载最近的打卡记录
    func loadRecentCheckins(limit: Int = 10) async {
        do {
            let response = try await apiService.getCheckinRecords(page: 1, limit: limit)
            recentCheckins = response.checkins
        } catch {
            print("加载最近记录失败: \(error)")
        }
    }
    
    /// 请求位置权限
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// 获取当前位置
    func getCurrentLocation() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        locationManager.requestLocation()
    }
    
    /// 清空打卡表单
    func clearCheckinForm() {
        checkinNote = ""
        checkinMood = ""
        checkinChallenges = ""
        useLocation = false
        currentLocation = nil
        locationAddress = nil
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationDelegate = LocationDelegate { [weak self] location in
            Task { @MainActor in
                await self?.updateLocation(location)
            }
        }
        
        locationManager.delegate = locationDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    @MainActor
    private func updateLocation(_ location: CLLocation) async {
        currentLocation = location
        await reverseGeocodeLocation(location)
    }
    
    @MainActor
    private func reverseGeocodeLocation(_ location: CLLocation) async {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                locationAddress = formatAddress(from: placemark)
            }
        } catch {
            print("反向地理编码失败: \(error)")
            locationAddress = "位置获取失败"
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let country = placemark.country {
            components.append(country)
        }
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let subLocality = placemark.subLocality {
            components.append(subLocality)
        }
        
        return components.joined(separator: "")
    }
    
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.model) \(device.systemName) \(device.systemVersion)"
    }
    
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkManager.NetworkError {
            switch networkError {
            case .networkError(let message):
                errorMessage = message
            case .noData:
                errorMessage = "服务器响应无效"
            case .decodingError:
                errorMessage = "数据解析失败"
            case .serverError(let code):
                errorMessage = "服务器错误：\(code)"
            case .serverMessage(let message):
                errorMessage = message
            case .rateLimitExceeded:
                errorMessage = "请求过于频繁，请稍后再试"
            case .invalidURL:
                errorMessage = "请求地址无效"
            }
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }
}

// MARK: - Location Delegate
private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    private let onLocationUpdate: (CLLocation) -> Void
    
    init(onLocationUpdate: @escaping (CLLocation) -> Void) {
        self.onLocationUpdate = onLocationUpdate
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdate(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置获取失败: \(error)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            print("位置权限被拒绝")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Extensions
extension CheckinViewModel {
    /// 获取连续天数显示文本
    var consecutiveDaysText: String {
        guard let stats = statistics else { return "0" }
        return "\(stats.consecutiveDays)"
    }
    
    /// 获取本月完成率显示文本
    var completionRateText: String {
        guard let stats = statistics else { return "0%" }
        let calendar = Calendar.current
        let now = Date()
        let _ = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let daysInMonth = calendar.dateInterval(of: .month, for: now)?.duration ?? 0
        let totalDaysInMonth = Int(daysInMonth / 86400)
        
        let rate = totalDaysInMonth > 0 ? Double(stats.thisMonthDays) / Double(totalDaysInMonth) : 0.0
        return String(format: "%.0f%%", rate * 100)
    }
    
    /// 获取总打卡天数显示文本
    var totalDaysText: String {
        guard let stats = statistics else { return "0" }
        return "\(stats.totalDays)"
    }
    
    /// 检查是否可以打卡
    var canCheckin: Bool {
        return !hasCheckedInToday && !isCheckingIn
    }
    
    /// 获取打卡按钮文本
    var checkinButtonText: String {
        if isCheckingIn {
            return "打卡中..."
        } else if hasCheckedInToday {
            return "今日已打卡"
        } else {
            return "立即打卡"
        }
    }
}


