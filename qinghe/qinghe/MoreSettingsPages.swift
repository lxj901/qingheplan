import SwiftUI

// MARK: - 广告信息页面
struct AdInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 广告说明
                    VStack(alignment: .leading, spacing: 12) {
                        Text("关于广告推送")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("青禾计划通过展示广告来支持应用的免费使用。我们致力于为您提供相关且有用的广告内容。")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    
                    // 广告类型
                    VStack(alignment: .leading, spacing: 12) {
                        Text("广告类型")
                            .font(.system(size: 18, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• 横幅广告：显示在页面顶部或底部")
                            Text("• 插屏广告：在页面切换时显示")
                            Text("• 原生广告：融入内容流中的广告")
                            Text("• 视频广告：短视频形式的广告内容")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    }
                    
                    // 个性化设置
                    VStack(alignment: .leading, spacing: 12) {
                        Text("个性化设置")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("您可以在\"应用权限\"中关闭个性化广告，但仍会看到广告，只是与您的兴趣相关性较低。")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    // 联系方式
                    VStack(alignment: .leading, spacing: 12) {
                        Text("意见反馈")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("如果您对广告内容有任何意见或建议，请通过\"反馈与帮助\"联系我们。")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onAppear {
            print("🧭 AdInfoView onAppear - navigationPath.count = \(navigationPath.count)")
        }
    }
    
    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text("了解广告推送")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - 反馈与帮助页面
struct FeedbackHelpView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    @State private var feedbackText = ""
    @State private var selectedCategory = "功能建议"
    @State private var contactEmail = ""
    @State private var showingSubmitAlert = false
    
    private let categories = ["功能建议", "问题反馈", "使用咨询", "其他"]
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar
            
            List {
                // 反馈类型
                Section("反馈类型") {
                    Picker("类型", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // 反馈内容
                Section("反馈内容") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("请详细描述您的问题或建议")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $feedbackText)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                }
                
                // 联系方式
                Section("联系方式（可选）") {
                    TextField("您的邮箱", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                // 提交按钮
                Section {
                    Button(action: {
                        submitFeedback()
                    }) {
                        HStack {
                            Spacer()
                            Text("提交反馈")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(feedbackText.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(8)
                    }
                    .disabled(feedbackText.isEmpty)
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 常见问题
                Section("常见问题") {
                    ForEach(FAQItem.allCases, id: \.self) { faq in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(faq.question)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(faq.answer)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .alert("反馈已提交", isPresented: $showingSubmitAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("感谢您的反馈，我们会认真处理您的建议")
        }
        .onAppear {
            print("🧭 FeedbackHelpView onAppear - navigationPath.count = \(navigationPath.count)")
        }
    }
    
    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text("反馈与帮助")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 提交反馈
    private func submitFeedback() {
        // 这里可以添加实际的反馈提交逻辑
        print("📝 提交反馈: \(selectedCategory) - \(feedbackText)")
        showingSubmitAlert = true
        
        // 清空表单
        feedbackText = ""
        contactEmail = ""
        selectedCategory = "功能建议"
    }
}

// MARK: - 常见问题枚举
enum FAQItem: CaseIterable {
    case login
    case notification
    case privacy
    case account
    
    var question: String {
        switch self {
        case .login: return "如何登录账号？"
        case .notification: return "为什么收不到通知？"
        case .privacy: return "如何保护隐私？"
        case .account: return "如何注销账号？"
        }
    }
    
    var answer: String {
        switch self {
        case .login: return "您可以使用手机号码登录，首次使用会自动注册账号。"
        case .notification: return "请检查系统设置中的通知权限，确保已允许青禾计划发送通知。"
        case .privacy: return "我们严格保护用户隐私，您可以在隐私设置中管理个人信息。"
        case .account: return "在设置-账号与安全中可以找到注销账号选项。"
        }
    }
}

// MARK: - 青禾规则中心页面
struct RulesCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            List {
                ForEach(RuleCategory.allCases, id: \.self) { category in
                    Section(category.title) {
                        ForEach(category.rules, id: \.title) { rule in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(rule.title)
                                    .font(.system(size: 16, weight: .medium))

                                Text(rule.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .onAppear {
            print("🧭 RulesCenterView onAppear - navigationPath.count = \(navigationPath.count)")
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("青禾规则中心")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - 规则类别枚举
enum RuleCategory: CaseIterable {
    case community
    case privacy
    case content

    var title: String {
        switch self {
        case .community: return "社区规范"
        case .privacy: return "隐私保护"
        case .content: return "内容规范"
        }
    }

    var rules: [Rule] {
        switch self {
        case .community:
            return [
                Rule(title: "友善交流", description: "保持友善和尊重的交流态度"),
                Rule(title: "禁止骚扰", description: "不得对其他用户进行骚扰或恶意攻击"),
                Rule(title: "真实身份", description: "鼓励使用真实身份，禁止冒充他人")
            ]
        case .privacy:
            return [
                Rule(title: "个人信息保护", description: "严格保护用户个人信息不被泄露"),
                Rule(title: "数据安全", description: "采用先进技术保障数据传输安全"),
                Rule(title: "隐私控制", description: "用户可自主控制个人信息的可见范围")
            ]
        case .content:
            return [
                Rule(title: "原创内容", description: "鼓励发布原创内容，尊重知识产权"),
                Rule(title: "健康内容", description: "发布积极健康的内容，传播正能量"),
                Rule(title: "禁止违规", description: "禁止发布违法违规、暴力色情等内容")
            ]
        }
    }
}

// MARK: - 规则模型
struct Rule {
    let title: String
    let description: String
}
