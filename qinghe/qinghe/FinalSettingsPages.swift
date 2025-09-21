import SwiftUI

// MARK: - 资质证照页面
struct QualificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar
            
            List {
                ForEach(Qualification.allCases, id: \.self) { qualification in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(qualification.title)
                                .font(.system(size: 16, weight: .semibold))
                            
                            Spacer()
                            
                            Text("有效")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Text(qualification.description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("证书编号：\(qualification.certificateNumber)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("有效期至：\(qualification.expiryDate)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .onAppear {
            print("🧭 QualificationsView onAppear - navigationPath.count = \(navigationPath.count)")
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
            
            Text("资质证照")
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

// MARK: - 资质证照枚举
enum Qualification: CaseIterable {
    case businessLicense
    case icp
    case appStore
    
    var title: String {
        switch self {
        case .businessLicense: return "营业执照"
        case .icp: return "ICP备案"
        case .appStore: return "应用商店资质"
        }
    }
    
    var description: String {
        switch self {
        case .businessLicense: return "青禾科技有限公司营业执照"
        case .icp: return "网站ICP备案信息"
        case .appStore: return "App Store开发者资质认证"
        }
    }
    
    var certificateNumber: String {
        switch self {
        case .businessLicense: return "91110000123456789X"
        case .icp: return "京ICP备12345678号"
        case .appStore: return "APPLE-DEV-123456"
        }
    }
    
    var expiryDate: String {
        switch self {
        case .businessLicense: return "2025-12-31"
        case .icp: return "长期有效"
        case .appStore: return "2025-06-30"
        }
    }
}

// MARK: - 用户协议页面
struct UserAgreementView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("青禾计划用户协议")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.bottom, 10)
                    
                    ForEach(AgreementSection.allCases, id: \.self) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title)
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text(section.content)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                    }
                    
                    Text("最后更新时间：2024年12月")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onAppear {
            print("🧭 UserAgreementView onAppear - navigationPath.count = \(navigationPath.count)")
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
            
            Text("用户协议")
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

// MARK: - 协议章节枚举
enum AgreementSection: CaseIterable {
    case introduction
    case userRights
    case userObligations
    case privacyProtection
    case serviceTerms
    
    var title: String {
        switch self {
        case .introduction: return "1. 协议介绍"
        case .userRights: return "2. 用户权利"
        case .userObligations: return "3. 用户义务"
        case .privacyProtection: return "4. 隐私保护"
        case .serviceTerms: return "5. 服务条款"
        }
    }
    
    var content: String {
        switch self {
        case .introduction:
            return "欢迎使用青禾计划！本协议是您与青禾科技有限公司之间关于使用青禾计划服务的法律协议。使用我们的服务即表示您同意本协议的所有条款。"
        case .userRights:
            return "您有权使用我们提供的所有功能和服务，包括但不限于社区交流、内容分享、消息通讯等。我们保障您的合法权益，尊重您的隐私和数据安全。"
        case .userObligations:
            return "您应当遵守相关法律法规，不得利用我们的服务从事违法违规活动。您应当对自己发布的内容负责，不得侵犯他人合法权益。"
        case .privacyProtection:
            return "我们严格保护您的个人信息和隐私数据，采用先进的安全技术和管理措施。未经您同意，我们不会向第三方披露您的个人信息。"
        case .serviceTerms:
            return "我们保留随时修改、暂停或终止服务的权利。对于服务的变更，我们会提前通知用户。您可以随时停止使用我们的服务。"
        }
    }
}

// MARK: - 个人信息收集清单页面
struct PersonalInfoListView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar
            
            List {
                ForEach(PersonalInfoCategory.allCases, id: \.self) { category in
                    Section(category.title) {
                        ForEach(category.items, id: \.name) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(item.name)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Spacer()
                                    
                                    Text(item.isRequired ? "必需" : "可选")
                                        .font(.system(size: 12))
                                        .foregroundColor(item.isRequired ? .red : .orange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background((item.isRequired ? Color.red : Color.orange).opacity(0.1))
                                        .cornerRadius(8)
                                }
                                
                                Text(item.purpose)
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
            print("🧭 PersonalInfoListView onAppear - navigationPath.count = \(navigationPath.count)")
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
            
            Text("个人信息收集清单")
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

// MARK: - 个人信息类别枚举
enum PersonalInfoCategory: CaseIterable {
    case basic
    case device
    case usage

    var title: String {
        switch self {
        case .basic: return "基本信息"
        case .device: return "设备信息"
        case .usage: return "使用信息"
        }
    }

    var items: [PersonalInfoItem] {
        switch self {
        case .basic:
            return [
                PersonalInfoItem(name: "手机号码", purpose: "用于账号注册和登录验证", isRequired: true),
                PersonalInfoItem(name: "昵称", purpose: "用于个人资料展示", isRequired: false),
                PersonalInfoItem(name: "头像", purpose: "用于个人资料展示", isRequired: false),
                PersonalInfoItem(name: "性别", purpose: "用于个性化推荐", isRequired: false)
            ]
        case .device:
            return [
                PersonalInfoItem(name: "设备型号", purpose: "用于适配和优化应用性能", isRequired: true),
                PersonalInfoItem(name: "操作系统版本", purpose: "用于兼容性检查", isRequired: true),
                PersonalInfoItem(name: "应用版本", purpose: "用于功能更新和问题排查", isRequired: true),
                PersonalInfoItem(name: "网络类型", purpose: "用于优化网络连接", isRequired: false)
            ]
        case .usage:
            return [
                PersonalInfoItem(name: "使用时长", purpose: "用于统计分析和改进服务", isRequired: false),
                PersonalInfoItem(name: "功能使用情况", purpose: "用于产品优化", isRequired: false),
                PersonalInfoItem(name: "崩溃日志", purpose: "用于问题修复", isRequired: false),
                PersonalInfoItem(name: "位置信息", purpose: "用于位置相关功能", isRequired: false)
            ]
        }
    }
}

// MARK: - 个人信息项模型
struct PersonalInfoItem {
    let name: String
    let purpose: String
    let isRequired: Bool
}

// MARK: - 第三方信息共享清单页面
struct ThirdPartyInfoListView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            List {
                ForEach(ThirdPartyService.allCases, id: \.self) { service in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(service.name)
                                .font(.system(size: 16, weight: .semibold))

                            Spacer()

                            Text(service.category)
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }

                        Text(service.purpose)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Text("共享信息：\(service.sharedInfo)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        if let website = service.website {
                            Text("隐私政策：\(website)")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .onAppear {
            print("🧭 ThirdPartyInfoListView onAppear - navigationPath.count = \(navigationPath.count)")
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

            Text("第三方信息共享清单")
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

// MARK: - 第三方服务枚举
enum ThirdPartyService: CaseIterable {
    case analytics
    case push
    case payment
    case map

    var name: String {
        switch self {
        case .analytics: return "数据分析服务"
        case .push: return "推送通知服务"
        case .payment: return "支付服务"
        case .map: return "地图服务"
        }
    }

    var category: String {
        switch self {
        case .analytics: return "分析"
        case .push: return "通知"
        case .payment: return "支付"
        case .map: return "位置"
        }
    }

    var purpose: String {
        switch self {
        case .analytics: return "用于分析应用使用情况，改进产品体验"
        case .push: return "用于向用户发送消息通知"
        case .payment: return "用于处理应用内购买和支付"
        case .map: return "用于提供位置相关服务"
        }
    }

    var sharedInfo: String {
        switch self {
        case .analytics: return "设备信息、使用统计"
        case .push: return "设备标识、推送令牌"
        case .payment: return "订单信息、支付状态"
        case .map: return "位置信息、地址信息"
        }
    }

    var website: String? {
        switch self {
        case .analytics: return "analytics.example.com/privacy"
        case .push: return "push.example.com/privacy"
        case .payment: return "payment.example.com/privacy"
        case .map: return "maps.example.com/privacy"
        }
    }
}
