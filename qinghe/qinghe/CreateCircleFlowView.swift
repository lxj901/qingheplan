import SwiftUI
import PhotosUI

/// 创建圈子完整流程视图（9步）
struct CreateCircleFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateCircleFlowViewModel()
    @State private var currentStep = 1
    @State private var showAuditPage = false
    @State private var navigateToManagement = false
    
    private let totalSteps = 9
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if !showAuditPage {
                        // 进度条
                        progressBar
                        
                        // 顶部导航栏
                        topNavigationBar
                    }
                    
                    // 主内容区域
                    ScrollView {
                        VStack(spacing: 0) {
                            if showAuditPage {
                                auditPageView
                                    .padding(.top, 40)
                            } else {
                                stepContentView
                                    .padding(.top, 24)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                    
                    Spacer()
                    
                    // 底部按钮
                    if !showAuditPage {
                        bottomButton
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToManagement) {
                CircleManagementView()
                    .asSubView()
            }
        }
    }
    
    // MARK: - 进度条
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.4, green: 0.8, blue: 0.6), Color(red: 0.3, green: 0.7, blue: 0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 4)
                    .animation(.easeOut(duration: 0.5), value: currentStep)
            }
        }
        .frame(height: 4)
    }
    
    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        HStack {
            Button(action: {
                if currentStep > 1 {
                    withAnimation {
                        currentStep -= 1
                    }
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
            .opacity(currentStep == 1 ? 0 : 1)

            Spacer()

            Text("创建圈子 (\(currentStep)/\(totalSteps))")
                .font(.system(size: 16, weight: .bold))

            Spacer()

            // 第一步显示"跳过"按钮，其他步骤显示空白占位
            if currentStep == 1 {
                Button(action: {
                    navigateToManagement = true
                }) {
                    Text("跳过")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.1))
                        .cornerRadius(20)
                }
            } else {
                Color.clear.frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - 步骤内容视图
    @ViewBuilder
    private var stepContentView: some View {
        switch currentStep {
        case 1:
            Step1BasicInfoView(viewModel: viewModel)
        case 2:
            Step2ImagesView(viewModel: viewModel)
        case 3:
            Step3CategoryView(viewModel: viewModel)
        case 4:
            Step4AddressView(viewModel: viewModel)
        case 5:
            Step5PhoneView(viewModel: viewModel)
        case 6:
            Step6IDCardView(viewModel: viewModel)
        case 7:
            Step7FaceVerifyView(viewModel: viewModel)
        case 8:
            Step8BusinessLicenseView(viewModel: viewModel)
        case 9:
            Step9PaymentView(viewModel: viewModel)
        default:
            EmptyView()
        }
    }

    // MARK: - 审核页面
    private var auditPageView: some View {
        VStack(spacing: 24) {
            // 状态图标
            ZStack {
                Circle()
                    .fill(Color(red: 0.94, green: 0.98, blue: 0.96))
                    .frame(width: 96, height: 96)

                ZStack {
                    Circle()
                        .stroke(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.2), lineWidth: 4)
                        .frame(width: 96, height: 96)

                    Circle()
                        .trim(from: 0, to: 0.25)
                        .stroke(Color(red: 0.4, green: 0.8, blue: 0.6), lineWidth: 4)
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: showAuditPage)
                }

                Image(systemName: "clock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
            }
            .padding(.top, 32)

            VStack(spacing: 8) {
                Text("提交成功，等待审核")
                    .font(.system(size: 24, weight: .bold))

                Text("您的圈子申请资料已提交，我们将在 24 小时内完成人工审核")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // 审核进度卡片
            VStack(spacing: 0) {
                // 装饰背景
                ZStack(alignment: .topTrailing) {
                    Color.gray.opacity(0.05)

                    Circle()
                        .fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.1))
                        .frame(width: 128, height: 128)
                        .blur(radius: 20)
                        .offset(x: 40, y: -40)
                }
                .frame(height: 0)

                VStack(spacing: 24) {
                    // 步骤 1
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                                    .frame(width: 24, height: 24)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Rectangle()
                                .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                                .frame(width: 2, height: 40)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("资料提交 & 支付")
                                .font(.system(size: 14, weight: .bold))
                            Text("2024-03-20 14:30:05")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    // 步骤 2
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.3, green: 0.7, blue: 0.7))
                                    .frame(width: 24, height: 24)

                                Circle()
                                    .stroke(Color(red: 0.3, green: 0.7, blue: 0.7).opacity(0.3), lineWidth: 4)
                                    .frame(width: 32, height: 32)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 2, height: 40)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("平台人工审核中")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.7))
                            Text("预计 1 个工作日内完成")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    // 步骤 3
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 24, height: 24)

                                Image(systemName: "bell.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray.opacity(0.4))
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("审核结果通知")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("将通过短信及 App 推送发送")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .opacity(0.5)
                }
                .padding(24)
            }
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
            .padding(.top, 16)

            // 返回首页按钮
            Button(action: {
                dismiss()
            }) {
                Text("返回首页")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.top, 8)
        }
    }

    // MARK: - 底部按钮
    private var bottomButton: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1)

            Button(action: {
                handleNextStep()
            }) {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }

                    if currentStep == totalSteps {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 16))
                        Text("立即支付 ¥199")
                            .font(.system(size: 16, weight: .bold))
                    } else {
                        Text("下一步")
                            .font(.system(size: 16, weight: .bold))
                        Text("(\(currentStep)/\(totalSteps))")
                            .font(.system(size: 14))
                            .opacity(0.8)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: viewModel.canProceedFromStep(currentStep)
                            ? [Color(red: 0.4, green: 0.8, blue: 0.6), Color(red: 0.3, green: 0.7, blue: 0.7)]
                            : [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
                .shadow(
                    color: viewModel.canProceedFromStep(currentStep)
                        ? Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.2)
                        : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .disabled(!viewModel.canProceedFromStep(currentStep) || viewModel.isLoading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color.white
                    .background(.ultraThinMaterial)
            )
        }
    }

    // MARK: - 处理下一步
    private func handleNextStep() {
        if currentStep < totalSteps {
            withAnimation {
                currentStep += 1
            }
        } else {
            // 最后一步，提交支付
            viewModel.submitPayment {
                withAnimation {
                    showAuditPage = true
                }
            }
        }
    }
}

