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
                // 仅展示需要的资质项目（隐藏 .appStore）
                ForEach(Qualification.allCases.filter { $0 != .appStore }, id: \.self) { qualification in
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
        case .businessLicense: return "杭州耶里信息技术有限责任公司营业执照"
        case .icp: return "网站ICP备案信息"
        case .appStore: return "App Store开发者资质认证"
        }
    }
    
    var certificateNumber: String {
        switch self {
        case .businessLicense: return "统一社会信用代码：91330110MA8GF6KR22"
        case .icp: return "浙ICP备2023025943号-4"
        case .appStore: return "APPLE-DEV-123456"
        }
    }
    
    var expiryDate: String {
        switch self {
        case .businessLicense: return "长期有效"
        case .icp: return "长期有效"
        case .appStore: return "2025-06-30"
        }
    }
}

// MARK: - 服务条款页面
struct ServiceTermsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("青禾计划服务条款")
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
                    
                    Text("最后更新时间：2025年10月14日")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onAppear {
            print("🧭 ServiceTermsView onAppear - navigationPath.count = \(navigationPath.count)")
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
            
            Text("服务条款")
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

                    ForEach(UserAgreementSection.allCases, id: \.self) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title)
                                .font(.system(size: 18, weight: .semibold))

                            Text(section.content)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                    }

                    Text("最后更新时间：2025年10月14日")
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

// MARK: - 会员服务协议页面
struct MembershipServiceAgreementView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("青禾计划会员服务协议")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.bottom, 10)

                    ForEach(MembershipAgreementSection.allCases, id: \.self) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title)
                                .font(.system(size: 18, weight: .semibold))

                            Text(section.content)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                    }

                    Text("最后更新时间：2025年10月14日")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onAppear {
            print("🧭 MembershipServiceAgreementView onAppear - navigationPath.count = \(navigationPath.count)")
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

            Text("会员服务协议")
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

// MARK: - 会员服务协议章节
enum MembershipAgreementSection: CaseIterable {
    case introduction
    case definition
    case scope
    case membershipBenefits
    case purchaseAndPayment
    case autoRenewal
    case trialAndPromo
    case priceChange
    case cancellation
    case restore
    case refund
    case useRestrictions
    case changesAndTermination
    case disclaimer
    case contact

    var title: String {
        switch self {
        case .introduction: return "引言与适用对象"
        case .definition: return "1. 定义"
        case .scope: return "2. 服务范围"
        case .membershipBenefits: return "3. 会员权益"
        case .purchaseAndPayment: return "4. 购买与支付（Apple 内购）"
        case .autoRenewal: return "5. 自动续订与管理"
        case .trialAndPromo: return "6. 试用与促销活动"
        case .priceChange: return "7. 价格变更"
        case .cancellation: return "8. 取消与到期"
        case .restore: return "9. 恢复购买"
        case .refund: return "10. 退款说明"
        case .useRestrictions: return "11. 使用限制"
        case .changesAndTermination: return "12. 服务变更与终止"
        case .disclaimer: return "13. 免责声明与责任限制"
        case .contact: return "14. 联系我们"
        }
    }

    var content: String {
        switch self {
        case .introduction:
            return "本《会员服务协议》适用于在中国大陆境内使用“青禾计划”并开通会员的用户。开通或续费会员即视为您已阅读并同意本协议及《隐私政策》《用户协议》等配套规则。"
        case .definition:
            return """
            • 会员：指通过 Apple 内购订阅方式开通的付费用户。
            • 计费周期：按月/季度/年等结算的订阅周期，以应用内展示为准。
            • 权益：指会员可享受的功能与服务，以应用内展示与实际开通结果为准。
            """
        case .scope:
            return "会员服务包括但不限于：解除免费版功能次数或容量限制、解锁高级功能、优先体验新功能等。具体以应用内展示为准；如有调整，以更新后的页面说明为准。"
        case .membershipBenefits:
            return """
            会员常见权益示例（以应用内展示为准）：
            • 问答次数/额度提升
            • 睡眠/健康分析功能不限次或增强
            • 白噪声、音频内容全集与离线播放
            • 优先客服或专属活动
            我们可能根据运营需要优化或调整权益，但会在合理范围内保障会员的核心体验。
            """
        case .purchaseAndPayment:
            return """
            • 平台：iOS 端通过 Apple 内购（StoreKit）完成支付与订阅。
            • 账单：付款与账单由 Apple 处理，我们不直接接触您的支付卡信息。
            • 验证：购买完成后需进行收据验证，验证失败可能影响权益生效或退款处理。
            """
        case .autoRenewal:
            return """
            • 默认开启自动续订（如适用）。如需关闭：在 iOS “设置 > Apple ID > 订阅”中管理或取消。
            • 取消在当前订阅周期结束后生效，已生效周期费用不予退还。
            • 因用户自身未及时取消导致的续费费用，由用户自行承担。
            """
        case .trialAndPromo:
            return """
            • 若提供免费试用或限时促销，具体规则以活动页或应用内展示为准。
            • 试用到期未取消，将自动转为订阅并扣费（如适用）。
            """
        case .priceChange:
            return """
            • 我们可能根据业务需要调整订阅价格或套餐构成；价格调整将于下一结算周期生效。
            • Apple 可能就价格变更进行通知或需用户确认，具体以 Apple 政策为准。
            """
        case .cancellation:
            return """
            • 您可随时在“设置 > Apple ID > 订阅”中取消续订；取消后会员权益在当前计费周期结束时失效。
            • 取消不影响您在本周期内已获得的权益；已收取的本周期费用不予退还。
            """
        case .restore:
            return """
            • 如更换设备或重装应用，您可在会员页面点击“恢复购买”，以同步先前已生效的订阅记录。
            • 恢复购买需使用与订阅时相同的 Apple ID 登录设备。
            """
        case .refund:
            return """
            • 退款遵循 Apple 的订阅条款与退款规则；如需退款，请通过 Apple 官方渠道申请。
            • 如因收据验证失败导致权益未生效，我们将协助排查并指引您处理。
            """
        case .useRestrictions:
            return """
            • 会员权益仅限开通账户本人使用，不得转让、出租、共享、倒卖或用于非法用途。
            • 不得以任何方式规避订阅机制、绕过次数/额度限制或实施影响平台公平性的行为。
            """
        case .changesAndTermination:
            return """
            • 我们可能基于运营或安全需要，对会员服务进行更新、优化或调整；涉及重大变更的，将以应用内公告或其他合理方式提示。
            • 如您严重违反法律法规或平台规则，我们可依法采取限制或终止会员服务的措施。
            """
        case .disclaimer:
            return """
            • 会员服务按“现状”与“可用”提供，不保证在任何时候均无错误、不中断或完全满足个别需求。
            • 对因网络/通信故障、第三方服务异常、不可抗力等原因造成的服务中断或损失，我们不承担责任；法律另有规定除外。
            """
        case .contact:
            return """
            • 运营者：杭州耶里信息技术有限责任公司
            • 联系邮箱：hangzhouyeli@gmail.com
            • ICP 备案号：浙ICP备2023025943号-4
            • 应用内：进入“设置 > 意见反馈”或相关客服入口
            """
        }
    }
}
// MARK: - 用户协议章节
enum UserAgreementSection: CaseIterable {
    case introduction
    case scope
    case account
    case eligibility
    case userConduct
    case ugc
    case intellectualProperty
    case thirdParty
    case healthDisclaimer
    case payment
    case privacy
    case serviceChanges
    case prohibited
    case disclaimer
    case infringement
    case law
    case updates
    case contact

    var title: String {
        switch self {
        case .introduction: return "引言与生效"
        case .scope: return "1. 协议范围与服务内容"
        case .account: return "2. 账号注册与使用"
        case .eligibility: return "3. 资格、未成年人与监护"
        case .userConduct: return "4. 用户义务与承诺"
        case .ugc: return "5. 用户内容（UGC）授权与管理"
        case .intellectualProperty: return "6. 知识产权"
        case .thirdParty: return "7. 第三方服务与外部链接"
        case .healthDisclaimer: return "8. 健康与安全声明（重要）"
        case .payment: return "9. 付费服务、自动续订与退款"
        case .privacy: return "10. 个人信息与隐私"
        case .serviceChanges: return "11. 服务变更、中断与终止"
        case .prohibited: return "12. 禁止行为"
        case .disclaimer: return "13. 免责声明与责任限制"
        case .infringement: return "14. 侵权通知与处理"
        case .law: return "15. 适用法律与争议解决"
        case .updates: return "16. 协议更新与通知"
        case .contact: return "17. 联系我们"
        }
    }

    var content: String {
        switch self {
        case .introduction:
            return "本《用户协议》（下称“本协议”）由您与杭州耶里信息技术有限责任公司（下称“我们”）就您使用“青禾计划”产品与服务所订立。本协议自您勾选/点击同意或实际使用之日起生效，对您与我们均具有约束力。请在使用前仔细阅读并充分理解本协议及《隐私政策》《社区公约》等配套规则。"
        case .scope:
            return """
            • 适用对象：在中国大陆境内使用本产品的自然人或依法成立的组织。
            • 服务内容：社区互动（UGC 发布与互动）、健康与睡眠工具与内容、音视频播放与录制、位置相关服务、通知提醒、内购订阅等。
            • 医疗提示：本产品不提供医疗诊断或治疗，相关功能仅作一般性参考。
            """
        case .account:
            return """
            • 您可通过手机号（短信验证码/密码）或 Apple 登录创建与登录账户。
            • 您应确保注册资料真实、准确、完整，并及时更新；因您提供信息不实导致的损失由您自行承担。
            • 您应妥善保管账户与设备安全，任何经您的账户发出的操作视为您的真实意思表示。
            • 如发现账户被未经授权使用，请通过应用内“意见反馈”或客服渠道立即联系我们。
            """
        case .eligibility:
            return """
            • 使用本产品应具备完全民事行为能力；未成年人应在监护人同意、知情与指导下使用，监护人应承担监护责任。
            • 涉及成年人主题或敏感内容的功能将设置适当的访问限制。
            """
        case .userConduct:
            return """
            • 遵守法律法规、公序良俗与本协议及配套规则。
            • 不得从事侵害他人合法权益、平台安全或社会公共利益的行为；不得利用本产品进行任何违法犯罪活动。
            • 不得对本产品进行逆向工程、反编译、抓取、镜像、批量注册、恶意攻击或其他影响服务稳定性的行为。
            """
        case .ugc:
            return """
            • 您在本产品发布的任何内容（文字、图片、音/视频、评论、私信、话题、标签等）应确保拥有相应权利或已取得合法授权，不侵犯第三方权益（如姓名权、肖像权、著作权、商标权、专利权、商业秘密等）。
            • 您授予我们为提供服务之必要，在全球范围内对您“公开发布”的内容享有可转授权、可再许可的非独占、免版税的使用权（包括存储、复制、展示、传播、改编格式处理、用于推荐与运营展示等）；法律禁止的除外。非公开/私密内容仅在提供服务所必需范围内处理。
            • 我们可依据法律法规与《社区公约》对涉嫌违规或侵权内容采取删除、下架、限制传播、屏蔽、功能限制、封禁账户等处置。
            """
        case .intellectualProperty:
            return """
            • 本产品及其提供的内容、功能与界面相关的知识产权由我们或权利人享有。未经授权，任何人不得复制、修改、传播、抓取、镜像或用于商业用途。
            • 对于开源组件、第三方素材或依许可证使用的内容，我们与您均应遵守其许可证条款。
            """
        case .thirdParty:
            return """
            • 为实现认证、内购、地图、通知、广告与媒体存储分发等功能，我们可能集成：Apple 身份认证（AuthenticationServices）、Apple 内购（StoreKit）、Apple 地图/定位（CoreLocation/Maps）、APNs 推送、腾讯广告（广点通/GDT）SDK、阿里云对象存储与 CDN 等服务或组件。相关服务可能单独适用第三方条款与政策。
            • 本产品可能包含指向第三方网站或服务的链接。我们不对第三方的内容与行为负责，您应审慎阅读并遵守第三方的条款与政策。
            """
        case .healthDisclaimer:
            return """
            • 健康、睡眠与运动功能仅用于日常管理、记录与参考，不构成医疗建议、诊断或治疗；请在需要时咨询专业医疗人员。
            • 任何训练、运动、呼吸或放松练习请量力而行，如有不适应立即停止并寻求帮助。
            """
        case .payment:
            return """
            9.1 订阅与价格
            • 我们提供会员订阅等付费服务，具体套餐、价格、权益以应用内页面为准；价格可能调整，变更自下一结算周期起生效。

            9.2 购买与支付（Apple 内购）
            • 通过 Apple 的内购（StoreKit）完成交易，付款与账单由 Apple 处理，我们不接触您的支付卡信息。
            • 购买完成后需完成收据验证，否则可能影响权益开通或退款处理。

            9.3 自动续订与取消
            • 默认开启自动续订（如适用）。您可在“设备设置 > Apple ID > 订阅”中管理或取消；取消于当前周期结束后生效。

            9.4 试用与退款
            • 如提供免费试用，试用期结束后自动续费，除非提前取消。
            • 退款遵循 Apple 的订阅条款与规则；请通过 Apple 官方渠道申请。
            """
        case .privacy:
            return """
            • 我们将依据《隐私政策》收集、使用、共享和保护您的信息（包括账户信息、设备信息、使用信息、位置信息（在授权后）、UGC 内容、健康与睡眠相关数据（在您自愿提供时）、内购交易凭据（不含支付卡信息）等）。
            • 请务必阅读并同意《隐私政策》。
            """
        case .serviceChanges:
            return """
            • 我们可能基于运营或安全需要，对服务进行更新、优化、下线或变更。对于影响重大或涉及付费权益的变更，将以应用内公告或其他合理方式提前告知。
            • 如用户严重违反法律法规或本协议/规则，我们可在依法合规范围内采取限制或终止服务措施。
            """
        case .prohibited:
            return """
            • 传播违法、侵权、低俗或不当内容；
            • 恶意炒作、引流、传销、诈骗、赌博、色情、暴力、仇恨或其他高风险行为；
            • 破坏服务、干扰系统、批量注册、自动化滥用、传播恶意代码等。
            """
        case .disclaimer:
            return """
            • 本产品按“现状”与“可用”提供，不保证无错误、不中断或完全满足个别需求。
            • 对因自然灾害、网络或通信故障、第三方服务异常、系统维护、不可抗力或非因我们原因造成的损失，我们不承担责任；法律另有规定除外。
            • 因用户不当使用健康/运动功能造成的身体不适或损害，我们不承担医疗或赔偿责任；法律另有规定或另行约定的除外。
            """
        case .infringement:
            return "如您认为您的合法权益被侵害，请通过应用内“意见反馈”或客服渠道提交权属证明、侵权链接/内容、联系方式与请求。我们将在核验后依法处理。"
        case .law:
            return """
            • 本协议的订立、效力、解释、变更、执行与争议解决，适用中华人民共和国法律（不含冲突规范）。
            • 因本协议或本产品产生的争议，双方应友好协商；协商不成的，提交本产品运营者所在地有管辖权的人民法院诉讼解决。
            """
        case .updates:
            return "我们可能根据业务、法律或监管变化更新本协议。重大变更将通过应用内公告等方式提示。若您不同意更新，请停止使用并注销账户；继续使用即视为同意受更新后的协议约束。"
        case .contact:
            return """
            • 运营者：杭州耶里信息技术有限责任公司
            • 联系邮箱：hangzhouyeli@gmail.com
            • ICP 备案号：浙ICP备2023025943号-4
            • 应用内：进入“设置 > 意见反馈”或相关客服入口
            """
        }
    }
}

// MARK: - 服务条款章节枚举
enum AgreementSection: CaseIterable {
    case introduction
    case scope
    case account
    case eligibility
    case ugc
    case intellectualProperty
    case thirdParty
    case healthDisclaimer
    case payment
    case dataPrivacy
    case prohibitedBehavior
    case serviceChanges
    case disclaimer
    case infringement
    case law
    case updates
    case contact

    var title: String {
        switch self {
        case .introduction: return "引言"
        case .scope: return "1. 适用对象与服务概要"
        case .account: return "2. 账户注册与安全"
        case .eligibility: return "3. 资格与未成年人"
        case .ugc: return "4. 用户内容（UGC）与行为规范"
        case .intellectualProperty: return "5. 知识产权"
        case .thirdParty: return "6. 第三方服务与外部链接"
        case .healthDisclaimer: return "7. 健康与安全声明（重要）"
        case .payment: return "8. 付费服务与订阅"
        case .dataPrivacy: return "9. 数据与隐私"
        case .prohibitedBehavior: return "10. 禁止的行为"
        case .serviceChanges: return "11. 服务的变更、中断与终止"
        case .disclaimer: return "12. 免责声明与责任限制"
        case .infringement: return "13. 侵权通知与投诉处理"
        case .law: return "14. 适用法律与争议解决"
        case .updates: return "15. 通知与条款更新"
        case .contact: return "16. 联系我们"
        }
    }

    var content: String {
        switch self {
        case .introduction:
            return "欢迎使用青禾计划（以下简称\"本产品\"或\"我们\"）。为使用我们的产品与服务（含 iOS 客户端、网站、API 与相关配套服务），请您仔细阅读并同意本服务条款（以下简称\"本条款\"）。您安装、登录、访问或使用本产品，即表示您已阅读、理解并同意受本条款以及《隐私政策》《社区公约》等配套规则的约束。"
        case .scope:
            return """
            • 本条款适用于在中国大陆境内使用本产品的自然人和依法成立的组织。
            • 本产品提供社区互动（UGC 发布与互动）、健康与睡眠相关的工具与内容、音视频播放与录制、位置相关功能、通知提醒、会员订阅等服务。
            • 本产品不提供医疗诊断或治疗服务，健康与睡眠模块旨在提供一般性参考或工具支持，不构成医疗建议。
            """
        case .account:
            return """
            • 您可通过手机号（短信验证码/密码）或 Apple 登录创建与登录账户；为完成及保障服务，您应提供真实、准确、完整的信息并及时更新。
            • 您对账户及其下发生的所有活动负责，应妥善保管登录凭据与设备安全。如果发现账户被未经授权使用，请通过应用内"意见反馈"或客服渠道立即与我们联系。
            """
        case .eligibility:
            return """
            • 使用本产品应具备完全民事行为能力。未成年人应在监护人指导、同意并充分知情的前提下使用，监护人应承担监护责任。
            • 涉及成年人主题或敏感内容的功能会采取适当的年龄门槛与展示限制。
            """
        case .ugc:
            return """
            • 用户在本产品发布的任何内容（文字、图片、音/视频、评论、私信、话题、标签等）均应遵守法律法规与《社区公约》。
            • 您承诺对上传内容拥有相应权利或已取得合法授权，不侵犯任何第三方合法权益（如姓名权、肖像权、著作权、商标权、专利权、商业秘密等）。
            • 您授予我们为提供服务之必要，在全球范围内对您公开发布的内容享有可转授权、可再许可的非独占、免版税的使用权（包括但不限于存储、复制、展示、传播、改编格式处理、用于推荐与运营展示等）；法律禁止的除外。非公开/私密内容仅在提供服务所必需的范围内处理。
            • 我们有权依据《社区公约》和法律法规对涉嫌违规或侵权内容采取删除、下架、限制传播、屏蔽、功能限制、封禁账户等处置。
            """
        case .intellectualProperty:
            return """
            • 本产品及其提供的内容、功能与界面相关的知识产权（包括但不限于软件、代码、界面设计、图形、商标、文字、音视频等）均由我们或相应权利人享有。未经授权，任何人不得复制、修改、传播、抓取、镜像或用于商业用途。
            • 对于开源组件、第三方素材或依许可证使用的内容，我们会遵守相应许可协议，您亦应遵守其许可证条款。
            """
        case .thirdParty:
            return """
            • 为实现认证、内购、地图、通知、广告与媒体存储分发等功能，我们可能集成：Apple 身份认证（AuthenticationServices）、Apple 内购（StoreKit）、Apple 地图/定位（CoreLocation/Maps）、APNs 推送、腾讯广告（广点通/GDT）SDK、阿里云对象存储与 CDN 等服务或组件。相关服务可能单独适用第三方条款与政策。
            • 如您使用免费版本，可能展示开屏或信息流广告；关于广告 SDK 的信息收集与使用，请参见《隐私政策》中的第三方共享章节与清单。
            • 本产品可能包含指向第三方网站或服务的链接。我们不对第三方的内容与行为负责，您应审慎阅读并遵守第三方的条款与政策。
            """
        case .healthDisclaimer:
            return """
            • 健康、睡眠与运动功能仅用于日常管理、记录与参考，不构成医疗建议、诊断或治疗。请在需要时咨询专业医疗人员。
            • 任何训练、运动、呼吸或放松练习请量力而行，如有不适应立即停止并寻求帮助。
            """
        case .payment:
            return """
            8.1 订阅与价格
            • 我们提供会员订阅等付费服务，具体套餐、价格、权益以应用内页面为准。
            • 价格可能调整，变更将于下一结算周期生效，您可在生效前取消自动续订。

            8.2 购买与支付（Apple 内购）
            • iOS 平台通过 Apple 的内购（StoreKit）完成交易，付款与账单由 Apple 处理，我们无法直接获取您的支付卡信息。
            • 购买完成后，系统将验证交易与收据；如验证失败，可能导致权益无法开通或需退款处理。

            8.3 自动续订与取消
            • 默认开启自动续订（如适用）。您可在"设备设置 > Apple ID > 订阅"中管理或取消续订。取消将在当前订阅期结束后生效，已生效周期的费用不予退还。

            8.4 试用与退款
            • 如提供免费试用，试用期结束后将自动转为订阅并收费，除非您在到期前取消。
            • 退款政策由 Apple 的订阅条款与退款规则约束。如需退款，请通过 Apple 官方渠道申请。

            8.5 会员权益与变更
            • 我们可能优化或调整会员权益，但会确保核心功能的合理可得性并提前公示变更。
            """
        case .dataPrivacy:
            return """
            • 我们将依据《隐私政策》收集、使用、共享和保护您的信息，涵盖账户信息、设备信息、使用信息、位置信息（在您授权后）、UGC 内容、健康与睡眠相关数据（在您自愿提供时）、内购交易凭据（不含支付卡信息）等。
            • 请务必阅读并同意《隐私政策》。
            """
        case .prohibitedBehavior:
            return """
            • 违反法律法规、公序良俗或《社区公约》的内容与行为。
            • 侵害他人合法权益或平台/用户安全的行为（含恶意抓取、逆向工程、批量注册、自动化滥用、传播恶意代码等）。
            • 未经许可的商业推广、引流、传销、诈骗、赌博、色情、暴力、仇恨或其他高风险行为。
            """
        case .serviceChanges:
            return """
            • 我们可能基于运营或安全需要，对服务进行更新、优化、下线或变更。对于影响重大或涉及付费权益的变更，将以应用内公告或其他合理方式提前告知。
            • 如用户严重违反法律法规或本条款/规则，我们可在依法合规的范围内采取限制或终止服务措施。
            """
        case .disclaimer:
            return """
            • 本产品按"现状"与"可用"提供，不保证无错误、不中断或完全满足您的个别需求。
            • 对因自然灾害、网络或通信故障、第三方服务异常、系统维护、不可抗力或非因我们原因造成的损失，我们不承担责任。
            • 对于用户因不当使用健康/运动功能造成的身体不适或损害，我们不承担医疗或赔偿责任；但法律另有规定或另行约定的除外。
            """
        case .infringement:
            return "如您认为您的合法权益被侵害，请通过应用内\"意见反馈\"或客服渠道提交权属证明、侵权链接/内容、联系方式与请求。我们将在核验后依法处理。"
        case .law:
            return """
            • 本条款的订立、效力、解释、变更、执行与争议解决，适用中华人民共和国法律（不含冲突规范）。
            • 因本条款或本产品产生的争议，双方应友好协商；协商不成的，提交本产品运营者所在地有管辖权的人民法院诉讼解决。
            """
        case .updates:
            return "我们可能根据业务、法律或监管变化更新本条款。重大变更将通过应用内公告等方式提示。若您不同意更新，请停止使用并注销账户；继续使用即视为同意受更新后的条款约束。"
        case .contact:
            return """
            • 应用内：进入"设置 > 意见反馈"或相关客服入口。
            • 处理周期：一般在7个自然日内反馈（复杂情形适度延长）。

            — 感谢您使用青禾计划 —
            """
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
                PersonalInfoItem(name: "网络类型", purpose: "用于优化网络连接", isRequired: false),
                PersonalInfoItem(name: "推送令牌", purpose: "用于向您下发系统与服务通知（APNs）", isRequired: false),
                PersonalInfoItem(name: "广告标识符（IDFA）", purpose: "经您在ATT中授权后用于广告归因与反作弊；拒绝不影响基本功能", isRequired: false)
            ]
        case .usage:
            return [
                PersonalInfoItem(name: "使用时长", purpose: "用于统计分析和改进服务", isRequired: false),
                PersonalInfoItem(name: "功能使用情况", purpose: "用于产品优化", isRequired: false),
                PersonalInfoItem(name: "崩溃日志", purpose: "用于问题修复", isRequired: false),
                PersonalInfoItem(name: "位置信息", purpose: "用于位置相关功能（在授权后）", isRequired: false),
                PersonalInfoItem(name: "订单与交易摘要", purpose: "用于订阅校验、售后与风控（不含支付卡信息）", isRequired: false),
                PersonalInfoItem(name: "健康与睡眠相关数据（可选）", purpose: "用于提供个性化分析与工具，不构成医疗建议", isRequired: false)
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
    case ads // 腾讯广告（广点通/GDT）
    case ossCdn // 阿里云对象存储与CDN

    var name: String {
        switch self {
        case .analytics: return "内置统计（无独立第三方SDK）"
        case .push: return "Apple 推送通知（APNs）"
        case .payment: return "Apple 内购（StoreKit）"
        case .map: return "Apple 地图/定位（CoreLocation/Maps）"
        case .ads: return "腾讯广告（广点通/GDT）SDK"
        case .ossCdn: return "阿里云对象存储与 CDN（OSS/CDN）"
        }
    }

    var category: String {
        switch self {
        case .analytics: return "分析"
        case .push: return "通知"
        case .payment: return "支付"
        case .map: return "位置"
        case .ads: return "广告"
        case .ossCdn: return "存储/分发"
        }
    }

    var purpose: String {
        switch self {
        case .analytics: return "用于分析应用使用情况（仅内部统计），改进产品体验"
        case .push: return "用于向用户发送消息通知"
        case .payment: return "用于处理应用内购买、收据验证与订阅管理"
        case .map: return "用于提供位置相关服务"
        case .ads: return "用于开屏/信息流广告展示、投放优化与反作弊"
        case .ossCdn: return "用于图片/音视频等静态资源的存储与分发"
        }
    }

    var sharedInfo: String {
        switch self {
        case .analytics: return "设备信息、使用统计（聚合/匿名化）"
        case .push: return "设备标识、推送令牌"
        case .payment: return "订单信息、交易收据、订阅状态"
        case .map: return "位置信息（在授权后）"
        case .ads: return "设备信息、广告标识符（经同意）、网络信息、粗略位置信息、曝光/点击事件"
        case .ossCdn: return "上传的媒体文件、URL、元数据（文件名/大小/格式）"
        }
    }

    var website: String? {
        switch self {
        case .analytics: return nil
        case .push: return "apple.com/legal/privacy/"
        case .payment: return "apple.com/legal/privacy/"
        case .map: return "apple.com/legal/privacy/"
        case .ads: return "privacy.qq.com"
        case .ossCdn: return "aliyun.com"
        }
    }
}

// MARK: - 隐私政策页面
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("青禾计划隐私政策")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.bottom, 10)
                    
                    ForEach(PrivacyPolicySection.allCases, id: \.self) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title)
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text(section.content)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                    }
                    
                    Text("最后更新时间：2025年10月14日")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onAppear {
            print("🧭 PrivacyPolicyView onAppear - navigationPath.count = \(navigationPath.count)")
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
            
            Text("隐私政策")
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

// MARK: - 隐私政策章节枚举
enum PrivacyPolicySection: CaseIterable {
    case introduction
    case informationCollection
    case informationUse
    case thirdPartySharing
    case storage
    case cookies
    case childrenProtection
    case userRights
    case automation
    case security
    case crossBorder
    case policyUpdates
    case contact

    var title: String {
        switch self {
        case .introduction: return "引言"
        case .informationCollection: return "1. 我们收集的信息"
        case .informationUse: return "2. 信息的使用目的与法律依据"
        case .thirdPartySharing: return "3. 第三方共享与委托处理"
        case .storage: return "4. 信息的存储地点与期限"
        case .cookies: return "5. Cookies 与本地存储"
        case .childrenProtection: return "6. 未成年人保护"
        case .userRights: return "7. 您的权利"
        case .automation: return "8. 自动化决策与个性化推荐"
        case .security: return "9. 信息安全"
        case .crossBorder: return "10. 跨境传输"
        case .policyUpdates: return "11. 本政策的更新"
        case .contact: return "12. 联系我们"
        }
    }

    var content: String {
        switch self {
        case .introduction:
            return "青禾计划（以下简称\"我们\"或\"本产品\"）非常重视您的个人信息与隐私保护。本隐私政策旨在说明我们如何收集、使用、共享、存储与保护您的个人信息，以及您所享有的权利。\n\n数据控制者/运营者：杭州耶里信息技术有限责任公司\n联系邮箱：hangzhouyeli@gmail.com\nICP备案号：浙ICP备2023025943号-4\n\n使用本产品前，请您仔细阅读并充分理解本政策要点；您使用本产品即表示您已阅读并同意本政策。\n\n本政策适用于青禾计划 iOS 客户端、网站、API 及相关配套服务。"
        case .informationCollection:
            return """
            我们基于提供与优化服务之目的，按照最小必要原则收集以下类别的信息。不同功能可能需要不同的授权，您可以在系统设置中进行管理。

            1) 账户与身份信息（注册/登录）
            • 手机号码、验证码/密码、Apple 登录标识与身份令牌（仅用于认证与安全）
            • 昵称、头像、性别、生日、所在地、学校、个人简介等资料字段
            • 青禾ID、注册时间、最后活跃时间、账号状态等账号元数据

            2) 用户内容与互动信息（UGC）
            • 您发布的帖子、评论、图片、音/视频、话题与标签、收藏与点赞、私信内容与时间等
            • 涉及图片/音视频上传的文件名、URL、大小、格式、CDN/存储提供方信息（如阿里云）

            3) 设备与日志信息
            • 设备型号、操作系统版本、应用版本、网络类型
            • 应用使用时长、功能使用情况、性能与崩溃日志、错误报告
            • IP 地址与 IP 归属地（用于安全与风控、展示归属地与合规要求）

            4) 位置信息（在您授权后）
            • 精确定位：用于"同城/附近"等位置相关功能
            • 模糊或派生定位：如基于 IP 的归属地
            • 您可在系统设置中撤回定位权限，不影响不依赖定位的功能使用

            5) 健康与睡眠相关数据（可选）
            • 您在本产品中主动记录或生成的睡眠/健康相关数据（如目标、偏好、睡眠时段与质量评分、音频事件特征等）
            • 此类数据用于提供个性化分析与工具功能，不构成医疗建议

            6) 支付与订阅信息（Apple 内购）
            • 交易 ID、收据摘要、商品 ID、订阅状态、剩余天数等
            • 我们不直接接触您的支付卡信息，相关支付由 Apple 处理

            7) 通信与客服
            • 您与我们的沟通记录（工单、反馈、申诉、举报）及其处理结果
            """
        case .informationUse:
            return """
            我们将出于以下目的使用您的信息：
            • 提供、维护、优化产品功能与用户体验
            • 账号注册、登录认证与安全防护
            • 实现社区发布、互动、搜索与推荐（可能基于内容与使用行为进行个性化排序）
            • 位置相关服务（在授权后）
            • 健康/睡眠分析与工具功能（在您自愿提供相关数据时）
            • 内购订阅与会员权益的校验、开通与售后
            • 故障排查、性能监测与统计分析
            • 处理投诉举报、侵权通知与纠纷
            • 遵守法律法规与监管要求

            在中国个人信息保护相关法律框架下，我们处理个人信息通常基于以下一种或多种合法性基础：
            • 取得您的单独或明示同意
            • 履行与您签订或履行的合同所必需
            • 履行法定职责或法定义务所必需
            • 应对突发公共卫生事件或紧急情况下保护自然人的生命健康和财产安全所必需
            • 在合理范围内为新闻报道、舆论监督等公共利益实施而进行
            • 在合理范围内处理您自行公开或其他已合法公开的信息
            • 法律法规规定的其他情形
            """
        case .thirdPartySharing:
            return """
            为实现业务功能与安全合规，可能涉及以下第三方服务或委托方：
            • Apple 身份认证（AuthenticationServices）：用于 Apple 登录授权与身份令牌验证
            • Apple 内购（StoreKit）与 APNs：用于订阅购买、交易验证与推送通知
            • 腾讯广告（广点通/GDT）SDK：用于开屏/信息流广告展示、投放优化与反作弊；如您拒绝“允许App跟踪”权限（ATT），SDK 不会获取您的 IDFA
            • 阿里云对象存储与 CDN：用于图片/音视频存储与分发
            • 地图与定位（CoreLocation/Maps）：用于位置相关功能
            • Web 内容渲染（WebKit，若内嵌特定页面）

            说明：第三方可能独立收集与处理您的信息，您应同时查阅其隐私政策与条款。
            """
        case .storage:
            return """
            • 存储地点：原则上在中华人民共和国境内存储与处理。
            • 存储期限：在达成收集目的所必需的最短期限内保存；法律法规或争议处理需要延长的，依法延长。期满后将删除或匿名化处理。
            • 备份：出于安全与审计需要，删除可能不会即时从备份介质中移除，但会在备份轮换后完成删除。
            """
        case .cookies:
            return "iOS 客户端不使用传统网站 Cookie；但可能使用本地存储（如数据库、缓存、Keychain）以保存登录状态、配置或离线数据。"
        case .childrenProtection:
            return "未成年人应在监护人指导下使用本产品。涉及未成年人数据的处理将遵循最小必要与保护优先原则。监护人可通过\"意见反馈\"与我们联系以访问、更正或删除相关数据。"
        case .userRights:
            return """
            在法律允许范围内，您可以行使以下权利：
            • 访问与复制：获取您的个人信息副本（在技术可行范围内）
            • 更正与更新：纠正不准确或不完整的信息
            • 删除：满足法定条件时，您可以请求删除相关信息
            • 撤回同意：对于基于同意处理的场景，您可随时撤回，不影响撤回前的处理活动合法性
            • 账户注销：在"设置—账号与安全"中发起，注销后我们将删除或匿名化处理您的个人信息（法律法规另有规定的除外）
            • 投诉与申诉：通过应用内"意见反馈"或客服渠道提交，我们通常在7个自然日内反馈（复杂情形适度延长）

            为保障安全，我们可能需要您提供身份验证或相关证明。对于显著不合理、重复或需要过多技术投入的请求，我们在法律允许范围内可予以拒绝或收取合理费用。
            """
        case .automation:
            return "我们可能基于您的内容与使用行为进行个性化排序或推荐，以提升体验。您可通过调整偏好、关闭部分个性化设置或减少相关数据提供来影响推荐效果。"
        case .security:
            return """
            • 我们采用加密传输、访问控制、最小权限、敏感分级、审计与监测等安全措施，降低数据泄露、损毁、误用或未授权访问的风险。
            • 如发生个人信息安全事件，我们将按照法律法规的要求向您告知基本情况、可能影响、已采取或将采取的措施、建议您自主防范的措施以及补救措施，并按监管要求上报。
            """
        case .crossBorder:
            return "原则上不进行个人信息跨境传输；如确需发生（例如使用境外服务进行必要处理），我们将依法评估并履行相应合规义务，并征得您的单独同意。"
        case .policyUpdates:
            return "我们可能因业务与法律变化更新本政策。重大变更将通过应用内公告等合理方式提示，更新后继续使用即视为同意受其约束。您可在应用内或官网查看最新版本。"
        case .contact:
            return """
            • 应用内：进入"设置 > 意见反馈"或相关客服入口。
            • 处理周期：一般在7个自然日内反馈（复杂情形适度延长）。

            — 感谢您信任青禾计划 —
            """
        }
    }
}
