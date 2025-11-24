import SwiftUI
import UIKit

// MARK: - Banner 广告 SwiftUI 包装器
struct BannerAdView: UIViewRepresentable {
    let adView: UIView
    
    func makeUIView(context: Context) -> UIView {
        return adView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Banner 广告不需要更新
    }
}

// MARK: - Banner 广告容器（带标识和关闭按钮）
struct BannerAdContainer: View {
    let adView: UIView
    let onAdClosed: (() -> Void)?

    init(adView: UIView, onAdClosed: (() -> Void)? = nil) {
        self.adView = adView
        self.onAdClosed = onAdClosed
    }

    var body: some View {
        VStack(spacing: 0) {
            // Banner 广告内容
            BannerAdView(adView: adView)
                .frame(height: 60)
        }
        .background(Color.black.opacity(0.9))
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BannerAdClosed"))) { _ in
            print("🎯 BannerAdContainer: 收到广告关闭通知")
            onAdClosed?()
        }
    }
}

