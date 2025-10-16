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

// MARK: - 使用条款页面
struct TermsOfUseView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("青禾计划使用条款")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.bottom, 10)

                    ForEach(TermsOfUseSection.allCases, id: \.self) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title)
                                .font(.system(size: 18, weight: .semibold))

                            Text(section.content)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                    }

                    Text("最后更新时间：2025年10月16日")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onAppear {
            print("🧭 TermsOfUseView onAppear - navigationPath.count = \(navigationPath.count)")
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

            Text("使用条款")
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

// MARK: - 使用条款章节枚举
enum TermsOfUseSection: CaseIterable {
    case introduction
    case license
    case intellectualProperty
    case userAccount
    case paidServices
    case userContent
    case privacy
    case thirdParty
    case disclaimer
    case liability
    case indemnification
    case termination
    case law
    case changes
    case general
    case contact
    case apple

    var title: String {
        switch self {
        case .introduction: return "重要提示"
        case .license: return "1. 许可授予"
        case .intellectualProperty: return "2. 知识产权"
        case .userAccount: return "3. 用户账户"
        case .paidServices: return "4. 付费服务与订阅"
        case .userContent: return "5. 用户内容"
        case .privacy: return "6. 隐私"
        case .thirdParty: return "7. 第三方服务"
        case .disclaimer: return "8. 免责声明"
        case .liability: return "9. 责任限制"
        case .indemnification: return "10. 赔偿"
        case .termination: return "11. 服务变更与终止"
        case .law: return "12. 适用法律与争议解决"
        case .changes: return "13. 条款变更"
        case .general: return "14. 一般条款"
        case .contact: return "15. 联系我们"
        case .apple: return "16. Apple 特定条款"
        }
    }

    var content: String {
        switch self {
        case .introduction:
            return """
在下载、安装、访问或使用本应用之前，请仔细阅读本使用条款。使用本应用即表示您同意受本条款的约束。如果您不同意本条款，请勿使用本应用。
"""
        case .license:
            return """
我们授予您一项有限的、非独占的、不可转让的、可撤销的许可，允许您在符合 Apple App Store 使用规则的 iOS 设备上下载、安装和使用本应用，仅供个人、非商业用途。

您不得复制、修改、改编、翻译、反向工程、反编译或反汇编本应用的任何部分；不得出租、出借、转售、分发、传播或以其他方式转让本应用或本许可。
"""
        case .intellectualProperty:
            return """
本应用及其所有内容、功能和特性（包括但不限于软件、文本、图形、图像、音频、视频、设计、商标、服务标志和徽标）均由我们或我们的许可方拥有，受中华人民共和国及国际版权法、商标法和其他知识产权法律的保护。

"青禾计划"及相关标识是我们的商标或注册商标。未经我们事先书面许可，您不得使用这些商标。
"""
        case .userAccount:
            return """
您可以通过手机号码或 Apple ID 创建账户。您必须提供准确、完整和最新的注册信息，并及时更新以保持信息的准确性。

您有责任维护账户的保密性和安全性。您对在您账户下发生的所有活动负责。如果您发现任何未经授权使用您账户的情况，请立即通知我们。
"""
        case .paidServices:
            return """
本应用提供自动续订订阅服务（包括月度、季度和年度会员）。订阅将自动续订，除非您在当前订阅期结束前至少 24 小时取消订阅。

所有付款通过 Apple 的 App Store 处理。您的 Apple ID 账户将在确认购买时被收费。您可以在 iOS 设备的"设置" > "Apple ID" > "订阅"中管理您的订阅并关闭自动续订。

退款请求应直接向 Apple 提出。我们遵循 Apple 的退款政策。一般情况下，已支付的订阅费用不予退还，除非法律另有规定。
"""
        case .userContent:
            return """
您可以在本应用中发布、上传或提交内容（包括文本、图片、视频、评论等）。您对您的用户内容负全部责任。

通过在本应用中发布用户内容，您授予我们一项全球性的、非独占的、免版税的、可转让的、可再许可的许可，允许我们使用、复制、修改、改编、发布、翻译、创建衍生作品、分发和展示您的用户内容。

您的用户内容不得侵犯任何第三方的知识产权或其他权利；不得包含非法、有害、威胁、辱骂、骚扰、诽谤、粗俗、淫秽或其他令人反感的内容；不得包含虚假或误导性信息。
"""
        case .privacy:
            return """
您的隐私对我们非常重要。我们如何收集、使用和保护您的个人信息在我们的《隐私政策》中有详细说明。使用本应用即表示您同意我们按照《隐私政策》处理您的信息。

请在应用内"设置" > "隐私政策"中查看完整的隐私政策。
"""
        case .thirdParty:
            return """
本应用可能集成或链接到第三方服务、网站或内容（包括但不限于 Apple 身份认证、Apple 内购、腾讯广告 SDK、阿里云 OSS/CDN 等）。这些第三方服务有其自己的条款和隐私政策，我们不对其负责。

我们不对任何第三方服务的可用性、准确性、内容或功能负责。您使用第三方服务的风险由您自行承担。
"""
        case .disclaimer:
            return """
本应用按"按现状"和"按可用性"提供，不提供任何明示或暗示的保证，包括但不限于对适销性、特定用途适用性和非侵权性的暗示保证。

我们不保证本应用将满足您的要求或期望；不保证本应用将不间断、及时、安全或无错误；不保证通过本应用获得的结果将准确或可靠。

重要提示：本应用提供的健康、睡眠、运动等相关功能和内容仅供一般信息和参考之用，不构成医疗建议、诊断或治疗。在做出任何健康相关决定之前，请咨询合格的医疗专业人员。
"""
        case .liability:
            return """
在适用法律允许的最大范围内，我们不对任何间接、偶然、特殊、后果性或惩罚性损害负责，包括但不限于利润损失、数据丢失、商誉损失或其他无形损失。

我们对您因使用或无法使用本应用而产生的任何索赔的总责任，无论基于何种法律理论，均不超过您在索赔发生前 12 个月内向我们支付的金额，或人民币 100 元（以较高者为准）。
"""
        case .indemnification:
            return """
您同意赔偿、辩护并使我们及我们的关联公司、董事、管理人员、员工、代理人和许可方免受因以下原因引起的任何索赔、责任、损害、损失、成本和费用（包括合理的律师费）：您使用或滥用本应用；您违反本条款；您侵犯任何第三方的权利；您的用户内容。
"""
        case .termination:
            return """
我们保留随时修改、暂停或终止本应用（或其任何部分）的权利，无论是否通知。我们不对您或任何第三方因修改、暂停或终止本应用而承担责任。

我们可以随时以任何理由终止或暂停您对本应用的访问，无需事先通知或承担责任，包括但不限于您违反本条款的情况。
"""
        case .law:
            return """
本条款受中华人民共和国法律管辖并按其解释，不考虑其法律冲突原则。

因本条款或本应用引起的或与之相关的任何争议，双方应首先通过友好协商解决。如果协商不成，任何一方均可将争议提交至我们所在地有管辖权的人民法院诉讼解决。
"""
        case .changes:
            return """
我们保留随时修改或更新本条款的权利。如果我们对本条款进行重大变更，我们将通过应用内通知、电子邮件或其他合理方式通知您。

修订后的条款将在发布后立即生效，或在通知中指定的日期生效。您在条款变更后继续使用本应用即表示您接受修订后的条款。
"""
        case .general:
            return """
本条款（连同我们的《隐私政策》、《用户协议》、《会员服务协议》和《社区公约》）构成您与我们之间关于本应用的完整协议，并取代所有先前或同期的口头或书面协议。

如果本条款的任何条款被认定为无效或不可执行，该条款将被解释为反映各方的原始意图，其余条款将继续完全有效。
"""
        case .contact:
            return """
如果您对本使用条款有任何疑问、意见或投诉，请通过以下方式联系我们：

运营者：杭州耶里信息技术有限责任公司
联系邮箱：hangzhouyeli@gmail.com
ICP 备案号：浙ICP备2023025943号-4
应用内反馈：进入"设置" > "意见反馈"

我们将在收到您的请求后 7 个工作日内回复（复杂情况可能需要更长时间）。
"""
        case .apple:
            return """
您承认并同意，Apple 及其子公司是本条款的第三方受益人，Apple 有权（并将被视为已接受该权利）根据本条款对您强制执行本条款。

Apple 不对本应用或其内容负责。Apple 对本应用没有任何维护或支持义务。如果本应用未能符合任何适用的保证，您可以通知 Apple，Apple 将向您退还购买价格（如有）。

您声明并保证：您不在受美国政府禁运或被美国政府指定为"支持恐怖主义"国家的国家/地区；您不在美国政府的任何禁止或限制方名单上。
"""
        }
    }
}
