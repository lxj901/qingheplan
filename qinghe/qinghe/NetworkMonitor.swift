import Foundation
import Network
import SwiftUI

/// 网络状态监控器
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    @Published var isExpensive = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                
                // 获取连接类型
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wiredEthernet
                } else {
                    self?.connectionType = nil
                }
                
                // 打印网络状态变化
                if let self = self {
                    print("🌐 网络状态变化: 连接=\(self.isConnected), 类型=\(self.connectionType?.description ?? "未知"), 昂贵=\(self.isExpensive)")
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    /// 检查是否可以加载图片
    /// 修改为：只要有网络连接就允许加载图片（包括移动网络）
    var canLoadImages: Bool {
        return isConnected
    }
    
    /// 获取网络状态描述
    var statusDescription: String {
        if !isConnected {
            return "网络未连接"
        }
        
        var description = "已连接"
        if let type = connectionType {
            description += " (\(type.description))"
        }
        
        if isExpensive {
            description += " - 流量网络"
        }
        
        return description
    }
}

// MARK: - NWInterface.InterfaceType 扩展
extension NWInterface.InterfaceType {
    var description: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "蜂窝网络"
        case .wiredEthernet:
            return "有线网络"
        case .loopback:
            return "本地回环"
        case .other:
            return "其他"
        @unknown default:
            return "未知"
        }
    }
}

// MARK: - 网络状态指示器视图
struct NetworkStatusIndicator: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.red)
                
                Text("网络未连接")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.1))
            .cornerRadius(16)
        } else if networkMonitor.isExpensive && networkMonitor.connectionType == .cellular {
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.orange)
                
                Text("使用流量网络")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

// MARK: - 网络感知的图片加载组件
struct NetworkAwareAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var imageLoader = ImageLoader()
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = imageLoader.image {
                content(Image(uiImage: image))
            } else if !networkMonitor.isConnected {
                // 网络未连接状态
                placeholder()
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "wifi.slash")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text("网络未连接")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    )
            } else if imageLoader.hasError {
                // 加载错误状态
                placeholder()
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            Button("重试") {
                                if networkMonitor.canLoadImages {
                                    imageLoader.loadImage(from: url)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .disabled(!networkMonitor.canLoadImages)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    )
            } else if imageLoader.isLoading {
                // 加载中状态
                placeholder()
                    .overlay(
                        ProgressView()
                            .tint(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                    )
            } else {
                placeholder()
            }
        }
        .onAppear {
            if networkMonitor.canLoadImages {
                // 
                DispatchQueue.main.async {
                    imageLoader.loadImage(from: url)
                }
            }
        }
        .onChange(of: url) {
            if networkMonitor.canLoadImages {
                // 
                DispatchQueue.main.async {
                    imageLoader.loadImage(from: url)
                }
            }
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if isConnected && networkMonitor.canLoadImages && imageLoader.image == nil && !imageLoader.isLoading {
                DispatchQueue.main.async {
                    imageLoader.loadImage(from: url)
                }
            }
        }
    }
}
