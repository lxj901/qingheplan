import SwiftUI
import MapKit
import CoreLocation

// MARK: - Apple 地图视图
struct AppleMapView: UIViewRepresentable {
    let zoomLevel: Double
    let showUserLocation: Bool
    let mapType: MKMapType
    @Binding var shouldCenterOnLocation: Bool
    @Binding var mapRegion: MKCoordinateRegion?
    let routePoints: [CLLocationCoordinate2D]
    let currentLocation: CLLocation?
    // 新增：是否展示起终点标注、可选的路段时间戳（用于速度着色）
    let showStartEndMarkers: Bool
    let routeTimestamps: [Date]?

    init(
        zoomLevel: Double = 17.0,
        showUserLocation: Bool = true,
        mapType: MKMapType = .standard,
        shouldCenterOnLocation: Binding<Bool>,
        mapRegion: Binding<MKCoordinateRegion?>,
        routePoints: [CLLocationCoordinate2D] = [],
        currentLocation: CLLocation? = nil,
        showStartEndMarkers: Bool = false,
        routeTimestamps: [Date]? = nil
    ) {
        self.zoomLevel = zoomLevel
        self.showUserLocation = showUserLocation
        self.mapType = mapType
        self._shouldCenterOnLocation = shouldCenterOnLocation
        self._mapRegion = mapRegion
        self.routePoints = routePoints
        self.currentLocation = currentLocation
        self.showStartEndMarkers = showStartEndMarkers
        self.routeTimestamps = routeTimestamps
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = mapType
        mapView.showsUserLocation = showUserLocation
        mapView.userTrackingMode = .none

        // 设置地图样式（在模拟器中使用平面地形，减少渲染告警）
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = false
        if #available(iOS 17.0, *) {
            let config = MKStandardMapConfiguration(elevationStyle: .flat)
            mapView.preferredConfiguration = config
        }

        // 如果有当前位置，立即设置地图区域
        if let location = currentLocation {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 50,
                longitudinalMeters: 50
            )
            mapView.setRegion(region, animated: false)
            print("🎯 AppleMapView初始化: 立即设置地图区域到 \(location.coordinate)")
        }

        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 更新地图类型
        if mapView.mapType != mapType {
            mapView.mapType = mapType
        }

        // 更新用户位置显示
        if mapView.showsUserLocation != showUserLocation {
            mapView.showsUserLocation = showUserLocation
        }

        // 优先响应来自上层绑定的 mapRegion（例如强制30米视野居中）
        if let targetRegion = mapRegion {
            let current = mapView.region
            // 粗略判断是否需要更新，避免重复 setRegion 导致抖动
            let centerDelta = abs(current.center.latitude - targetRegion.center.latitude) + abs(current.center.longitude - targetRegion.center.longitude)
            let spanDelta = abs(current.span.latitudeDelta - targetRegion.span.latitudeDelta) + abs(current.span.longitudeDelta - targetRegion.span.longitudeDelta)
            if centerDelta > 1e-6 || spanDelta > 1e-6 {
                mapView.setRegion(targetRegion, animated: true)
            }
            // 外部已指定区域，重置一次性居中标志
            DispatchQueue.main.async {
                self.shouldCenterOnLocation = false
            }
        }
        // 其次根据 shouldCenterOnLocation + currentLocation 进行一次性居中
        else if shouldCenterOnLocation, let location = currentLocation {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 50,  // 50米可见范围
                longitudinalMeters: 50  // 50米可见范围
            )
            mapView.setRegion(region, animated: true)
            print("🎯 AppleMapView: 地图居中到位置 \(location.coordinate)，50米视野")
            DispatchQueue.main.async {
                self.shouldCenterOnLocation = false
            }
        }

        // 更新路线
        updateRoute(mapView: mapView, coordinator: context.coordinator)
    }
    
    private func updateRoute(mapView: MKMapView, coordinator: Coordinator) {
        // 多段安全渲染：根据点间距自动分段，避免“跨越连线”导致混乱
        // 视觉：三层覆盖物（白描 + 主线 + 渐变彩线），前两层用 MKMultiPolyline 承载所有段
        let count = routePoints.count
        guard count >= 2 else {
            if let outline = coordinator.outlineOverlay { mapView.removeOverlay(outline) }
            if let main = coordinator.mainOverlay { mapView.removeOverlay(main) }
            // 移除旧的渐变覆盖物
            if !coordinator.gradientOverlays.isEmpty {
                coordinator.gradientOverlays.forEach { mapView.removeOverlay($0) }
            }
            coordinator.gradientOverlays.removeAll(keepingCapacity: false)
            coordinator.overlayColors.removeAll(keepingCapacity: false)
            // 清理起终点标注
            if let startAnno = coordinator.startAnnotation { mapView.removeAnnotation(startAnno) }
            if let endAnno = coordinator.endAnnotation { mapView.removeAnnotation(endAnno) }
            coordinator.startAnnotation = nil
            coordinator.endAnnotation = nil
            coordinator.outlineOverlay = nil
            coordinator.mainOverlay = nil
            return
        }

        // 组装多段折线
        let gapThreshold: CLLocationDistance = 100.0  // 超过100m视为断开
        var polylines: [MKPolyline] = []
        var currentSegment: [CLLocationCoordinate2D] = []

        func flushSegment() {
            if currentSegment.count >= 2 {
                var seg = currentSegment
                let poly = MKPolyline(coordinates: &seg, count: seg.count)
                polylines.append(poly)
            }
            currentSegment.removeAll(keepingCapacity: true)
        }

        for (idx, point) in routePoints.enumerated() {
            if idx == 0 {
                currentSegment.append(point)
                continue
            }
            let prev = routePoints[idx - 1]
            let d = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
                .distance(from: CLLocation(latitude: point.latitude, longitude: point.longitude))
            if d > gapThreshold {
                // 断开上一段
                flushSegment()
                currentSegment.append(point)
            } else {
                currentSegment.append(point)
            }
        }
        // 刷新最后一段
        flushSegment()

        // 如果所有段都无法组成有效折线，则退出
        guard !polylines.isEmpty else {
            if let outline = coordinator.outlineOverlay { mapView.removeOverlay(outline) }
            if let main = coordinator.mainOverlay { mapView.removeOverlay(main) }
            // 清空渐变层
            if !coordinator.gradientOverlays.isEmpty {
                coordinator.gradientOverlays.forEach { mapView.removeOverlay($0) }
            }
            coordinator.gradientOverlays.removeAll(keepingCapacity: false)
            coordinator.overlayColors.removeAll(keepingCapacity: false)
            coordinator.outlineOverlay = nil
            coordinator.mainOverlay = nil
            return
        }

        let outlineMulti = MKMultiPolyline(polylines)
        let mainMulti = MKMultiPolyline(polylines)

        // 替换旧覆盖物（先描边后主线）
        if let outline = coordinator.outlineOverlay { mapView.removeOverlay(outline) }
        if let main = coordinator.mainOverlay { mapView.removeOverlay(main) }
        // 清理旧的渐变覆盖物
        if !coordinator.gradientOverlays.isEmpty {
            coordinator.gradientOverlays.forEach { mapView.removeOverlay($0) }
        }
        coordinator.gradientOverlays.removeAll(keepingCapacity: false)
        coordinator.overlayColors.removeAll(keepingCapacity: false)

        mapView.addOverlay(outlineMulti)
        mapView.addOverlay(mainMulti)
        coordinator.outlineOverlay = outlineMulti
        coordinator.mainOverlay = mainMulti

        // 追加彩色覆盖物（细线段拼接）
        // 如果提供了时间戳，则按“速度”映射颜色；否则按“整体进度”映射颜色
        // 统计总段数用于归一化
        let totalSegments: Int = polylines.reduce(0) { partial, poly in
            partial + max(0, poly.pointCount - 1)
        }
        guard totalSegments > 0 else { return }

        // 预计算每段速度（km/h），与 routePoints 一一对应的段（count-1）
        var segmentSpeeds: [Double]? = nil
        if let ts = routeTimestamps, ts.count == routePoints.count, routePoints.count >= 2 {
            var speeds: [Double] = []
            speeds.reserveCapacity(routePoints.count - 1)
            for i in 0..<(routePoints.count - 1) {
                let p0 = routePoints[i]
                let p1 = routePoints[i + 1]
                let dMeters = CLLocation(latitude: p0.latitude, longitude: p0.longitude)
                    .distance(from: CLLocation(latitude: p1.latitude, longitude: p1.longitude))
                let dt = ts[i + 1].timeIntervalSince(ts[i])
                if dt > 0 {
                    let kmh = (dMeters / 1000.0) / (dt / 3600.0)
                    speeds.append(kmh)
                } else {
                    speeds.append(0)
                }
            }
            // 计算速度范围（排除0以降低噪声）
            let positive = speeds.filter { $0 > 0 }
            if let minV = positive.min(), let maxV = positive.max(), maxV > minV {
                segmentSpeeds = speeds
                coordinator.speedRange = (minV, maxV)
            } else {
                segmentSpeeds = speeds
                coordinator.speedRange = (0, max(10, speeds.max() ?? 10))
            }
        } else {
            coordinator.speedRange = nil
        }

        var seenSegments = 0
        for poly in polylines {
            var coords = [CLLocationCoordinate2D](repeating: .init(), count: poly.pointCount)
            poly.getCoordinates(&coords, range: NSRange(location: 0, length: poly.pointCount))
            if coords.count >= 2 {
                for i in 0..<(coords.count - 1) {
                    let pair = [coords[i], coords[i + 1]]
                    let small = MKPolyline(coordinates: pair, count: 2)
                    let color: UIColor
                    if let speeds = segmentSpeeds {
                        let v = speeds[min(seenSegments, speeds.count - 1)]
                        let (minV, maxV) = coordinator.speedRange ?? (0, 20)
                        color = Self.colorForSpeed(v, minSpeed: minV, maxSpeed: maxV)
                    } else {
                        // 按整体进度生成颜色（橙→绿）
                        let t = CGFloat(seenSegments) / CGFloat(max(1, totalSegments - 1))
                        color = Self.gradientColor(t)
                    }
                    coordinator.overlayColors[ObjectIdentifier(small)] = color
                    coordinator.gradientOverlays.append(small)
                    mapView.addOverlay(small)
                    seenSegments += 1
                }
            }
        }

        // 起终点标注
        if showStartEndMarkers {
            // 使用整体首末点，避免分段影响
            let startCoord = routePoints.first!
            let endCoord = routePoints.last!
            // 清理旧标注
            if let startAnno = coordinator.startAnnotation { mapView.removeAnnotation(startAnno) }
            if let endAnno = coordinator.endAnnotation { mapView.removeAnnotation(endAnno) }
            let sa = StartAnnotation(coordinate: startCoord)
            let ea = EndAnnotation(coordinate: endCoord)
            coordinator.startAnnotation = sa
            coordinator.endAnnotation = ea
            mapView.addAnnotations([sa, ea])
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // 起点/终点标注类型
    final class StartAnnotation: NSObject, MKAnnotation {
        dynamic var coordinate: CLLocationCoordinate2D
        init(coordinate: CLLocationCoordinate2D) { self.coordinate = coordinate; super.init() }
    }
    final class EndAnnotation: NSObject, MKAnnotation {
        dynamic var coordinate: CLLocationCoordinate2D
        init(coordinate: CLLocationCoordinate2D) { self.coordinate = coordinate; super.init() }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: AppleMapView

        init(_ parent: AppleMapView) {
            self.parent = parent
        }

        // 保持对当前两条覆盖物的引用（描边 + 主线），类型可能为 MKMultiPolyline 或 MKPolyline
        var outlineOverlay: MKOverlay?
        var mainOverlay: MKOverlay?
        // 渐变层相关：记录所有小段 overlay 以及对应颜色
        var gradientOverlays: [MKPolyline] = []
        var overlayColors: [ObjectIdentifier: UIColor] = [:]
        // 起终点标注
        var startAnnotation: StartAnnotation?
        var endAnnotation: EndAnnotation?
        // 速度范围（km/h），用于颜色映射
        var speedRange: (min: Double, max: Double)?

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // 创建合适的渲染器
            let renderer: MKOverlayPathRenderer
            if let multi = overlay as? MKMultiPolyline {
                renderer = MKMultiPolylineRenderer(multiPolyline: multi)
            } else if let poly = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: poly)
                renderer = r
            } else {
                return MKOverlayRenderer(overlay: overlay)
            }

            // 设置高质量渲染
            renderer.lineJoin = .round
            renderer.lineCap = .round
            renderer.shouldRasterize = false  // 保持矢量渲染，避免模糊

            // 渐变彩线（最上层）：若该 overlay 在映射表中，则使用其专属颜色和更细线宽
            if let color = overlayColors[ObjectIdentifier(overlay)] {
                renderer.strokeColor = color
                renderer.lineWidth = 3.5
                renderer.alpha = 0.95
                return renderer
            }

            // 根据引用判断是描边还是主线
            if let outline = outlineOverlay, overlay === outline {
                // 外描边：更宽的半透明白色边框，增强对比度和立体感
                renderer.strokeColor = UIColor.white.withAlphaComponent(0.9)
                renderer.lineWidth = 7.0
                renderer.alpha = 0.85
            } else if let main = mainOverlay, overlay === main {
                // 主轨迹线：使用更鲜艳的青禾绿，增强视觉冲击力
                let qingheGreen = UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)  // 更鲜艳的绿色
                renderer.strokeColor = qingheGreen
                renderer.lineWidth = 4.5
                renderer.alpha = 1.0
            } else {
                // 兜底：使用增强的青禾绿主色调
                let qingheGreen = UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
                renderer.strokeColor = qingheGreen
                renderer.lineWidth = 4.5
                renderer.alpha = 1.0
            }

            return renderer
        }

        // 自定义起终点标注视图
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let start = annotation as? StartAnnotation {
                let id = "start-dot"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                if view == nil { view = MKAnnotationView(annotation: start, reuseIdentifier: id) }
                view?.annotation = start
                view?.canShowCallout = false
                view?.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
                view?.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                let circle = CAShapeLayer()
                circle.path = UIBezierPath(ovalIn: view!.bounds).cgPath
                circle.fillColor = UIColor.systemGreen.cgColor
                circle.strokeColor = UIColor.white.cgColor
                circle.lineWidth = 2
                view?.layer.addSublayer(circle)
                return view
            }
            if let end = annotation as? EndAnnotation {
                let id = "end-dot"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                if view == nil { view = MKAnnotationView(annotation: end, reuseIdentifier: id) }
                view?.annotation = end
                view?.canShowCallout = false
                view?.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
                view?.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                let circle = CAShapeLayer()
                circle.path = UIBezierPath(ovalIn: view!.bounds).cgPath
                circle.fillColor = UIColor.systemRed.cgColor
                circle.strokeColor = UIColor.white.cgColor
                circle.lineWidth = 2
                view?.layer.addSublayer(circle)
                return view
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.mapRegion = mapView.region
            }
        }
    }

    // 统一使用“速度说明条”的调色板（更慢→更快：绿→黄→橙→红）
    // 渐变采样工具：根据 t(0~1) 在线性插值多段颜色
    private static let legendStops: [(t: CGFloat, color: UIColor)] = [
        (0.00, UIColor(red: 52/255.0,  green: 199/255.0, blue:  89/255.0,  alpha: 1.0)), // #34C759 绿（慢）
        (0.25, UIColor(red: 166/255.0, green: 206/255.0, blue:  57/255.0,  alpha: 1.0)), // #A6CE39 绿黄
        (0.50, UIColor(red: 255/255.0, green: 214/255.0, blue:  10/255.0,  alpha: 1.0)), // #FFD60A 黄
        (0.75, UIColor(red: 255/255.0, green: 149/255.0, blue:   0/255.0,  alpha: 1.0)), // #FF9500 橙
        (1.00, UIColor(red: 255/255.0, green:  59/255.0, blue:  48/255.0,  alpha: 1.0))  // #FF3B30 红（快）
    ]

    private static func legendGradientColor(_ t: CGFloat) -> UIColor {
        let x = max(0.0, min(1.0, t))
        // 找到 x 所在的颜色区间
        for i in 0..<(legendStops.count - 1) {
            let a = legendStops[i]
            let b = legendStops[i + 1]
            if x >= a.t && x <= b.t {
                let localT = (x - a.t) / max(0.0001, b.t - a.t)
                return blend(start: a.color, end: b.color, t: localT)
            }
        }
        return legendStops.last!.color
    }

    // 生成渐变颜色（t: 0~1）—改为使用统一调色板
    private static func gradientColor(_ t: CGFloat) -> UIColor {
        return legendGradientColor(t)
    }

    // 按速度映射颜色（慢→快：绿→红）
    private static func colorForSpeed(_ v: Double, minSpeed: Double, maxSpeed: Double) -> UIColor {
        let lo = minSpeed
        let hi = maxSpeed > minSpeed ? maxSpeed : (minSpeed + 1)
        let t = CGFloat(Swift.max(0, Swift.min(1, (v - lo) / (hi - lo))))
        return legendGradientColor(t)
    }

    private static func blend(start: UIColor, end: UIColor, t: CGFloat) -> UIColor {
        var sr: CGFloat = 0, sg: CGFloat = 0, sb: CGFloat = 0, sa: CGFloat = 0
        var er: CGFloat = 0, eg: CGFloat = 0, eb: CGFloat = 0, ea: CGFloat = 0
        start.getRed(&sr, green: &sg, blue: &sb, alpha: &sa)
        end.getRed(&er, green: &eg, blue: &eb, alpha: &ea)
        let r = sr + (er - sr) * t
        let g = sg + (eg - sg) * t
        let b = sb + (eb - sb) * t
        let a = sa + (ea - sa) * t
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - 预览
struct AppleMapView_Previews: PreviewProvider {
    static var previews: some View {
        AppleMapView(
            shouldCenterOnLocation: .constant(false),
            mapRegion: .constant(nil)
        )
    }
}
