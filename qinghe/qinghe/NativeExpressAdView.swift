import SwiftUI
import UIKit

// MARK: - 信息流广告SwiftUI包装器
struct NativeExpressAdView: UIViewRepresentable {
    let adView: UIView
    let onAdClicked: (() -> Void)?
    
    init(adView: UIView, onAdClicked: (() -> Void)? = nil) {
        self.adView = adView
        self.onAdClicked = onAdClicked
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemBackground
        
        // 添加广告视图
        containerView.addSubview(adView)
        adView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: containerView.topAnchor),
            adView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            adView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 不需要更新
    }
}

// MARK: - 广告卡片视图
struct AdCardView: View {
    let adView: UIView
    let onAdClosed: (() -> Void)?
    
    init(adView: UIView, onAdClosed: (() -> Void)? = nil) {
        self.adView = adView
        self.onAdClosed = onAdClosed
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 广告标识和关闭按钮
            HStack {
                Text("广告")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                // 关闭按钮
                Button(action: {
                    print("🎯 用户点击广告关闭按钮")
                    onAdClosed?()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // 广告内容
            NativeExpressAdView(adView: adView)
                .frame(height: getAdViewHeight())
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    private func getAdViewHeight() -> CGFloat {
        // 根据广告视图的实际高度返回
        return adView.bounds.height > 0 ? adView.bounds.height : 200
    }
}

// MARK: - 广告管理器扩展
extension GDTAdManager {
    /// 获取适合社区列表的广告尺寸
    static func getCommunityAdSize() -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let adWidth = screenWidth - 32 // 左右各16的边距
        let adHeight: CGFloat = 200 // 固定高度
        return CGSize(width: adWidth, height: adHeight)
    }
    
    /// 获取适合详情页的广告尺寸
    static func getDetailPageAdSize() -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let adWidth = screenWidth - 32 // 左右各16的边距
        let adHeight: CGFloat = 250 // 详情页广告稍微高一点
        return CGSize(width: adWidth, height: adHeight)
    }
    
    /// 为社区页面加载信息流广告
    func loadCommunityNativeAds(completion: @escaping (Bool, [UIView]) -> Void) {
        let adSize = GDTAdManager.getCommunityAdSize()
        print("🎯 GDTAdManager：loadCommunityNativeAds 被调用，广告尺寸: \(adSize)")
        // 增加广告数量以支持分页加载
        // 每页20个帖子，每7个帖子一个广告，每页约需要3个广告
        // 加载5个广告以支持多页浏览
        loadNativeExpressAd(adSize: adSize, adCount: 5, completion: completion)
    }
    
    /// 为详情页加载插入广告
    func loadDetailPageNativeAds(completion: @escaping (Bool, [UIView]) -> Void) {
        let adSize = GDTAdManager.getDetailPageAdSize()
        print("🎯 GDTAdManager：loadDetailPageNativeAds 被调用，广告尺寸: \(adSize)")
        // 详情页只需要1个广告
        loadDetailPageAd(adSize: adSize, adCount: 1, completion: completion)
    }
}

// MARK: - 预览
#Preview {
    VStack {
        Text("信息流广告预览")
            .font(.title2)
            .padding()

        // 模拟广告视图
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 200)
            .overlay(
                Text("广告内容区域")
                    .foregroundColor(.secondary)
            )
            .padding(.horizontal, 16)

        Spacer()
    }
}
