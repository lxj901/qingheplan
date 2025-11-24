import SwiftUI
import UserNotifications

/// 启动开屏页：使用全新的「青禾 · Modern Oriental Lifestyle」视觉设计，
/// 同时保留原有的 ATT + 推送权限请求逻辑与 onComplete 回调行为。
struct SplashView: View {
    // MARK: - 视觉配色（对应原 React 设计中的色值）
    private let lime = Color(red: 0.71, green: 0.96, blue: 0.36)   // #B4F65C
    private let yellow = Color(red: 0.96, green: 0.84, blue: 0.36) // #F6D65C
    private let lilac = Color(red: 0.88, green: 0.76, blue: 0.99)  // #E0C3FC

    // MARK: - 入场动画状态
    @State private var showTop = false
    @State private var showCard = false
    @State private var showBottom = false

    // MARK: - 背景 Blob 动画状态
    @State private var animateBlob1 = false
    @State private var animateBlob2 = false
    @State private var animateBlob3 = false

    // MARK: - 权限与完成状态
    @State private var attRequestCompleted = false
    @State private var hasCompleted = false

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            backgroundBlobs

            VStack {
                topSection
                Spacer(minLength: 0)
                cardSection
                Spacer(minLength: 0)
                bottomSection
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 32)
        }
        .preferredColorScheme(.light) // 开屏页面固定浅色
        .onAppear {
            startIntroAnimations()
            // 保留原有：进入开屏时启动 ATT + 推送权限请求流程
            requestATTAndLoadAd()
        }
    }

    // MARK: - 背景动效

    private var backgroundBlobs: some View {
        ZStack {
            // 左上绿色
            Circle()
                .fill(lime)
                .frame(width: 500, height: 500)
                .blur(radius: 80)
                .opacity(0.8)
                .offset(x: animateBlob1 ? -100 : -60,
                        y: animateBlob1 ? -260 : -200)
                .blendMode(.multiply)
                .animation(
                    .easeInOut(duration: 7)
                        .repeatForever(autoreverses: true),
                    value: animateBlob1
                )

            // 右上黄色
            Circle()
                .fill(yellow)
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .opacity(0.6)
                .offset(x: animateBlob2 ? 130 : 80,
                        y: animateBlob2 ? -20 : 40)
                .blendMode(.multiply)
                .animation(
                    .easeInOut(duration: 7)
                        .repeatForever(autoreverses: true),
                    value: animateBlob2
                )

            // 左下紫色
            Circle()
                .fill(lilac)
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .opacity(0.5)
                .offset(x: animateBlob3 ? 40 : 20,
                        y: animateBlob3 ? 260 : 220)
                .blendMode(.multiply)
                .animation(
                    .easeInOut(duration: 7)
                        .repeatForever(autoreverses: true),
                    value: animateBlob3
                )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - 顶部徽标区

    private var topSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("Daily Wellness")
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.05))
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
                            )
                    )

                Text("甲辰 · 冬")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.05))
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
                            )
                    )
            }

            Text("青\n禾。")
                .font(.system(size: 64, weight: .black))
                .multilineTextAlignment(.center)
                .lineSpacing(-10)
                .foregroundColor(.black)

            Text("Modern Oriental Lifestyle")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
                .tracking(3)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .opacity(showTop ? 1 : 0)
        .offset(y: showTop ? 0 : 20)
        .animation(.easeOut(duration: 0.9), value: showTop)
    }

    // MARK: - 中部指标卡片

    private var cardSection: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white.opacity(0.4))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 24, x: 0, y: 20)

            // 装饰光
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 120, height: 120)
                .blur(radius: 40)
                .offset(x: 40, y: -40)

            VStack(alignment: .leading, spacing: 20) {
                scoreSection
                metricsSection
                nextTaskSection
            }
            .padding(24)
        }
        .frame(maxWidth: 340)
        .opacity(showCard ? 1 : 0)
        .scaleEffect(showCard ? 1 : 0.95)
        .animation(.easeOut(duration: 0.9).delay(0.1), value: showCard)
    }

    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(lime)
                        .frame(width: 6, height: 6)
                        .scaleEffect(1.1)
                        .animation(
                            .easeInOut(duration: 1)
                                .repeatForever(autoreverses: true),
                            value: animateBlob1
                        )

                    Text("Body & Mind Index")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                        .tracking(0.8)
                }

                Spacer()

                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .padding(6)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Circle())
            }

            ZStack(alignment: .leading) {
                ScoreWaveShape()
                    .fill(lime)
                    .frame(height: 48)
                    .opacity(0.2)
                    .offset(y: 18)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("85")
                        .font(.system(size: 72, weight: .black))
                        .foregroundColor(.black)
                        .tracking(-4)

                    Text(".4")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.gray)
                }
            }

            HStack(spacing: 8) {
                Text("Excellent")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(lime)
                    )

                Text("+2.3 vs yesterday")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    )
            }
        }
    }

    private var metricsSection: some View {
        HStack(spacing: 8) {
            // Sleep
            VStack(spacing: 4) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.purple)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("7.5")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.gray.opacity(0.9))
                    Text("h")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.6))
                }

                Text("Sleep")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray.opacity(0.6))
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

            // Zen
            VStack(spacing: 4) {
                Image(systemName: "wind")
                    .font(.system(size: 16))
                    .foregroundColor(lime)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("20")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                    Text("m")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }

                Text("Zen")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(lime)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

            // Kcal
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.orange)

                Text("320")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.gray.opacity(0.9))

                Text("Kcal")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray.opacity(0.6))
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

    private var nextTaskSection: some View {
        Button(action: {
            // 可在这里接入「晨间唤醒 · 八段锦」的导航逻辑
        }) {
            ZStack {
                LinearGradient(
                    colors: [Color.gray.opacity(0.08), Color.white],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(0.8)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                HStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.88, green: 0.96, blue: 0.95))
                            Image(systemName: "play.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 0.0, green: 0.41, blue: 0.36))
                        }
                        .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recommended")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray.opacity(0.6))
                                .textCase(.uppercase)
                                .tracking(0.8)

                            Text("晨间唤醒 · 八段锦")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray.opacity(0.9))
                        }
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.gray.opacity(0.4))
                    }
                    .frame(width: 24, height: 24)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 底部按钮区

    private var bottomSection: some View {
        VStack(spacing: 16) {
            Button(action: handlePrimaryButtonTap) {
                HStack {
                    Text("开启青禾")
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(lime)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .frame(width: 48, height: 48)
                }
                .padding(.leading, 24)
                .padding(.trailing, 8)
                .frame(maxWidth: 340, minHeight: 64)
            }
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.black)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 20)

            Text("Designed for Gen Z · Zen & Health")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
                .tracking(3)
                .textCase(.uppercase)
                .opacity(0.6)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .opacity(showBottom ? 1 : 0)
        .offset(y: showBottom ? 0 : 20)
        .animation(.easeOut(duration: 0.9).delay(0.2), value: showBottom)
    }

    // MARK: - 动画与权限逻辑

    private func startIntroAnimations() {
        // 顺序进场
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showTop = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showCard = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showBottom = true
        }

        animateBlobs()
    }

    private func animateBlobs() {
        animateBlob1 = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            animateBlob2 = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            animateBlob3 = true
        }
    }

    private func handlePrimaryButtonTap() {
        // 允许用户主动「开启青禾」，但依然确保只触发一次 onComplete
        completeIfNeeded()
    }

    /// 只在尚未完成时触发 onComplete，避免重复动画与回调。
    private func completeIfNeeded() {
        guard !hasCompleted else { return }
        hasCompleted = true
        withAnimation(.easeInOut(duration: 0.8)) {
            onComplete()
        }
    }

    /// 保留原有 ATT + 推送权限请求流程
    private func requestATTAndLoadAd() {
        Task {
            print("📊 [SplashView] 启动页加载，开始权限请求流程")

            // ✅ 延迟 1 秒，确保 UI 完全加载
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒

            // ✅ 第一步：请求 ATT 权限（广告追踪）
            print("📊 [SplashView] 🎯 第 1 步：请求 ATT 权限")
            let _ = await ATTrackingPermissionManager.shared.requestTrackingPermission()
            print("📊 [SplashView] ✅ ATT 权限请求完成")

            // ✅ 延迟 0.5 秒，让用户看到 ATT 结果
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

            // ✅ 第二步：在未登录阶段弹出“通知权限”（仅首次且状态为未决定时）
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                print("📊 [SplashView] 🎯 第 2 步：请求推送通知权限")
                _ = await PushNotificationManager.shared.requestNotificationPermission()
                print("📊 [SplashView] ✅ 推送通知权限请求完成")
            } else {
                print("📊 [SplashView] ℹ️ 推送权限状态：\(settings.authorizationStatus == .authorized ? "已授权" : "非未决定" )，跳过请求")
            }

            // ✅ 标记权限请求已完成
            await MainActor.run {
                attRequestCompleted = true
            }

            print("📊 [SplashView] ✅ ATT+推送权限流程完成，进入下一步")

            // ✅ 完成启动页（仅触发一次）
            await MainActor.run {
                completeIfNeeded()
            }
        }
    }
}

// MARK: - 得分区域背景曲线（替代原 SVG path）

struct ScoreWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: h))

        // 左侧弧线
        path.addQuadCurve(
            to: CGPoint(x: 0.4 * w, y: 0.85 * h),
            control: CGPoint(x: 0.2 * w, y: 0.75 * h)
        )

        // 右侧弧线
        path.addQuadCurve(
            to: CGPoint(x: w, y: 0.5 * h),
            control: CGPoint(x: 0.75 * w, y: h)
        )

        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView {
            print("启动完成")
        }
    }
}

