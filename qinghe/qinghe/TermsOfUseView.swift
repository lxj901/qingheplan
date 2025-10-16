import SwiftUI

struct TermsOfUseView: View {
    @Binding var navigationPath: NavigationPath
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 自定义导航栏
                customNavigationBar

                // 内容区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 标题
                        Text("使用条款")
                            .font(.system(size: 28, weight: .bold))
                            .padding(.horizontal)
                            .padding(.top, 24)

                        // 最后更新日期
                        Text("最后更新：2025年1月")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        Divider()
                            .padding(.vertical, 8)

                        // 条款内容
                        VStack(alignment: .leading, spacing: 20) {
                            termsSection(
                                title: "1. 服务说明",
                                content: """
                                欢迎使用清和App。清和是一款专注于健康管理的移动应用程序，为用户提供健康数据记录、分析和建议服务。使用本服务即表示您同意遵守本使用条款。
                                """
                            )

                            termsSection(
                                title: "2. 用户账户",
                                content: """
                                • 您需要创建一个账户才能使用某些功能
                                • 您有责任保护账户安全和密码的保密性
                                • 您对账户下的所有活动负责
                                • 如发现账户被未授权使用，请立即通知我们
                                """
                            )

                            termsSection(
                                title: "3. 用户行为规范",
                                content: """
                                使用本服务时，您不得：
                                • 发布虚假、误导性或不准确的信息
                                • 侵犯他人的知识产权或其他权利
                                • 传播恶意软件或从事其他有害活动
                                • 骚扰、威胁或冒充他人
                                • 违反任何适用的法律法规
                                """
                            )

                            termsSection(
                                title: "4. 会员服务",
                                content: """
                                • 会员服务提供额外的功能和权益
                                • 会员费用将在购买时明确告知
                                • 会员订阅将自动续订，除非您取消订阅
                                • 退款政策遵循App Store的相关规定
                                """
                            )

                            termsSection(
                                title: "5. 健康免责声明",
                                content: """
                                • 本应用提供的健康信息仅供参考
                                • 不能替代专业医疗建议、诊断或治疗
                                • 在做出任何健康决定前，请咨询专业医疗人员
                                • 我们不对使用本服务导致的任何健康问题负责
                                """
                            )

                            termsSection(
                                title: "6. 知识产权",
                                content: """
                                • 本服务的所有内容、功能和界面归清和所有
                                • 未经授权，您不得复制、修改或分发任何内容
                                • 您在平台上发布的内容，授予我们使用和展示的权利
                                """
                            )

                            termsSection(
                                title: "7. 隐私保护",
                                content: """
                                我们重视您的隐私。请查看我们的隐私政策以了解我们如何收集、使用和保护您的个人信息。
                                """
                            )

                            termsSection(
                                title: "8. 服务变更与终止",
                                content: """
                                • 我们保留随时修改或终止服务的权利
                                • 我们会尽力提前通知重大变更
                                • 如您违反本条款，我们可能暂停或终止您的账户
                                """
                            )

                            termsSection(
                                title: "9. 责任限制",
                                content: """
                                在法律允许的最大范围内：
                                • 我们不对任何间接、偶然或后果性损害负责
                                • 我们的总责任不超过您支付给我们的费用
                                • 某些司法管辖区不允许责任限制，此条款可能不适用
                                """
                            )

                            termsSection(
                                title: "10. 争议解决",
                                content: """
                                • 本条款受中华人民共和国法律管辖
                                • 因本条款引起的任何争议，应友好协商解决
                                • 协商不成的，提交北京市有管辖权的人民法院解决
                                """
                            )

                            termsSection(
                                title: "11. 联系我们",
                                content: """
                                如对本使用条款有任何疑问，请联系我们：
                                • 邮箱：support@qinghe.app
                                • 应用内反馈
                                """
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.isEmpty {
                    dismiss()
                } else {
                    navigationPath.removeLast()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 17))
                }
                .foregroundColor(.green)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - 条款章节
    private func termsSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(6)
        }
    }
}

#Preview {
    NavigationStack {
        TermsOfUseView(navigationPath: .constant(NavigationPath()))
    }
}
