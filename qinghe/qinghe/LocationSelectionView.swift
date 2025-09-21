import SwiftUI
import MapKit
import CoreLocation

struct LocationSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = AppleMapService.shared
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedLocation: CLLocation?
    @State private var selectedLocationName = ""
    @State private var isSearching = false
    @State private var nearbyLocations: [NearbyLocation] = []
    @State private var enhancedNearbyLocations: [EnhancedNearbyLocation] = []
    @State private var filteredNearbyLocations: [EnhancedNearbyLocation] = []
    @State private var selectedLocationFilter: LocationCategory = .all

    let onLocationSelected: (String, Double?, Double?) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            searchSection

            // 附近地名列表
            nearbyLocationsList
        }
        .background(Color(.systemGray6))
        .navigationTitle("选择位置")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            setupLocation()
            // 延迟加载附近地点，确保位置权限获取完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                loadNearbyLocations()
            }
        }
    }
    
    // MARK: - View Components
    
    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("搜索位置", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        searchLocation()
                    }
                    .onChange(of: searchText) { newValue in
                        if newValue.isEmpty {
                            isSearching = false
                            searchResults = []
                        } else {
                            searchLocation()
                        }
                    }

                if !searchText.isEmpty {
                    Button("清除") {
                        searchText = ""
                        searchResults = []
                        isSearching = false
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
    
    private var nearbyLocationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // 当前位置选项
                currentLocationSection

                // 搜索结果或附近地点
                if isSearching && !searchResults.isEmpty {
                    searchResultsSection
                } else if !isSearching {
                    nearbyLocationsSection
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    private var currentLocationSection: some View {
        VStack(spacing: 0) {
            Button(action: useCurrentLocation) {
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("使用当前位置")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        if locationManager.isTracking {
                            Text("正在获取位置...")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        } else {
                            Text("自动定位到您的当前位置")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if locationManager.isTracking {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(locationManager.isTracking)

            Divider()
                .padding(.leading, 48)
        }
    }
    
    private var searchResultsSection: some View {
        ForEach(searchResults, id: \.self) { item in
            LocationResultRow(item: item) {
                selectLocation(item)
            }
            Divider()
                .padding(.leading, 48)
        }
    }

    private var nearbyLocationsSection: some View {
        VStack(spacing: 0) {
            // 附近地点标题
            HStack {
                Text("附近地点")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))

            // 附近地点列表
            ForEach(filteredNearbyLocations.isEmpty ? enhancedNearbyLocations : filteredNearbyLocations, id: \.id) { location in
                Button(action: {
                    selectEnhancedNearbyLocation(location)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            // 上面显示地址名称（具体地点名称）
                            Text(location.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            // 下面显示完整详细地址
                            Text(location.address)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(String(format: "%.0fm", location.distance))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())

                Divider()
                    .padding(.leading, 48)
            }
        }
    }
    

    
    // MARK: - Data

    private func loadNearbyLocations() {
        print("🔍 开始加载附近地点...")

        // 检查授权状态，避免在主线程上直接启动位置更新
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // 已授权，可以启动位置更新
            locationManager.startLocationUpdates()

            // 等待位置更新，然后加载真实的附近地点
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.loadRealNearbyLocations()
            }
        case .notDetermined:
            // 未确定，请求权限，等待授权回调
            locationManager.requestLocationPermission()

            // 等待权限授权完成后再次尝试
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.loadNearbyLocations()
            }
        case .denied, .restricted:
            // 权限被拒绝，直接显示备用数据
            print("⚠️ 位置权限被拒绝，使用备用数据")
            loadFallbackNearbyLocations()
        @unknown default:
            loadFallbackNearbyLocations()
        }
    }

    /// 加载真实的附近地点数据
    private func loadRealNearbyLocations() {
        guard let currentLocation = locationManager.currentLocation else {
            print("⚠️ 当前位置不可用，使用备用数据")
            loadFallbackNearbyLocations()
            return
        }

        print("📍 当前位置可用，加载真实附近地点")

        // 使用AppleMapService获取附近地点
        Task {
            do {
                let realNearbyLocations = await locationManager.getNearbyLocations(category: .all, radius: 1000)

                await MainActor.run {
                    if !realNearbyLocations.isEmpty {
                        print("✅ 成功加载 \(realNearbyLocations.count) 个附近地点")
                        self.enhancedNearbyLocations = realNearbyLocations
                        self.filteredNearbyLocations = realNearbyLocations
                    } else {
                        print("⚠️ 未找到附近地点，使用备用数据")
                        self.loadFallbackNearbyLocations()
                    }
                }
            }
        }
    }

    /// 备用的附近地点数据（当真实搜索失败时使用）
    private func loadFallbackNearbyLocations() {
        print("⚠️ 使用备用地点数据")
        nearbyLocations = [
            NearbyLocation(name: "位置获取失败", address: "请检查位置权限设置或网络连接", latitude: 0.0, longitude: 0.0, category: "other", distance: 0.0),
        ]

        enhancedNearbyLocations = nearbyLocations.map { location in
            EnhancedNearbyLocation(
                name: location.name,
                address: location.address,
                latitude: location.latitude,
                longitude: location.longitude,
                category: .other,
                distance: location.distance,
                rating: nil,
                isOpen: nil
            )
        }

        filteredNearbyLocations = enhancedNearbyLocations
    }
    
    // MARK: - Methods
    
    private func setupLocation() {
        locationManager.requestLocationPermission()
    }
    
    private func useCurrentLocation() {
        // 检查授权状态，避免在主线程上直接启动位置更新
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // 已授权，可以启动位置更新
            locationManager.startLocationUpdates()

            // 监听位置更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if let currentLocation = locationManager.currentLocation {
                    selectedLocation = currentLocation

                    // 反向地理编码获取地址名称
                    let geocoder = CLGeocoder()
                    geocoder.reverseGeocodeLocation(currentLocation) { placemarks, error in
                        if let placemark = placemarks?.first {
                            let address = formatChineseAddressFromPlacemark(placemark)
                            selectedLocationName = address
                            onLocationSelected(address, currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
                            dismiss()
                        }
                    }
                }
            }
        case .notDetermined:
            // 未确定，请求权限
            locationManager.requestLocationPermission()
        case .denied, .restricted:
            // 权限被拒绝，提示用户
            print("⚠️ 位置权限被拒绝，无法获取当前位置")
        @unknown default:
            break
        }
    }
    
    private func searchLocation() {
        guard !searchText.isEmpty else { return }

        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            Task { @MainActor in
                if let response = response {
                    // 将搜索结果转换为增强的地点信息，包含智能识别的类型
                    self.searchResults = response.mapItems

                    // 同时更新附近地点列表，添加搜索到的地点（如果不存在的话）
                    let newLocations = response.mapItems.prefix(5).compactMap { mapItem -> EnhancedNearbyLocation? in
                        guard let name = mapItem.name else { return nil }
                        let address = mapItem.placemark.title ?? ""
                        let latitude = mapItem.placemark.coordinate.latitude
                        let longitude = mapItem.placemark.coordinate.longitude

                        // 检查是否已存在
                        let exists = self.enhancedNearbyLocations.contains { $0.name == name }
                        if !exists {
                            return EnhancedNearbyLocation(
                                name: name,
                                address: address,
                                latitude: latitude,
                                longitude: longitude,
                                category: .other,
                                distance: 0.0,
                                rating: nil,
                                isOpen: nil
                            )
                        }
                        return nil
                    }

                    // 将新搜索到的地点添加到列表顶部
                    if !newLocations.isEmpty {
                        self.enhancedNearbyLocations = newLocations + self.enhancedNearbyLocations
                        self.filterNearbyLocations()
                    }
                } else {
                    self.searchResults = []
                }
            }
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        selectedLocationName = item.name ?? formatAddress(from: item.placemark)
        let latitude = item.placemark.coordinate.latitude
        let longitude = item.placemark.coordinate.longitude
        onLocationSelected(selectedLocationName, latitude, longitude)
        dismiss()
    }

    private func selectNearbyLocation(_ location: NearbyLocation) {
        onLocationSelected(location.name, location.latitude, location.longitude)
        dismiss()
    }

    private func selectEnhancedNearbyLocation(_ location: EnhancedNearbyLocation) {
        onLocationSelected(location.name, location.latitude, location.longitude)
        dismiss()
    }

    private func filterNearbyLocations() {
        if selectedLocationFilter == .all {
            filteredNearbyLocations = enhancedNearbyLocations
        } else {
            filteredNearbyLocations = enhancedNearbyLocations.filter { $0.category == selectedLocationFilter }
        }
    }
}

// MARK: - Location Category Classifier

/// 智能地点类型分类器 - 根据地点名称和地址自动识别类型
struct LocationCategoryClassifier {

    /// 根据地点名称和地址智能识别地点类型
    static func classify(name: String, address: String) -> LocationCategory {
        let fullText = "\(name) \(address)".lowercased()

        // 小区住宅关键词
        let residentialKeywords = ["小区", "花园", "公寓", "家园", "城", "苑", "居", "庭", "墅", "村", "社区", "住宅", "新城", "华府", "豪庭", "雅苑", "名邸", "府邸", "别墅", "洋房"]
        if containsAny(fullText, keywords: residentialKeywords) {
            return .residential
        }

        // 商超购物关键词
        let shoppingKeywords = ["商城", "购物", "百货", "超市", "商场", "广场", "太古里", "万达", "银泰", "大悦城", "商业", "mall", "plaza", "市场", "店", "专卖", "旗舰"]
        if containsAny(fullText, keywords: shoppingKeywords) {
            return .shopping
        }

        // 道路街道关键词
        let roadKeywords = ["路", "街", "大街", "大道", "环路", "高速", "快速路", "立交", "桥", "胡同", "巷", "弄", "里", "号路", "中路", "东路", "西路", "南路", "北路"]
        if containsAny(fullText, keywords: roadKeywords) {
            return .road
        }

        // 地标建筑关键词
        let landmarkKeywords = ["大厦", "中心", "大楼", "塔", "soho", "国贸", "金融街", "cbd", "世贸", "国际", "广场", "天安门", "故宫", "长城", "鸟巢", "水立方"]
        if containsAny(fullText, keywords: landmarkKeywords) {
            return .landmark
        }

        // 公园景点关键词
        let parkKeywords = ["公园", "园", "景区", "景点", "森林", "湿地", "植物园", "动物园", "游乐园", "主题公园", "广场", "绿地", "山", "湖", "河", "海", "寺", "庙", "宫"]
        if containsAny(fullText, keywords: parkKeywords) {
            return .park
        }

        // 交通枢纽关键词
        let transportKeywords = ["地铁站", "火车站", "高铁站", "机场", "汽车站", "公交站", "停车场", "地铁", "站", "枢纽", "交通", "客运", "航站楼"]
        if containsAny(fullText, keywords: transportKeywords) {
            return .transport
        }

        // 餐饮美食关键词
        let restaurantKeywords = ["餐厅", "饭店", "酒店", "咖啡", "茶", "火锅", "烤肉", "料理", "食府", "美食", "小吃", "快餐", "西餐", "中餐", "日料", "韩料", "麦当劳", "肯德基", "星巴克", "海底捞"]
        if containsAny(fullText, keywords: restaurantKeywords) {
            return .restaurant
        }

        // 医疗健康关键词
        let hospitalKeywords = ["医院", "诊所", "卫生院", "急救", "医疗", "健康", "药店", "药房", "体检", "口腔", "眼科", "妇科", "儿科", "中医", "西医"]
        if containsAny(fullText, keywords: hospitalKeywords) {
            return .hospital
        }

        // 教育机构关键词
        let educationKeywords = ["学校", "大学", "学院", "中学", "小学", "幼儿园", "培训", "教育", "图书馆", "博物馆", "科技馆", "清华", "北大", "人大", "师范"]
        if containsAny(fullText, keywords: educationKeywords) {
            return .education
        }

        // 政府机构关键词
        let governmentKeywords = ["政府", "市政", "区政府", "街道办", "派出所", "公安", "法院", "检察院", "税务", "工商", "民政", "社保", "公积金", "办事处"]
        if containsAny(fullText, keywords: governmentKeywords) {
            return .government
        }

        // 写字楼关键词
        let officeKeywords = ["写字楼", "办公楼", "商务楼", "科技园", "产业园", "孵化器", "创业园", "软件园", "金融中心", "商务中心"]
        if containsAny(fullText, keywords: officeKeywords) {
            return .office
        }

        // 酒店住宿关键词
        let hotelKeywords = ["酒店", "宾馆", "旅馆", "客栈", "民宿", "度假村", "resort", "hotel", "inn", "青旅", "招待所"]
        if containsAny(fullText, keywords: hotelKeywords) {
            return .hotel
        }

        // 银行金融关键词
        let bankKeywords = ["银行", "atm", "取款机", "证券", "保险", "金融", "投资", "理财", "信贷", "工行", "建行", "农行", "中行", "招行"]
        if containsAny(fullText, keywords: bankKeywords) {
            return .bank
        }

        // 加油站关键词
        let gasKeywords = ["加油站", "中石油", "中石化", "壳牌", "bp", "加气站", "充电站"]
        if containsAny(fullText, keywords: gasKeywords) {
            return .gas
        }

        // 默认返回其他类型
        return .other
    }

    /// 检查文本是否包含任何关键词
    private static func containsAny(_ text: String, keywords: [String]) -> Bool {
        return keywords.contains { keyword in
            text.contains(keyword)
        }
    }
}

struct LocationResultRow: View {
    let item: MKMapItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    // 主要名称（具体地点名称）
                    Text(item.name ?? "未知位置")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    // 详细地址（省市县区街道等）
                    let fullAddress = formatAddress(from: item.placemark)
                    if !fullAddress.isEmpty {
                        Text(extractDetailedAddress(from: fullAddress))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 地点类型筛选芯片组件
struct LocationCategoryChip: View {
    let category: LocationCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))

                Text(category.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : category.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? category.color : category.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(category.color, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper Functions

/// 格式化中国地址 - 符合中国用户习惯
func formatChineseAddress(_ address: String) -> String {
    // 如果地址已经是中文格式，直接返回
    if address.contains("省") || address.contains("市") || address.contains("区") || address.contains("县") {
        return address
    }

    // 对于英文格式的地址，尝试重新排列
    let components = address.components(separatedBy: ", ")
    if components.count > 1 {
        // 反转顺序，让最具体的地址在前面
        return components.reversed().joined(separator: " ")
    }

    return address
}

/// 格式化距离显示
func formatDistance(_ distance: Double) -> String {
    if distance < 1000 {
        return String(format: "%.0fm", distance)
    } else {
        return String(format: "%.1fkm", distance / 1000)
    }
}

/// 从完整地址中提取详细地址信息（省市县区街道等）
func extractDetailedAddress(from fullAddress: String) -> String {
    // 如果地址包含中文行政区划，直接返回
    if fullAddress.contains("省") || fullAddress.contains("市") || fullAddress.contains("区") || fullAddress.contains("县") {
        return fullAddress
    }

    // 对于英文格式地址，尝试提取有用信息
    let components = fullAddress.components(separatedBy: ", ")

    // 过滤掉重复的地点名称，只保留地理位置信息
    let filteredComponents = components.filter { component in
        !component.isEmpty &&
        component.count > 2 && // 过滤太短的组件
        !component.lowercased().contains("unnamed") // 过滤未命名的地址
    }

    if filteredComponents.count > 1 {
        // 取最后几个组件作为详细地址（通常是更大的地理区域）
        return filteredComponents.suffix(min(3, filteredComponents.count)).joined(separator: " ")
    }

    return fullAddress.isEmpty ? "位置信息获取中..." : fullAddress
}

/// 从CLPlacemark格式化中国风格的地址
func formatChineseAddressFromPlacemark(_ placemark: CLPlacemark) -> String {
    var components: [String] = []

    // 优先使用具体的地点名称
    if let name = placemark.name, !name.isEmpty {
        components.append(name)
    }

    // 如果没有具体名称，构建地址
    if components.isEmpty {
        var addressComponents: [String] = []

        // 按照中国习惯的顺序：省 -> 市 -> 区/县 -> 街道 -> 门牌号
        if let administrativeArea = placemark.administrativeArea, !administrativeArea.isEmpty {
            addressComponents.append(administrativeArea)
        }

        if let locality = placemark.locality, !locality.isEmpty {
            addressComponents.append(locality)
        }

        if let subLocality = placemark.subLocality, !subLocality.isEmpty {
            addressComponents.append(subLocality)
        }

        if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
            addressComponents.append(thoroughfare)
        }

        if let subThoroughfare = placemark.subThoroughfare, !subThoroughfare.isEmpty {
            addressComponents.append(subThoroughfare)
        }

        if !addressComponents.isEmpty {
            components.append(addressComponents.joined(separator: ""))
        }
    }

    return components.isEmpty ? "当前位置" : components.joined(separator: " ")
}

func formatAddress(from placemark: CLPlacemark) -> String {
    var components: [String] = []

    // 按照中国习惯：具体地址在前，行政区域在后
    if let name = placemark.name, !name.isEmpty {
        components.append(name)
    }

    // 构建行政区域信息
    var administrativeComponents: [String] = []

    if let administrativeArea = placemark.administrativeArea, !administrativeArea.isEmpty {
        administrativeComponents.append(administrativeArea)
    }

    if let locality = placemark.locality, !locality.isEmpty {
        administrativeComponents.append(locality)
    }

    if let subLocality = placemark.subLocality, !subLocality.isEmpty {
        administrativeComponents.append(subLocality)
    }

    if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
        administrativeComponents.append(thoroughfare)
    }

    // 如果有行政区域信息，添加到组件中
    if !administrativeComponents.isEmpty {
        components.append(administrativeComponents.joined(separator: ""))
    }

    return components.joined(separator: " ")
}

#Preview {
    LocationSelectionView { location, latitude, longitude in
        print("Selected location: \(location), 纬度: \(latitude ?? 0), 经度: \(longitude ?? 0)")
    }
}

