import SwiftUI

/// 账户提现页面
struct WithdrawView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String = ""
    @State private var selectedCardID: Int = WithdrawCard.mockCards.first?.id ?? 0
    @State private var showPasswordSheet: Bool = false
    @State private var password: String = ""
    @State private var step: WithdrawStep = .input

    private let maxAmount: Double = 12845.00

    enum WithdrawStep {
        case input
        case success
    }

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.97, blue: 0.96)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if step == .input {
                    inputStepBody
                } else {
                    successStepBody
                }
            }

            if showPasswordSheet {
                passwordSheetOverlay
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

            Text("提现")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            NavigationLink {
                AccountTransactionsView()
            } label: {
                Text("明细")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 步骤：输入提现信息
    private var inputStepBody: some View {
        VStack(spacing: 16) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    accountSection
                    amountSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }

            // 底部提示 + 按钮
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.top, 2)

                    Text("预计 2 小时内到账。单日最高提现额度 ¥50,000。如遇问题请联系客服。")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 22)

                Button(action: {
                    showPasswordSheet = true
                }) {
                    Text("确认提现")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isConfirmDisabled ? Color.gray.opacity(0.3) : AppConstants.Colors.primaryGreen)
                        .cornerRadius(24)
                        .shadow(
                            color: isConfirmDisabled ? Color.clear : AppConstants.Colors.primaryGreen.opacity(0.3),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                }
                .disabled(isConfirmDisabled)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private var isConfirmDisabled: Bool {
        guard let value = Double(amountText), value > 0, value <= maxAmount else {
            return true
        }
        return false
    }

    // MARK: - 到账账户选择
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("到账账户")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Text("添加账户")
                        .font(.system(size: 12, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(AppConstants.Colors.primaryGreen)
            }

            VStack(spacing: 8) {
                ForEach(WithdrawCard.mockCards) { card in
                    WithdrawAccountRow(
                        card: card,
                        isSelected: card.id == selectedCardID
                    ) {
                        selectedCardID = card.id
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppConstants.Colors.primaryGreen.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    // MARK: - 提现金额
    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("提现金额")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                    Text("手续费 0.1%")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(10)
                .foregroundColor(.secondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("¥")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.primary)

                ZStack(alignment: .trailing) {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 34, weight: .black))
                        .foregroundColor(.primary)
                        .placeholder(when: amountText.isEmpty) {
                            Text("0.00")
                                .font(.system(size: 34, weight: .black))
                                .foregroundColor(Color.gray.opacity(0.2))
                        }

                    if !amountText.isEmpty {
                        Button(action: { amountText = "" }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(6)
                                .background(Color.gray.opacity(0.25))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(height: 1),
                alignment: .bottom
            )

            HStack {
                Text("可提现余额 ¥\(String(format: "%.2f", maxAmount))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    amountText = String(format: "%.2f", maxAmount)
                }) {
                    Text("全部提现")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(32)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(AppConstants.Colors.primaryGreen.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    // MARK: - 步骤：成功状态
    private var successStepBody: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppConstants.Colors.primaryGreen.opacity(0.15))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(AppConstants.Colors.primaryGreen)
                    .frame(width: 80, height: 80)
                    .shadow(color: AppConstants.Colors.primaryGreen.opacity(0.4), radius: 12, x: 0, y: 6)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }

            Text("提现申请已提交")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.primary)

            VStack(spacing: 4) {
                Text("预计将在 今天 14:30 前 到账")
                Text("请留意银行通知短信")
            }
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

            VStack(spacing: 0) {
                HStack {
                    Text("提现金额")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("¥ \(formattedAmount)")
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 8)

                Divider()

                HStack {
                    Text("到账账户")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(selectedCardNameForSummary)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 8)
            }
            .font(.system(size: 13))
            .padding(14)
            .background(Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 32)

            Button(action: {
                amountText = ""
                password = ""
                step = .input
            }) {
                Text("完成")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(999)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var formattedAmount: String {
        let value = Double(amountText) ?? 0
        return String(format: "%.2f", value)
    }

    private var selectedCardNameForSummary: String {
        guard let card = WithdrawCard.mockCards.first(where: { $0.id == selectedCardID }) else {
            return "-"
        }
        if card.type == .bank, let last4 = card.number.suffix(4) as Substring? {
            return "\(card.name) (\(last4))"
        }
        return card.name
    }

    // MARK: - 支付密码弹窗
    private var passwordSheetOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showPasswordSheet = false
                    password = ""
                }

            VStack(spacing: 0) {
                // 标题栏
                ZStack {
                    Text("输入支付密码")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)

                    HStack {
                        Button(action: {
                            showPasswordSheet = false
                            password = ""
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)

                // 金额 + 密码点
                VStack(spacing: 16) {
                    Text("¥ \(formattedAmount)")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.primary)
                        .padding(.top, 16)

                    HStack(spacing: 10) {
                        ForEach(0..<6) { index in
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                    .background(Color.gray.opacity(0.06))
                                if index < password.count {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .frame(width: 42, height: 42)
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                        Text("安全键盘已开启")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)

                // 数字键盘
                VStack(spacing: 0) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 3), spacing: 1) {
                        ForEach(1...9, id: \.self) { num in
                            keypadButton(title: "\(num)") {
                                handleKeyTap("\(num)")
                            }
                        }

                        // 占位空白
                        Color.gray.opacity(0.1)
                            .frame(height: 52)

                        keypadButton(title: "0") {
                            handleKeyTap("0")
                        }

                        keypadButton(systemImage: "delete.left") {
                            handleDelete()
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                }
            }
            .background(Color.white)
            .cornerRadius(28, corners: [.topLeft, .topRight])
        }
        .animation(.easeInOut(duration: 0.25), value: showPasswordSheet)
    }

    private func keypadButton(title: String? = nil,
                              systemImage: String? = nil,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Color.white

                if let title = title {
                    Text(title)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.primary)
                } else if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
        }
        .frame(height: 52)
    }

    private func handleKeyTap(_ key: String) {
        guard password.count < 6 else { return }
        password.append(key)

        if password.count == 6 {
            // 模拟验证成功
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showPasswordSheet = false
                password = ""
                step = .success
            }
        }
    }

    private func handleDelete() {
        guard !password.isEmpty else { return }
        password.removeLast()
    }
}

// MARK: - 到账账户数据与行视图
struct WithdrawCard: Identifiable {
    enum CardType {
        case bank
        case wechat
    }

    let id: Int
    let type: CardType
    let name: String
    let number: String
    let color: Color
    let limitDescription: String

    static let mockCards: [WithdrawCard] = [
        WithdrawCard(
            id: 1,
            type: .bank,
            name: "招商银行",
            number: "****8848",
            color: Color(red: 0.75, green: 0.22, blue: 0.17),
            limitDescription: "单笔限额 5万"
        ),
        WithdrawCard(
            id: 2,
            type: .wechat,
            name: "微信零钱",
            number: "已绑定",
            color: Color(red: 0.03, green: 0.76, blue: 0.38),
            limitDescription: "单笔限额 1万"
        )
    ]
}

private struct WithdrawAccountRow: View {
    let card: WithdrawCard
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(card.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(card.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        Text(card.number)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Text(card.limitDescription)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppConstants.Colors.primaryGreen)
                }
            }
            .padding(10)
            .background(isSelected ? AppConstants.Colors.primaryGreen.opacity(0.08) : Color.gray.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppConstants.Colors.primaryGreen : Color.clear, lineWidth: 1.5)
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch card.type {
        case .bank: return "creditcard.fill"
        case .wechat: return "wallet.pass"
        }
    }
}

// MARK: - 辅助：占位符
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
        WithdrawView()
    }
}
