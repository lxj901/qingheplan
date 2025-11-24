import SwiftUI

/// 发起投票页面
struct CreatePollView: View {
    @Environment(\.dismiss) private var dismiss

    struct PollOption: Identifiable {
        let id = UUID()
        var text: String
    }

    @State private var question: String = ""
    @State private var options: [PollOption] = [
        PollOption(text: ""),
        PollOption(text: "")
    ]

    @State private var allowMultiple: Bool = false
    @State private var anonymous: Bool = false
    @State private var deadline: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(24 * 3600)
    @State private var showDeadlinePicker: Bool = false
    @State private var isPublishing: Bool = false

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.97, blue: 0.96)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        questionSection
                        optionsSection
                        settingsSection
                        footerNote
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .sheet(isPresented: $showDeadlinePicker) {
            deadlinePickerSheet
        }
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

            Text("发起投票")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            Button(action: handlePublish) {
                HStack(spacing: 6) {
                    if isPublishing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    }
                    Text(isPublishing ? "发布中" : "发布")
                        .font(.system(size: 13, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(isValid ? AppConstants.Colors.primaryGreen : Color.gray.opacity(0.2))
                .foregroundColor(isValid ? .white : Color.gray.opacity(0.6))
                .cornerRadius(999)
                .shadow(color: isValid ? AppConstants.Colors.primaryGreen.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
            }
            .disabled(!isValid || isPublishing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - 投票问题
    private var questionSection: some View {
        VStack {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                    .padding(.top, 4)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $question)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(minHeight: 80)

                    if question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("大家想讨论什么？抛出你的问题...")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.gray.opacity(0.3))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppConstants.Colors.primaryGreen.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 选项列表
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("投票选项")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(options.count)/10")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppConstants.Colors.primaryGreen.opacity(0.7))
            }
            .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    optionRow(option: option, index: index)
                }
            }

            if options.count < 10 {
                Button(action: addOption) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("添加选项")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppConstants.Colors.primaryGreen.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    )
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                }
            }
        }
    }

    private func optionRow(option: PollOption, index: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(index + 1).")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.leading, 12)
                .padding(.trailing, 4)

            TextField("选项 \(index + 1)", text: Binding(
                get: { option.text },
                set: { updateOption(option.id, newText: $0) }
            ))
            .font(.system(size: 14))
            .foregroundColor(.primary)
            .padding(.vertical, 10)

            if options.count > 2 {
                Button(action: { removeOption(option.id) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.horizontal, 10)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - 投票设置
    private var settingsSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("投票设置")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.05))

            VStack(spacing: 0) {
                // 多选
                settingRow(
                    iconName: "checklist",
                    iconActiveColor: AppConstants.Colors.primaryGreen,
                    title: "允许多选",
                    subtitle: "开启后成员可选择多个选项",
                    isOn: allowMultiple
                ) {
                    allowMultiple.toggle()
                }

                Divider().background(Color.gray.opacity(0.05))

                // 匿名
                settingRow(
                    iconName: "eye.slash.fill",
                    iconActiveColor: AppConstants.Colors.primaryGreen,
                    title: "匿名投票",
                    subtitle: "成员投票后不显示头像",
                    isOn: anonymous
                ) {
                    anonymous.toggle()
                }

                Divider().background(Color.gray.opacity(0.05))

                // 截止时间
                deadlineRow
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

    private func settingRow(iconName: String,
                            iconActiveColor: Color,
                            title: String,
                            subtitle: String,
                            isOn: Bool,
                            toggle: @escaping () -> Void) -> some View {
        Button(action: toggle) {
            HStack {
                HStack(spacing: 10) {
                    Circle()
                        .fill(isOn ? iconActiveColor.opacity(0.15) : Color.gray.opacity(0.12))
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: iconName)
                                .font(.system(size: 16))
                                .foregroundColor(isOn ? iconActiveColor : .secondary)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 自定义开关
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? AppConstants.Colors.primaryGreen : Color.gray.opacity(0.4))
                        .frame(width: 46, height: 24)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                        .padding(.horizontal, 3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isOn ? AppConstants.Colors.primaryGreen.opacity(0.04) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private var deadlineRow: some View {
        Button(action: {
            showDeadlinePicker = true
        }) {
            HStack {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: "clock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("截止时间")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                        Text("点击修改时间")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(deadlineDescription)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppConstants.Colors.primaryGreen.opacity(0.08))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private var deadlineDescription: String {
        let date = deadline
        let now = Date()
        let diff = date.timeIntervalSince(now)

        if diff < 0 {
            return "已结束"
        }

        let calendar = Calendar.current
        let comps = calendar.dateComponents([.month, .day, .hour, .minute], from: date)
        let base = String(format: "%d月%d日 %02d:%02d",
                          comps.month ?? 0,
                          comps.day ?? 0,
                          comps.hour ?? 0,
                          comps.minute ?? 0)

        let days = Int(diff / (24 * 3600))
        let hours = Int((diff.truncatingRemainder(dividingBy: 24 * 3600)) / 3600)

        if days > 0 {
            return "\(base) (\(days)天后)"
        } else if hours > 0 {
            return "\(base) (\(hours)小时后)"
        } else {
            return base
        }
    }

    // MARK: - 底部提示
    private var footerNote: some View {
        Text("投票发起后不可修改选项，请仔细核对。\n严禁发起涉及敏感话题或违规内容的投票。")
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.top, 8)
    }

    // MARK: - 截止时间选择 sheet
    private var deadlinePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker(
                    "截止时间",
                    selection: $deadline,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()

                Text(deadlineDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppConstants.Colors.primaryGreen)

                Spacer()
            }
            .navigationTitle("选择截止时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        showDeadlinePicker = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        showDeadlinePicker = false
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.5), .large])
    }

    // MARK: - 逻辑
    private var isValid: Bool {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let nonEmptyOptions = options.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return !q.isEmpty && nonEmptyOptions.count >= 2
    }

    private func addOption() {
        guard options.count < 10 else { return }
        options.append(PollOption(text: ""))
    }

    private func removeOption(_ id: UUID) {
        guard options.count > 2 else { return }
        options.removeAll { $0.id == id }
    }

    private func updateOption(_ id: UUID, newText: String) {
        if let index = options.firstIndex(where: { $0.id == id }) {
            options[index].text = newText
        }
    }

    private func handlePublish() {
        guard isValid, !isPublishing else { return }
        isPublishing = true

        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPublishing = false
            // TODO: 成功后可导航到投票详情或返回
            dismiss()
        }
    }
}

// MARK: - 预览
#Preview {
    NavigationStack {
        CreatePollView()
    }
}

