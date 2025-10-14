import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    @StateObject private var adManager = GDTAdManager.shared

    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 76/255, green: 175/255, blue: 80/255),
                    Color(red: 139/255, green: 195/255, blue: 74/255),
                    Color(red: 165/255, green: 214/255, blue: 167/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(backgroundOpacity)
            .ignoresSafeArea()
            
            // 装饰性背景元素
            GeometryReader { geometry in
                // 左上角圆形
                Circle()
                    .fill(Color(.systemBackground).opacity(0.1))
                    .frame(width: 200, height: 200)
                    .offset(x: -100, y: -100)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)

                // 右下角圆形
                Circle()
                    .fill(Color(.systemBackground).opacity(0.08))
                    .frame(width: 300, height: 300)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 100)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                // 中间小圆形
                Circle()
                    .fill(Color(.systemBackground).opacity(0.06))
                    .frame(width: 150, height: 150)
                    .offset(x: geometry.size.width * 0.7, y: geometry.size.height * 0.3)
                    .scaleEffect(isAnimating ? 1.3 : 1.0)
            }
            
            // 主要内容
            VStack(spacing: 32) {
                Spacer()
                
                // Logo区域
                VStack(spacing: 24) {
                    // Logo图标
                    ZStack {
                        // 外层圆环
                        Circle()
                            .stroke(Color(.systemBackground).opacity(0.3), lineWidth: 3)
                            .frame(width: 120, height: 120)
                            .scaleEffect(logoScale)

                        // 内层圆形背景
                        Circle()
                            .fill(Color(.systemBackground).opacity(0.2))
                            .frame(width: 100, height: 100)
                            .scaleEffect(logoScale)
                        
                        // 叶子图标
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.white)
                            .scaleEffect(logoScale)
                    }
                    .opacity(logoOpacity)
                    
                    // 应用名称
                    VStack(spacing: 8) {
                        Text("青禾")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("自律成就更好的自己")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .opacity(textOpacity)
                }
                
                Spacer()
                
                // 底部版本信息
                VStack(spacing: 8) {
                    Text("Version 1.0.0")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("© 2025 杭州耶里信息技术有限责任公司")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(textOpacity)
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 40)
        }
        .preferredColorScheme(.light) // 开屏页面不适配深色模式
        .onAppear {
            startAnimation()
            // 在启动页显示期间就开始加载广告（开屏广告不受去广告权益影响）
            loadSplashAd()
        }
    }
    
    private func startAnimation() {
        // 背景渐入
        withAnimation(.easeOut(duration: 0.5)) {
            backgroundOpacity = 1.0
        }
        
        // Logo动画
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // 文字动画
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            textOpacity = 1.0
        }
        
        // 装饰元素动画
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.0)) {
            isAnimating = true
        }
        
        // 2秒后完成启动
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                onComplete()
            }
        }
    }

    private func loadSplashAd() {
        // 在启动页显示期间就开始加载广告
        adManager.loadSplashAd { success in
            print("🎯 启动页期间广告加载结果: \(success)")
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView {
            print("启动完成")
        }
    }
}
