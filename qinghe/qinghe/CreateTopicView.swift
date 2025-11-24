import SwiftUI

/// 创建话题页面
struct CreateTopicView: View {
    @Environment(\.dismiss) private var dismiss

    enum Permission {
        case all
        case admin
    }

    // 基本信息
    @State private var titleText: String = ""
    @State private var descText: String = ""
    @State private var permission: Permission = .all

    // 交互状态
    @State private var hasCover: Bool = false
    @State private var isUploading: Bool = false
    @State private var isCreating: Bool = false
    @State private var showSuccess: Bool = false

    private let maxTitleLength: Int = 15

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.97, blue: 0.96)
                .ignoresSafeArea()

            if showSuccess {
                successBody
            } else {
                mainBody
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }

    // MARK: - 成功状态视图
    private var successBody: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppConstants.Colors.primaryGreen.opacity(0.15))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(AppConstants.Colors.primaryGreen)
                    .frame(width: 80, height: 80)
                    .shadow(color: AppConstants.Colors.primaryGreen.opacity(0.4), radius: 14, x: 0, y: 8)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 4)

            Text("话题创建成功")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.primary)

            VStack(spacing: 4) {
                Text("话题 #\(titleText.isEmpty ? "话题名称" : titleText) 已上线")
                Text("快去邀请群友参与讨论吧！")
            }
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            VStack(spacing: 10) {
                Button(action: {
                    resetTopic()
                    // TODO: 实际项目中可跳转到话题详情
                }) {
                    Text("查看话题")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppConstants.Colors.primaryGreen)
                        .cornerRadius(999)
                        .shadow(color: AppConstants.Colors.primaryGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                }

                Button(action: {
                    resetTopic()
                    // TODO: 实际项目中可返回话题列表
                }) {
                    Text("返回列表")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(AppConstants.Colors.primaryGreen.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - 创建话题主界面
    private var mainBody: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    previewSection
                    coreInputSection
                    permissionSection
                    footerNote
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
    }

    // 顶部导航栏
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

            Text("创建话题")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            Button(action: handleCreate) {
                HStack(spacing: 6) {
                    if isCreating {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    }
                    Text(isCreating ? "创建中" : "创建")
                        .font(.system(size: 13, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(createEnabled ? AppConstants.Colors.primaryGreen : Color.gray.opacity(0.2))
                .foregroundColor(createEnabled ? .white : Color.gray.opacity(0.6))
                .cornerRadius(999)
                .shadow(color: createEnabled ? AppConstants.Colors.primaryGreen.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
            }
            .disabled(!createEnabled || isCreating)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var createEnabled: Bool {
        !titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - 效果预览区
    private var previewSection: some View {
        HStack {
            ZStack {
                if hasCover {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.02, green: 0.37, blue: 0.31),
                                    Color(red: 0.03, green: 0.55, blue: 0.48)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.25),
                                radius: 14,
                                x: 0,
                                y: 8)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: AppConstants.Colors.primaryGreen.opacity(0.2),
                                radius: 8,
                                x: 0,
                                y: 4)
                }

                if !hasCover {
                    VStack(spacing: 8) {
                        if isUploading {
                            ProgressView()
                                .tint(AppConstants.Colors.primaryGreen)
                            Text("上传中...")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppConstants.Colors.primaryGreen)
                        } else {
                            Image(systemName: "number")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(Color.gray.opacity(0.25))
                        }
                    }
                }

                if hasCover {
                    VStack {
                        HStack {
                            Text("NEW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(6)

                            Spacer()

                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
                        }
                        Spacer()
                    }
                    .padding(10)
                }

                // 内容层
                VStack(spacing: 10) {
                    HStack {
                        Text("NEW")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(hasCover ? Color.white.opacity(0.2) : AppConstants.Colors.primaryGreen.opacity(0.12))
                            .foregroundColor(hasCover ? .white : AppConstants.Colors.primaryGreen)
                            .cornerRadius(6)

                        Spacer()
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("#")
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(hasCover ? Color.white.opacity(0.7) : AppConstants.Colors.primaryGreen)
                            Text(titleText.isEmpty ? "话题名称" : titleText)
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(hasCover ? .white : .primary)
                                .lineLimit(1)
                        }

                        Text(descText.isEmpty ? "添加一句描述，吸引大家参与..." : descText)
                            .font(.system(size: 11))
                            .foregroundColor(hasCover ? Color.white.opacity(0.8) : .secondary)
                            .lineLimit(1)
                    }
                }
                .padding(14)

                // 右上角移除封面按钮
                if hasCover {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                hasCover = false
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .frame(height: 120)
        }
    }

    // MARK: - 核心填写区
    private var coreInputSection: some View {
        VStack(spacing: 0) {
            // 话题名称
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("话题名称")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(min(titleText.count, maxTitleLength))/\(maxTitleLength)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(titleText.count >= maxTitleLength ? .red.opacity(0.8) : .secondary.opacity(0.7))
                }

                HStack(spacing: 8) {
                    Text("#")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(AppConstants.Colors.primaryGreen)

                    ZStack(alignment: .trailing) {
                        TextField("例如：晨间冥想打卡", text: $titleText)
                            .onChange(of: titleText) { _, newValue in
                                if newValue.count > maxTitleLength {
                                    titleText = String(newValue.prefix(maxTitleLength))
                                }
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .placeholder(when: titleText.isEmpty) {
                                Text("例如：晨间冥想打卡")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color.gray.opacity(0.3))
                            }

                        if !titleText.isEmpty {
                            Button(action: { titleText = "" }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .padding(6)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(12)
            }
            .padding(16)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.06))
                    .frame(height: 1),
                alignment: .bottom
            )

            // 话题简介
            VStack(alignment: .leading, spacing: 8) {
                Text("话题简介")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $descText)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .frame(minHeight: 80)
                        .padding(6)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)

                    if descText.isEmpty {
                        Text("在这个话题下，我们一起讨论...")
                            .font(.system(size: 13))
                            .foregroundColor(Color.gray.opacity(0.4))
                            .padding(.top, 12)
                            .padding(.leading, 10)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color.white)

            // 封面上传
            VStack(alignment: .leading, spacing: 8) {
                Button(action: handleUpload) {
                    HStack(spacing: 8) {
                        if isUploading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(AppConstants.Colors.primaryGreen)
                            Text("上传中...")
                        } else if hasCover {
                            Image(systemName: "checkmark.circle.fill")
                            Text("封面已上传 (点击移除)")
                        } else {
                            Image(systemName: "camera.fill")
                            Text("上传背景图")
                        }
                    }
                    .font(.system(size: 13, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                hasCover ? AppConstants.Colors.primaryGreen : Color.gray.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: [6])
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(hasCover ? AppConstants.Colors.primaryGreen.opacity(0.08) : Color.clear)
                            )
                    )
                    .foregroundColor(hasCover ? AppConstants.Colors.primaryGreen : .secondary)
                }
                .disabled(isUploading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AppConstants.Colors.primaryGreen.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - 权限设置
    private var permissionSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("参与权限")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.05))

            VStack(spacing: 0) {
                permissionRow(
                    title: "全员参与",
                    subtitle: "所有成员均可在此话题下发帖",
                    iconName: "person.3.fill",
                    isSelected: permission == .all
                ) {
                    permission = .all
                }

                Divider().background(Color.gray.opacity(0.05))

                permissionRow(
                    title: "仅管理员",
                    subtitle: "仅管理员可发帖，成员仅可评论",
                    iconName: "shield.fill",
                    isSelected: permission == .admin
                ) {
                    permission = .admin
                }
            }
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppConstants.Colors.primaryGreen.opacity(0.08), lineWidth: 1)
        )
    }

    private func permissionRow(title: String,
                               subtitle: String,
                               iconName: String,
                               isSelected: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                HStack(spacing: 10) {
                    Circle()
                        .fill(isSelected ? AppConstants.Colors.primaryGreen.opacity(0.15) : Color.gray.opacity(0.12))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: iconName)
                                .font(.system(size: 18))
                                .foregroundColor(isSelected ? AppConstants.Colors.primaryGreen : .secondary)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isSelected ? AppConstants.Colors.primaryGreen : .primary)
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? AppConstants.Colors.primaryGreen : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(AppConstants.Colors.primaryGreen)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? AppConstants.Colors.primaryGreen.opacity(0.05) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 底部提示
    private var footerNote: some View {
        Text("创建话题即代表同意《社区话题管理规范》，请勿发布违规内容。\n好的话题名称能带来更多流量哦～")
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.top, 8)
    }

    // MARK: - 逻辑
    private func handleUpload() {
        if hasCover {
            // 模拟移除封面
            hasCover = false
            return
        }

        guard !isUploading else { return }
        isUploading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isUploading = false
            hasCover = true
        }
    }

    private func handleCreate() {
        guard createEnabled, !isCreating else { return }
        isCreating = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCreating = false
            showSuccess = true
        }
    }

    private func resetTopic() {
        titleText = ""
        descText = ""
        permission = .all
        hasCover = false
        isUploading = false
        isCreating = false
        showSuccess = false
    }
}

// MARK: - 占位符扩展（仅此文件使用）
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
        CreateTopicView()
    }
}
