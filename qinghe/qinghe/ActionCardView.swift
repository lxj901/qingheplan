import SwiftUI

/// 动作卡片视图（用于显示问卷卡片、拍照卡片等）
struct ActionCardView: View {
    let card: ActionCard
    let onAction: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和图标
            headerView

            // 描述
            descriptionView

            // 提示信息
            if !card.tips.isEmpty {
                tipsView
            }

            // 操作按钮
            buttonsView
        }
        .padding(16)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - 子视图

    private var headerView: some View {
        HStack(spacing: 8) {
            Text(card.icon)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 2) {
                Text(card.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                if let reason = card.reason, !reason.isEmpty {
                    reasonView(reason)
                }
            }

            Spacer()
        }
    }

    private func reasonView(_ reason: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 11))
                .foregroundColor(.orange)
            Text(reason)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    private var descriptionView: some View {
        Text(card.description)
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .lineLimit(3)
    }

    private var tipsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(card.tips, id: \.self) { tip in
                Text(tip)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.08))
        )
    }

    private var buttonsView: some View {
        HStack(spacing: 12) {
            ForEach(card.buttons, id: \.text) { button in
                buttonView(for: button)
            }
        }
    }

    private func buttonView(for button: ActionCardButton) -> some View {
        let isCompleted = card.isCompleted == true
        let isDisabled = button.isDisabled == true || isCompleted
        let isCompletedStyle = (button.type == "completed") || (isCompleted && button.type == "primary")
        let showCheckmark = isCompletedStyle
        let shouldDim = isDisabled && !isCompletedStyle

        return Button(action: {
            if !isDisabled {
                onAction(button.action)
            }
        }) {
            HStack(spacing: 6) {
                if showCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                }

                Text(button.text)
                    .font(.system(size: 15, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(buttonBackgroundColor(for: button, isCompleted: isCompleted))
            )
            .foregroundColor(buttonTextColor(for: button, isCompleted: isCompleted))
            .opacity(shouldDim ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.95))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
    }
    
    private func buttonBackgroundColor(for button: ActionCardButton, isCompleted: Bool) -> Color {
        // 需求：完成后变成灰色
        if isCompleted && button.type == "primary" {
            return Color.gray.opacity(0.35)
        }
        if button.type == "completed" {
            return Color.gray.opacity(0.35)
        }
        switch button.type {
        case "primary":
            return Color.blue
        case "secondary":
            return Color.gray.opacity(0.15)
        default:
            return Color.gray.opacity(0.15)
        }
    }

    private func buttonTextColor(for button: ActionCardButton, isCompleted: Bool) -> Color {
        // 如果卡片已完成，主按钮显示白色
        if isCompleted && button.type == "primary" {
            return .white
        }

        // 如果按钮类型是 completed
        if button.type == "completed" {
            return .white
        }

        switch button.type {
        case "primary":
            return .white
        case "secondary":
            return .primary
        default:
            return .primary
        }
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 20) {
        // 问卷卡片预览
        ActionCardView(
            card: ActionCard(
                type: "questionnaire",
                diagnosisType: "tongue",
                title: "舌诊前问卷",
                description: "为了提高分析准确性，请先填写一份简短的健康问卷",
                reason: "体质判断需要",
                icon: "📋",
                action: nil,
                buttons: [
                    ActionCardButton(text: "开始填写", type: "primary", action: "start_questionnaire"),
                    ActionCardButton(text: "稍后再说", type: "secondary", action: "dismiss")
                ],
                tips: [
                    "⏱️ 大约需要2-3分钟",
                    "📊 问卷包含8个简单问题",
                    "🔒 您的信息将被严格保密"
                ]
            ),
            onAction: { action in
                print("Action: \(action)")
            }
        )
        .padding()
        
        // 拍照卡片预览
        ActionCardView(
            card: ActionCard(
                type: "tongue_diagnosis",
                diagnosisType: nil,
                title: "舌诊拍照",
                description: "问卷已完成，现在请拍摄您的舌头照片",
                reason: nil,
                icon: "👅",
                action: ActionCardAction(
                    type: "navigate",
                    route: "TongueDiagnosis",
                    diagnosisType: nil,
                    params: nil
                ),
                buttons: [
                    ActionCardButton(text: "立即拍照", type: "primary", action: "start_tongue_diagnosis"),
                    ActionCardButton(text: "稍后再说", type: "secondary", action: "dismiss")
                ],
                tips: [
                    "📸 请在自然光下拍摄",
                    "👅 伸出舌头，保持放松",
                    "⏰ 建议早晨空腹时拍摄"
                ]
            ),
            onAction: { action in
                print("Action: \(action)")
            }
        )
        .padding()
        
        Spacer()
    }
    .background(Color.gray.opacity(0.1))
}

