//
//  CoordinateConverter.swift
//  qinghe
//
//  Created by AI Assistant on 2025-09-08.
//  坐标系转换工具类 - 解决中国地区GPS偏移问题
//

import Foundation
import CoreLocation

// MARK: - 坐标系转换工具类
class CoordinateConverter {
    
    // MARK: - 常量定义
    private static let a: Double = 6378245.0  // 长半轴
    private static let ee: Double = 0.00669342162296594323  // 偏心率平方
    
    // MARK: - 坐标系转换方法
    
    /// WGS84转GCJ02（火星坐标系）
    /// - Parameter wgs84: WGS84坐标
    /// - Returns: GCJ02坐标
    static func wgs84ToGcj02(_ wgs84: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // 海外地区不需要转换
        if isOutOfChina(wgs84) {
            return wgs84
        }
        
        var dLat = transformLat(wgs84.longitude - 105.0, wgs84.latitude - 35.0)
        var dLon = transformLon(wgs84.longitude - 105.0, wgs84.latitude - 35.0)
        
        let radLat = wgs84.latitude / 180.0 * Double.pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)
        
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * Double.pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * Double.pi)
        
        return CLLocationCoordinate2D(
            latitude: wgs84.latitude + dLat,
            longitude: wgs84.longitude + dLon
        )
    }
    
    /// GCJ02转WGS84
    /// - Parameter gcj02: GCJ02坐标
    /// - Returns: WGS84坐标
    static func gcj02ToWgs84(_ gcj02: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // 海外地区不需要转换
        if isOutOfChina(gcj02) {
            return gcj02
        }
        
        var dLat = transformLat(gcj02.longitude - 105.0, gcj02.latitude - 35.0)
        var dLon = transformLon(gcj02.longitude - 105.0, gcj02.latitude - 35.0)
        
        let radLat = gcj02.latitude / 180.0 * Double.pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)
        
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * Double.pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * Double.pi)
        
        return CLLocationCoordinate2D(
            latitude: gcj02.latitude - dLat,
            longitude: gcj02.longitude - dLon
        )
    }
    
    /// GCJ02转BD09（百度坐标系）
    /// - Parameter gcj02: GCJ02坐标
    /// - Returns: BD09坐标
    static func gcj02ToBd09(_ gcj02: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let z = sqrt(gcj02.longitude * gcj02.longitude + gcj02.latitude * gcj02.latitude) + 0.00002 * sin(gcj02.latitude * Double.pi * 3000.0 / 180.0)
        let theta = atan2(gcj02.latitude, gcj02.longitude) + 0.000003 * cos(gcj02.longitude * Double.pi * 3000.0 / 180.0)
        
        return CLLocationCoordinate2D(
            latitude: z * sin(theta) + 0.006,
            longitude: z * cos(theta) + 0.0065
        )
    }
    
    /// BD09转GCJ02
    /// - Parameter bd09: BD09坐标
    /// - Returns: GCJ02坐标
    static func bd09ToGcj02(_ bd09: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let x = bd09.longitude - 0.0065
        let y = bd09.latitude - 0.006
        let z = sqrt(x * x + y * y) - 0.00002 * sin(y * Double.pi * 3000.0 / 180.0)
        let theta = atan2(y, x) - 0.000003 * cos(x * Double.pi * 3000.0 / 180.0)
        
        return CLLocationCoordinate2D(
            latitude: z * sin(theta),
            longitude: z * cos(theta)
        )
    }
    
    // MARK: - 辅助方法
    
    /// 判断是否在中国境内
    /// - Parameter coord: 坐标
    /// - Returns: 是否在中国境内
    private static func isOutOfChina(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.longitude < 72.004 || coord.longitude > 137.8347 ||
               coord.latitude < 0.8293 || coord.latitude > 55.8271
    }
    
    /// 纬度转换
    /// - Parameters:
    ///   - lon: 经度偏移
    ///   - lat: 纬度偏移
    /// - Returns: 转换后的纬度偏移
    private static func transformLat(_ lon: Double, _ lat: Double) -> Double {
        var ret = -100.0 + 2.0 * lon + 3.0 * lat + 0.2 * lat * lat + 0.1 * lon * lat + 0.2 * sqrt(abs(lon))
        ret += (20.0 * sin(6.0 * lon * Double.pi) + 20.0 * sin(2.0 * lon * Double.pi)) * 2.0 / 3.0
        ret += (20.0 * sin(lat * Double.pi) + 40.0 * sin(lat / 3.0 * Double.pi)) * 2.0 / 3.0
        ret += (160.0 * sin(lat / 12.0 * Double.pi) + 320 * sin(lat * Double.pi / 30.0)) * 2.0 / 3.0
        return ret
    }
    
    /// 经度转换
    /// - Parameters:
    ///   - lon: 经度偏移
    ///   - lat: 纬度偏移
    /// - Returns: 转换后的经度偏移
    private static func transformLon(_ lon: Double, _ lat: Double) -> Double {
        var ret = 300.0 + lon + 2.0 * lat + 0.1 * lon * lon + 0.1 * lon * lat + 0.1 * sqrt(abs(lon))
        ret += (20.0 * sin(6.0 * lon * Double.pi) + 20.0 * sin(2.0 * lon * Double.pi)) * 2.0 / 3.0
        ret += (20.0 * sin(lon * Double.pi) + 40.0 * sin(lon / 3.0 * Double.pi)) * 2.0 / 3.0
        ret += (150.0 * sin(lon / 12.0 * Double.pi) + 300.0 * sin(lon / 30.0 * Double.pi)) * 2.0 / 3.0
        return ret
    }
}

// MARK: - CLLocation 扩展
extension CLLocation {
    
    /// 获取转换为中国地图坐标系的位置
    /// - Returns: 转换后的CLLocation对象
    func convertedForChineseMap() -> CLLocation {
        let convertedCoordinate = CoordinateConverter.wgs84ToGcj02(self.coordinate)
        
        return CLLocation(
            coordinate: convertedCoordinate,
            altitude: self.altitude,
            horizontalAccuracy: self.horizontalAccuracy,
            verticalAccuracy: self.verticalAccuracy,
            course: self.course,
            speed: self.speed,
            timestamp: self.timestamp
        )
    }
    
    /// 获取原始WGS84坐标（从GCJ02转换回来）
    /// - Returns: WGS84坐标的CLLocation对象
    func convertedToWGS84() -> CLLocation {
        let convertedCoordinate = CoordinateConverter.gcj02ToWgs84(self.coordinate)
        
        return CLLocation(
            coordinate: convertedCoordinate,
            altitude: self.altitude,
            horizontalAccuracy: self.horizontalAccuracy,
            verticalAccuracy: self.verticalAccuracy,
            course: self.course,
            speed: self.speed,
            timestamp: self.timestamp
        )
    }
}

// MARK: - CLLocationCoordinate2D 扩展
extension CLLocationCoordinate2D {
    
    /// 验证坐标有效性
    var isValid: Bool {
        return CLLocationCoordinate2DIsValid(self) &&
               latitude >= -90 && latitude <= 90 &&
               longitude >= -180 && longitude <= 180
    }
    
    /// 转换为GCJ02坐标系
    var toGCJ02: CLLocationCoordinate2D {
        return CoordinateConverter.wgs84ToGcj02(self)
    }
    
    /// 转换为WGS84坐标系
    var toWGS84: CLLocationCoordinate2D {
        return CoordinateConverter.gcj02ToWgs84(self)
    }
    
    /// 转换为BD09坐标系
    var toBD09: CLLocationCoordinate2D {
        return CoordinateConverter.gcj02ToBd09(self.toGCJ02)
    }
}
