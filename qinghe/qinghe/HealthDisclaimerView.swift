import SwiftUI

// MARK: - 健康检测免责声明视图
struct HealthDisclaimerView: View {
    var onAgree: () -> Void
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss?()
                }
            
            // 免责声明卡片
            VStack(spacing: 0) {
                // 标题
                HStack {
                    Text("健康检测免责声明")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "1F2A60"))
                    Spacer()
                    Button(action: { onDismiss?() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                
                // 内容区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        disclaimerSection(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: Color.orange,
                            title: "重要提示",
                            content: "本功能提供的舌象检测和面部检测仅供参考，不构成任何医疗诊断、治疗建议或专业医疗意见。"
                        )
                        
                        disclaimerSection(
                            icon: "stethoscope",
                            iconColor: Color.blue,
                            title: "非医疗服务",
                            content: "本应用不是医疗设备，检测结果基于图像分析技术，可能存在误差。如有健康问题，请及时就医并遵循专业医生的诊断和建议。"
                        )
                        
                        disclaimerSection(
                            icon: "person.fill.checkmark",
                            iconColor: Color.green,
                            title: "用户责任",
                            content: "使用本功能即表示您理解并同意：\n• 检测结果仅作为健康参考\n• 不应依赖本功能进行自我诊断\n• 任何健康决策应咨询专业医生\n• 因使用本功能产生的后果由用户自行承担"
                        )
                        
                        disclaimerSection(
                            icon: "shield.fill",
                            iconColor: Color.purple,
                            title: "隐私保护",
                            content: "您的检测图片仅用于AI分析生成报告，分析完成后将立即删除，不会存储在我们的服务器上。我们承诺保护您的隐私安全。"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                .frame(maxHeight: 400)
                
                Divider()
                
                // 底部按钮
                VStack(spacing: 12) {
                    Button(action: {
                        onAgree()
                    }) {
                        Text("我已阅读并同意")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "6C63FF"), Color(hex: "5A52D5")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }

                    Button(action: { onDismiss?() }) {
                        Text("暂不使用")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .frame(width: min(UIScreen.main.bounds.width - 40, 400))
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }
    
    // MARK: - 免责声明条目
    private func disclaimerSection(icon: String, iconColor: Color, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(content)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - 预览
#Preview {
    HealthDisclaimerView(onAgree: {}, onDismiss: {})
}

