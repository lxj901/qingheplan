import SwiftUI
import UIKit

// MARK: - 开屏广告视图
struct SplashAdView: View {
    @StateObject private var adManager = GDTAdManager.shared
    @State private var showMainContent = false
    @State private var adLoadTimeout = false
    
    let onAdFinished: () -> Void
    
    var body: some View {
        ZStack {
            // 使用与SplashView相同的背景，避免闪屏
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.black.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 如果广告还没显示，显示与SplashView相同的内容
            if !adManager.isAdShowing {
                VStack(spacing: 20) {
                    // 应用Logo
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("青禾计划")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            // 直接尝试显示广告
            showAdIfReady()
        }
    }
    
    // MARK: - Private Methods

    private func showAdIfReady() {
        // 检查广告是否已经加载完成
        if adManager.isAdLoaded {
            // 广告已加载，直接显示
            showAdInWindow()
        } else {
            // 广告还没加载完成，等待一下再检查
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if adManager.isAdLoaded {
                    showAdInWindow()
                } else {
                    // 设置超时，如果3秒内还没加载完成就直接进入主界面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        if !adManager.isAdShowing {
                            print("🎯 开屏广告超时，直接进入主界面")
                            finishAdDisplay()
                        }
                    }
                }
            }
        }
    }
    
    private func showAdInWindow() {
        // 获取当前窗口
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("❌ 无法获取当前窗口")
            finishAdDisplay()
            return
        }
        
        // 显示开屏广告
        adManager.showSplashAd(in: window) {
            DispatchQueue.main.async {
                finishAdDisplay()
            }
        }
        
        // 监听广告关闭事件
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            monitorAdStatus()
        }
    }
    
    private func monitorAdStatus() {
        // 如果广告正在显示，继续监听
        if adManager.isAdShowing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                monitorAdStatus()
            }
        } else {
            // 广告已关闭，进入主界面
            finishAdDisplay()
        }
    }
    
    private func finishAdDisplay() {
        // 直接调用完成回调，进入主界面
        onAdFinished()
    }
}

// MARK: - Preview
struct SplashAdView_Previews: PreviewProvider {
    static var previews: some View {
        SplashAdView {
            print("广告展示完成")
        }
    }
}
