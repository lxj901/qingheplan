import SwiftUI

/// 发布活动页面
struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss

    enum EventType {
        case offline
        case online
    }

    @State private var eventType: EventType = .offline
    @State private var hasPrice: Bool = false
    @State private var titleText: String = ""
    @State private var detailText: String = ""
    @State private var peopleLimit: String = ""
    @State private var priceText: String = ""

    private let tagOptions: [String] = ["# 国学晨读", "# 中医义诊", "# 线下雅集", "# 周末徒步"]
    private let detailPlaceholder = "填写活动详情、流程安排、嘉宾介绍...\n让大家更了解这次活动"

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.97, blue: 0.96)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        coverSection
                        titleAndDetailSection
                        coreInfoSection
                        peopleAndFeeSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }

    // MARK: - 顶部导航
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.8))
                    )
            }

            Spacer()

            Text("发布活动")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                // TODO: 发布活动逻辑
            }) {
                Text("发布")
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(publishEnabled ? AppConstants.Colors.primaryGreen : Color.gray.opacity(0.2))
                    .foregroundColor(publishEnabled ? .white : Color.gray.opacity(0.6))
                    .cornerRadius(999)
                    .shadow(color: publishEnabled ? AppConstants.Colors.primaryGreen.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
            }
            .disabled(!publishEnabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var publishEnabled: Bool {
        !titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - 封面上传
    private var coverSection: some View {
        Button(action: {
            // TODO: 选择或上传海报
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(AppConstants.Colors.primaryGreen.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                    )

                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.9, green: 0.97, blue: 0.94))
                            .frame(width: 56, height: 56)
                            .shadow(color: AppConstants.Colors.primaryGreen.opacity(0.2), radius: 6, x: 0, y: 3)

                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                    }

                    Text("上传活动海报")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppConstants.Colors.primaryGreen)

                    Text("建议尺寸 16:9，展示活动魅力")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(16)
            }
            .frame(height: 180)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 标题与详情
    private var titleAndDetailSection: some View {
        VStack(spacing: 0) {
            // 标题
            VStack {
                TextField("活动主题 (必填)", text: $titleText)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .placeholder(when: titleText.isEmpty) {
                        Text("活动主题 (必填)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.gray.opacity(0.3))
                    }
            }
            .padding(16)

            Divider().background(Color.gray.opacity(0.06))

            // 详情
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $detailText)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .frame(minHeight: 120)
                        .background(Color.clear)

                    if detailText.isEmpty {
                        Text(detailPlaceholder)
                            .font(.system(size: 13))
                            .foregroundColor(Color.gray.opacity(0.35))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                }
            }
            .padding(16)

            // 标签区域
            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tagOptions, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppConstants.Colors.primaryGreen)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppConstants.Colors.primaryGreen.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }

                Button(action: {
                    // TODO: 添加自定义标签
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text("添加自定义标签")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppConstants.Colors.primaryGreen.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 核心信息设置
    private var coreInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 形式切换
            HStack(spacing: 0) {
                eventTypeButton(title: "线下聚会", type: .offline)
                eventTypeButton(title: "线上讨论", type: .online)
            }
            .padding(4)
            .background(AppConstants.Colors.primaryGreen.opacity(0.05))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppConstants.Colors.primaryGreen.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, 12)
            .padding(.top, 10)

            VStack(spacing: 10) {
                // 开始时间
                settingRow(
                    iconName: "calendar",
                    iconColor: AppConstants.Colors.primaryGreen,
                    title: "开始时间",
                    subtitle: "请选择"
                )

                // 活动地点（线下）
                if eventType == .offline {
                    settingRow(
                        iconName: "mappin.and.ellipse",
                        iconColor: Color.blue,
                        title: "活动地点",
                        subtitle: "选择具体位置"
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppConstants.Colors.primaryGreen.opacity(0.08), lineWidth: 1)
        )
    }

    private func eventTypeButton(title: String, type: EventType) -> some View {
        let isActive = (eventType == type)
        return Button(action: {
            eventType = type
        }) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isActive ? Color.white : Color.clear)
                .foregroundColor(isActive ? AppConstants.Colors.primaryGreen : .secondary)
                .cornerRadius(10)
                .shadow(color: isActive ? Color.black.opacity(0.06) : .clear, radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func settingRow(iconName: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(AppConstants.Colors.primaryGreen.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 14))
                            .foregroundColor(iconColor)
                    )

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
            }

            Spacer()

            HStack(spacing: 4) {
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(14)
    }

    // MARK: - 人数与费用
    private var peopleAndFeeSection: some View {
        VStack(spacing: 0) {
            // 人数限制
            HStack {
                HStack(spacing: 10) {
                    Circle()
                        .fill(AppConstants.Colors.primaryGreen.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppConstants.Colors.primaryGreen)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("人数限制")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    TextField("∞", text: $peopleLimit)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: 40)

                    Text("人")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(10)
            }
            .padding(14)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.06))
                    .frame(height: 1),
                alignment: .bottom
            )

            // 报名费用
            HStack {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "yensign.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        )

                    Text("报名费用")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Text("免费")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(hasPrice ? .secondary : .primary)

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hasPrice.toggle()
                        }
                    }) {
                        ZStack(alignment: hasPrice ? .trailing : .leading) {
                            Capsule()
                                .fill(hasPrice ? AppConstants.Colors.primaryGreen : Color.gray.opacity(0.4))
                                .frame(width: 44, height: 22)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 16, height: 16)
                                .padding(.horizontal, 4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(Color.white)

            if hasPrice {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("¥")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)

                        TextField("0.00", text: $priceText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.06))
                    .cornerRadius(12)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 4, height: 4)
                        Text("费用将直接进入您的圈子账户")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
                .background(Color.white)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppConstants.Colors.primaryGreen.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - View 占位符扩展
private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - 预览
#Preview {
    NavigationStack {
        CreateEventView()
    }
}

