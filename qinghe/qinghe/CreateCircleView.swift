import SwiftUI
import PhotosUI

/// 创建圈子申请视图
struct CreateCircleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateCircleViewModel()

    // 表单步骤
    @State private var currentStep = 0
    private let totalSteps = 4
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 进度指示器
                progressIndicator

                // 表单内容
                TabView(selection: $currentStep) {
                    BasicInfoStepView(viewModel: viewModel)
                        .tag(0)

                    RealNameVerificationStepView(viewModel: viewModel)
                        .tag(1)

                    AlipayBindingStepView(viewModel: viewModel)
                        .tag(2)

                    ReviewStepView(viewModel: viewModel)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .gesture(DragGesture(), including: .all) // 禁用滑动手势,但不影响内部交互

                // 底部按钮
                bottomButtons
            }
        }
        .navigationTitle("申请创建圈子")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
        }
        .alert("提示", isPresented: $viewModel.showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .asSubView() // 使用自定义的 TabBar 隐藏修饰符
    }
    
    // MARK: - 进度指示器
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                VStack(spacing: 4) {
                    Circle()
                        .fill(index <= currentStep ? AppConstants.Colors.primaryGreen : Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    
                    Text(stepTitle(for: index))
                        .font(.system(size: 10))
                        .foregroundColor(index <= currentStep ? .primary : .secondary)
                }
                
                if index < totalSteps - 1 {
                    Rectangle()
                        .fill(index < currentStep ? AppConstants.Colors.primaryGreen : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }
    
    private func stepTitle(for index: Int) -> String {
        switch index {
        case 0: return "基本信息"
        case 1: return "实名认证"
        case 2: return "绑定支付宝"
        case 3: return "确认提交"
        default: return ""
        }
    }
    
    // MARK: - 底部按钮
    private var bottomButtons: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    Text("上一步")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppConstants.Colors.primaryGreen, lineWidth: 1)
                        )
                }
            }
            
            Button(action: {
                handleNextStep()
            }) {
                HStack {
                    Text(currentStep == totalSteps - 1 ? "提交申请" : "下一步")
                        .font(.system(size: 16, weight: .semibold))
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppConstants.Colors.primaryGreen)
                .cornerRadius(12)
            }
            .disabled(viewModel.isLoading || !canProceedToNextStep())
            .opacity(viewModel.isLoading || !canProceedToNextStep() ? 0.6 : 1.0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
    }
    
    private func canProceedToNextStep() -> Bool {
        viewModel.canProceedFromStep(currentStep)
    }
    
    private func handleNextStep() {
        if currentStep == totalSteps - 1 {
            // 提交申请
            viewModel.submitApplication {
                dismiss()
            }
        } else {
            // 下一步
            withAnimation {
                currentStep += 1
            }
        }
    }
}

