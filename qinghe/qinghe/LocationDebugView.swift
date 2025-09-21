//
//  LocationDebugView.swift
//  qinghe
//
//  Created by AI Assistant on 2025-09-08.
//  定位调试视图 - 用于诊断定位问题
//

import SwiftUI
import CoreLocation

struct LocationDebugView: View {
    @StateObject private var locationManager = AppleMapService.shared
    @State private var isShowingDebugInfo = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                Text("🛰️ 定位服务调试")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // 快速状态卡片
                VStack(spacing: 16) {
                    StatusCard(
                        title: "设备位置服务",
                        status: CLLocationManager.locationServicesEnabled(),
                        description: CLLocationManager.locationServicesEnabled() ? "已开启" : "未开启"
                    )
                    
                    StatusCard(
                        title: "应用权限",
                        status: locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways,
                        description: authorizationStatusDescription(locationManager.authorizationStatus)
                    )
                    
                    StatusCard(
                        title: "当前位置",
                        status: locationManager.currentLocation != nil,
                        description: locationManager.currentLocation != nil ? "已获取" : "未获取"
                    )
                    
                    StatusCard(
                        title: "追踪状态",
                        status: locationManager.isTracking,
                        description: locationManager.isTracking ? "追踪中" : "已停止"
                    )
                }
                .padding(.horizontal)
                
                // 当前位置信息
                if let location = locationManager.currentLocation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📍 当前位置信息")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("纬度: \(String(format: "%.8f", location.coordinate.latitude))")
                            Text("经度: \(String(format: "%.8f", location.coordinate.longitude))")
                            Text("精度: ±\(String(format: "%.0f", location.horizontalAccuracy))m")
                            Text("海拔: \(String(format: "%.0f", location.altitude))m")
                            Text("速度: \(String(format: "%.1f", location.speed * 3.6))km/h")
                            Text("更新时间: \(DateFormatter.localizedString(from: location.timestamp, dateStyle: .none, timeStyle: .medium))")
                        }
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                
                // 错误信息
                if let errorMessage = locationManager.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚠️ 错误信息")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                        
                        Text(errorMessage)
                            .font(.body)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                
                // 操作按钮
                VStack(spacing: 12) {
                    Button("🔄 强制位置更新") {
                        locationManager.forceLocationUpdate()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("🔐 请求位置权限") {
                        locationManager.requestLocationPermission()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("📊 显示详细信息") {
                        isShowingDebugInfo.toggle()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("定位调试")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingDebugInfo) {
                NavigationView {
                    ScrollView {
                        Text(locationManager.getLocationServiceStatus())
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }
                    .navigationTitle("详细状态")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("完成") {
                                isShowingDebugInfo = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func authorizationStatusDescription(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "未确定"
        case .denied:
            return "已拒绝"
        case .restricted:
            return "受限制"
        case .authorizedWhenInUse:
            return "使用期间"
        case .authorizedAlways:
            return "始终允许"
        @unknown default:
            return "未知"
        }
    }
}

struct StatusCard: View {
    let title: String
    let status: Bool
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(status ? .green : .red)
                .font(.title2)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    LocationDebugView()
}
