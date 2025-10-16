import SwiftUI
import UIKit

struct HealthManagerView: View {
    private var topBarHeight: CGFloat {
        let topInset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.safeAreaInsets.top ?? 0
        return topInset + 44
    }

    @Environment(\.dismiss) private var dismiss

    @Namespace private var diagnosisNS
    @State private var showDiagnosisEntry: Bool = false
    @State private var goTongue: Bool = false
    @State private var goFace: Bool = false
    @State private var goHealthRecord: Bool = false
    @State private var goHealthAssistant: Bool = false

    var body: some View {
        NavigationView {
            // 内容区域 - 叠加两层线性渐变（含给定位置/透明度）+ 顶部右侧柔和径向光晕
            ZStack {
                // 背景：使用主题定义的三层渐变（主渐变 + 轻透明覆盖层 + 顶部右侧柔光）
                HealthDesignTheme.Background.base
                    .ignoresSafeArea()
                    .preferredColorScheme(.light) // 健康档案页面不适配深色模式
                HealthDesignTheme.Background.overlay
                    .opacity(0.28)
                    .ignoresSafeArea()
                HealthDesignTheme.Background.topRightGlow()
                    .ignoresSafeArea()

                // 底部背景面板：使用与页面一致的全屏渐变，再做底部裁剪，避免与整屏背景“相位不一致”
                VStack { Spacer() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color(hex: "C3E88D"), location: 0.0),
                                    .init(color: Color(hex: "B2F0E1"), location: 0.55),
                                    .init(color: Color(hex: "FFE485"), location: 1.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            LinearGradient(
                                colors: [Color(hex: "C3E88D"), Color(hex: "B2F0E1"), Color(hex: "FFE485")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .opacity(0.28)
                        }
                    )
                    .mask(
                        VStack(spacing: 0) {
                            Spacer()
                            Rectangle().frame(height: 160)
                        }
                        .ignoresSafeArea(edges: .bottom)
                    )
                    .allowsHitTesting(false)


                // 顶部可见背景条：与页面背景完全一致，覆盖系统透明导航栏区域
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 头部区域（点击气泡进入健康助手）
                        HeaderSection(onOpenAssistant: {
                            // 打开健康助手独立页面
                            goHealthAssistant = true
                        })
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        // 概览 + 详细分析 + 建议风险 + 历史记录
                        AskSuggestionsCard()
                            .padding(.bottom, 24)
                    }
                }

                // 右侧悬浮入口按钮 + 缩放展开面板
                VStack { Spacer() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .trailing) {
                        VStack {
                            Spacer()
                            // 入口按钮
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showDiagnosisEntry.toggle()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("舌/面诊")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.white.opacity(0.92))
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(Color.white.opacity(0.55), lineWidth: 0.5)
                                )
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                            }
                            .padding(.trailing, 8)
                            .padding(.bottom, 48)
                            Spacer()
                        }
                        .frame(maxHeight: .infinity)
                    }

                if showDiagnosisEntry {
                    // 展开面板（缩放动画）
                    Color.black.opacity(0.02).ignoresSafeArea().onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showDiagnosisEntry = false }
                    }

                    VStack(spacing: 12) {
                        Text("选择模式")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                        HStack(spacing: 12) {
                            // 舌诊
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showDiagnosisEntry = false
                                    goTongue = true
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "mouth")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(Color(hex: "1F2A60"))
                                    Text("舌诊")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color(hex: "1F2A60"))
                                }
                                .padding(.vertical, 16)
                                .frame(width: 110)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.55), lineWidth: 0.5))
                            }

                            // 面诊
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showDiagnosisEntry = false
                                    goFace = true
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "face.smiling")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(Color(hex: "1F2A60"))
                                    Text("面诊")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color(hex: "1F2A60"))
                                }
                                .padding(.vertical, 16)
                                .frame(width: 110)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.55), lineWidth: 0.5))
                            }
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.96)))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.6), lineWidth: 0.6))
                    .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 10)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .transition(.scale(scale: 0.9, anchor: .trailing))
                    .zIndex(10)
                }

                // 隐藏式导航跳转
                NavigationLink(destination: TongueDiagnosisView(mode: .tongue), isActive: $goTongue) { EmptyView() }
                NavigationLink(destination: TongueDiagnosisView(mode: .face), isActive: $goFace) { EmptyView() }
                NavigationLink(destination: HealthRecordView(), isActive: $goHealthRecord) { EmptyView() }
                NavigationLink(destination: HealthAssistantView(), isActive: $goHealthAssistant) { EmptyView() }
            }

            .navigationBarBackButtonHidden(true)
            // 使用透明导航栏，让页面背景（渐变）透过显示
            // 使用透明导航栏，让页面下方的同一层渐变透出，保证颜色完全一致

            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(.black)
                    .tint(.black)
                }
                ToolbarItem(placement: .principal) {
                    Text("健康报告")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        goHealthRecord = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
                appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
                appearance.shadowColor = .clear
                // 使用系统动态颜色
                appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
                appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
                let navBar = UINavigationBar.appearance()
                navBar.standardAppearance = appearance
                navBar.compactAppearance = appearance
                navBar.scrollEdgeAppearance = appearance
                // 返回按钮与右侧按钮使用系统动态颜色
                navBar.tintColor = .label
            }
        }

        .asSubView() // 隐藏底部Tab栏
    }
}

#Preview {
    HealthManagerView()
}
